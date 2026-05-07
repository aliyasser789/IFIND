# iFind — AI-Powered Lost & Found Platform

iFind is a community-driven mobile application that connects people who have **lost items** with people who have **found them**. It uses AI-powered item recognition, voice-based reporting, GPS location tagging, real-time chat, and identity verification to create a secure, trustworthy recovery system.

Built as a Year 3 university project at ECU, developed from the ground up as a full-stack mobile application with a Flutter frontend and a Python/FastAPI backend.

---

## What It Does

When someone **finds** a lost item, they open the app and either:
- **Take a photo** — an AI model (YOLOv8) automatically identifies the item and extracts its features (category, color, material, brand)
- **Record a voice note** — a local Whisper model transcribes the description and extracts item details via Gemini

The item is saved with its GPS district (Cairo, 13 districts for v1) and stored in the database.

When someone **lost** something, they open the app and search by keyword and/or district. Smart color-aware search means typing "blue bag" returns all blue bags, not just items with "blue" in the title. They browse item cards, and if they spot theirs, they tap **"This is mine!"** to open a real-time chat with the finder.

The chat system uses WebSockets for instant messaging and is privacy-first — no real names, phone numbers, or emails are ever exposed. Users identify only by username. If any user behaves badly, the in-chat report button captures the full chat transcript and the reported user's verified National ID for admin review.

Every account is verified through email (OTP via Brevo SMTP) and a National ID photo check (YOLO + EasyOCR model). This means every person on the platform is a real, identified individual — not an anonymous account.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), MVC architecture, Provider state management |
| Backend | Python 3.13, FastAPI, Uvicorn |
| Database | PostgreSQL (local), SQLAlchemy ORM, Alembic migrations |
| AI — Item Recognition | YOLOv8 (ultralytics) — 45 relevant COCO categories |
| AI — Voice Transcription | faster-whisper (local) + Gemini API (feature extraction) |
| AI — ID Verification | ocr_egyptian_ID (YOLO + EasyOCR) by NASO7Y on GitHub |
| Real-Time Chat | WebSockets via FastAPI + web_socket_channel in Flutter |
| Auth | JWT tokens, bcrypt password hashing, Brevo SMTP OTP |
| Secure Storage | flutter_secure_storage with Android EncryptedSharedPreferences |

---

## Features

- Splash screen with branded animation
- Combined auth/login screen
- Multi-step registration: personal info → email OTP → National ID photo verification
- Forgot password / reset password via email
- Home screen with I Found / I Lost navigation
- I Found: photo report (camera only) with AI feature extraction
- I Found: voice report with Whisper transcription + Gemini extraction
- I Lost: keyword search with color-aware matching + district filter chips
- Item cards with multi-photo carousel and detail modals
- "This is mine!" flow: one tap to start a chat
- Real-time WebSocket chat with WhatsApp-style bubble UI
- Per-chat unread badge with 5-second background polling
- Anonymous chat labels — username only, no real identity exposed
- Soft-delete chat (deleted_by_finder / deleted_by_claimer columns)
- Report user inside chat: checklist reasons + full transcript saved
- Settings: change name, username, email (re-verified), logout
- 5-tab unified navigation shell (IndexedStack — all tabs stay alive)
- Release APK tested on a real Samsung Note10 Lite

---

## Project Structure

```
IFIND/
├── frontend/
│   └── ifind_app/              # Flutter app (MVC)
│       └── lib/
│           ├── main.dart
│           ├── models/         # Data models
│           ├── views/          # All screens
│           ├── controllers/    # Business logic
│           ├── services/       # API, WebSocket, Storage
│           └── widgets/        # Reusable UI components
└── backend/                    # FastAPI backend
    ├── main.py
    └── app/
        ├── models/             # SQLAlchemy table models
        ├── routers/            # API route handlers
        ├── services/           # Business logic services
        ├── ai_models/          # AI service + model files
        └── database/           # DB connection + schemas
```

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
pip install -r requirements.txt
```

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

Create the database in PostgreSQL (pgAdmin or psql):

```sql
CREATE DATABASE ifind;
```

Run migrations and start the server:

```bash
alembic upgrade head
py -m uvicorn main:app --reload --host 0.0.0.0
```

The backend starts at `http://localhost:8000`. API docs available at `http://localhost:8000/docs`.

---

### 3. Frontend setup

```bash
cd frontend/ifind_app
flutter pub get
```

---

### Running on the Android Emulator

The emulator uses the special IP `10.0.2.2` to reach your machine's localhost:

```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000
```

---

### Running on a Real Android Device

> **This is the most common setup issue.** A physical phone is on your WiFi network and cannot use `10.0.2.2` — it needs your machine's actual local IP address.

**Step 1 — Find your machine's local IP**

On Windows:
```
ipconfig
```
Look for the IPv4 address under your active WiFi adapter, e.g. `192.168.1.45`.

**Step 2 — Build the APK with your IP baked in**

