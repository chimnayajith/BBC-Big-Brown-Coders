# import cv2
# import cvzone
# import math
# from ultralytics import YOLO

# cap = cv2.VideoCapture('fall.mp4')

# model = YOLO('yolov8s.pt')

# classnames = []
# with open('classes.txt', 'r') as f:
#     classnames = f.read().splitlines()


# while True:
#     ret, frame = cap.read()
#     frame = cv2.resize(frame, (980,740))

#     results = model(frame)

#     for info in results:
#         parameters = info.boxes
#         for box in parameters:
#             x1, y1, x2, y2 = box.xyxy[0]
#             x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
#             confidence = box.conf[0]
#             class_detect = box.cls[0]
#             class_detect = int(class_detect)
#             class_detect = classnames[class_detect]
#             conf = math.ceil(confidence * 100)


#             # implement fall detection using the coordinates x1,y1,x2
#             height = y2 - y1
#             width = x2 - x1
#             threshold  = height - width

#             if conf > 80 and class_detect == 'person':
#                 cvzone.cornerRect(frame, [x1, y1, width, height], l=30, rt=6)
#                 cvzone.putTextRect(frame, f'{class_detect}', [x1 + 8, y1 - 12], thickness=2, scale=2)
            
#             if threshold < 0:
#                 cvzone.putTextRect(frame, 'Fall Detected', [height, width], thickness=2, scale=2)
            
#             else:pass


#     cv2.imshow('frame', frame)
#     if cv2.waitKey(1) & 0xFF == ord('t'):
#         break


# cap.release()
# cv2.destroyAllWindows()



import cv2
import cvzone
import math
import time
import threading
import os
from twilio.rest import Client
import pygame
from ultralytics import YOLO

TWILIO_SID = 'AC5cca60358f05eaaeb76f03409d24fd38'
TWILIO_AUTH_TOKEN = 'a8500293b73b05e7ad96d0689d5996d7'
TWILIO_FROM_NUMBER = '+19897873741'
EMERGENCY_NUMBERS = ['+918075911824']

pygame.mixer.init()
ALARM_SOUND_PATH = "mixkit-retro-emergency-tones-2971.wav"
if not os.path.exists(ALARM_SOUND_PATH):
    print("Warning: Alarm sound file not found! Will use console alert instead.")

def trigger_sos():
    """Triggers an SOS alert with an alarm sound and SMS notification."""
    print("\n*** FALL DETECTED! TRIGGERING SOS ALERT ***\n")
    
    try:
        if os.path.exists(ALARM_SOUND_PATH):
            pygame.mixer.music.load(ALARM_SOUND_PATH)
            pygame.mixer.music.play()
        else:
            for _ in range(5):
                print("🚨 EMERGENCY ALERT: FALL DETECTED! 🚨")
    except Exception as e:
        print(f"Error playing alarm sound: {e}")

    thread = threading.Thread(target=send_emergency_sms)
    thread.daemon = True
    thread.start()

def send_emergency_sms():
    """Sends emergency SMS using Twilio."""
    try:
        client = Client(TWILIO_SID, TWILIO_AUTH_TOKEN)
        for number in EMERGENCY_NUMBERS:
            message = client.messages.create(
                body="EMERGENCY ALERT: Fall detected! Immediate assistance may be required.",
                from_=TWILIO_FROM_NUMBER,
                to=number
            )
            print(f"Emergency SMS sent to {number}")
    except Exception as e:
        print(f"Error sending emergency SMS: {e}")


cap = cv2.VideoCapture('fall.mp4')
model = YOLO('runs/detect/train7/weights/best.pt')


classnames = []
with open('classes.txt', 'r') as f:
    classnames = f.read().splitlines()

while True:
    ret, frame = cap.read()
    if not ret:
        break
    frame = cv2.resize(frame, (980, 740))

    results = model(frame)

    for info in results:
        parameters = info.boxes
        for box in parameters:
            x1, y1, x2, y2 = box.xyxy[0]
            x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
            confidence = box.conf[0]
            class_detect = box.cls[0]
            class_detect = int(class_detect)
            class_detect = classnames[class_detect]
            conf = math.ceil(confidence * 100)

            height = y2 - y1
            width = x2 - x1
            threshold = height - width

            if conf > 80 and class_detect == 'person':
                cvzone.cornerRect(frame, [x1, y1, width, height], l=30, rt=6)
                cvzone.putTextRect(frame, f'{class_detect}', [x1 + 8, y1 - 12], thickness=2, scale=2)
            
            if threshold < 0:
                cvzone.putTextRect(frame, 'Fall Detected', [50, 50], thickness=2, scale=2, colorR=(0, 0, 255))
                trigger_sos()  
    
    cv2.imshow('Fall Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()