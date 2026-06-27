import { Seconds } from '../model/AppConstantsModel';

/**
 * Pure timer engine using wall-clock timestamps.
 *
 * Instead of counting down with setInterval (which gets throttled in background
 * and drifts over time), the timer records a start timestamp and calculates
 * remaining time from `Date.now()` on every tick.  This keeps the countdown
 * accurate even when:
 * - The app is minimised (setInterval is throttled by the OS)
 * - The user switches between tabs (Navigation keeps the page alive)
 */
export class PomodoroTimerService {
  private totalSeconds: Seconds = 0;
  private remainingSeconds: Seconds = 0;
  private isRunning: boolean = false;
  private isPaused: boolean = false;
  private timerId: number = -1;

  // Wall-clock tracking — the timer's truth is always:
  //   remaining = totalSeconds - pausedElapsed - floor((Date.now() - startTimestamp) / 1000)
  private startTimestamp: number = 0;
  private pausedElapsed: Seconds = 0;

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
    this.pausedElapsed = 0;
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
    this.startTimestamp = Date.now();
    this.hasFiredHalfway = (this.totalSeconds - this.pausedElapsed) <= this.totalSeconds / 2;

    this.timerId = setInterval(() => {
      if (this.isPaused) {
        return;
      }

      this.tick();
    }, 1000);
  }

  /**
   * Pauses the timer without resetting.
   * Accumulates elapsed time into pausedElapsed so resume continues from the
   * correct wall-clock position.
   */
  pause(): void {
    if (!this.isRunning || this.isPaused) {
      return;
    }

    this.isPaused = true;
    // Accumulate the seconds that have elapsed since the last start/resume.
    const elapsed: Seconds = Math.floor((Date.now() - this.startTimestamp) / 1000);
    this.pausedElapsed += elapsed;
    // Clamp pausedElapsed so we don't overshoot totalSeconds.
    if (this.pausedElapsed > this.totalSeconds) {
      this.pausedElapsed = this.totalSeconds;
    }
  }

  /**
   * Resumes the timer from pause.
   */
  resume(): void {
    if (!this.isRunning || !this.isPaused) {
      return;
    }

    this.isPaused = false;
    this.startTimestamp = Date.now();
  }

  /**
   * Stops and resets the timer completely.
   */
  reset(): void {
    this.stop();
    this.remainingSeconds = this.totalSeconds;
    this.pausedElapsed = 0;
    this.hasFiredHalfway = false;
  }

  /**
   * Core tick — calculates remaining time from wall-clock and fires callbacks.
   */
  private tick(): void {
    const elapsed: Seconds = Math.floor((Date.now() - this.startTimestamp) / 1000);
    const totalElapsed: Seconds = this.pausedElapsed + elapsed;
    let remaining: Seconds = this.totalSeconds - totalElapsed;

    if (remaining < 0) {
      remaining = 0;
    }

    this.remainingSeconds = remaining;

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
