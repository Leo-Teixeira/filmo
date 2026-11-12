import { TitleType } from '../../generated/prisma/enums';
import {
  fromDetails,
  fromSearchResult,
  isAnime,
  parseTmdbDate,
} from './tmdb.mapper';

describe('tmdb.mapper', () => {
  describe('fromSearchResult', () => {
    it('maps a movie with title and release_date', () => {
      const result = fromSearchResult({
        id: 603,
        media_type: 'movie',
        title: 'Matrix',
        overview: 'Neo...',
        poster_path: '/matrix.jpg',
        release_date: '1999-03-31',
        genre_ids: [28, 878],
        original_language: 'en',
      });

      expect(result).toEqual({
        externalId: '603',
        type: TitleType.MOVIE,
        isAnime: false,
        title: 'Matrix',
        overview: 'Neo...',
        posterPath: '/matrix.jpg',
        releaseDate: new Date('1999-03-31'),
      });
    });

    it('maps a TV show with name and first_air_date', () => {
      const result = fromSearchResult({
        id: 1399,
        media_type: 'tv',
        name: 'Game of Thrones',
        first_air_date: '2011-04-17',
      });

      expect(result).toMatchObject({
        externalId: '1399',
        type: TitleType.TV,
        title: 'Game of Thrones',
        releaseDate: new Date('2011-04-17'),
      });
    });

    it('ignores people', () => {
      expect(
        fromSearchResult({ id: 1, media_type: 'person', name: 'Keanu' }),
      ).toBeNull();
    });

    it('turns empty strings from TMDB into null', () => {
      const result = fromSearchResult({
        id: 2,
        media_type: 'movie',
        title: 'Unknown',
        overview: '',
        poster_path: null,
        release_date: '',
      });

      expect(result).toMatchObject({
        overview: null,
        posterPath: null,
        releaseDate: null,
      });
    });
  });

  describe('fromDetails', () => {
    it('reads genres as objects and uses the given type', () => {
      const result = fromDetails(TitleType.TV, {
        id: 37854,
        name: 'One Piece',
        genres: [{ id: 16, name: 'Animation' }],
        original_language: 'ja',
      });

      expect(result).toMatchObject({
        externalId: '37854',
        type: TitleType.TV,
        title: 'One Piece',
        isAnime: true,
      });
    });
  });

  describe('isAnime', () => {
    it('needs both the Animation genre and Japanese as original language', () => {
      expect(isAnime([16], 'ja')).toBe(true);
      expect(isAnime([16], 'en')).toBe(false); // Pixar
      expect(isAnime([18], 'ja')).toBe(false); // Japanese live-action drama
    });
  });

  describe('parseTmdbDate', () => {
    it('returns null for missing or invalid dates', () => {
      expect(parseTmdbDate(undefined)).toBeNull();
      expect(parseTmdbDate('')).toBeNull();
      expect(parseTmdbDate('not-a-date')).toBeNull();
    });
  });
});
