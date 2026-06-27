import { notificationManager } from '@kit.NotificationKit';
import { common, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Seconds } from '../model/AppConstantsModel';
import { PomodoroSessionType } from '../model/PomodoroSessionModel';
import { AppConstants } from '../constants/AppConstants';

const DOMAIN: number = 0x0002;
const TAG: string = 'NotificationService';

/**
 * Notification types supported by the app.
 */
enum NotificationType {
  TIMER = 0,
  SESSION_COMPLETE = 1,
}

/**
 * Service for managing pomodoro timer notifications and completion alerts.
 */
export class NotificationService {
  private context: common.Context;
  private timerNotificationActive: boolean = false;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Shows or updates the ongoing timer notification.
   */
  async showTimerNotification(
    sessionType: PomodoroSessionType,
    remainingSeconds: Seconds
  ): Promise<void> {
    const label: string = this.getSessionLabel(sessionType);
    const timeStr: string = this.formatRemainingTime(remainingSeconds);

    const request: notificationManager.NotificationRequest = {
      id: AppConstants.NOTIFICATION_TIMER_ID,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: `MemoFlow · ${label}`,
          text: `剩余 ${timeStr}`,
        },
      },
      isOngoing: true,
      isUnremovable: false,
    };

    try {
      await notificationManager.publish(request);
      this.timerNotificationActive = true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to publish timer notification: %{public}s', e.message);
    }
  }

  /**
   * Updates the existing timer notification with new remaining time.
   */
  async updateTimerNotification(remainingSeconds: Seconds): Promise<void> {
    if (!this.timerNotificationActive) {
      return;
    }

    const timeStr: string = this.formatRemainingTime(remainingSeconds);

    const request: notificationManager.NotificationRequest = {
      id: AppConstants.NOTIFICATION_TIMER_ID,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: 'MemoFlow · 专注中',
          text: `剩余 ${timeStr}`,
        },
      },
      isOngoing: true,
      isUnremovable: false,
    };

    try {
      await notificationManager.publish(request);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to update timer notification: %{public}s', e.message);
    }
  }

  /**
   * Cancels the ongoing timer notification.
   */
  async cancelTimerNotification(): Promise<void> {
    try {
      await notificationManager.cancel(AppConstants.NOTIFICATION_TIMER_ID);
      this.timerNotificationActive = false;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to cancel timer notification: %{public}s', e.message);
    }
  }

  /**
   * Shows a session-complete notification.
   */
  async showSessionCompleteNotification(
    sessionType: PomodoroSessionType,
    completedCount: number
  ): Promise<void> {
    const isWork: boolean = sessionType === PomodoroSessionType.WORK;
    const title: string = isWork ? '专注完成！' : '休息结束！';
    const text: string = isWork
      ? `已完成 ${completedCount} 个番茄钟，该休息一下了。`
      : '休息时间结束，准备开始新的专注吧！';

    const request: notificationManager.NotificationRequest = {
      id: AppConstants.NOTIFICATION_SESSION_COMPLETE_ID,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: text,
        },
      },
      isOngoing: false,
      isUnremovable: false,
    };

    try {
      await notificationManager.publish(request);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to publish completion notification: %{public}s', e.message);
    }
  }

  /**
   * Cancels all app notifications.
   */
  async cancelAll(): Promise<void> {
    try {
      await notificationManager.cancelAll();
      this.timerNotificationActive = false;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to cancel all notifications: %{public}s', e.message);
    }
  }

  private getSessionLabel(sessionType: PomodoroSessionType): string {
    switch (sessionType) {
      case PomodoroSessionType.WORK:
        return '专注';
      case PomodoroSessionType.SHORT_BREAK:
        return '短休息';
      case PomodoroSessionType.LONG_BREAK:
        return '长休息';
      default:
        return '计时';
    }
  }

  private formatRemainingTime(seconds: Seconds): string {
    const mins: number = Math.floor(Math.max(0, seconds) / 60);
    const secs: number = Math.floor(Math.max(0, seconds) % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}
