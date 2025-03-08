from mongoengine import Document, StringField, FloatField, DateTimeField

class UserLocation(Document):
    user_id = StringField(required=True)
    latitude = FloatField(required=True)
    longitude = FloatField(required=True)
    timestamp = DateTimeField(required=True)