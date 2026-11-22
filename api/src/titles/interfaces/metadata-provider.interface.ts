// Relative import: Jest has no mapper for the 'src/' prefix.
import { TitleType } from '../../generated/prisma/enums';

export const METADATA_PROVIDER = Symbol('METADATA_PROVIDER');

export interface ExternalTitle {
  // String so non-numeric ids (AniList, IMDb "tt…") fit the same column.
  externalId: string;
  type: TitleType;
  isAnime: boolean;
  title: string;
  overview: string | null;
  // Relative path (e.g. "/abc.jpg"): the client picks the image size.
  posterPath: string | null;
  releaseDate: Date | null;
}

export interface MetadataProvider {
  // Stored in Title.provider: must never change once data exists.
  readonly name: string;
  search(query: string): Promise<ExternalTitle[]>;
  getDetails(type: TitleType, externalId: string): Promise<ExternalTitle>;
}
