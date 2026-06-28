import { PomodoroSession, PomodoroSessionType, PomodoroState, PomodoroConfig } from '../model/PomodoroSessionModel';
import { Seconds } from '../model/AppConstantsModel';
import { PomodoroRepository } from '../repository/PomodoroRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { PomodoroTimerService } from '../service/PomodoroTimerService';
import { generateId } from '../utils/IdGenerator';
import { now, startOfToday, endOfToday } from '../utils/DateUtils';
import { formatDuration } from '../utils/DateUtils';//能支持沉浸观感的
import { getDefaultPomodoroConfig } from '../constants/PomodoroConstants';

/**
 * ViewModel for the Pomodoro timer feature.
 * Manages timer state machine and session history.
 */
@ObservedV2
export class PomodoroViewModel {
  @Trace currentState: PomodoroState = PomodoroState.IDLE;
  @Trace currentType: PomodoroSessionType = PomodoroSessionType.WORK;
  @Trace remainingSeconds: Seconds = 0;
  @Trace totalSeconds: Seconds = 0;
  @Trace progress: number = 0;
  @Trace todaySessions: PomodoroSession[] = [];
  @Trace todayCompletedCount: number = 0;
  @Trace todayTotalMinutes: number = 0;
  @Trace config: PomodoroConfig;

  private currentSessionId: string = '';
  private completedWorkCount: number = 0;
  private tickHandler: ((remaining: Seconds, progress: number, state: PomodoroState) => void) | null = null;
  private timerService: PomodoroTimerService;
  private repository: PomodoroRepository;
  private settingsRepository: SettingsRepository;

  constructor(
    repository: PomodoroRepository,
    settingsRepository: SettingsRepository
  ) {
    this.repository = repository;
    this.settingsRepository = settingsRepository;
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
   */
  setTickHandler(handler: ((remaining: Seconds, progress: number, state: PomodoroState) => void) | null): void {
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
   * Starts the timer from IDLE or resumes from PAUSED.
   */
  startTimer(): void {
    if (this.currentState === PomodoroState.IDLE) {
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
    } else if (this.currentState === PomodoroState.PAUSED) {
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
    // Cycle through all three session types: WORK → SHORT_BREAK → LONG_BREAK → WORK
    if (this.currentType === PomodoroSessionType.WORK) {
      this.completedWorkCount++;
      this.setSessionType(PomodoroSessionType.SHORT_BREAK);
    } else if (this.currentType === PomodoroSessionType.SHORT_BREAK) {
      this.setSessionType(PomodoroSessionType.LONG_BREAK);
    } else {
      this.setSessionType(PomodoroSessionType.WORK);
    }
    if (this.tickHandler !== null) {
      this.tickHandler(this.remainingSeconds, this.progress, this.currentState);
    }
  }

  private async onSessionComplete(): Promise<void> {
    if (this.currentType === PomodoroSessionType.WORK) {
      this.completedWorkCount++;
      await this.loadTodaySessions();

      if (this.completedWorkCount % this.config.longBreakInterval === 0) {
        this.setSessionType(PomodoroSessionType.LONG_BREAK);
      } else {
        this.setSessionType(PomodoroSessionType.SHORT_BREAK);
      }
    } else {
      this.setSessionType(PomodoroSessionType.WORK);
    }

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
   * Reloads config from persistent storage without altering timer state.
   */
  async reloadConfig(): Promise<void> {
    const saved: PomodoroConfig = await this.settingsRepository.loadPomodoroConfig();
    this.config = saved;
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
   */
  async persistConfig(config: PomodoroConfig): Promise<void> {
    this.config = config;
    await this.settingsRepository.savePomodoroConfig(config);
  }

  /**
   * Cleanup.
   */
  destroy(): void {
    this.timerService.destroy();
  }
}

// ── Module-level singleton ──────────────────────────────────────────────
// PomodoroPage is destroyed/recreated on tab switch because HarmonyOS Tabs
// tears down non-visible TabContent.  Storing the ViewModel at module level
// keeps the timer alive when the user switches to Notes or Todos.
let _instance: PomodoroViewModel | null = null;

export function initPomodoroViewModel(
  repository: PomodoroRepository,
  settingsRepository: SettingsRepository
): PomodoroViewModel {
  if (_instance === null) {
    _instance = new PomodoroViewModel(repository, settingsRepository);
  }
  return _instance;
}

export function getPomodoroViewModel(): PomodoroViewModel {
  if (_instance === null) {
    throw new Error('PomodoroViewModel not initialized — call initPomodoroViewModel first');
  }
  return _instance;
}
