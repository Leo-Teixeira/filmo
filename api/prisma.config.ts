
import dotenv from 'dotenv';
import path from 'node:path';
import { defineConfig } from 'prisma/config';

dotenv.config({
  path: path.resolve(__dirname, '../.env'),
});

const databaseUrl =
  process.env['DATABASE_URL'] ??
  `postgresql://${process.env['POSTGRES_USER']}:${process.env['POSTGRES_PASSWORD']}@localhost:${process.env['POSTGRES_PORT'] ?? '5434'}/${process.env['POSTGRES_DB']}?schema=public`;

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: databaseUrl,
  },
});
