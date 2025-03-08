from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import User
from .serializers import UserSerializer, LoginSerializer
from django.contrib.auth.hashers import check_password
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.views import View
import json
from .models import User
import bcrypt

@method_decorator(csrf_exempt, name="dispatch")
class RegisterView(View):
    permission_classes = [AllowAny]
    def post(self, request):
        try:
            data = json.loads(request.body)
            name = data.get("name")
            email = data.get("email")
            password = data.get("password")

            if not name or not email or not password:
                return JsonResponse({"error": "Missing fields"}, status=400)

            hashed_pw = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

            user = User(name=name, email=email, password=hashed_pw)
            user.save()

            return JsonResponse({"message": "User registered successfully"}, status=201)

        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)


class LoginView(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            password = serializer.validated_data['password']

            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

            if not check_password(password, user.password):
                return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

            refresh = RefreshToken.for_user(user)
            return Response({
                "refresh": str(refresh),
                "access": str(refresh.access_token)
            })

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
