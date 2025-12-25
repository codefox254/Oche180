## Oche180

Professional darts scoring platform (MVP phase).

### Stack
- Backend: Django 5, DRF, JWT (SimpleJWT), PostgreSQL, Redis, Celery-ready, drf-spectacular
- Frontend: Flutter (Android/iOS/Web), Riverpod, go_router, Dio, Hive, secure storage
- DevOps: Docker + docker-compose, Gunicorn, Nginx-ready (future)

### Backend quickstart
1) Copy env template: `cp backend/.env.example backend/.env` and adjust secrets.
2) Build and run: `docker-compose up --build` (serves on http://localhost:8000).
3) Django admin: create a superuser once containers are up: `docker-compose exec backend python manage.py createsuperuser`.
4) API docs: Swagger UI at `/api/schema/swagger-ui/`, Redoc at `/api/schema/redoc/`.

### Frontend quickstart
1) Ensure Flutter SDK is available (`flutter --version`).
2) From `frontend/`, install deps: `flutter pub get` (project was created with `--no-pub`).
3) Run: `flutter run` (or `flutter run -d chrome` for web). The starter router includes Splash, Home, and Auth landing placeholders.

### Project layout
- backend/: Django project with custom user model and API scaffolding
- frontend/: Flutter app skeleton with Riverpod + go_router wired
- docker-compose.yml: backend + Postgres + Redis
- backend/.env.example: environment template

### Next steps (planned phases)
- Phase 2: Auth flows (JWT endpoints, social auth, frontend forms)
- Phase 3: 501 game logic + scoring APIs and UI
- Phase 4: Cricket/ATC + stats and training modes
