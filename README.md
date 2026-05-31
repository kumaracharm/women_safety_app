# 🚨 Women Safety App

A Flutter-based cross-platform application designed to enhance personal safety by providing emergency alert features, real-time location tracking, and intelligent assistance.

---

## 📌 Overview

This application helps users quickly trigger emergency responses and notify trusted contacts during unsafe situations. It integrates voice, location, and AI-based assistance to improve personal safety response time.

---

## ✨ Features

- 📍 Real-time location tracking
- 🚨 Emergency SOS trigger button
- 🎤 Voice-activated emergency alerts
- 📞 Instant notification to emergency contacts
- 🤖 AI-based assistant support (Jarvis system)
- 🔔 Background safety monitoring services
- 🔐 Secure API key handling using environment variables

---

## 🛠 Tech Stack

- Flutter (Dart)
- Firebase (optional integration)
- REST APIs
- Device sensors (GPS, microphone)
- dotenv for secure configuration

---

## 🔐 Security

- No API keys are stored in source code
- Environment variables used via `.env`
- `.env` is excluded using `.gitignore`
- `.env.example` provided for setup reference

⚠️ Never upload `.env` to GitHub.

---

## ⚙️ Setup

### 1. Clone Repository
```bash
git clone https://github.com/kumaracharm/women_safety_app.git
cd women_safety_app
