import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Track, PlayerState } from '../model/MusicModel';

const DOMAIN: number = 0x0001;
const TAG: string = 'MusicPlayerService';

/**
 * Wraps HarmonyOS AVPlayer with a clean state machine and callback pattern.
 * Follows the same callback registration pattern as PomodoroTimerService.
 */
export class MusicPlayerService {
  private avPlayer: media.AVPlayer | null = null;
  private playerState: PlayerState = PlayerState.IDLE;
  private currentTrackId: string = '';
  private volumeLevel: number = 0.7;
  private currentPositionMs: number = 0;
  private durationMs: number = 0;
  private autoPlayWhenReady: boolean = false;

  // Callbacks (set by ViewModel)
  private onStateChangeCallback: ((state: PlayerState) => void) | null = null;
  private onPositionUpdateCallback: ((currentMs: number, totalMs: number) => void) | null = null;
  private onTrackEndCallback: (() => void) | null = null;
  private onErrorCallback: ((message: string) => void) | null = null;

  constructor() {
    // AVPlayer is created lazily on first loadTrack call
  }

  onStateChange(callback: (state: PlayerState) => void): void {
    this.onStateChangeCallback = callback;
  }

  onPositionUpdate(callback: (currentMs: number, totalMs: number) => void): void {
    this.onPositionUpdateCallback = callback;
  }

  onTrackEnd(callback: () => void): void {
    this.onTrackEndCallback = callback;
  }

  onError(callback: (message: string) => void): void {
    this.onErrorCallback = callback;
  }

  private setState(state: PlayerState): void {
    this.playerState = state;
    if (this.onStateChangeCallback !== null) {
      this.onStateChangeCallback(state);
    }
  }

  // ── Player Initialization ──

  private async ensurePlayer(): Promise<media.AVPlayer> {
    if (this.avPlayer === null) {
      this.avPlayer = await media.createAVPlayer();
      this.setupListeners();
    }
    return this.avPlayer;
  }

  private setupListeners(): void {
    if (this.avPlayer === null) {
      return;
    }

    this.avPlayer.on('stateChange', (state: string) => {
      hilog.info(DOMAIN, TAG, 'AVPlayer state: %{public}s', state);
      if (state === 'initialized') {
        this.setState(PlayerState.LOADING);
      } else if (state === 'prepared') {
        this.setState(PlayerState.LOADING);
        // Auto-play when ready — fixes race condition where play() is
        // called before the async URL preparation completes (common for
        // HTTP streams which take longer than local files).
        if (this.autoPlayWhenReady) {
          this.autoPlayWhenReady = false;
          if (this.avPlayer !== null) {
            this.avPlayer.play();
          }
        }
      } else if (state === 'playing') {
        this.setState(PlayerState.PLAYING);
        this.autoPlayWhenReady = false;
      } else if (state === 'paused') {
        this.setState(PlayerState.PAUSED);
        this.autoPlayWhenReady = false;
      } else if (state === 'stopped') {
        this.setState(PlayerState.STOPPED);
        this.autoPlayWhenReady = false;
      } else if (state === 'completed') {
        this.setState(PlayerState.STOPPED);
        this.autoPlayWhenReady = false;
        if (this.onTrackEndCallback !== null) {
          this.onTrackEndCallback();
        }
      } else if (state === 'error') {
        this.setState(PlayerState.ERROR);
        this.autoPlayWhenReady = false;
      } else if (state === 'released') {
        this.setState(PlayerState.IDLE);
        this.autoPlayWhenReady = false;
      }
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.currentPositionMs = time;
      if (this.onPositionUpdateCallback !== null) {
        this.onPositionUpdateCallback(this.currentPositionMs, this.durationMs);
      }
    });

    this.avPlayer.on('durationUpdate', (duration: number) => {
      this.durationMs = duration;
      if (this.onPositionUpdateCallback !== null) {
        this.onPositionUpdateCallback(this.currentPositionMs, this.durationMs);
      }
    });

    this.avPlayer.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'AVPlayer error: %{public}d, %{public}s', err.code, err.message);
      this.setState(PlayerState.ERROR);
      if (this.onErrorCallback !== null) {
        this.onErrorCallback('播放错误: ' + err.message);
      }
    });
  }

  // ── Track Loading ──

  async loadTrack(track: Track): Promise<void> {
    try {
      this.setState(PlayerState.LOADING);
      const player: media.AVPlayer = await this.ensurePlayer();

      // Reset player to idle before loading new URL. stop() alone
      // keeps the old source; reset() clears it so setting url triggers
      // a fresh idle→initialized→prepared cycle.
      if (this.playerState !== PlayerState.IDLE) {
        player.reset();
      }

      // Determine URL based on source
      let url: string = '';
      if (track.source === 'novidrome') {
        url = track.fileUri; // Already the full stream URL from getStreamUrl()
      } else {
        url = 'file://' + track.fileUri;
      }

      hilog.info(DOMAIN, TAG, 'Loading track URL: %{public}s', url);
      this.autoPlayWhenReady = true;
      player.url = url;
      this.currentTrackId = track.id;
      this.currentPositionMs = 0;
      this.durationMs = track.durationMs;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to load track: %{public}s', e.message);
      this.setState(PlayerState.ERROR);
      if (this.onErrorCallback !== null) {
        this.onErrorCallback('加载失败: ' + e.message);
      }
    }
  }

  // ── Playback Control ──

  play(): void {
    if (this.avPlayer === null) {
      return;
    }
    const state: string = this.avPlayer.state;
    if (state === 'prepared' || state === 'paused' || state === 'completed') {
      this.avPlayer.play();
    }
  }

  pause(): void {
    if (this.avPlayer !== null && this.avPlayer.state === 'playing') {
      this.avPlayer.pause();
    }
  }

  stop(): void {
    if (this.avPlayer !== null) {
      this.setState(PlayerState.STOPPED);
      this.avPlayer.stop();
    }
  }

  seekTo(positionMs: number): void {
    if (this.avPlayer !== null) {
      try {
        this.avPlayer.seek(positionMs, media.SeekMode.SEEK_PREV_SYNC);
        this.currentPositionMs = positionMs;
        if (this.onPositionUpdateCallback !== null) {
          this.onPositionUpdateCallback(this.currentPositionMs, this.durationMs);
        }
      } catch (err) {
        const e: BusinessError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, 'Seek failed: %{public}s', e.message);
      }
    }
  }

  setVolume(level: number): void {
    this.volumeLevel = level;
    if (this.avPlayer !== null) {
      try {
        this.avPlayer.setVolume(level);
      } catch (err) {
        const e: BusinessError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, 'Set volume failed: %{public}s', e.message);
      }
    }
  }

  // ── State Queries ──

  getPlayerState(): PlayerState {
    return this.playerState;
  }

  getCurrentPosition(): number {
    return this.currentPositionMs;
  }

  getDuration(): number {
    return this.durationMs;
  }

  getCurrentTrackId(): string {
    return this.currentTrackId;
  }

  // ── Cleanup ──

  destroy(): void {
    if (this.avPlayer !== null) {
      try {
        this.avPlayer.stop();
        this.avPlayer.release();
      } catch (err) {
        const e: BusinessError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, 'Destroy error: %{public}s', e.message);
      }
      this.avPlayer = null;
    }
    this.setState(PlayerState.IDLE);
    this.onStateChangeCallback = null;
    this.onPositionUpdateCallback = null;
    this.onTrackEndCallback = null;
    this.onErrorCallback = null;
  }
}
