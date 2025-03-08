

from django.urls import path, include 
from rest_framework_simplejwt import views as jwt_views 
  
urlpatterns = [ 
    path('', include('authing.urls')), 
    path('caregivers/', include('caregivers.urls')),
] 
