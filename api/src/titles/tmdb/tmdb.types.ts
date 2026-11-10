// Raw TMDB v3 response shapes, limited to the fields we actually read.
// Everything optional is genuinely optional in TMDB's payloads (movie vs tv use different keys).

export type TmdbMediaType = 'movie' | 'tv' | 'person';

// One item of GET /search/multi. Movies use title/release_date, TV shows use name/first_air_date.
export interface TmdbSearchResult {
  id: number;
  media_type: TmdbMediaType;
  title?: string;
  name?: string;
  overview?: string;
  poster_path?: string | null;
  release_date?: string;
  first_air_date?: string;
  // Search results only give genre ids; details give full { id, name } objects (see TmdbDetails).
  genre_ids?: number[];
  original_language?: string;
}

export interface TmdbSearchResponse {
  page: number;
  results: TmdbSearchResult[];
  total_pages: number;
  total_results: number;
}

// GET /movie/{id} and GET /tv/{id}: same idea, but with genres as objects.
export interface TmdbDetails {
  id: number;
  title?: string;
  name?: string;
  overview?: string;
  poster_path?: string | null;
  release_date?: string;
  first_air_date?: string;
  genres?: { id: number; name: string }[];
  original_language?: string;
}
