from django.urls import path
from .views import SOSConfigView

urlpatterns = [
    path("edit-config/", SOSConfigView.as_view(), name="edit-config"),
]