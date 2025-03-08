import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import live_track.routing  # Replace 'yourapp' with your actual app name

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "boing.settings")

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(live_track.routing.websocket_urlpatterns)
    ),
})