# Filmo

Personal watch-tracking app (movies, TV shows, anime) with shared household collections.

- `api/` — NestJS 11 + Prisma 7 + PostgreSQL
- `app/` — Flutter + Riverpod 3

Metadata provided by [TMDB](https://www.themoviedb.org/). This product uses the TMDB API but is not endorsed or certified by TMDB.

## Getting started

```bash
cp .env.example .env            # then fill TMDB_ACCESS_TOKEN and JWT_SECRET
docker compose up -d            # PostgreSQL on localhost:5432
cd api && pnpm install && pnpm prisma migrate dev && pnpm start:dev
cd app && flutter pub get && dart run build_runner build && flutter run
```
