from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from authing.models import User
from .serializers import ElderlyUserSerializer
from rest_framework_simplejwt.authentication import JWTAuthentication

class CareGiverElderlyView(APIView):
    authentication_classes = [JWTAuthentication]  # Explicitly specify authentication
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        # Check if the requesting user is a caregiver
        if request.user.role != 'caregiver':
            return Response(
                {"error": "Only caregivers can access this endpoint"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get all elderly users
        elderly_users = User.objects.filter(role='elderly')
        serializer = ElderlyUserSerializer(elderly_users, many=True)
        
        return Response(serializer.data, status=status.HTTP_200_OK)