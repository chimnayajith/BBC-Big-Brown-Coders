from django.urls import re_path
from .consumers import LiveLocationConsumer

websocket_urlpatterns = [
    re_path(r"ws/location/(?P<user_id>\w+)/$", LiveLocationConsumer.as_asgi()),
]