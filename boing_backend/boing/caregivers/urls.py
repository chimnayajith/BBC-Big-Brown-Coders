from django.urls import path
from .views import AddCaregiverView, GetCaregiversView, UpdateCaregiverView, DeleteCaregiverView

urlpatterns = [
    path('add/', AddCaregiverView.as_view(), name='add_caregiver'),
    path('<str:user_id>/list/', GetCaregiversView.as_view(), name='get_caregivers'),
    path('<str:caregiver_id>/update/', UpdateCaregiverView.as_view(), name='update_caregiver'),
    path('<str:user_id>/<str:caregiver_id>/delete/', DeleteCaregiverView.as_view(), name='delete_caregiver'),

]