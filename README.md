# Habical App

Habical — приложение для личной продуктивности: задачи, привычки, календарные события и активность друзей.
Этот репозиторий — Flutter-клиент (UI, клиентская логика, интеграция с API).

## Архитектура
- `lib/main.dart` — bootstrap: `BlocObserver`, логирование ошибок, `SessionService`, `ApiClient`.
- `lib/app/app.dart` — DI через `MultiRepositoryProvider`, `MaterialApp`, тема, `AuthGateScreen`.
- `lib/screens/` — UI по фичам (`auth`, `home`, `calendar`, `friends`, `habits`, `settings`).
- `lib/cubits/` — состояние экрана и бизнес-логика уровня UI.
- `lib/repositories/` — доступ к данным. `Api*Repository` ходят в backend через Dio.
- `lib/models/` — DTO/доменные модели.
- `lib/services/` — инфраструктура сессии и вспомогательная логика.
- Поток данных: `Screen -> Cubit -> Repository -> ApiClient -> Gateway API`.

## Конфиг API
- Базовый URL читается из `--dart-define=API_BASE_URL=...`.
- Если `API_BASE_URL` не задан:
  - Android emulator: `http://10.0.2.2:4010`
  - Остальные платформы: `http://127.0.0.1:4010`

## Инструкция по запуску
```bash
cd habical-app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:4010
```

Пример для Android эмулятора:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4010
```

## Проверки
```bash
flutter test
flutter analyze
```

