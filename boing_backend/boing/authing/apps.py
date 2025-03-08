from django.apps import AppConfig


class AuthingConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "authing"

    def ready(self):
        import authing.models