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

@Injectable()
export class TmdbProvider implements MetadataProvider {
  readonly name = 'tmdb';

  private readonly logger = new Logger(TmdbProvider.name);

  constructor(private readonly http: HttpService) {}

  async search(query: string): Promise<ExternalTitle[]> {
    const data = await this.get<TmdbSearchResponse>('/search/multi', {
      query,
      include_adult: false,
      page: 1,
    });
    return data.results
      .map(fromSearchResult)
      .filter((title): title is ExternalTitle => title !== null);
  }

  async getDetails(
    type: TitleType,
    externalId: string,
  ): Promise<ExternalTitle> {
    const segment = type === TitleType.MOVIE ? 'movie' : 'tv';
    // Encoded even though it comes from our DB: never glue a raw string into a URL.
    const path = `/${segment}/${encodeURIComponent(externalId)}`;
    const data = await this.get<TmdbDetails>(path);
    return fromDetails(type, data);
  }

  private async get<T>(
    path: string,
    params: Record<string, string | number | boolean> = {},
  ): Promise<T> {
    try {
      const response = await firstValueFrom(
        this.http.get<T>(path, { params: { language: 'fr-FR', ...params } }),
      );
      return response.data;
    } catch (error) {
      throw this.toHttpException(error, path);
    }
  }

  private toHttpException(error: unknown, path: string): unknown {
    // Not an HTTP error (a bug on our side): passed through so Nest returns a 500.
    if (!isAxiosError(error)) return error;

    const status = error.response?.status;
    // Never log the axios error itself: its request config holds the Bearer token.
    this.logger.warn(`TMDB ${path} failed: ${status ?? error.code}`);

    if (status === 404) return new NotFoundException('Title not found');
    if (!error.response)
      return new GatewayTimeoutException('Metadata provider unreachable');
    // 503, not 502: the app must not retry a rate limit right away.
    if (status === 429) {
      return new ServiceUnavailableException('Metadata provider busy');
    }
    // Anything else, TMDB's 401 included, is a 502: the client must never read it as its own expiry.
    return new BadGatewayException('Metadata provider error');
  }
}
