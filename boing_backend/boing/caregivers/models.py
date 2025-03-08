from mongoengine import Document, StringField, ReferenceField, ListField, connect, IntField

connect('boing_db', host='mongodb://127.0.0.1:27017/boing_db')

class User(Document):
    name = StringField(required=True)
    age = IntField()
    phone = StringField(required=True, unique=True)
    email = StringField(unique=True)

class Caregiver(Document):
    name = StringField(required=True)
    phone = StringField(required=True, unique=True)
    email = StringField(required=True)

class UserCaregivers(Document):
    user = ReferenceField(User, required=True, unique=True)
    caregivers = ListField(ReferenceField(Caregiver))
