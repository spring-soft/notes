import { relationalStore } from '@kit.ArkData';
import { Track, Playlist, MusicSource } from '../model/MusicModel';
import { ID, Timestamp } from '../model/AppConstantsModel';
import {
  TABLE_MUSIC_TRACKS,
  COL_TRACKS_ID,
  COL_TRACKS_TITLE,
  COL_TRACKS_ARTIST,
  COL_TRACKS_ALBUM,
  COL_TRACKS_DURATION_MS,
  COL_TRACKS_FILE_URI,
  COL_TRACKS_ALBUM_ART_URI,
  COL_TRACKS_SOURCE,
  COL_TRACKS_SERVER_TRACK_ID,
  COL_TRACKS_DATE_ADDED,
  TABLE_MUSIC_PLAYLISTS,
  COL_PLAYLISTS_ID,
  COL_PLAYLISTS_NAME,
  COL_PLAYLISTS_CREATED_AT,
  TABLE_MUSIC_PLAYLIST_TRACKS,
  COL_PLTRACKS_PLAYLIST_ID,
  COL_PLTRACKS_TRACK_ID,
  COL_PLTRACKS_POSITION,
} from '../constants/DatabaseConstants';

export class MusicRepository {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  // ── Track CRUD ──

  async getAllTracks(): Promise<Track[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.orderByAsc(COL_TRACKS_DATE_ADDED + ' DESC');
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const tracks: Track[] = [];
    while (resultSet.goToNextRow()) {
      tracks.push(this.rowToTrack(resultSet));
    }
    resultSet.close();
    return tracks;
  }

