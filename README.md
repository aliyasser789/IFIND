# iFind — AI-Powered Lost & Found Platform

<!-- SCREENSHOTS — paste your 5 screenshots here after uploading them to your repo -->
<!-- Example format once you have the images:
<p align="center">
  <img src="screenshots/splash.png" width="18%" />
  <img src="screenshots/home.png" width="18%" />
  <img src="screenshots/found.png" width="18%" />
  <img src="screenshots/lost.png" width="18%" />
  <img src="screenshots/chat.png" width="18%" />
</p>
-->

---

iFind is a community-driven mobile application that connects people who have **lost items** with people who have **found them**. It uses AI-powered item recognition, voice-based reporting, district-based location tagging, real-time chat, and verified identity to create a secure, trustworthy recovery system.

Built as a Year 3 algorithms project at Egyptian Chinese University — developed from the ground up as a full-stack mobile application with a Flutter frontend and a Python/FastAPI backend.

---

## What It Does

When someone **finds** a lost item, they open the app and either:
- **Take a photo** — YOLOv8 automatically identifies the item and extracts its features (category, color, material, brand) from a curated 45-category list
- **Record a voice note** — faster-whisper transcribes the description locally (no API cost), then Gemini extracts structured item details from the transcription

The item is saved with its Cairo district (13 districts for v1) and stored in the database.

When someone **lost** something, they search by keyword and district. Color-aware search means typing "blue bag" returns all blue bags. They browse item cards with photo carousels, and if they spot theirs, they tap **"This is mine!"** to open a real-time chat with the finder.

The chat system uses WebSockets for instant messaging and is privacy-first — no real names, phone numbers, or emails are ever exposed. Users identify by username only. If a user behaves badly, the in-chat report button captures the full chat transcript and the reported user's verified National ID for admin review.

Every account is verified through email OTP (via Brevo SMTP) and a National ID photo check (YOLO + EasyOCR). Every person on the platform is a real, verified individual.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) · MVC Architecture · Provider State Management |
| Backend | Python 3.13 · FastAPI · Uvicorn |
| Database | PostgreSQL (local) · SQLAlchemy ORM · Alembic Migrations |
| AI — Item Recognition | YOLOv8 (ultralytics) · 45 curated categories |
| AI — Voice Transcription | faster-whisper (local, offline) + Gemini API (feature extraction) |
| AI — ID Verification | ocr_egyptian_ID — YOLO + EasyOCR (by NASO7Y on GitHub) |
| Real-Time Chat | WebSockets via FastAPI + web_socket_channel in Flutter |
| Auth | JWT Tokens · bcrypt Password Hashing · Brevo SMTP OTP |
| Secure Storage | flutter_secure_storage with Android EncryptedSharedPreferences |

---

## Features

- Splash screen with branded 7-second loading animation
- Combined auth/login screen — clean single-screen experience
- Multi-step registration: personal info → email OTP → National ID photo verification
- Forgot password / reset password via email
- Home screen with frosted-glass top bar and welcome greeting from real username
- **I Found:** photo report (camera only) with YOLOv8 AI feature extraction
- **I Found:** voice report with offline Whisper transcription + Gemini extraction, animated pulsing mic
- **I Lost:** keyword search with color-aware matching + 13 Cairo district filter chips
- Item cards with multi-photo carousel (PageView + dot indicators) and detail modals
- "This is mine!" flow — one tap to open a real-time chat with the finder
- Real-time WebSocket chat with WhatsApp-style bubble UI
- Per-chat unread badge counter with 5-second background polling timer
- Anonymous chat identity — username only, no real personal info ever exposed
- Soft-delete chat (deleted_by_finder / deleted_by_claimer — never hard deleted)
- Report user inside chat: checklist reasons + full chat transcript + reported user's National ID saved
- Settings: change name, username, email (re-verified via OTP), logout
- 5-tab unified navigation shell (IndexedStack — all tabs stay alive in memory)
- Release APK tested on a real Samsung Note10 Lite

