from rest_framework import serializers
from authing.models import User

class ElderlyUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'phone', 'email', 'emergency_contact']
        # Exclude sensitive fields like password