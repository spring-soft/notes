/**
 * Music player data models and enums.
 */
import { ID, Seconds, Timestamp } from './AppConstantsModel';

// ── Enums ──

export enum RepeatMode {
  OFF = 0,
  REPEAT_ALL = 1,
  REPEAT_ONE = 2,
}

export enum MusicSource {
  LOCAL = 'local',
  NOVIDROME = 'novidrome',
}

export enum PlayerState {
  IDLE = 0,
  LOADING = 1,
  PLAYING = 2,
  PAUSED = 3,
  STOPPED = 4,
  ERROR = 5,
}

export enum MusicPageTab {
  TRACKS = 0,
  ALBUMS = 1,
  ARTISTS = 2,
  PLAYLISTS = 3,
  SEARCH = 4,
  NOVIDROME = 5,
}

// ── Core Data Interfaces ──

export interface Track {
  id: ID;
  title: string;
  artist: string;
  album: string;
  durationMs: number;
  fileUri: string;
  albumArtUri: string;
  source: MusicSource;
  serverTrackId: string;
  dateAdded: Timestamp;
}

export interface Playlist {
  id: ID;
  name: string;
  createdAt: Timestamp;
  trackCount?: number;
}

// ── Configuration Interfaces ──

export interface NovidromeConfig {
  serverUrl: string;
  username: string;
  password: string;
  enabled: boolean;
}

export interface MusicPlayerConfig {
  volume: number;
  repeatMode: RepeatMode;
  shuffleEnabled: boolean;
  lastTrackId: string;
  lastPosition: number;
}

// ── Subsonic API Response Interfaces ──

export interface SubsonicArtist {
  id: string;
  name: string;
  albumCount: number;
  coverArt?: string;
}

export interface SubsonicAlbum {
  id: string;
  name: string;
  artist: string;
  artistId: string;
  coverArt: string;
  songCount: number;
  duration: number;
  year: number;
  genre: string;
}

export interface SubsonicSong {
  id: string;
  parent: string;
  title: string;
  album: string;
  artist: string;
  track: number;
  coverArt: string;
  size: number;
  contentType: string;
  suffix: string;
  duration: number;
  bitRate: number;
  path: string;
  playCount: number;
  discNumber: number;
  created: string;
  albumId: string;
  artistId: string;
  type: string;
  isVideo: boolean;
}

export interface SubsonicSearchResult3 {
  artist: SubsonicArtist[];
  album: SubsonicAlbum[];
  song: SubsonicSong[];
}

// ── Subsonic API Wrapper Interfaces ──

export interface SubsonicResponseBase {
  status: string;
  version: string;
  error?: SubsonicError;
}

export interface SubsonicError {
  code: number;
  message: string;
}

export interface SubsonicArtistsResponse extends SubsonicResponseBase {
  artists: SubsonicArtistsContainer;
}

export interface SubsonicArtistsContainer {
  index: SubsonicArtistIndex[];
}

export interface SubsonicArtistIndex {
  name: string;
  artist: SubsonicArtist[];
}

export interface SubsonicDirectoryResponse extends SubsonicResponseBase {
  directory: SubsonicDirectory;
}

export interface SubsonicDirectory {
  id: string;
  name: string;
  child: SubsonicSong[];
}

export interface SubsonicAlbumListResponse extends SubsonicResponseBase {
  albumList: SubsonicAlbumListContainer;
}

export interface SubsonicAlbumListContainer {
  album: SubsonicAlbum[];
}

export interface SubsonicSearchResponse extends SubsonicResponseBase {
  searchResult3: SubsonicSearchResult3;
}

// ── Default Factories ──

export function getDefaultNovidromeConfig(): NovidromeConfig {
  return {
    serverUrl: '',
    username: '',
    password: '',
    enabled: false,
  };
}

export function getDefaultMusicPlayerConfig(): MusicPlayerConfig {
  return {
    volume: 0.7,
    repeatMode: RepeatMode.REPEAT_ALL,
    shuffleEnabled: false,
    lastTrackId: '',
    lastPosition: 0,
  };
}

export function getEmptyTrack(): Track {
  return {
    id: '',
    title: '',
    artist: '',
    album: '',
    durationMs: 0,
    fileUri: '',
    albumArtUri: '',
    source: MusicSource.LOCAL,
    serverTrackId: '',
    dateAdded: 0,
  };
}
