# Filmo

Personal watch-tracking app (movies, TV shows, anime) with shared household collections.

- `api/` — NestJS 11 + Prisma 7 + PostgreSQL
- `app/` — Flutter + Riverpod 3, feature-first (`lib/features/<feature>/{data,domain,presentation}`)

Metadata provided by [TMDB](https://www.themoviedb.org/). This product uses the TMDB API but is not endorsed or certified by TMDB.

## Getting started

```bash
docker compose up -d            # PostgreSQL on localhost:5434
cd api && cp .env.example .env  # then fill TMDB_ACCESS_TOKEN and JWT_SECRET
pnpm install && pnpm db:migrate && pnpm db:generate && pnpm start:dev
cd ../app && flutter pub get && dart run build_runner build && flutter run
# Android emulator: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```
# filmo
