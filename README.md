<h1 align="center">📊 Smart Desk AI</h1>
<p align="center">
  <img src="assets/demo.gif" alt="demo" width="80%" />
</p>

<p align="center">
  Real-time AI system that detects and logs workplace activities using YOLOv8 🔍 + Firebase 🔥 + Flutter 📱  
</p>

---

## 🧠 What is this project?

**Smart Desk AI** is an intelligent real-time monitoring system that detects and analyzes employee behavior at their desks using a custom-trained **YOLOv8** model.

The system logs time spent on different activities like **Working**, **Eating**, **Sleeping**, and **Speaking on phone**.  
It stores data in Firebase and Excel, while the **Flutter app** shows a live feed of activities with performance analysis.

---

## 🚀 Features

- 🧠 Real-time activity detection using YOLOv8
- 🕒 Duration tracking per desk and per activity
- ☁️ Firebase Realtime Database integration
- 📊 Auto-generated Excel logs (per day)
- 📱 Flutter app with pie charts, stars, and full history

---

## 💻 Tech Stack

<p align="center">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white"/>
  <img src="https://img.shields.io/badge/YOLOv8-FF3C00?style=for-the-badge&logo=ultralytics&logoColor=white"/>
</p>

---

## 📁 Project Structure

```bash
Second_year_graduation_project/
│
├── real-time/                   # 🎯 Real-time AI Detection + Logging (Python)
│   ├── main.py                  # 🔁 Entry point for real-time detection loop
│   ├── yolo_utils.py            # 🧠 YOLOv8 model + frame hashing & LRU caching
│   ├── firebase_utils.py        # ☁️ Firebase Client with threaded queue system
│   ├── excel_utils.py           # 📊 Handles Excel logs (daily activity logs)
│   └── desk_monitor.py          # 🪑 DeskActivityMonitor: core AI activity handler
│
├── mobile_app/                  # 📱 Flutter app to visualize desk activities
│   ├── lib/
│   │   ├── main.dart            # 🧩 Entry point of Flutter app
│   │   └── screens/             # 🖼️ Screens (realtime, history, performance chart)
│   ├── pubspec.yaml             # 📦 Flutter dependencies & assets config
│   └── android/ ios/ build/     # 📁 Auto-generated folders
│
├── weights/
│   └── best.pt                  # 🔍 Custom-trained YOLOv8 weights
│
├── assets/                      # 🎞️ Demo images and GIFs
│   ├── demo.gif
│   ├── pie.png
│   └── history.png
│
├── service_account.json         # 🔐 Firebase Admin SDK
├── desk_times_history.xlsx      # 📊 Daily Excel logs
├── requirements.txt             # 🧪 Python dependencies
├── README.md
└── LICENSE
