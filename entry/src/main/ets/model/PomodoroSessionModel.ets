import { ID, Timestamp, Seconds } from './AppConstantsModel';

export enum PomodoroSessionType {
  WORK = 0,
  SHORT_BREAK = 1,
  LONG_BREAK = 2,
}

export interface PomodoroSession {
  id: ID;
  startTime: Timestamp;
  endTime: Timestamp;
  type: PomodoroSessionType;
  duration: Seconds;
  isCompleted: boolean;
  abandonedAt: Timestamp;
}

export enum PomodoroState {
  IDLE = 0,
  WORKING = 1,
  SHORT_BREAK_RUNNING = 2,
  LONG_BREAK_RUNNING = 3,
  PAUSED = 4,
}

export interface PomodoroConfig {
  workDuration: Seconds;
  shortBreakDuration: Seconds;
  longBreakDuration: Seconds;
  longBreakInterval: number;
}
