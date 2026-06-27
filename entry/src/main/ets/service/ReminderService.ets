import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ID, Timestamp } from '../model/AppConstantsModel';
import { RepeatType } from '../model/ReminderModel';

const DOMAIN: number = 0x0002;
const TAG: string = 'ReminderService';

/**
 * Service for scheduling and managing todo item reminders.
 */
export class ReminderService {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Creates a reminder for a todo item.
   * @returns The system reminder ID, or 0 on failure.
   */
  async createTodoReminder(
    todoId: ID,
    title: string,
    reminderTime: Timestamp,
    repeatType: RepeatType
  ): Promise<number> {
    try {
      const reminderRequest: reminderAgentManager.ReminderRequest = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        actionButton: [
          {
            title: '查看',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
          },
          {
            title: '完成',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
          },
        ],
        wantAgent: {
          pkgName: '',
          abilityName: '',
        },
        maxScreenWantAgent: {
          pkgName: '',
          abilityName: '',
        },
        title: title,
        content: '点击查看待办详情',
        expiredContent: '提醒已过期',
        notificationId: this.generateNotificationId(todoId),
        snoozeContent: '稍后提醒',
        snoozeTimes: 15 * 60,
        ringDuration: 30,
      };

      const reminderId: number = await reminderAgentManager.publishReminder(reminderRequest);
      hilog.info(DOMAIN, TAG, 'Reminder created: id=%{public}d, title=%{public}s', reminderId, title);
      return reminderId;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to create reminder: %{public}s', e.message);
      return 0;
    }
  }

  /**
   * Cancels a reminder by its system ID.
   */
  async cancelReminder(reminderId: number): Promise<void> {
    if (reminderId === 0) {
      return;
    }
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      hilog.info(DOMAIN, TAG, 'Reminder cancelled: id=%{public}d', reminderId);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to cancel reminder: %{public}s', e.message);
    }
  }

  /**
   * Cancels all reminders registered by this app.
   */
  async cancelAllReminders(): Promise<void> {
    try {
      const reminders: reminderAgentManager.ReminderInfo[] =
        await reminderAgentManager.getAllValidReminders();
      for (const reminder of reminders) {
        await reminderAgentManager.cancelReminder(reminder.reminderId);
      }
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to cancel all reminders: %{public}s', e.message);
    }
  }

  private generateNotificationId(todoId: ID): number {
    let hash: number = 0;
    for (let i: number = 0; i < todoId.length; i++) {
      const char: number = todoId.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash) % 100000;
  }

  private convertRepeatType(repeatType: RepeatType): number[] {
    switch (repeatType) {
      case RepeatType.DAILY:
        return [1, 2, 3, 4, 5, 6, 7];
      case RepeatType.WEEKLY:
        return [new Date().getDay() || 7];
      case RepeatType.MONTHLY:
        return [new Date().getDate()];
      case RepeatType.NONE:
      default:
        return [];
    }
  }
}
