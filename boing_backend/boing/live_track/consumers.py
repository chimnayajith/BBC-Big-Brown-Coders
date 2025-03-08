import json
from channels.generic.websocket import AsyncWebsocketConsumer
from .models import UserLocation
from django.utils.timezone import now

class LiveLocationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user_id = self.scope["url_route"]["kwargs"]["user_id"]
        self.room_group_name = f"location_{self.user_id}"

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        latitude = data["lat"]
        longitude = data["lon"]

        UserLocation.objects.create(
            user_id=self.user_id, latitude=latitude, longitude=longitude, timestamp=now()
        )

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "send_location",
                "latitude": latitude,
                "longitude": longitude,
            },
        )

    async def send_location(self, event):
        await self.send(text_data=json.dumps({
            "latitude": event["latitude"],
            "longitude": event["longitude"],
        }))
