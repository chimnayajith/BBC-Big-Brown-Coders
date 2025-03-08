from rest_framework import serializers
from .models import SOSConfig

class SOSConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = SOSConfig
        fields = "__all__"