---

## Project Structure

```
IFIND/
├── frontend/
│   └── ifind_app/                  # Flutter app (MVC)
│       └── lib/
│           ├── main.dart
│           ├── models/             # Data models
│           ├── views/              # All screens
│           ├── controllers/        # Business logic
│           ├── services/           # API, WebSocket, Storage, Badge
│           └── widgets/            # Reusable UI components (MainShell, ItemCard, ChatBubble)
└── backend/                        # FastAPI backend
    ├── main.py
    └── app/
        ├── models/                 # SQLAlchemy table models
        ├── routers/                # API route handlers
        ├── services/               # Business logic (auth, email, OTP, district, item, AI)
        ├── ai_models/              # AI orchestrator + YOLOv8 / Whisper / EasyOCR model files
        └── database/               # DB connection + schemas
```

---

## Navigation Architecture

All screens live inside a 5-tab `MainShell` using `IndexedStack`. All tabs stay alive in memory — no rebuild on tab switch, badge polling runs continuously in the background.

| Tab | Screen | Icon |
|---|---|---|
| 0 | Home | house |
| 1 | I Lost | search |
| 2 | I Found | add_circle |
| 3 | Chat | chat_bubble |
| 4 | Settings | settings |

`Navigator.pushReplacement` is never used for tab switching — all navigation is handled through MainShell index callbacks.

---

## Running Locally

### Prerequisites

- Python 3.13+
- Flutter SDK (stable)
- PostgreSQL 15+ (local instance)
- Android Studio (for emulator) or a physical Android device
- A valid Gemini API key (for voice feature extraction)

---

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/IFind.git
cd IFind/IFIND
```

---

### 2. Backend setup

```bash
cd backend
pip install -r requirements.txt --only-binary=:all:
```

> Note: `psycopg2-binary` requires `--only-binary=:all:` on Python 3.13.

Create a `.env` file in the `backend/` folder:

```env
DATABASE_URL=postgresql://postgres:YOUR_PG_PASSWORD@localhost/ifind
SECRET_KEY=your_jwt_secret_key
EMAIL_HOST=smtp-relay.brevo.com
EMAIL_PORT=587
EMAIL_USERNAME=your_brevo_login_email
EMAIL_PASSWORD=your_brevo_smtp_key
GEMINI_API_KEY=your_gemini_api_key
```

Create the database in PostgreSQL:

```sql
CREATE DATABASE ifind;
```

Run migrations and start the server:

```bash
alembic upgrade head
py -m uvicorn main:app --reload --host 0.0.0.0
```

API docs available at `http://localhost:8000/docs`

---

### 3. Frontend setup

```bash
cd frontend/ifind_app
flutter pub get
```

**Android Emulator:**

```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000
```

**Real Android Device:**

Find your machine's local IP (`ipconfig` on Windows), then:

```bash
flutter build apk --dart-define=BASE_URL=http://YOUR_LOCAL_IP:8000
```

APK output path:
```
frontend/ifind_app/build/app/outputs/flutter-apk/app-release.apk
```

Transfer to phone and install (enable "Install from unknown sources" in Android settings).

> Both your computer and phone must be on the same WiFi network.

---

### When Your IP Changes

Your local IP changes every time you connect to a different WiFi network. Update it in **four places**:

| File | What to update |
|---|---|
| `frontend/ifind_app/lib/services/api_service.dart` | `defaultValue` in `BASE_URL` const |
| `frontend/ifind_app/lib/services/websocket_service.dart` | `defaultValue` in `BASE_URL` const |
| `build_apk.bat` (project root) | IP in the flutter build command |
| `.vscode/launch.json` | IP in the physical phone launch configs |

---

## Key Implementation Notes

