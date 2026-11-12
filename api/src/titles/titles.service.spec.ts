import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { TitleType } from '../generated/prisma/enums';
import { PrismaService } from '../prisma/prisma.service';
import {
  ExternalTitle,
  METADATA_PROVIDER,
  MetadataProvider,
} from './interfaces/metadata-provider.interface';
import { CACHE_TTL_MS, TitlesService } from './titles.service';

const dune: ExternalTitle = {
  externalId: '438631',
  type: TitleType.MOVIE,
  isAnime: false,
  title: 'Dune',
  overview: null,
  posterPath: '/dune.jpg',
  releaseDate: new Date('2021-09-15'),
};

// A row as it would come out of the database.
const cachedRow = (cachedAt: Date) => ({
  id: 'title-uuid',
  provider: 'fake',
  cachedAt,
  ...dune,
});

describe('TitlesService', () => {
  let service: TitlesService;

  // The whole point of the port: no HTTP, no TMDB, just an object that respects the contract.
  // Standalone jest.fn() so expect(getDetails) doesn't trip the unbound-method lint rule.
  const search = jest.fn<Promise<ExternalTitle[]>, [string]>();
  const getDetails = jest.fn<Promise<ExternalTitle>, [TitleType, string]>();
  const metadata: MetadataProvider = { name: 'fake', search, getDetails };

  const prisma = {
    title: { findUnique: jest.fn(), upsert: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      providers: [
        TitlesService,
        { provide: PrismaService, useValue: prisma },
        { provide: METADATA_PROVIDER, useValue: metadata },
      ],
    }).compile();
    service = moduleRef.get(TitlesService);
  });

  describe('search', () => {
    it('upserts every result on (provider, type, externalId)', async () => {
      search.mockResolvedValue([dune]);
      prisma.title.upsert.mockReturnValue(cachedRow(new Date()));

      const results = await service.search('dune');

      expect(prisma.title.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            provider_type_externalId: {
              provider: 'fake',
              type: TitleType.MOVIE,
              externalId: '438631',
            },
          },
        }),
      );
      expect(results[0].id).toBe('title-uuid');
    });

    it('does not touch the database when the provider finds nothing', async () => {
      search.mockResolvedValue([]);

      await expect(service.search('zzzz')).resolves.toEqual([]);
      expect(prisma.title.upsert).not.toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('throws 404 for an unknown id', async () => {
      prisma.title.findUnique.mockResolvedValue(null);

      await expect(service.findOne('nope')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('serves a fresh cached title without calling the provider', async () => {
      prisma.title.findUnique.mockResolvedValue(cachedRow(new Date()));

      await service.findOne('title-uuid');

      expect(getDetails).not.toHaveBeenCalled();
    });

    const staleDate = () => new Date(Date.now() - CACHE_TTL_MS - 1000);

    it('refreshes a stale title from the provider and saves it', async () => {
      prisma.title.findUnique.mockResolvedValue(cachedRow(staleDate()));
      getDetails.mockResolvedValue({ ...dune, title: 'Dune (2021)' });
      prisma.title.upsert.mockResolvedValue({
        ...cachedRow(new Date()),
        title: 'Dune (2021)',
      });

      const title = await service.findOne('title-uuid');

      expect(getDetails).toHaveBeenCalledWith(TitleType.MOVIE, '438631');
      expect(title.title).toBe('Dune (2021)');
    });

    it('serves the stale copy when the provider is down', async () => {
      const stale = cachedRow(staleDate());
      prisma.title.findUnique.mockResolvedValue(stale);
      getDetails.mockRejectedValue(new Error('TMDB down'));

      await expect(service.findOne('title-uuid')).resolves.toEqual(stale);
    });
  });
});
