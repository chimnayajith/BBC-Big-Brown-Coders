from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from .models import SOSConfig
from .serializers import SOSConfigSerializer

class SOSConfigView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sos_config, _ = SOSConfig.objects.get_or_create(user=request.user)
        serializer = SOSConfigSerializer(sos_config)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        sos_config, _ = SOSConfig.objects.get_or_create(user=request.user)
        serializer = SOSConfigSerializer(sos_config, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
