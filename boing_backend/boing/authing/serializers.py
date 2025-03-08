from rest_framework import serializers
from .models import User
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import check_password


class UserSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    phone = serializers.CharField(max_length=15)
    email = serializers.EmailField()
    role = serializers.ChoiceField(choices=['elderly', 'caregiver'])
    password = serializers.CharField(write_only=True)

    def validate_phone(self, value):
        if not value:
            raise serializers.ValidationError("Phone number is required.")
        return value
    
    def create(self, validated_data):
        user = User(
            name=validated_data["name"],
            phone=validated_data["phone"],
            email=validated_data.get("email", ""),
            role = validated_data.get("role", "")
        )
        user.set_password(validated_data["password"])
        user.save()
        return user

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'access': str(refresh.access_token),
    }

from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User
from rest_framework_simplejwt.tokens import RefreshToken


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=15, required=True)
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        phone = data.get("phone")
        password = data.get("password")

        try:
            user = User.objects.get(phone=phone)
        except User.DoesNotExist:
            raise serializers.ValidationError("User not found.")

        if not user.check_password(password):
            raise serializers.ValidationError("Invalid credentials.")

        return {"user": user}

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
    }
