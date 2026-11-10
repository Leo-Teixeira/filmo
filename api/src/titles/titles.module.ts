import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { METADATA_PROVIDER } from './interfaces/metadata-provider.interface';
import { TitlesController } from './titles.controller';
import { TitlesService } from './titles.service';
import { TmdbProvider } from './tmdb/tmdb.provider';

@Module({
  imports: [
    // registerAsync + inject: the config is read AFTER ConfigModule has loaded .env (register() would run too early).
    HttpModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        // getOrThrow: the app refuses to boot if a variable is missing, instead of failing on the first search.
        baseURL: config.getOrThrow<string>('TMDB_BASE_URL'),
        // 5 s: TMDB usually answers in <300 ms. Past that, better a clean 504 than a hanging request.
        timeout: 5000,
        headers: {
          // "API Read Access Token" (v4 auth) from TMDB settings, sent as Bearer. Never put it in a query string.
          Authorization: `Bearer ${config.getOrThrow<string>('TMDB_ACCESS_TOKEN')}`,
        },
      }),
    }),
  ],
  controllers: [TitlesController],
  providers: [
    TitlesService,
    // The binding of the port to its adapter: "whoever asks for METADATA_PROVIDER gets a TmdbProvider".
    // This line is the ONLY place to change to switch provider (or to inject a fake in tests).
    { provide: METADATA_PROVIDER, useClass: TmdbProvider },
  ],
})
export class TitlesModule {}
