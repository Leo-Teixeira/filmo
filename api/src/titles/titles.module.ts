import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { METADATA_PROVIDER } from './interfaces/metadata-provider.interface';
import { TitlesController } from './titles.controller';
import { TitlesService } from './titles.service';
import { TmdbProvider } from './tmdb/tmdb.provider';

@Module({
  imports: [
    // registerAsync: register() would read env before ConfigModule loads it.
    HttpModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        baseURL: config.getOrThrow<string>('TMDB_BASE_URL'),
        // Past 5 s, a clean 504 beats a hanging request.
        timeout: 5000,
        headers: {
          // Bearer header only: never put the token in a query string.
          Authorization: `Bearer ${config.getOrThrow<string>('TMDB_ACCESS_TOKEN')}`,
        },
      }),
    }),
  ],
  controllers: [TitlesController],
  providers: [
    TitlesService,
    { provide: METADATA_PROVIDER, useClass: TmdbProvider },
  ],
})
export class TitlesModule {}
