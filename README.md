# CareSphere - AI-Powered Elderly Healthcare & IoT Platform

CareSphere is a commercial-grade healthcare monitoring application built for the **Smart India Hackathon (SIH)**. It combines real-time smartwatch health metrics, ESP32 Smart Bedside IoT Hub telemetry, FastAPI AI predictive analytics, and Firebase Cloud Backend into a seamless Flutter cross-platform mobile experience.

---

## 🌟 Key Features

1. **Smartwatch Health Telemetry**: Real-time streaming for Heart Rate (BPM), SpO2 Saturation, Sleep Cycles, Steps, Calories Burned, and Stress Index.
2. **Bedside ESP32 IoT Hub**:
   - Environmental Temperature (SHT31 Sensor)
   - Humidity Control (SHT31 Sensor)
   - Ambient Lighting (BH1750 Sensor)
   - Human Micro-Movement Presence Detection (HLK-LD2410 Radar)
   - Physical Bedside Panic SOS Button
3. **AI Predictive Engine**: FastAPI integration combining multi-modal smartwatch + IoT telemetry to predict overall patient risk level (Low, Moderate, High, Critical), confidence scores, and personalized medicine/hydration recommendations.
4. **Caregiver Remote Portal**: Live patient geolocation, emergency alerts stream, direct phone call, and video call triggers.
5. **Interactive Telemetry Graphs**: Powered by `fl_chart` for Daily, Weekly, Monthly, and Yearly vital trend analytics.
6. **Medication Schedule & Reminders**: Complete pill dosage tracker with voice reminder integration.
7. **Production UI/UX**: Material 3 theme, glassmorphic auth screens, dark/light mode support, status badges, and rounded card decorators.

---

## 🚀 Tech Stack

- **Flutter**: Version 3.x with Riverpod State Management
- **Navigation**: `go_router` with shell navigation
- **Backend / Cloud**: Firebase Authentication, Cloud Firestore
- **Networking**: `dio` & REST service for FastAPI connection
- **Visuals**: `fl_chart`, `google_fonts`, `percent_indicator`, `font_awesome_flutter`

---

## 📁 Folder Structure

```
lib/
├── core/
│   ├── constants/       # AppConstants & API routes
│   ├── providers/       # Global state providers
│   ├── routes/          # GoRouter configuration
│   └── theme/           # Material 3 light/dark themes
├── data/
│   ├── models/          # UserModel, SmartwatchData, Esp32Data, AiPrediction, AlertModel
│   └── repositories/    # Auth, Smartwatch, ESP32, AI FastAPI, Medication Repositories
└── ui/
    ├── screens/         # Splash, Onboarding, Auth, Dashboard, Monitoring, AI, Hub, Caregiver, Alerts, Medication, Profile, Settings
    └── widgets/         # CustomButton, CustomTextField, VitalsCard, IotSensorCard, AiRiskMeter, SosFloatingButton, StatusBadge
```

---

## ⚡ Getting Started

```bash
# Get dependencies
flutter pub get

# Run application
flutter run
```

Developed for Smart India Hackathon.
