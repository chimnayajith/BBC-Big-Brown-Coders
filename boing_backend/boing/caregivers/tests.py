from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from caregivers.models import Caregiver, UserCaregivers

class CaregiverTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user_id = "12345"

        self.caregiver_data = {
            "name": "John Doe",
            "phone": "9876543210",
            "email": "john@example.com"
        }

    def test_add_caregiver(self):
        response = self.client.post("/caregivers/add/", {"user_id": self.user_id, "caregiver": self.caregiver_data}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # Check if caregiver is stored in MongoDB
        self.assertTrue(Caregiver.objects(email="john@example.com").first() is not None)

    def test_add_caregiver_to_existing_user(self):
        """Test adding multiple caregivers to the same user"""
        self.client.post("/caregivers/add/", {"user_id": self.user_id, "caregiver": self.caregiver_data}, format="json")
        new_caregiver_data = {"name": "Jane Doe", "phone": "9876543211", "email": "jane@example.com"}
        response = self.client.post("/caregivers/add/", {"user_id": self.user_id, "caregiver": new_caregiver_data}, format="json")
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # Check if user has 2 caregivers
        user_entry = UserCaregivers.objects(user_id=self.user_id).first()
        self.assertEqual(len(user_entry.caregivers), 2)
