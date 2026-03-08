# TT Modern Stack Monorepo

Готовый каркас монорепозитория на **Nx** с современным стеком:

- Frontend: **Next.js 15** + React 19 + TanStack Query + Zod
- Backend: **NestJS** + TypeORM + PostgreSQL + Zod
- Monorepo/build orchestration: **Nx**
- Тестирование: **Vitest**

## 1) Требования

- Node.js 20+
- pnpm 9+
- Docker (для локального PostgreSQL)

## 2) Быстрый старт

```bash
cp .env.example .env
pnpm install
pnpm db:up
pnpm dev
```

После запуска:

- Web: http://localhost:3000
- API health: http://localhost:3333/api/health
- API users: http://localhost:3333/api/users

## 3) Полезные команды

```bash
pnpm dev:web       # только фронт
pnpm dev:api       # только бэк
pnpm build         # сборка web + api
pnpm test          # vitest по всем проектам
pnpm lint          # линт по всем проектам
pnpm db:down       # остановить postgres
```

## 4) Структура проекта

```text
apps/
  web/              # Next.js 15 app router
  api/              # NestJS API
libs/
  shared/           # общие схемы/типы
db/
  init/             # SQL-инициализация схемы, view и функций
```

## 5) Архитектура БД (table -> view -> function)

Текущий бэкенд настроен под ваш подход:

- Данные физически лежат в таблицах (например `users`).
- Все SELECT в приложении идут только из view (`v_users`).
- Любые изменения данных делаются только через функции (`fn_create_user`, `fn_update_user_name`).
- Прямых `INSERT/UPDATE/DELETE` из NestJS в таблицы нет.

Инициализационный SQL лежит в `db/init/001_schema.sql` и автоматически применяется при первом старте контейнера postgres.

> Важно: если вы уже запускали postgres раньше, пересоздайте volume, чтобы init-скрипт выполнился заново:

```bash
docker compose down -v
pnpm db:up
```

## 6) Как это работает

### Frontend (`apps/web`)

- `AppQueryProvider` подключает TanStack Query.
- Главная страница вызывает `fetchHealth` и валидирует ответ через Zod.

### Backend (`apps/api`)

- `AppModule` поднимает TypeORM подключение к PostgreSQL через `DATABASE_URL`.
- Контроллер `GET /api/health` отдает heartbeat.
- Модуль `users` читает данные из `v_users` и пишет через `fn_create_user` / `fn_update_user_name`.
- Входные данные валидируются через Zod-схемы.

### Shared (`libs/shared`)

- Библиотека общих схем с примером `EnvironmentSchema` на Zod.

## 7) PostgreSQL

Локальная база запускается через `docker-compose.yml`.

По умолчанию используются значения:

- DB: `ttdb`
- User: `ttuser`
- Password: `ttpass`
- Port: `5432`

Можно поменять в `.env`.

## 8) Что можно сделать следующим шагом

- Добавить SQL-функции для полного CRUD и soft-delete.
- Добавить отдельный слой db-access (репозиторий функций) и audit-лог изменений.
- Подключить auth (JWT + refresh flow).
- Добавить CI (GitHub Actions) с `pnpm test` и `pnpm build`.
- Добавить e2e тесты для API и frontend.

## 9) Проектирование БД под Figma (Компоненты + Макеты десктоп)

- Документ с целевой структурой: `docs/db-design-figma-components-desktop.md`.
- SQL-черновик доменной схемы: `db/init/002_design_system.sql`.
- Принцип сохранен: чтение через `VIEW`, запись через `fn_*` функции.

## 10) Tea domain (левое меню + проливы)

- SQL-домен для чаёв: `db/init/003_tea_domain.sql`.
- Документ по логике расчета проливов: `docs/db-tea-domain.md`.
- Для типового случая используйте `linear` режим (`base_time_sec + step_time_sec` по номеру пролива).
- Для особых чаёв используйте `custom` шаги и `fn_set_tea_custom_step`.
- Получение плана проливов: `fn_get_tea_brew_plan(tea_id)`.
