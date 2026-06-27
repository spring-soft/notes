import { Seconds } from '../model/AppConstantsModel';

/**
 * Pure timer engine using setInterval.
 * Emits ticks and completion events via callbacks.
 * Does NOT depend on any ArkUI state — the ViewModel subscribes to events.
 */
export class PomodoroTimerService {
  private totalSeconds: Seconds = 0;
  private remainingSeconds: Seconds = 0;
  private isRunning: boolean = false;
  private isPaused: boolean = false;
  private timerId: number = -1;

  private onTickCallback: ((remaining: Seconds, total: Seconds) => void) | null = null;
  private onCompleteCallback: (() => void) | null = null;
  private onHalfwayCallback: (() => void) | null = null;
  private hasFiredHalfway: boolean = false;

  /**
   * Registers a callback for every second tick.
   */
  onTick(callback: (remaining: Seconds, total: Seconds) => void): void {
    this.onTickCallback = callback;
  }

  /**
   * Registers a callback for timer completion.
   */
  onComplete(callback: () => void): void {
    this.onCompleteCallback = callback;
  }

  /**
   * Registers a callback for when the timer reaches halfway.
   */
  onHalfway(callback: () => void): void {
    this.onHalfwayCallback = callback;
  }

  /**
   * Sets the total duration and resets state.
   */
  setDuration(totalSeconds: Seconds): void {
    this.totalSeconds = totalSeconds;
    this.remainingSeconds = totalSeconds;
    this.hasFiredHalfway = false;
  }

  /**
   * Starts the timer from the beginning or from current remaining time.
   */
  start(): void {
    if (this.isRunning) {
      return;
    }

    this.isRunning = true;
    this.isPaused = false;
    this.hasFiredHalfway = this.remainingSeconds <= this.totalSeconds / 2;

    this.timerId = setInterval(() => {
      if (this.isPaused) {
        return;
      }

      this.remainingSeconds--;

      if (this.onTickCallback !== null) {
        this.onTickCallback(this.remainingSeconds, this.totalSeconds);
      }

      // Check halfway
      if (!this.hasFiredHalfway && this.remainingSeconds <= this.totalSeconds / 2) {
        this.hasFiredHalfway = true;
        if (this.onHalfwayCallback !== null) {
          this.onHalfwayCallback();
        }
      }

      // Check completion
      if (this.remainingSeconds <= 0) {
        this.stop();
        if (this.onCompleteCallback !== null) {
          this.onCompleteCallback();
        }
      }
    }, 1000);
  }

  /**
   * Pauses the timer without resetting.
   */
  pause(): void {
    this.isPaused = true;
  }

  /**
   * Resumes the timer from pause.
   */
  resume(): void {
    this.isPaused = false;
  }

  /**
   * Stops and resets the timer completely.
   */
  reset(): void {
    this.stop();
    this.remainingSeconds = this.totalSeconds;
    this.hasFiredHalfway = false;
  }

  /**
   * Stops the timer interval.
   */
  private stop(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.isRunning = false;
    this.isPaused = false;
  }

  /**
   * Gets the remaining time.
   */
  getRemaining(): Seconds {
    return this.remainingSeconds;
  }

  /**
   * Gets the progress ratio (0.0 to 1.0).
   */
  getProgress(): number {
    if (this.totalSeconds === 0) {
      return 0;
    }
    return (this.totalSeconds - this.remainingSeconds) / this.totalSeconds;
  }

  /**
   * Checks if the timer is actively running (not paused).
   */
  get active(): boolean {
    return this.isRunning && !this.isPaused;
  }

  /**
   * Checks if the timer is paused.
   */
  get paused(): boolean {
    return this.isPaused;
  }

  /**
   * Checks if the timer is currently running (either active or paused).
   */
  get running(): boolean {
    return this.isRunning;
  }

  /**
   * Cleans up the timer. Call when destroying the service.
   */
  destroy(): void {
    this.stop();
    this.onTickCallback = null;
    this.onCompleteCallback = null;
    this.onHalfwayCallback = null;
  }
}
