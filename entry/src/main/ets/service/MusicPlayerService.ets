import { media } from '@kit.MediaKit';
import { avSession } from '@kit.AVSessionKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Track, PlayerState, MusicSource } from '../model/MusicModel';

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
  private loadTimeoutId: number | null = null;

  // AVSession for background playback
  private audioSession: avSession.AVSession | null = null;
  private sessionActive: boolean = false;

  // Callbacks (set by ViewModel)
  private onStateChangeCallback: ((state: PlayerState) => void) | null = null;
  private onPositionUpdateCallback: ((currentMs: number, totalMs: number) => void) | null = null;
  private onTrackEndCallback: (() => void) | null = null;
  private onErrorCallback: ((message: string) => void) | null = null;

  constructor() {
    // AVPlayer is created lazily on first loadTrack call
  }

  /**
   * Enable background audio playback via AVSession.
   * Must be called once with a valid context (from Index.initializeApp).
   */
  async enableBackgroundPlayback(context: common.Context): Promise<void> {
    if (this.sessionActive) {
      return;
    }
    try {
      this.audioSession = await avSession.createAVSession(context, 'MemoFlowMusic', 'audio');
      await this.audioSession.activate();
      this.sessionActive = true;
      hilog.info(DOMAIN, TAG, 'AVSession created and activated for background playback');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'AVSession creation failed: %{public}s', e.message);
      // Background playback won't work, but foreground playback is unaffected.
    }
  }

  private updateSessionMetadata(track: Track): void {
    if (!this.sessionActive || this.audioSession === null) {
      return;
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: track.id,
        title: track.title !== '' ? track.title : '未知曲目',
        artist: track.artist !== '' ? track.artist : '未知艺术家',
        album: track.album !== undefined ? track.album : '',
        duration: track.durationMs > 0 ? track.durationMs : 0,
      };
      this.audioSession.setAVMetadata(metadata);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'setAVMetadata failed: %{public}s', e.message);
    }
  }

  private updateSessionPlayState(isPlaying: boolean): void {
    if (!this.sessionActive || this.audioSession === null) {
      return;
    }
    try {
      const playState: avSession.AVPlaybackState = {
        state: isPlaying
          ? avSession.PlaybackState.PLAYBACK_STATE_PLAY
          : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
        speed: isPlaying ? 1.0 : 0.0,
        position: {
          elapsedTime: this.currentPositionMs,
          updateTime: Date.now(),
        },
      };
      this.audioSession.setAVPlaybackState(playState);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'setAVPlaybackState failed: %{public}s', e.message);
    }
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

  // ── Player Setup ──

  /**
   * Registers event listeners on the CURRENT avPlayer instance.
   * Called after creating a fresh AVPlayer on each loadTrack.
   */
  private setupListeners(): void {
    if (this.avPlayer === null) {
      return;
    }

    this.avPlayer.on('stateChange', (state: string) => {
      hilog.info(DOMAIN, TAG, 'AVPlayer state: %{public}s', state);
      if (state === 'initialized') {
        this.setState(PlayerState.LOADING);
        // CRITICAL: AVPlayer requires an explicit prepare() call to
        // transition from initialized → prepared.  Without this, HTTP
        // streams never reach the prepared state and playback silently
        // fails.
        if (this.avPlayer !== null) {
          hilog.info(DOMAIN, TAG, 'Calling prepare() to move from initialized → prepared');
          this.avPlayer.prepare();
        }
      } else if (state === 'prepared') {
        this.clearLoadTimeout();
        // Auto-play when ready — fixes race condition where play() is
        // called before the async URL preparation completes.
        if (this.autoPlayWhenReady) {
          this.autoPlayWhenReady = false;
          if (this.avPlayer !== null) {
            this.avPlayer.play();
          }
        }
      } else if (state === 'playing') {
        this.clearLoadTimeout();
        this.setState(PlayerState.PLAYING);
        this.autoPlayWhenReady = false;
        this.updateSessionPlayState(true);
      } else if (state === 'paused') {
        this.setState(PlayerState.PAUSED);
        this.autoPlayWhenReady = false;
        this.updateSessionPlayState(false);
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
        this.clearLoadTimeout();
        this.setState(PlayerState.ERROR);
        this.autoPlayWhenReady = false;
        hilog.error(DOMAIN, TAG, 'AVPlayer entered error state');
        if (this.onErrorCallback !== null) {
          this.onErrorCallback('播放器进入错误状态');
        }
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
      this.clearLoadTimeout();
      this.setState(PlayerState.ERROR);
      this.autoPlayWhenReady = false;
      if (this.onErrorCallback !== null) {
        this.onErrorCallback('播放错误: ' + err.message);
      }
    });
  }

  // ── Track Loading ──

  async loadTrack(track: Track): Promise<void> {
    try {
      this.clearLoadTimeout();

      // 1. Destroy old player entirely — release()+createAVPlayer() instead
      //    of reset().  When switching HTTP streams, the old player's
      //    internal state (buffered data, pending callbacks) can interfere
      //    with the new URL load.  A fresh AVPlayer starts in clean 'idle'
      //    state, guaranteeing a reliable idle→initialized→prepared chain.
      if (this.avPlayer !== null) {
        try {
          // Detach all listeners BEFORE release so stale 'released' events
          // cannot mutate autoPlayWhenReady / playerState on the new player.
          this.avPlayer.off('stateChange');
          this.avPlayer.off('timeUpdate');
          this.avPlayer.off('durationUpdate');
          this.avPlayer.off('error');
          this.avPlayer.release();
        } catch (e) {
          const err: BusinessError = e as BusinessError;
          hilog.warn(DOMAIN, TAG, 'Error releasing old player: %{public}s', err.message);
        }
        this.avPlayer = null;
      }

      // 2. Create a fresh AVPlayer — starts in 'idle' state
      this.avPlayer = await media.createAVPlayer();
      this.setupListeners();
      this.avPlayer.setVolume(this.volumeLevel);

      // 3. Determine URL based on source.
      let url: string = '';
      if (track.source === MusicSource.NOVIDROME) {
        // Navidrome stream — full HTTP URL already resolved by ViewModel
        url = track.fileUri;
      } else {
        // Local file — prepend file:// protocol
        url = 'file://' + track.fileUri;
      }

      hilog.info(DOMAIN, TAG, 'Loading track URL (%{public}s): %{public}s',
        track.source, url);

      // 4. Set a safety timeout — if the stream doesn't prepare within 30 s,
      //    report an error so the user isn't left wondering.
      this.loadTimeoutId = setTimeout(() => {
        if (this.avPlayer !== null && this.avPlayer.state !== 'prepared'
          && this.avPlayer.state !== 'playing' && this.avPlayer.state !== 'paused') {
          hilog.error(DOMAIN, TAG, 'Stream load timed out after 30 s');
          this.setState(PlayerState.ERROR);
          this.autoPlayWhenReady = false;
          if (this.onErrorCallback !== null) {
            this.onErrorCallback('加载超时: 服务器无响应，请检查网络连接和服务器地址');
          }
        }
      }, 30000);

      // 5. Set URL — triggers idle → initialized → prepared chain.
      //    stateChange handler calls prepare() on 'initialized',
      //    then play() on 'prepared' when autoPlayWhenReady is true.
      this.autoPlayWhenReady = true;
      this.avPlayer.url = url;
      this.currentTrackId = track.id;
      this.currentPositionMs = 0;
      this.durationMs = track.durationMs;
      // Notify system media session of track change (background playback)
      this.updateSessionMetadata(track);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to load track: %{public}s', e.message);
      this.setState(PlayerState.ERROR);
      if (this.onErrorCallback !== null) {
        this.onErrorCallback('加载失败: ' + e.message);
      }
    }
  }

  private clearLoadTimeout(): void {
    if (this.loadTimeoutId !== null) {
      clearTimeout(this.loadTimeoutId);
      this.loadTimeoutId = null;
    }
  }

  // ── Playback Control ──

  play(): void {
    if (this.avPlayer === null) {
      hilog.warn(DOMAIN, TAG, 'play() called but avPlayer is null');
      return;
    }
    const state: string = this.avPlayer.state;
    hilog.info(DOMAIN, TAG, 'play() called, current state: %{public}s', state);

    // Prepared / paused / completed / stopped — can play (or replay).
    if (state === 'prepared' || state === 'paused'
      || state === 'completed' || state === 'stopped') {
      this.avPlayer.play();
    } else if (state === 'initialized' || state === 'idle') {
      // URL was just set and the codec is still initializing.  Defer play
      // to the stateChange handler via autoPlayWhenReady.
      this.autoPlayWhenReady = true;
      // If already initialized, the stateChange handler above may have
      // already called prepare() — but if play() is called independently
      // (e.g. playPause toggle), we must trigger the transition ourselves.
      if (state === 'initialized' && this.avPlayer !== null) {
        this.avPlayer.prepare();
      }
    } else if (state === 'playing') {
      // Already playing — no action needed.
    } else if (state === 'error') {
      // Player is in error state.  Reset and the caller should retry.
      hilog.warn(DOMAIN, TAG, 'play() called in error state — resetting');
      this.autoPlayWhenReady = true;
      this.avPlayer.reset();
    } else {
      // 'released' or unknown — can't play.
      hilog.warn(DOMAIN, TAG, 'play() called in unhandled state: %{public}s', state);
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
    // Deactivate AVSession for background playback
    if (this.audioSession !== null) {
      try {
        this.audioSession.deactivate();
        this.audioSession.destroy();
      } catch (err) {
        const e: BusinessError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, 'Session destroy error: %{public}s', e.message);
      }
      this.audioSession = null;
      this.sessionActive = false;
    }
    this.setState(PlayerState.IDLE);
    this.onStateChangeCallback = null;
    this.onPositionUpdateCallback = null;
    this.onTrackEndCallback = null;
    this.onErrorCallback = null;
  }
}
