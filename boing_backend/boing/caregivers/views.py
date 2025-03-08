from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import UserCaregivers, Caregiver

class AddCaregiverView(APIView):
    def post(self, request):
        user_id = request.data.get("user_id")
        caregiver_data = request.data.get("caregiver")

        user_entry = UserCaregivers.objects(user_id=user_id).first()
        if not user_entry:
            user_entry = UserCaregivers(user_id=user_id).save()

        caregiver = Caregiver(**caregiver_data).save()
        user_entry.caregivers.append(caregiver)
        user_entry.save()

        return Response({"message": "Caregiver added"}, status=status.HTTP_201_CREATED)


class GetCaregiversView(APIView):
    def get(self, request, user_id):
        user_entry = UserCaregivers.objects(user_id=user_id).first()
        if not user_entry:
            return Response({"message": "No caregivers found"}, status=status.HTTP_404_NOT_FOUND)

        caregivers = [
            {"id": str(caregiver.id), "name": caregiver.name, "phone": caregiver.phone, "email": caregiver.email}
            for caregiver in user_entry.caregivers
        ]
        return Response({"caregivers": caregivers}, status=status.HTTP_200_OK)


class UpdateCaregiverView(APIView):
    def put(self, request, caregiver_id):
        caregiver = Caregiver.objects(id=caregiver_id).first()
        if not caregiver:
            return Response({"message": "Caregiver not found"}, status=status.HTTP_404_NOT_FOUND)

        caregiver.name = request.data.get("name", caregiver.name)
        caregiver.phone = request.data.get("phone", caregiver.phone)
        caregiver.email = request.data.get("email", caregiver.email)
        caregiver.save()

        return Response({"message": "Caregiver updated"}, status=status.HTTP_200_OK)


class DeleteCaregiverView(APIView):
    def delete(self, request, user_id, caregiver_id):
        user_entry = UserCaregivers.objects(user_id=user_id).first()
        if not user_entry:
            return Response({"message": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        caregiver = Caregiver.objects(id=caregiver_id).first()
        if not caregiver:
            return Response({"message": "Caregiver not found"}, status=status.HTTP_404_NOT_FOUND)

        # Remove caregiver from user's list
        user_entry.caregivers.remove(caregiver)
        user_entry.save()

        # Delete caregiver document from MongoDB
        caregiver.delete()

        return Response({"message": "Caregiver deleted"}, status=status.HTTP_200_OK)
