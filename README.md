# Local LLM

A Flutter app for running and integrating large language models locally on-device and via API.

## Features

- On-device inference via Ollama and Flutter Gemma
- Property listing generation (PropSnap feature)
- Authentication with Supabase
- Settings management for model configuration

## Tech Stack

- **Flutter** with Riverpod for state management
- **Supabase** for auth and backend
- **Ollama** for local LLM inference
- **Flutter Gemma** for on-device model inference
- **go_router** for navigation
- Clean Architecture (data / domain / presentation layers)

## Getting Started

1. Clone the repo
2. Copy `config.json.example` to `config.json` and fill in your Supabase credentials
3. Run `flutter pub get`
4. Run `flutter run`

## Configuration

The app reads `config.json` at runtime (excluded from version control):

```json
{
  "SUPABASE_URL": "your-supabase-url",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```
