import { Seconds } from '../model/AppConstantsModel';
import { PomodoroConfig } from '../model/PomodoroSessionModel';

/**
 * Default pomodoro timer configuration values.
 */
export class PomodoroConstants {
  static readonly DEFAULT_WORK_DURATION: Seconds = 25 * 60;
  static readonly DEFAULT_SHORT_BREAK_DURATION: Seconds = 5 * 60;
  static readonly DEFAULT_LONG_BREAK_DURATION: Seconds = 15 * 60;
  static readonly DEFAULT_LONG_BREAK_INTERVAL: number = 4;

  static readonly MIN_WORK_DURATION: Seconds = 5 * 60;
  static readonly MAX_WORK_DURATION: Seconds = 60 * 60;
  static readonly MIN_BREAK_DURATION: Seconds = 1 * 60;
  static readonly MAX_BREAK_DURATION: Seconds = 30 * 60;

  static readonly TIMER_TICK_INTERVAL_MS: number = 1000;
}

/**
 * Returns the default pomodoro config.
 */
export function getDefaultPomodoroConfig(): PomodoroConfig {
  return {
    workDuration: PomodoroConstants.DEFAULT_WORK_DURATION,
    shortBreakDuration: PomodoroConstants.DEFAULT_SHORT_BREAK_DURATION,
    longBreakDuration: PomodoroConstants.DEFAULT_LONG_BREAK_DURATION,
    longBreakInterval: PomodoroConstants.DEFAULT_LONG_BREAK_INTERVAL,
  };
}
