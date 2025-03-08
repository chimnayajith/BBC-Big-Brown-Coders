from mongoengine import Document, StringField, IntField, ReferenceField, connect

connect('boing_db', host='mongodb://127.0.0.1:27017/boing_db')


class User(Document):
    ROLE_CHOICES = ('elderly', 'caregiver')
    name = StringField(required=True)
    age = IntField()
    phone = StringField(required=True, unique=True)
    email = StringField(unique=True)
    role = StringField(choices=ROLE_CHOICES, required=True)