```bash
flutter build apk --dart-define=BASE_URL=http://192.168.1.45:8000
```

The APK is output to:
```
frontend/ifind_app/build/app/outputs/flutter-apk/app-release.apk
```

Transfer it to your phone and install it (enable "Install from unknown sources" in Android settings).

**Step 3 — Make sure both devices are on the same WiFi network**

Your phone and your computer must be connected to the same WiFi network. If you are using a university or corporate network with device isolation, this will not work — use a personal hotspot instead.

---

### When Your IP Changes

Your local IP changes every time you connect to a different WiFi network. When this happens, you must update the IP in **four places** before rebuilding:

| File | What to update |
|---|---|
| `frontend/ifind_app/lib/services/api_service.dart` | `defaultValue` in `BASE_URL` const |
| `frontend/ifind_app/lib/services/websocket_service.dart` | `defaultValue` in `BASE_URL` const |
| `build_apk.bat` (project root) | IP in the flutter build command |
| `.vscode/launch.json` | IP in the physical phone launch configs |

The `build_apk.bat` script at the project root is a convenience shortcut — open it, update the IP, and double-click to build.

---

### Backend: allow connections from your phone

Make sure the backend is started with `--host 0.0.0.0` (not the default localhost-only binding):

```bash
py -m uvicorn main:app --reload --host 0.0.0.0
```

Also check your Windows Firewall — port `8000` must be allowed for inbound connections on private networks.

---

## Key Implementation Notes

- All `FlutterSecureStorage` instances **must** use `AndroidOptions(encryptedSharedPreferences: true)`. Using a plain `FlutterSecureStorage()` instance reads from a different storage partition on Android and the JWT token will always come back as null.
- The AI service file is at `backend/app/ai_models/ai_service.py` — not in the `services/` folder.
- `found_items.photo_url` is stored as a **JSONB list** (multiple photos per item), not a single string.
- `features` JSONB shape: `{color, material, brand, size, distinguishing_feature, description}`.
- JWT tokens are issued **only after** email OTP + National ID verification are both complete.
- Chat screens use anonymous labels — the backend never returns real names or emails in any chat endpoint.

---

## API Overview

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/register` | Register a new user |
| POST | `/auth/login` | Login, receive JWT |
| POST | `/auth/verify-email` | Verify email OTP |
| POST | `/auth/forgot-password` | Send password reset email |
| POST | `/auth/reset-password` | Set new password |
| POST | `/ai/verify-id` | Verify National ID photo |
| POST | `/ai/analyze-photo` | AI item recognition from photo |
| POST | `/ai/transcribe-voice` | Whisper transcription + feature extraction |
| POST | `/items/found/photo` | Save found item (photo path) |
| POST | `/items/found/voice` | Save found item (voice path) |
| GET | `/items/search` | Search found items by keyword + district |
| POST | `/chat/start` | Create a new chat for an item |
| WS | `/chat/ws/{chat_id}` | WebSocket real-time messaging |
| GET | `/chat/list` | Get all chats for the current user |
| GET | `/chat/history/{chat_id}` | Get message history |
| POST | `/reports/submit` | Submit a user report |
| PUT | `/user/update` | Update profile fields |
| GET | `/user/me` | Get current user info |

---

## Current Status

All core features are complete and tested on a real Android device (Samsung Note10 Lite).

| Step | Feature | Status |
|---|---|---|
| 1 | Tools & Folder Structure | Complete |
| 2 | Flutter ↔ FastAPI Connection | Complete |
| 3 | Splash Screen | Complete |
| 4 | Auth / Login Screen | Complete |
| 5 | Registration | Complete |
| 6 | Email Verification | Complete |
| 7 | ID Photo & AI Verification | Complete |
| 8 | Login & Forgot Password | Complete |
| 9 | Home Screen | Complete |
| 10 | I Found — Photo Report | Complete |
| 11 | I Found — Voice Report | Complete |
| 12 | GPS & District Logic | Complete |
| 13 | I Lost — Search & Filter | Complete |
| 14 | Chat System | Complete |
| 15 | Report User | Complete |
| 16 | Settings Screen | Complete |
| 17 | Bug Fixes & APK Release | Complete |
| 18 | UI Polish & iOS Build | v2 |

---

## Known Limitations (v1)

- **Local backend only** — the FastAPI server runs on the developer's machine. There is no cloud deployment. All users must be on the same local network as the running server.
- **Cairo only** — GPS district logic covers 13 Cairo districts. Other cities are not supported in v1.
- **Android only** — iOS build is deferred to v2. The app was built and tested on Android (emulator + physical device).
- **IP address must be updated manually** when the WiFi network changes. See the "When Your IP Changes" section above.
- **Gemini API key required** — the voice feature extraction step uses the Gemini API. Without a valid key in `.env`, voice reports will fail.

---

## License

This project was developed as a university assignment for ECU (Edith Cowan University), Semester 2, Year 3.
