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
        // Only show loading for first-time track loads (IDLE/STOPPED).
        // During track switch while playing, keep PLAYING so the UI
        // shows the pause button continuously — no perceived interruption.
        if (this.playerState !== PlayerState.PLAYING) {
          this.setState(PlayerState.LOADING);
        }
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

  /**
   * Loads a new track for playback.  Uses an overlapping strategy to
   * eliminate the silence gap between tracks:
   *
   *   1. Create a new AVPlayer in the background (old one keeps playing)
   *   2. Set URL and wait for the 'prepared' state on the new player
   *   3. Only THEN release the old player and make the new one current
   *   4. Return — caller calls play() which starts playback near-instantly
   *
   * This way the HTTP stream setup / buffering happens while the old
   * track is still playing, so the user hears a seamless transition.
   */
  async loadTrack(track: Track): Promise<void> {
    try {
      this.clearLoadTimeout();

      // Determine URL
      let url: string = '';
      if (track.source === MusicSource.NOVIDROME) {
        url = track.fileUri;
      } else {
        url = 'file://' + track.fileUri;
      }

      hilog.info(DOMAIN, TAG, 'Loading track URL (%{public}s): %{public}s',
        track.source, url);

      // ── Phase 1: Create new player and wait for 'prepared' ──
      // Old player keeps playing during this phase.
      const newPlayer: media.AVPlayer = await media.createAVPlayer();
      newPlayer.setVolume(this.volumeLevel);

      let prepareError: string = '';

      await new Promise<void>((resolve: (value: void) => void) => {
        let finished: boolean = false;

        const finish = (): void => {
          if (finished) {
            return;
          }
          finished = true;
          newPlayer.off('stateChange');
          newPlayer.off('error');
          clearTimeout(timeoutId);
          resolve();
        };

        const timeoutId: number = setTimeout(() => {
          prepareError = '加载超时: 服务器无响应';
          finish();
        }, 30000);

        newPlayer.on('stateChange', (state: string) => {
          if (state === 'initialized') {
            newPlayer.prepare();
          } else if (state === 'prepared') {
            // New player is ready — proceed to phase 2
            finish();
          } else if (state === 'error') {
            prepareError = '播放器进入错误状态';
            finish();
          }
        });

        newPlayer.on('error', (err: BusinessError) => {
          prepareError = '播放错误: ' + err.message;
          finish();
        });

        // Kick off the state machine
        newPlayer.url = url;
      });

      // ── Phase 2: If preparation failed, clean up and report ──
      if (prepareError !== '') {
        try {
          newPlayer.release();
        } catch (_e) {
          // ignore
        }
        this.setState(PlayerState.ERROR);
        if (this.onErrorCallback !== null) {
          this.onErrorCallback(prepareError);
        }
        return;
      }

      // ── Phase 3: Swap players — release old, promote new ──
      if (this.avPlayer !== null) {
        try {
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

      this.avPlayer = newPlayer;
      this.setupListeners();
      this.avPlayer.setVolume(this.volumeLevel);

      // ── Phase 4: Set up safety timeout for playback start ──
      this.loadTimeoutId = setTimeout(() => {
        if (this.avPlayer !== null && this.avPlayer.state !== 'playing'
          && this.avPlayer.state !== 'paused') {
          hilog.error(DOMAIN, TAG, 'Playback start timed out after 30 s');
          this.setState(PlayerState.ERROR);
          this.autoPlayWhenReady = false;
          if (this.onErrorCallback !== null) {
            this.onErrorCallback('播放启动超时');
          }
        }
      }, 30000);

      // ── Phase 5: Ready to play ──
      this.autoPlayWhenReady = true;
      this.currentTrackId = track.id;
      this.currentPositionMs = 0;
      this.durationMs = track.durationMs;
      this.updateSessionMetadata(track);

      hilog.info(DOMAIN, TAG, 'Track prepared and ready: %{public}s', track.title);
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
