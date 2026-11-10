// Relative import (not 'src/...'): Jest resolves from rootDir "src" and has no mapper for the "src/" prefix.
import { TitleType } from '../../generated/prisma/enums';

// Injection token: an interface disappears at compile time, so Nest needs a runtime value to find the provider.
export const METADATA_PROVIDER = Symbol('METADATA_PROVIDER');

// What the rest of the app knows about an external title: no TMDB-specific field leaks past this shape.
export interface ExternalTitle {
  // Always a string so a future provider with non-numeric ids (AniList, IMDb "tt…") fits the same column.
  externalId: string;
  type: TitleType;
  isAnime: boolean;
  title: string;
  overview: string | null;
  // Relative path only (e.g. "/abc.jpg"); the client builds the full image URL with the size it needs.
  posterPath: string | null;
  releaseDate: Date | null;
}

// The "port": TitlesService depends on this contract, never on TmdbProvider directly.
export interface MetadataProvider {
  // Stored in Title.provider, so it must stay stable once data exists in the database.
  readonly name: string;
  search(query: string): Promise<ExternalTitle[]>;
  getDetails(type: TitleType, externalId: string): Promise<ExternalTitle>;
}