- All `FlutterSecureStorage` instances **must** use `AndroidOptions(encryptedSharedPreferences: true)`. A plain `FlutterSecureStorage()` reads from a different storage partition on Android — the JWT token will always return null.
- The AI service orchestrator is at `backend/app/ai_models/ai_service.py` — not in the `services/` folder.
- `found_items.photo_url` is stored as a **JSONB list** — multiple photos per item are supported.
- `features` JSONB shape: `{color, material, brand, size, distinguishing_feature, description}`.
- JWT tokens are issued **only after** both email OTP and National ID verification are complete.
- Chat API endpoints never return real names, emails, or phone numbers — usernames only.
- OCR digit cleaning is applied during ID verification: `O→0`, `I→1`, `S→5`, `B→8` to handle camera misreads.
- YOLO categories are filtered to a clean 45-item relevant list — irrelevant COCO categories (animals, food, furniture) are remapped to "Other".

---

## API Overview

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/register` | Register a new user |
| POST | `/auth/login` | Login and receive JWT |
| POST | `/auth/verify-email` | Verify email OTP |
| POST | `/auth/forgot-password` | Send password reset email |
| POST | `/auth/reset-password` | Set new password |
| POST | `/ai/verify-id` | Verify National ID photo (YOLO + EasyOCR) |
| POST | `/ai/analyze-photo` | YOLOv8 item recognition from photo |
| POST | `/ai/transcribe-voice` | Whisper transcription + Gemini feature extraction |
| POST | `/items/found/photo` | Save found item via photo |
| POST | `/items/found/voice` | Save found item via voice |
| GET | `/items/search` | Search found items by keyword + district |
| GET | `/items/photos/{item_id}/{filename}` | Serve item photos (no auth required) |
| GET | `/user/me` | Get current user profile |
| PUT | `/user/update` | Update profile fields |
| POST | `/user/logout` | Logout and invalidate token |
| POST | `/chat/start` | Create a new chat for an item |
| WS | `/chat/ws/{chat_id}` | WebSocket real-time messaging |
| GET | `/chat/list` | Get all chats (with usernames + message count) |
| GET | `/chat/history/{chat_id}` | Get message history |
| POST | `/reports/submit` | Submit a user report |

---

## Implementation Status

| Step | Feature | Status |
|---|---|---|
| 1 | Tools & Folder Structure | ✅ Complete |
| 2 | Flutter ↔ FastAPI Connection | ✅ Complete |
| 3 | Splash Screen | ✅ Complete |
| 4 | Auth / Login Screen | ✅ Complete |
| 5 | Registration | ✅ Complete |
| 6 | Email Verification | ✅ Complete |
| 7 | ID Photo & AI Verification | ✅ Complete |
| 8 | Login & Forgot Password | ✅ Complete |
| 9 | Home Screen | ✅ Complete |
| 10 | I Found — Photo Report | ✅ Complete |
| 11 | I Found — Voice Report | ✅ Complete |
| 12 | GPS & District Logic | ✅ Complete |
| 13 | I Lost — Search & Filter | ✅ Complete |
| 14 | Chat System | ✅ Complete |
| 15 | Report User | ✅ Complete |
| 16 | Settings Screen | ✅ Complete |
| 17 | Bug Fixes & APK Release | ✅ Complete |
| 18 | UI Polish & Advanced Animations | 🔜 v2 |
| 19 | iOS Build & TestFlight | 🔜 v2 |

---

## Known Limitations (v1)

- **Local backend only** — FastAPI runs on the developer's machine. No cloud deployment yet. All users must be on the same local network.
- **Cairo only** — 13 hardcoded Cairo districts. Other cities planned for v2.
- **Android only** — iOS build deferred to v2. Tested on emulator (Medium Phone API 36.1) and physical device (Samsung Note10 Lite).
- **IP must be updated manually** when the WiFi network changes.
- **Gemini API key required** for voice feature extraction. Without a valid key in `.env`, voice reports will fail.
- **GPS auto-detection deferred to v2** — district is currently selected from a hardcoded list. `gps_lat` and `gps_lng` columns are reserved in the schema.

---

## License

Developed as a Year 3 algorithms project at Egyptian Chinese University (ECU), Semester 2, 2026.
