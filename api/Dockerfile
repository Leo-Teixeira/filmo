
# --------------------------------------------------
# Base
# --------------------------------------------------
FROM node:24-bookworm-slim AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable \
    && corepack prepare pnpm@10 --activate

WORKDIR /app

# --------------------------------------------------
# Dependencies
# --------------------------------------------------
FROM base AS deps

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

# --------------------------------------------------
# Build
# --------------------------------------------------
FROM deps AS build

COPY . .

# Le script prebuild lance prisma generate
RUN pnpm build

# --------------------------------------------------
# Database migrations
# --------------------------------------------------
FROM build AS migrate

CMD ["pnpm", "db:deploy"]

# --------------------------------------------------
# Production dependencies
# --------------------------------------------------
FROM base AS prod-deps

COPY package.json pnpm-lock.yaml ./

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       python3 make g++ \
    && pnpm install --prod --frozen-lockfile \
    && apt-get purge -y python3 make g++ \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Production
# --------------------------------------------------
FROM base AS production

ENV NODE_ENV=production

WORKDIR /app

COPY package.json ./

COPY --from=prod-deps /app/node_modules ./node_modules

COPY --from=build /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main"]
