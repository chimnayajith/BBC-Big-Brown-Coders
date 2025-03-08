from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import status
from .models import User
from .serializers import UserSerializer, get_tokens_for_user
from django.contrib.auth.hashers import check_password

import json
class RegisterView(APIView):
    def post(self, request):

        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token = get_tokens_for_user(user)
            return Response({"token": token['jwt']}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    def post(self, request):
        data = request.data
        email = data.get("email")
        password = data.get("password")

        user = User.objects.filter(email=email).first()

        if user and check_password(password, user.password):
            token = get_tokens_for_user(user)
            return Response({
                "token": token['jwt'],
                "user": {
                    "name": user.name,
                    "phone": user.phone,
                    "email": user.email,
                    "role": user.role
                }
            }, status=status.HTTP_200_OK)

        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

from rest_framework.views import APIView
from rest_framework.response import Response
import jwt
from django.conf import settings

class DebugTokenView(APIView):
    def post(self, request):
        token = request.data.get('token', '')
        
        # Check if token is in the right format
        if not token or not isinstance(token, str) or token.count('.') != 2:
            return Response({
                "error": "Invalid token format. Expected format: header.payload.signature",
                "received_token": token
            }, status=400)
            
        try:
            # Decode token manually without verification to see contents
            decoded = jwt.decode(token, options={"verify_signature": False})
            
            # Try to find user by decoded user_id
            user_id = decoded.get('user_id')
            try:
                from .models import User
                user = User.objects.get(id=user_id)
                user_exists = f"User found: {user.email}"
            except User.DoesNotExist:
                user_exists = f"No user with ID {user_id} found"
            except Exception as e:
                user_exists = f"Error checking user: {str(e)}"
            
            return Response({
                "token_contents": decoded,
                "user_check": user_exists
            })
        except Exception as e:
            return Response({
                "error": str(e),
                "received_token": token
            }, status=400)