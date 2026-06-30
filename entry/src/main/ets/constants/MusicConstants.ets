import { RepeatMode, MusicPlayerConfig } from '../model/MusicModel';

/**
 * Default music player configuration values.
 * Follows the pattern of PomodoroConstants.ets.
 */
export class MusicConstants {
  // ── Playback defaults ──
  static readonly DEFAULT_VOLUME: number = 0.7;
  static readonly DEFAULT_REPEAT_MODE: RepeatMode = RepeatMode.REPEAT_ALL;
  static readonly DEFAULT_SHUFFLE: boolean = false;

  // ── Limits ──
  static readonly MAX_PLAYLIST_NAME_LENGTH: number = 100;

  // ── Navidrome API ──
  static readonly NOVIDROME_API_VERSION: string = '1.16.1';
  static readonly NOVIDROME_CLIENT_NAME: string = 'MemoFlow';
  static readonly NOVIDROME_TIMEOUT_MS: number = 15000;
  static readonly NOVIDROME_CACHE_TTL_MS: number = 300000; // 5 minutes

  // ── UI ──
  static readonly SEEK_STEP_MS: number = 10000;
  static readonly MIN_PLAYER_WIDTH: number = 320;
  static readonly MINI_PLAYER_HEIGHT: number = 64;
  static readonly ALBUM_ART_SIZE_LARGE: number = 260;
  static readonly ALBUM_ART_SIZE_SMALL: number = 44;
}

/**
 * Returns the default music player config.
 */
export function getDefaultMusicPlayerConfig(): MusicPlayerConfig {
  return {
    volume: MusicConstants.DEFAULT_VOLUME,
    repeatMode: MusicConstants.DEFAULT_REPEAT_MODE,
    shuffleEnabled: MusicConstants.DEFAULT_SHUFFLE,
    lastTrackId: '',
    lastPosition: 0,
  };
}
