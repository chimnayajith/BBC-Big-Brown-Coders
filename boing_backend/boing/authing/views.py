from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import status
from .models import User
from .serializers import UserSerializer, get_tokens_for_user
import json
class RegisterView(APIView):
    def post(self, request):
        data = json.loads(request.body)
        print("Received Data:", data)

        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token = get_tokens_for_user(user)
            return Response({"token": token}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    def post(self, request):
        data = request.data
        email = data.get("email")
        password = data.get("password")

        user = User.objects(email=email).first()
        if user and check_password(password, user.password):
            token = get_tokens_for_user(user)
            return Response({
                "token": token,
                "user": {
                    "name": user.name,
                    "phone": user.phone,
                    "email": user.email,
                    "role": user.role
                }
            }, status=status.HTTP_200_OK)

        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
