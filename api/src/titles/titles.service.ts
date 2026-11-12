import {
  HttpException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Title } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  ExternalTitle,
  METADATA_PROVIDER,
  type MetadataProvider,
} from './interfaces/metadata-provider.interface';

// A cached title older than this should be refreshed from the provider (used by défi 1, see findOne).
export const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

@Injectable()
export class TitlesService {
  private readonly logger = new Logger(TitlesService.name);

  constructor(
    private readonly prisma: PrismaService,
    // @Inject(token) is mandatory here: the TS type "MetadataProvider" is erased at runtime, Nest only sees the Symbol.
    @Inject(METADATA_PROVIDER) private readonly metadata: MetadataProvider,
  ) {}

  // Search = ask the provider, then save every result locally so each one gets OUR uuid.
  // The client then only ever handles our ids (GET /titles/:id, PUT /library/:titleId).
  async search(query: string): Promise<Title[]> {
    const results = await this.metadata.search(query);
    // No transaction on purpose: each upsert is a single atomic INSERT ... ON CONFLICT on one row.
    // Wrapping them in one transaction would lock rows in ranking order, and two concurrent searches
    // ("dune" / "dune part two") locking the same rows in a different order could deadlock (→ 500).
    // Promise.all keeps the provider's ranking order in the returned array.
    return Promise.all(results.map((title) => this.upsertFromProvider(title)));
  }

  async findOne(id: string): Promise<Title> {
    const title = await this.prisma.title.findUnique({ where: { id } });
    if (!title) throw new TitleNotFoundException();
    // `<`, not `==`: an age is never exactly the TTL to the millisecond.
    if (Date.now() - title.cachedAt.getTime() < CACHE_TTL_MS) return title;

    try {
      const fresh = await this.metadata.getDetails(
        title.type,
        title.externalId,
      );
      return await this.upsertFromProvider(fresh);
    } catch (error) {
      // getDetails throws (504/502/404), it never returns null. A stale copy beats an error page.
      const status =
        error instanceof HttpException ? error.getStatus() : 'unknown';
      this.logger.warn(
        `Refresh failed for title ${id} (status ${status}), serving stale copy`,
      );
      return title;
    }
  }

  // Shared by search() and the refresh in findOne(): one place that knows how to write a provider title.
  // Resetting cachedAt here is correct: the data just came from the provider, so it IS fresh.
  private upsertFromProvider(title: ExternalTitle) {
    const provider = this.metadata.name;
    return this.prisma.title.upsert({
      // Compound unique key from @@unique([provider, type, externalId]): Prisma names it field1_field2_field3.
      where: {
        provider_type_externalId: {
          provider,
          type: title.type,
          externalId: title.externalId,
        },
      },
      create: { provider, ...title },
      // Existing row: refresh the data AND reset cachedAt so the TTL starts again.
      update: { ...title, cachedAt: new Date() },
    });
  }
}

// Same pattern as UserNotFoundException: a named exception keeps the message consistent everywhere.
export class TitleNotFoundException extends NotFoundException {
  constructor() {
    super('Title not found');
  }
}
