import { PomodoroSession, PomodoroSessionType, PomodoroState, PomodoroConfig } from '../model/PomodoroSessionModel';
import { Seconds } from '../model/AppConstantsModel';
import { PomodoroRepository } from '../repository/PomodoroRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { PomodoroTimerService } from '../service/PomodoroTimerService';
import { NotificationService } from '../service/NotificationService';
import { BackgroundTaskService } from '../service/BackgroundTaskService';
import { generateId } from '../utils/IdGenerator';
import { now, startOfToday, endOfToday } from '../utils/DateUtils';
import { formatDuration } from '../utils/DateUtils';
import { getDefaultPomodoroConfig } from '../constants/PomodoroConstants';

/**
 * ViewModel for the Pomodoro timer feature.
 * Manages timer state machine, session history, and background/notification sync.
 */
@Observed
export class PomodoroViewModel {
  currentState: PomodoroState = PomodoroState.IDLE;
  currentType: PomodoroSessionType = PomodoroSessionType.WORK;
  remainingSeconds: Seconds = 0;
  totalSeconds: Seconds = 0;
  progress: number = 0;
  todaySessions: PomodoroSession[] = [];
  todayCompletedCount: number = 0;
  todayTotalMinutes: number = 0;
  config: PomodoroConfig;

  private currentSessionId: string = '';
  private completedWorkCount: number = 0;
  private tickHandler: ((remaining: Seconds, progress: number, state: PomodoroState) => void) | null = null;
  private timerService: PomodoroTimerService;
  private repository: PomodoroRepository;
  private settingsRepository: SettingsRepository;
  private notificationService: NotificationService;
  private backgroundTaskService: BackgroundTaskService;

  constructor(
    repository: PomodoroRepository,
    settingsRepository: SettingsRepository,
    notificationService: NotificationService,
    backgroundTaskService: BackgroundTaskService
  ) {
    this.repository = repository;
    this.settingsRepository = settingsRepository;
    this.notificationService = notificationService;
    this.backgroundTaskService = backgroundTaskService;
    this.timerService = new PomodoroTimerService();
    this.config = getDefaultPomodoroConfig();

    this.timerService.onTick((remaining: Seconds, total: Seconds) => {
      this.remainingSeconds = remaining;
      this.totalSeconds = total;
      this.progress = 1 - remaining / total;
      if (this.tickHandler !== null) {
        this.tickHandler(remaining, this.progress, this.currentState);
      }
    });

    this.timerService.onComplete(() => {
      this.onSessionComplete();
    });
  }

  /**
   * Registers a direct callback that the page uses to update its @State fields.
   * Called on every timer tick with current values — the page sets @State directly,
   * which triggers ArkUI re-render reliably even from setInterval context.
   */
  setTickHandler(handler: (remaining: Seconds, progress: number, state: PomodoroState) => void): void {
    this.tickHandler = handler;
  }

  /**
   * Loads config and today's session history.
   */
  async initialize(): Promise<void> {
    this.config = await this.settingsRepository.loadPomodoroConfig();
    await this.loadTodaySessions();
    this.setSessionType(PomodoroSessionType.WORK);
  }

