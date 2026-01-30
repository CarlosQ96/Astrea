# Astrea

Your personal reminder butler. Talk to him naturally, by voice or text, and he keeps everything in sync across all your devices.

## What's Inside

```
astrea/
├── astrea_server/     # Serverpod backend
├── astrea_client/     # Generated client SDK (auto)
└── astrea_flutter/    # Flutter mobile app
```

## Prerequisites

Before you start, make sure you have:

- Flutter 3.x installed
- Dart 3.8+
- Docker (for local database)
- Serverpod CLI: `dart pub global activate serverpod_cli`

## Getting Started

### 1. Start the Database

The backend needs PostgreSQL and Redis running. Docker handles this for you.

```bash
cd astrea_server
docker compose up -d
```

This starts PostgreSQL on port 8090 and Redis on port 8091.

### 2. Configure API Keys

Copy the example passwords file and add your keys:

```bash
cd astrea_server/config
cp passwords.yaml.example passwords.yaml
```

Edit `passwords.yaml` and fill in:

```yaml
shared:
  # Required for AI chat
  anthropicApiKey: 'your-anthropic-api-key'

  # Required for semantic search (free tier works fine)
  geminiApiKey: 'your-gemini-api-key'

  # Optional: for push notifications
  firebaseServiceAccount: '{"type":"service_account",...}'

  # Optional: for email verification
  smtpHost: 'smtp.mailersend.net'
  smtpPort: '587'
  smtpUsername: 'your-username'
  smtpPassword: 'your-password'
  smtpFromEmail: 'your-email'
  smtpFromName: 'Astrea'
```

Get your API keys from:
- Anthropic: https://console.anthropic.com/
- Gemini: https://aistudio.google.com/app/apikey (free)

### 3. Run the Server

```bash
cd astrea_server
dart bin/main.dart --apply-migrations
```

The server starts on `http://localhost:8080`. You should see logs confirming the connection to PostgreSQL and Redis.

### 4. Run the Flutter App

In a new terminal:

```bash
cd astrea_flutter
flutter pub get
flutter run
```

The app connects to `localhost:8080` by default in development mode.

## Development Workflow

### Making Changes to the Server

When you modify endpoints or models in `astrea_server`, regenerate the client SDK:

```bash
cd astrea_server
serverpod generate
```

Then update dependencies in the Flutter app:

```bash
cd astrea_flutter
flutter pub get
```

### When to Regenerate

| Change | Regenerate? |
|--------|-------------|
| Add/modify endpoint methods | Yes |
| Add/modify `.spy.yaml` models | Yes |
| Change method signatures | Yes |
| Change business logic only | No |
| Change Flutter UI only | No |

### Database Migrations

After changing models, create and apply migrations:

```bash
cd astrea_server
serverpod create-migration
dart bin/main.dart --apply-migrations
```

## Project Structure

### Server (`astrea_server/`)

```
lib/
├── src/
│   ├── endpoints/      # API endpoints
│   ├── services/       # Business logic (Claude, embeddings, FCM)
│   ├── models/         # .spy.yaml model definitions
│   └── generated/      # Auto-generated code
└── server.dart         # Entry point, SMTP config
```

### Flutter App (`astrea_flutter/`)

```
lib/
├── src/
│   ├── pages/          # Screens (chat, reminders, settings, onboarding)
│   ├── providers/      # Riverpod state management
│   ├── services/       # Notifications, voice, sync
│   └── widgets/        # Reusable components
└── main.dart           # Entry point
```

## Key Features

**Natural Language Input**: Tell Astrea what to remember in plain English. "Remind me to call mom tomorrow at 3pm" just works.

**Voice Input**: Hold the mic button and speak. Uses your device's built-in speech recognition, no cloud API needed.

**Cross-Device Sync**: Changes propagate instantly through WebSockets. Complete a reminder on your phone, it disappears from your tablet.

**Smart Notifications**: Get notified when reminders are due with snooze and complete buttons right in the notification.

**Semantic Search**: Ask "what did I set for next week?" and Astrea finds relevant reminders by meaning, not just keywords.

## Running Tests

```bash
cd astrea_server
dart test
```

## Deployment

For production deployment to Railway or similar:

1. Set environment variables instead of using passwords.yaml
2. Configure your PostgreSQL and Redis instances
3. Update the Flutter app's server URL in the config

The server reads from environment variables as fallback:
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`
- `FIREBASE_SERVICE_ACCOUNT`

## Troubleshooting

**Server won't start**: Check that Docker containers are running with `docker ps`. You should see postgres and redis.

**Flutter can't connect**: Make sure the server is running and check the API URL in the Flutter config matches your server address.

**Notifications not working**: On iOS, you need to configure push notification entitlements. On Android, check that the Firebase configuration is correct.

**Voice not working**: The app needs microphone permissions. On iOS, add the microphone usage description to Info.plist.

## Architecture

The app uses Serverpod for the backend, which handles:
- Type-safe client generation
- WebSocket streaming for real-time sync
- Database ORM with PostgreSQL
- Built-in authentication with JWT

The Flutter app uses Riverpod for state management, keeping the UI reactive to changes from both local actions and server sync events.

Claude powers the conversational AI, understanding your intent and extracting reminder details. Gemini generates embeddings for semantic search through your reminders.
