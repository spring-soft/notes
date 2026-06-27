import { ID, Timestamp, ColorHex } from './AppConstantsModel';
import { RepeatType } from './ReminderModel';

export enum TodoPriority {
  LOW = 0,
  MEDIUM = 1,
  HIGH = 2,
}

export interface TodoItem {
  id: ID;
  title: string;
  description: string;
  isCompleted: boolean;
  priority: TodoPriority;
  categoryId: ID;
  reminderTime: Timestamp;
  reminderRepeatType: RepeatType;
  createdAt: Timestamp;
  dueDate: Timestamp;
  completedAt: Timestamp;
}

export interface TodoCategory {
  id: ID;
  name: string;
  colorHex: ColorHex;
  sortOrder: number;
}

export enum TodoFilterType {
  ALL = 0,
  ACTIVE = 1,
  COMPLETED = 2,
}

/** Default preset todo categories. */
export const PRESET_TODO_CATEGORIES: string[] = ['工作', '个人', '购物', '学习', '健康', '其他'];
