from mongoengine import Document, StringField
# Create your models here.
class User(Document):
    name = StringField(required=True)
    email = StringField(required=True, unique=True)
    password = StringField(required=True)