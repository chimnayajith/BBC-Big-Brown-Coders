# Generated by Django 5.1.7 on 2025-03-08 19:53

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('authing', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='emergency_contact',
            field=models.CharField(blank=True, max_length=15, null=True),
        ),
    ]
