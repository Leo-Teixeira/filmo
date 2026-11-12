import { HttpService } from '@nestjs/axios';
import {
  BadGatewayException,
  GatewayTimeoutException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { isAxiosError } from 'axios';
import { firstValueFrom } from 'rxjs';
import { TitleType } from '../../generated/prisma/enums';
import {
  ExternalTitle,
  MetadataProvider,
} from '../interfaces/metadata-provider.interface';
import { fromDetails, fromSearchResult } from './tmdb.mapper';
import { TmdbDetails, TmdbSearchResponse } from './tmdb.types';

// The "adapter": the only class in the app that knows TMDB's URLs and JSON. Swapping provider = writing another adapter.
@Injectable()
export class TmdbProvider implements MetadataProvider {
  readonly name = 'tmdb';

  private readonly logger = new Logger(TmdbProvider.name);

  // HttpService is pre-configured in TitlesModule (baseURL, Bearer token, timeout): this class never sees the token.
  constructor(private readonly http: HttpService) {}

  async search(query: string): Promise<ExternalTitle[]> {
    const data = await this.get<TmdbSearchResponse>('/search/multi', {
      query,
      include_adult: false,
      page: 1,
    });
    // Type guard in filter() so TypeScript knows the nulls (people) are gone.
    return data.results
      .map(fromSearchResult)
      .filter((title): title is ExternalTitle => title !== null);
  }

  async getDetails(
    type: TitleType,
    externalId: string,
  ): Promise<ExternalTitle> {
    const segment = type === TitleType.MOVIE ? 'movie' : 'tv';
    // encodeURIComponent: externalId comes from our DB, but never trust a string you glue into a URL.
    const path = `/${segment}/${encodeURIComponent(externalId)}`;
    const data = await this.get<TmdbDetails>(path);
    return fromDetails(type, data);
  }

  // Single exit point to TMDB: one place for the language, the Observable→Promise bridge and error mapping.
  private async get<T>(
    path: string,
    params: Record<string, string | number | boolean> = {},
  ): Promise<T> {
    try {
      // HttpService returns an RxJS Observable; firstValueFrom turns it into a Promise we can await.
      const response = await firstValueFrom(
        this.http.get<T>(path, { params: { language: 'fr-FR', ...params } }),
      );
      return response.data;
    } catch (error) {
      throw this.toHttpException(error, path);
    }
  }

  // Translates TMDB failures into HTTP errors that make sense for OUR client (it doesn't know TMDB exists).
  private toHttpException(error: unknown, path: string): unknown {
    // Not an HTTP error (bug in our code, mapper crash...): let Nest return a 500 and log the stack.
    if (!isAxiosError(error)) return error;

    const status = error.response?.status;
    // SECURITY: log status + path only. The axios error object contains the request config,
    // so logging it whole would print "Authorization: Bearer <token>" into the logs.
    this.logger.warn(`TMDB ${path} failed: ${status ?? error.code}`);

    if (status === 404) return new NotFoundException('Title not found');
    // No response at all = timeout or network down: 504 says "the upstream didn't answer".
    if (!error.response)
      return new GatewayTimeoutException('Metadata provider unreachable');
    // 429 = TMDB rate-limits us. 503 tells the client "busy, slow down": the app must NOT retry it right away.
    if (status === 429) {
      return new ServiceUnavailableException('Metadata provider busy');
    }
    // 401 (bad token), 5xx...: 502 says "the upstream answered badly". Details stay in our logs.
    return new BadGatewayException('Metadata provider error');
  }
}
