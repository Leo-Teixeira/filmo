import { HttpService } from '@nestjs/axios';
import {
  BadGatewayException,
  GatewayTimeoutException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AxiosError, AxiosHeaders, AxiosResponse } from 'axios';
import { of, throwError } from 'rxjs';
import { TitleType } from '../../generated/prisma/enums';
import { TmdbProvider } from './tmdb.provider';

// Builds a fake axios response wrapped in an Observable, like HttpService.get would return.
const ok = <T>(data: T) => of({ data, status: 200 } as AxiosResponse<T>);

// Builds an AxiosError: with a status = TMDB answered with an error; without = network/timeout.
const axiosError = (status?: number) => {
  const config = { headers: new AxiosHeaders() };
  const response = status
    ? ({
        status,
        data: {},
        headers: {},
        config,
        statusText: '',
      } as AxiosResponse)
    : undefined;
  return new AxiosError('boom', 'ERR', config, undefined, response);
};

describe('TmdbProvider', () => {
  let provider: TmdbProvider;
  const http = { get: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      providers: [TmdbProvider, { provide: HttpService, useValue: http }],
    }).compile();
    provider = moduleRef.get(TmdbProvider);
  });

  it('searches with the French language and filters out people', async () => {
    http.get.mockReturnValue(
      ok({
        page: 1,
        total_pages: 1,
        total_results: 2,
        results: [
          { id: 1, media_type: 'movie', title: 'Dune' },
          { id: 2, media_type: 'person', name: 'Zendaya' },
        ],
      }),
    );

    const results = await provider.search('dune');

    expect(http.get).toHaveBeenCalledWith('/search/multi', {
      params: expect.objectContaining({
        query: 'dune',
        include_adult: false,
        language: 'fr-FR',
      }) as unknown,
    });
    expect(results).toHaveLength(1);
    expect(results[0].title).toBe('Dune');
  });

  it('calls /tv/{id} for a TV show', async () => {
    http.get.mockReturnValue(ok({ id: 1399, name: 'GoT' }));

    await provider.getDetails(TitleType.TV, '1399');

    expect(http.get).toHaveBeenCalledWith('/tv/1399', expect.anything());
  });

  it('maps a TMDB 404 to NotFoundException', async () => {
    http.get.mockReturnValue(throwError(() => axiosError(404)));

    await expect(
      provider.getDetails(TitleType.MOVIE, '0'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('maps a network failure (no response) to GatewayTimeoutException', async () => {
    http.get.mockReturnValue(throwError(() => axiosError()));

    await expect(provider.search('dune')).rejects.toBeInstanceOf(
      GatewayTimeoutException,
    );
  });

  it('maps a TMDB rate limit (429) to ServiceUnavailableException', async () => {
    http.get.mockReturnValue(throwError(() => axiosError(429)));

    await expect(provider.search('dune')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('maps other TMDB errors (401, 5xx) to BadGatewayException', async () => {
    http.get.mockReturnValue(throwError(() => axiosError(401)));

    await expect(provider.search('dune')).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it('rethrows non-HTTP errors untouched', async () => {
    const bug = new TypeError('mapper crashed');
    http.get.mockReturnValue(throwError(() => bug));

    await expect(provider.search('dune')).rejects.toBe(bug);
  });
});