  async getTrackById(id: ID): Promise<Track | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.equalTo(COL_TRACKS_ID, id);
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    let track: Track | null = null;
    if (resultSet.goToFirstRow()) {
      track = this.rowToTrack(resultSet);
    }
    resultSet.close();
    return track;
  }

  async getTracksBySource(source: MusicSource): Promise<Track[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.equalTo(COL_TRACKS_SOURCE, source as string);
    predicates.orderByAsc(COL_TRACKS_DATE_ADDED + ' DESC');
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const tracks: Track[] = [];
    while (resultSet.goToNextRow()) {
      tracks.push(this.rowToTrack(resultSet));
    }
    resultSet.close();
    return tracks;
  }

  async searchTracks(query: string): Promise<Track[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.like(COL_TRACKS_TITLE, '%' + query + '%')
      .or()
      .like(COL_TRACKS_ARTIST, '%' + query + '%')
      .or()
      .like(COL_TRACKS_ALBUM, '%' + query + '%');
    predicates.orderByAsc(COL_TRACKS_DATE_ADDED + ' DESC');
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const tracks: Track[] = [];
    while (resultSet.goToNextRow()) {
      tracks.push(this.rowToTrack(resultSet));
    }
    resultSet.close();
    return tracks;
  }

  async insertTrack(track: Track): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.trackToValuesBucket(track);
    await this.store.insert(TABLE_MUSIC_TRACKS, valueBucket);
  }

  async updateTrack(track: Track): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.trackToValuesBucket(track);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.equalTo(COL_TRACKS_ID, track.id);
    await this.store.update(valueBucket, predicates);
  }

  async deleteTrack(id: ID): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.equalTo(COL_TRACKS_ID, id);
    await this.store.delete(predicates);
  }

  async deleteAllBySource(source: MusicSource): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    predicates.equalTo(COL_TRACKS_SOURCE, source as string);
    await this.store.delete(predicates);
  }

  async getTrackCount(): Promise<number> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_TRACKS);
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const count: number = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  // ── Playlist CRUD ──

  async getAllPlaylists(): Promise<Playlist[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLISTS);
    predicates.orderByAsc(COL_PLAYLISTS_CREATED_AT + ' DESC');
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const playlists: Playlist[] = [];
    while (resultSet.goToNextRow()) {
      playlists.push(this.rowToPlaylist(resultSet));
    }
    resultSet.close();
    return playlists;
  }

  async getPlaylistById(id: ID): Promise<Playlist | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLISTS);
    predicates.equalTo(COL_PLAYLISTS_ID, id);
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    let playlist: Playlist | null = null;
    if (resultSet.goToFirstRow()) {
      playlist = this.rowToPlaylist(resultSet);
    }
    resultSet.close();
    return playlist;
  }

  async createPlaylist(playlist: Playlist): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.playlistToValuesBucket(playlist);
    await this.store.insert(TABLE_MUSIC_PLAYLISTS, valueBucket);
  }

  async deletePlaylist(id: ID): Promise<void> {
    const playlistPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLISTS);
    playlistPredicates.equalTo(COL_PLAYLISTS_ID, id);
    await this.store.delete(playlistPredicates);
    const trackPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLIST_TRACKS);
    trackPredicates.equalTo(COL_PLTRACKS_PLAYLIST_ID, id);
    await this.store.delete(trackPredicates);
  }

  // ── Playlist-Track Junction ──

  async getTracksForPlaylist(playlistId: ID): Promise<Track[]> {
    const sql: string =
      'SELECT t.* FROM ' + TABLE_MUSIC_TRACKS + ' t ' +
      'INNER JOIN ' + TABLE_MUSIC_PLAYLIST_TRACKS + ' pt ON t.' + COL_TRACKS_ID + ' = pt.' + COL_PLTRACKS_TRACK_ID + ' ' +
      'WHERE pt.' + COL_PLTRACKS_PLAYLIST_ID + ' = ? ' +
      'ORDER BY pt.' + COL_PLTRACKS_POSITION + ' ASC';
    const args: string[] = [playlistId];
    const resultSet: relationalStore.ResultSet = await this.store.querySql(sql, args);
    const tracks: Track[] = [];
    while (resultSet.goToNextRow()) {
      tracks.push(this.rowToTrack(resultSet));
    }
    resultSet.close();
    return tracks;
  }

  async addTrackToPlaylist(playlistId: ID, trackId: ID): Promise<void> {
    const position: number = await this.getNextPosition(playlistId);
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[COL_PLTRACKS_PLAYLIST_ID] = playlistId;
    valueBucket[COL_PLTRACKS_TRACK_ID] = trackId;
    valueBucket[COL_PLTRACKS_POSITION] = position;
    await this.store.insert(TABLE_MUSIC_PLAYLIST_TRACKS, valueBucket);
  }

  async removeTrackFromPlaylist(playlistId: ID, trackId: ID): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLIST_TRACKS);
    predicates.equalTo(COL_PLTRACKS_PLAYLIST_ID, playlistId)
      .and()
      .equalTo(COL_PLTRACKS_TRACK_ID, trackId);
    await this.store.delete(predicates);
  }

  async getNextPosition(playlistId: ID): Promise<number> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLIST_TRACKS);
    predicates.equalTo(COL_PLTRACKS_PLAYLIST_ID, playlistId);
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const count: number = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  async isTrackInPlaylist(playlistId: ID, trackId: ID): Promise<boolean> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLIST_TRACKS);
    predicates.equalTo(COL_PLTRACKS_PLAYLIST_ID, playlistId)
      .and()
      .equalTo(COL_PLTRACKS_TRACK_ID, trackId);
    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const count: number = resultSet.rowCount;
    resultSet.close();
    return count > 0;
  }

  async clearPlaylistTracks(playlistId: ID): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_MUSIC_PLAYLIST_TRACKS);
    predicates.equalTo(COL_PLTRACKS_PLAYLIST_ID, playlistId);
    await this.store.delete(predicates);
  }

  // ── Row Mapping Helpers ──

  private rowToTrack(resultSet: relationalStore.ResultSet): Track {
    const sourceStr: string = resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_SOURCE));
    const source: MusicSource = sourceStr === MusicSource.NOVIDROME ? MusicSource.NOVIDROME : MusicSource.LOCAL;
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_ID)),
      title: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_TITLE)),
      artist: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_ARTIST)),
      album: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_ALBUM)),
      durationMs: resultSet.getLong(resultSet.getColumnIndex(COL_TRACKS_DURATION_MS)),
      fileUri: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_FILE_URI)),
      albumArtUri: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_ALBUM_ART_URI)),
      source: source,
      serverTrackId: resultSet.getString(resultSet.getColumnIndex(COL_TRACKS_SERVER_TRACK_ID)),
      dateAdded: resultSet.getLong(resultSet.getColumnIndex(COL_TRACKS_DATE_ADDED)),
    };
  }

  private trackToValuesBucket(track: Track): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket[COL_TRACKS_ID] = track.id;
    bucket[COL_TRACKS_TITLE] = track.title;
    bucket[COL_TRACKS_ARTIST] = track.artist;
    bucket[COL_TRACKS_ALBUM] = track.album;
    bucket[COL_TRACKS_DURATION_MS] = track.durationMs;
    bucket[COL_TRACKS_FILE_URI] = track.fileUri;
    bucket[COL_TRACKS_ALBUM_ART_URI] = track.albumArtUri;
    bucket[COL_TRACKS_SOURCE] = track.source as string;
    bucket[COL_TRACKS_SERVER_TRACK_ID] = track.serverTrackId;
    bucket[COL_TRACKS_DATE_ADDED] = track.dateAdded;
    return bucket;
  }

  private rowToPlaylist(resultSet: relationalStore.ResultSet): Playlist {
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_PLAYLISTS_ID)),
      name: resultSet.getString(resultSet.getColumnIndex(COL_PLAYLISTS_NAME)),
      createdAt: resultSet.getLong(resultSet.getColumnIndex(COL_PLAYLISTS_CREATED_AT)),
    };
  }

  private playlistToValuesBucket(playlist: Playlist): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket[COL_PLAYLISTS_ID] = playlist.id;
    bucket[COL_PLAYLISTS_NAME] = playlist.name;
    bucket[COL_PLAYLISTS_CREATED_AT] = playlist.createdAt;
    return bucket;
  }
}
