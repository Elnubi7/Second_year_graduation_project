<h1 align="center">🧠 SmartDesk AI — Real-Time Employee Activity Monitoring</h1>

<p align="center">
A full-stack AI-powered system that detects, analyzes, and visualizes desk-level employee activities in real time, using YOLOv8, Firebase, and Flutter.
</p>

---

## 📸 Project Description

SmartDesk AI is a real-time monitoring system that uses a custom-trained YOLOv8 model to detect and classify employee activities such as:

- 💻 Working  
- 🍽️ Eating  
- 📞 Speaking on Phone  
- 😴 Sleeping  

Detected activities are tracked, logged, and visualized through a Flutter mobile application with live Firebase integration.

---

## 🚀 Technologies Used

<p align="center">
  <img src="https://skillicons.dev/icons?i=python,dart,flutter,firebase,pytorch,opencv,git,github" alt="tech stack" />
</p>

- **YOLOv8** – Object detection and activity classification  
- **OpenCV** – Frame processing, hashing  
- **Firebase Realtime Database** – Cloud data storage  
- **Flutter** – Cross-platform mobile app  
- **Excel (openpyxl)** – Local logging of time statistics  
- **OOP Design + Threading + Queues + Hashing + LRU** – For efficient, modular, and optimized AI pipeline  

---

## 📱 Flutter Mobile App Features

- Realtime updates (no refresh needed)
- Shows:
  - ⏱️ Activity start & end times
  - 🕐 Duration in seconds, minutes, or hours
  - 📈 Activity history (with scrollable logs)
  - ⭐ Performance scores
  - 🥧 Pie chart of activity distribution

All connected directly to Firebase using:
- `firebase_core`
- `firebase_database`
- `fl_chart`

---

## 🧠 AI & Backend System (YOLOv8)

- 🧠 **Custom-trained YOLOv8 model** classifies activities directly from webcam feed  
- 🧮 **Perceptual hashing** is used to avoid reprocessing repeated frames  
- 🧠 **LRU Caching** ensures speed by caching frame detections (using `OrderedDict`)  
- 🧪 Results are logged to:
  - Realtime Firebase
  - Excel sheets (per day)

---

## 🧠 Optimization Techniques

| Technique | Why It's Used |
|----------|---------------|
| ✅ **Hashing** | Skip redundant frames to improve speed |
| ✅ **LRU Cache** | Keep most recent 30 frames only, for memory efficiency |
| ✅ **Threading + Queue** | Firebase updates handled in background thread |
| ✅ **OOP Design** | Each class handles a clean, specific task |
| ✅ **Competitive Programming** | Hashmaps, optimized loops, conditionals for peak performance |

---

## 🧩 Architecture

```text
📷 [Webcam Feed] 
    ↓
🧠 [YOLOv8 Detection + Frame Hashing] 
    ↓
🪑 [DeskActivityMonitor - Timer Updates] 
    ↓
📊 [ExcelLogger + FirebaseClient] 
    ↓
📱 [Flutter App - Live Visualization]

------

## 👥 Team Members

| Name               | Role                                   |
|--------------------|----------------------------------------|
| Abdullah Nubi      | 🧠 AI Engineer / Performance Optimizer |
| Abdelrahman Ahmed  | 🔗 Firebase Integration                |
| Riad Elsayed       | 🎥 Data Collection & Camera Integration |
| Ahd Hassan         | 🧠 AI Engineer                         |
| Manar Alaa         | 📱 Flutter Developer                   |
| Yostina Samah      | 📱 Flutter Developer                   |
