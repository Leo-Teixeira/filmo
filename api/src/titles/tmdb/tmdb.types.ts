// Raw TMDB v3 response shapes, limited to the fields we actually read.

export type TmdbMediaType = 'movie' | 'tv' | 'person';

// GET /search/multi item. Movies use title/release_date, TV shows use name/first_air_date.
export interface TmdbSearchResult {
  id: number;
  media_type: TmdbMediaType;
  title?: string;
  name?: string;
  overview?: string;
  poster_path?: string | null;
  release_date?: string;
  first_air_date?: string;
  genre_ids?: number[];
  original_language?: string;
}

export interface TmdbSearchResponse {
  page: number;
  results: TmdbSearchResult[];
  total_pages: number;
  total_results: number;
}

// GET /movie/{id} and GET /tv/{id}.
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
