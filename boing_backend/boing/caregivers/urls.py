from django.urls import path
from .views import CareGiverElderlyView

urlpatterns = [
    path('elderly/', CareGiverElderlyView.as_view(), name='elderly'),
]