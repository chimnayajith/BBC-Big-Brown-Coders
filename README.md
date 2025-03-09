
# Define 3.0
The official template repository for Define 3.0

![DefineHack 2025 Logo](https://github.com/user-attachments/assets/8173bc16-418e-4912-b500-c6427e4ba4b6)



# Boing!
 Cover Image  If applicable

### Team Information
- **Team Name**: BBC - Big Brown Coders
- **Track**: Sustainability

### Team Members
| Name | Role | GitHub | LinkedIn |
|------|------|--------|----------|
| Chinmay Ajith | Participant | [@chimnayajith](https://github.com/chimnayajith) | [Profile](https://www.linkedin.com/in/chinmay-ajith-9032722b1/) |
| Mukund Menon | Participant | [@Mukund-Menon](https://github.com/Mukund-Menon) | [Profile](https://www.linkedin.com/in/mukund-menon-1a535a27a/) |
| Navaneeth B | Participant | [@navaneeth0041](https://github.com/navaneeth0041) | [Profile](https://www.linkedin.com/in/navaneeth-b-777b8a287/) |

## Project Details

### Overview
Our project is a smart elderly care and SOS system that ensures safety through fall detection, emergency alerts, and real-time location tracking. Using phone sensors (gyroscope + accelerometer), it detects falls and automatically notifies caregivers via SMS and calls. The system also includes battery-based SOS alerts, medicine reminders, and caregiver-linked settings, providing enhanced security and peace of mind for elderly users

### Problem Statement
In emergency situations, timely assistance can be the difference between life and death. Elderly individuals, people with medical conditions, and those in hazardous environments often face risks such as falls, sudden health issues, or battery depletion on their phones, leaving them unable to call for help. Additionally, caregivers lack real-time visibility into their loved ones' safety and well-being.

### Solution
Existing solutions are often fragmented, requiring separate apps for fall detection, SOS alerts, location sharing, and medication reminders, leading to inefficiencies and delays in emergencies.

This project aims to develop an integrated SOS system with:
- Fall detection using sensors in phones and CCTV footage analysis.
- Automated SOS alerts (calls/SMS) when the phone's battery drops below a critical level.
- Real-time location sharing with a linked caretaker.
- Customizable settings for SOS alerts and monitoring, managed by the caretaker.
- Medicine reminders to ensure timely medication intake ad checkup calendars.

By consolidating these features into a single, user-friendly platform, this solution enhances safety, provides peace of mind to caretakers, and ensures swift assistance in emergencies.

### Demo
[![Project Demo](https://img.youtube.com/vi/KPAveUO96-M/0.jpg)](https://youtu.be/KPAveUO96-M)

## Technical Implementation

### Technologies Used
- **Frontend**: Flutter
- **Backend**: Django
- **Database**: PostgreSQL
- **APIs**: None
- **DevOps**: None
- **Other Tools**: OpenCV, YoloV8

### Key Features
- Real-Time Fall Detection: Using phone sensors and camera analysis.
- Automatic SOS Alerts: Instant notifications, calls, and SMS to caregivers.
- Caregiver Dashboard: View health logs, event history, and customize settings.

## Setup Instructions

### Prerequisites
- Python 3.10+
- Flutter 3.0+
- PostgreSQL
- django

### Installation 
```

git clone https://github.com/chimnayajith/BBC-Big-Brown-Coders.git
cd BBC-Big-Brown-Coders
```
### Frontend setup
```

cd boing_frontend
flutter pub get
flutter run --dart-define=API_URL=192.168.xx.xx:8000
```

### Backend setup
```
cd boing_backend
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 manage,py runserver 0.0.0.0:8000
```

### Running the Project
```bash
# Start the backend
cd boing_backend
source .venv/bin/activate  # Activate virtual environment
python3 manage.py runserver 0.0.0.0:8000  # Run the backend

# Open a new terminal and start the frontend
cd boing_frontend
flutter run --dart-define=API_URL=192.168.xx.xx:8000  # Run the frontend
```

## Additional Resources

### Project Timeline
- Phase 1: Research & Planning (✅ Completed)

    - Researched fall detection models and sensor-based data collection.
    - Chose Flutter for the frontend and Django for the backend.
    - Identified key features like emergency alerts, fall detection, and caregiver notifications.

- Phase 2: Core Development (✅ Completed)

    - Implemented real-time fall detection using accelerometer and gyroscope sensors.
    - Developed emergency alert system with automated SMS/call notifications.
    - Set up a backend to store user data and provide analytics for caregivers.

- Phase 3: Testing & Deployment (Upcoming)

    - Conducting real-world testing with volunteers to fine-tune fall detection accuracy.
    - Optimizing battery efficiency and reducing false positives.
    - Preparing for deployment and app store submission.

### Challenges Faced
- Ensuring completely accurate fall detection: The models were initially trained on still images, making it difficult to determine if a person was actually falling. Since falling is a dynamic action rather than a static pose, the model struggled with distinguishing falls from other similar positions (e.g., sitting or lying down).
    - Solution: Explored datasets but found a lack of high-quality video-based fall detection datasets.


### Future Enhancements
- Seamless Wearable Design 🏷️
    - Instead of a smartwatch, develop a lightweight clip-on device (e.g., attachable to clothes or a pendant) for ease of use.
    - Ensure long battery life and minimal charging needs.

- Voice Control with AI 🎙️
    - Integrate a voice assistant for emergency calls, reminders (medication, hydration), and general assistance.
    - Enable voice-based fall confirmation to reduce false positives.

- Location-Based Safety Alerts 📍
    - Implement geofencing to notify caregivers if users with dementia wander out of a safe zone.
    - Enable automatic navigation assistance (e.g., guiding them back home with voice prompts).

- Advanced Fall Detection with Video & Sensor Fusion 🎥
    - Train a custom dataset with video sequences to improve fall detection accuracy.
    - Combine camera-based movement tracking + sensor data (accelerometer, gyroscope) for better prediction.

- Health & Emergency Monitoring 🚑
    - Monitor heart rate, oxygen levels, and temperature with an optional health tracking module.
    - Detect extended inactivity and trigger wellness checks.

### References (if any)
- [Reference 1](https://www.who.int/news-room/fact-sheets/detail/ageing-and-health)
- [Reference 2](https://docs.ultralytics.com/modes/train/)

---

### Submission Checklist
- [x] Completed all sections of this README
- [x] Added project demo video
- [x] Provided live project link
- [x] Ensured all team members are listed
- [x] Included setup instructions
- [x] Submitted final code to repository

---

© Define 3.0 | [Define 3.0](https://www.define3.xyz/)