  /**
   * Switches the session type and resets the timer.
   */
  setSessionType(type: PomodoroSessionType): void {
    // Only reset the timer engine if it has an active interval (running or paused).
    // When IDLE there is nothing to stop — just update the type and duration.
    if (this.timerService.running || this.timerService.active) {
      this.timerService.reset();
    }
    this.currentType = type;

    switch (type) {
      case PomodoroSessionType.WORK:
        this.totalSeconds = this.config.workDuration;
        break;
      case PomodoroSessionType.SHORT_BREAK:
        this.totalSeconds = this.config.shortBreakDuration;
        break;
      case PomodoroSessionType.LONG_BREAK:
        this.totalSeconds = this.config.longBreakDuration;
        break;
    }

    this.remainingSeconds = this.totalSeconds;
    this.progress = 0;
    this.timerService.setDuration(this.totalSeconds);
    this.currentState = PomodoroState.IDLE;
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  /**
   * Starts the timer.
   */
  startTimer(): void {
    if (this.currentState === PomodoroState.IDLE) {
      // Create a new session
      this.currentSessionId = generateId();
      const session: PomodoroSession = {
        id: this.currentSessionId,
        startTime: now(),
        endTime: 0,
        type: this.currentType,
        duration: this.totalSeconds,
        isCompleted: false,
        abandonedAt: 0,
      };
      this.repository.insert(session);

      if (this.currentType === PomodoroSessionType.WORK) {
        this.currentState = PomodoroState.WORKING;
      } else if (this.currentType === PomodoroSessionType.SHORT_BREAK) {
        this.currentState = PomodoroState.SHORT_BREAK_RUNNING;
      } else {
        this.currentState = PomodoroState.LONG_BREAK_RUNNING;
      }
      this.timerService.start();

      // Show notification if work session
      if (this.currentType === PomodoroSessionType.WORK) {
        this.notificationService.showTimerNotification(this.currentType, this.remainingSeconds);
      }
    } else if (this.currentState === PomodoroState.PAUSED) {
      // Resume from pause
      this.timerService.resume();
      if (this.currentType === PomodoroSessionType.WORK) {
        this.currentState = PomodoroState.WORKING;
      } else if (this.currentType === PomodoroSessionType.SHORT_BREAK) {
        this.currentState = PomodoroState.SHORT_BREAK_RUNNING;
      } else {
        this.currentState = PomodoroState.LONG_BREAK_RUNNING;
      }
    }
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  /**
   * Pauses the timer.
   */
  pauseTimer(): void {
    this.timerService.pause();
    this.currentState = PomodoroState.PAUSED;
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  /**
   * Resets the timer.
   */
  resetTimer(): void {
    this.timerService.reset();
    this.remainingSeconds = this.totalSeconds;
    this.progress = 0;
    this.currentState = PomodoroState.IDLE;
    this.notificationService.cancelTimerNotification();

    // Mark current session as abandoned if exists
    if (this.currentSessionId !== '') {
      this.markSessionAbandoned(this.currentSessionId);
    }
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  /**
   * Skips to the next session.
   */
  skipToNext(): void {
    this.notificationService.cancelTimerNotification();
    if (this.currentType === PomodoroSessionType.WORK) {
      this.completedWorkCount++;
      if (this.completedWorkCount % this.config.longBreakInterval === 0) {
        this.setSessionType(PomodoroSessionType.LONG_BREAK);
      } else {
        this.setSessionType(PomodoroSessionType.SHORT_BREAK);
      }
    } else {
      this.setSessionType(PomodoroSessionType.WORK);
    }
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }
  private async onSessionComplete(): Promise<void> {
    this.notificationService.cancelTimerNotification();

    if (this.currentType === PomodoroSessionType.WORK) {
      this.completedWorkCount++;
      await this.loadTodaySessions();
      this.notificationService.showSessionCompleteNotification(
        PomodoroSessionType.WORK,
        this.todayCompletedCount
      );

      // Transition to break
      if (this.completedWorkCount % this.config.longBreakInterval === 0) {
        this.setSessionType(PomodoroSessionType.LONG_BREAK);
      } else {
        this.setSessionType(PomodoroSessionType.SHORT_BREAK);
      }
    } else {
      // Break complete
      this.notificationService.showSessionCompleteNotification(
        this.currentType,
        this.todayCompletedCount
      );
      this.setSessionType(PomodoroSessionType.WORK);
    }

    // Mark session as completed
    if (this.currentSessionId !== '') {
      this.markSessionCompleted(this.currentSessionId);
    }

    this.currentState = PomodoroState.IDLE;
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  private async markSessionCompleted(sessionId: string): Promise<void> {
    const session: PomodoroSession | null = await this.repository.getById(sessionId);
    if (session !== null) {
      session.endTime = now();
      session.isCompleted = true;
      await this.repository.update(session);
    }
  }

  private async markSessionAbandoned(sessionId: string): Promise<void> {
    const session: PomodoroSession | null = await this.repository.getById(sessionId);
    if (session !== null) {
      session.abandonedAt = now();
      await this.repository.update(session);
    }
  }

  /**
   * Loads today's session records.
   */
  async loadTodaySessions(): Promise<void> {
    this.todaySessions = await this.repository.getTodaySessions();
    this.todayCompletedCount = 0;
    this.todayTotalMinutes = 0;
    for (const session of this.todaySessions) {
      if (session.isCompleted && session.type === PomodoroSessionType.WORK) {
        this.todayCompletedCount++;
        this.todayTotalMinutes += Math.floor(session.duration / 60);
      }
    }
  }

  /**
   * Formats the remaining time as MM:SS.
   */
  getFormattedRemaining(): string {
    return formatDuration(this.remainingSeconds);
  }

  /**
   * Gets the label for the current session type.
   */
  getSessionLabel(): string {
    switch (this.currentType) {
      case PomodoroSessionType.WORK:
        return '专注';
      case PomodoroSessionType.SHORT_BREAK:
        return '短休息';
      case PomodoroSessionType.LONG_BREAK:
        return '长休息';
    }
  }

  /**
   * Called when app goes to background.
   */
  async onBackground(): Promise<void> {
    if (this.timerService.active) {
      await this.backgroundTaskService.requestContinuousTask();
    }
  }

  /**
   * Called when app returns to foreground.
   */
  async onForeground(): Promise<void> {
    await this.backgroundTaskService.stopContinuousTask();
    await this.loadTodaySessions();
  }

  /**
   * Reloads config from persistent storage without altering timer state.
   * Useful when returning from Settings page where durations may have changed.
   */
  async reloadConfig(): Promise<void> {
    const saved: PomodoroConfig = await this.settingsRepository.loadPomodoroConfig();
    this.config = saved;
    // If timer is idle, resync duration for current session type
    if (this.currentState === PomodoroState.IDLE) {
      switch (this.currentType) {
        case PomodoroSessionType.WORK:
          this.totalSeconds = this.config.workDuration;
          break;
        case PomodoroSessionType.SHORT_BREAK:
          this.totalSeconds = this.config.shortBreakDuration;
          break;
        case PomodoroSessionType.LONG_BREAK:
          this.totalSeconds = this.config.longBreakDuration;
          break;
      }
      this.remainingSeconds = this.totalSeconds;
      this.progress = 0;
      if (this.tickHandler !== null) {
        this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
      }
    }
  }

  /**
   * Persists pomodoro config to Preferences without resetting the timer.
   * Used by Settings sliders for immediate save-on-change.
   */
  async persistConfig(config: PomodoroConfig): Promise<void> {
    this.config = config;
    await this.settingsRepository.savePomodoroConfig(config);
  }

  /**
   * Saves current pomodoro config.
  async saveConfig(config: PomodoroConfig): Promise<void> {
    this.config = config;
    await this.settingsRepository.savePomodoroConfig(config);
    // Reset to work with new duration
    this.setSessionType(PomodoroSessionType.WORK);
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  /**
   * Cleanup.
   */
  destroy(): void {
    this.timerService.destroy();
  }
}
