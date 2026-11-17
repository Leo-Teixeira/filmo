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

// Cached titles older than this are refreshed from the provider in findOne.
export const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

@Injectable()
export class TitlesService {
  private readonly logger = new Logger(TitlesService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(METADATA_PROVIDER) private readonly metadata: MetadataProvider,
  ) {}

  // Every result is saved locally so the client only ever handles our uuids.
  async search(query: string): Promise<Title[]> {
    const results = await this.metadata.search(query);
    // No transaction: concurrent searches locking the same rows in different orders could deadlock.
    return Promise.all(results.map((title) => this.upsertFromProvider(title)));
  }

  async findOne(id: string): Promise<Title> {
    const title = await this.prisma.title.findUnique({ where: { id } });
    if (!title) throw new TitleNotFoundException();
    if (Date.now() - title.cachedAt.getTime() < CACHE_TTL_MS) return title;

    try {
      const fresh = await this.metadata.getDetails(
        title.type,
        title.externalId,
      );
      return await this.upsertFromProvider(fresh);
    } catch (error) {
      // A stale copy beats an error page: getDetails throws, it never returns null.
      const status =
        error instanceof HttpException ? error.getStatus() : 'unknown';
      this.logger.warn(
        `Refresh failed for title ${id} (status ${status}), serving stale copy`,
      );
      return title;
    }
  }

  private upsertFromProvider(title: ExternalTitle) {
    const provider = this.metadata.name;
    // No include/select: keeps the native atomic upsert (concurrent searches would race into P2002).
    return this.prisma.title.upsert({
      where: {
        provider_type_externalId: {
          provider,
          type: title.type,
          externalId: title.externalId,
        },
      },
      create: { provider, ...title },
      // Fresh from the provider: restart the TTL.
      update: { ...title, cachedAt: new Date() },
    });
  }
}

export class TitleNotFoundException extends NotFoundException {
  constructor() {
    super('Title not found');
  }
}
