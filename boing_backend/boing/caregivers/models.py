from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class SOSConfig(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="sos_config")
    
    contact_mode = models.CharField(max_length=10, choices=[("text", "Text"), ("call", "Call")], default="text")

    battery_sos_enabled = models.BooleanField(default=False)
    battery_threshold = models.IntegerField(default=15)

    phone_fall_sos_enabled = models.BooleanField(default=True)

    cctv_fall_sos_enabled = models.BooleanField(default=True)

    def __str__(self):
        return f"SOS Config for {self.user.email}"