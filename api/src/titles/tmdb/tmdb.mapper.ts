import { TitleType } from '../../generated/prisma/enums';
import { ExternalTitle } from '../interfaces/metadata-provider.interface';
import { TmdbDetails, TmdbSearchResult } from './tmdb.types';

// TMDB genre id for "Animation" (same id for movies and TV).
const ANIMATION_GENRE_ID = 16;

// Product rule: anime = Japanese animation (misses Franco-Japanese co-productions).
export function isAnime(
  genreIds: number[],
  originalLanguage: string | undefined,
): boolean {
  return genreIds.includes(ANIMATION_GENRE_ID) && originalLanguage === 'ja';
}

// TMDB sends "" for unknown dates; anything unparsable becomes null.
export function parseTmdbDate(value: string | undefined): Date | null {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

// TMDB sends "" for a missing overview.
function emptyToNull(value: string | null | undefined): string | null {
  return value ? value : null;
}

// Null for people: /search/multi mixes them with titles.
export function fromSearchResult(
  result: TmdbSearchResult,
): ExternalTitle | null {
  if (result.media_type === 'person') return null;

  const isMovie = result.media_type === 'movie';
  return {
    externalId: String(result.id),
    type: isMovie ? TitleType.MOVIE : TitleType.TV,
    isAnime: isAnime(result.genre_ids ?? [], result.original_language),
    title: (isMovie ? result.title : result.name) ?? '',
    overview: emptyToNull(result.overview),
    posterPath: emptyToNull(result.poster_path),
    releaseDate: parseTmdbDate(
      isMovie ? result.release_date : result.first_air_date,
    ),
  };
}

// The details payload has no media_type: the caller already knows the type.
export function fromDetails(
  type: TitleType,
  details: TmdbDetails,
): ExternalTitle {
  const isMovie = type === TitleType.MOVIE;
  return {
    externalId: String(details.id),
    type,
    isAnime: isAnime(
      (details.genres ?? []).map((genre) => genre.id),
      details.original_language,
    ),
    title: (isMovie ? details.title : details.name) ?? '',
    overview: emptyToNull(details.overview),
    posterPath: emptyToNull(details.poster_path),
    releaseDate: parseTmdbDate(
      isMovie ? details.release_date : details.first_air_date,
    ),
  };
}
