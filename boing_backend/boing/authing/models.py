from mongoengine import Document, StringField, IntField, ReferenceField, connect
from django.contrib.auth.hashers import make_password, check_password

connect('boing_db', host='mongodb://127.0.0.1:27017/boing_db')


class User(Document):
    name = StringField(required=True)
    phone = StringField(required=True, unique=True)
    email = StringField(unique=True)
    password = StringField(required=True)
    role = StringField(required=True, choices=["elderly", "caregiver"])

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)  