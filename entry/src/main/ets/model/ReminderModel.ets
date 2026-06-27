import { ID, Timestamp } from './AppConstantsModel';

export enum RepeatType {
  NONE = 0,
  DAILY = 1,
  WEEKLY = 2,
  MONTHLY = 3,
}

export interface ReminderConfig {
  todoId: ID;
  reminderTime: Timestamp;
  repeatType: RepeatType;
  reminderId: number;
}
