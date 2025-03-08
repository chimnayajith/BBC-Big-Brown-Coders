from django.urls import path
from .views import RegisterView, LoginView, DebugTokenView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path("login/", LoginView.as_view(), name="login"),
    path('debug-token/', DebugTokenView.as_view(), name='debug-token'),
]