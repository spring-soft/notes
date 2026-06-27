import { notificationManager } from '@kit.NotificationKit';
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Seconds } from '../model/AppConstantsModel';
import { PomodoroSessionType } from '../model/PomodoroSessionModel';
import { AppConstants } from '../constants/AppConstants';

const DOMAIN: number = 0x0002;
const TAG: string = 'NotificationService';

/**
 * Service for managing pomodoro timer notifications.
 *
 * The ongoing timer notification is updated every tick so the user can see
 * the countdown in the notification bar even when the app is in the background.
 * Tapping the notification returns the user to the app via a WantAgent.
 */
export class NotificationService {
  private context: common.Context;
  private timerNotificationActive: boolean = false;
  private returnWantAgent: WantAgent | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Shows the ongoing timer notification with a WantAgent to return to the app.
   */
  async showTimerNotification(
    sessionType: PomodoroSessionType,
    remainingSeconds: Seconds
  ): Promise<void> {
    try {
      if (this.returnWantAgent === null) {
        this.returnWantAgent = await this.createReturnWantAgent();
      }

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
        wantAgent: this.returnWantAgent ?? undefined,
      };

      await notificationManager.publish(request);
      this.timerNotificationActive = true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to publish timer notification: %{public}s', e.message);
    }
  }

  /**
   * Updates the ongoing timer notification with the latest remaining time.
   * Called on every timer tick to keep the notification bar countdown current.
   */
  async updateTimerNotification(
    sessionType: PomodoroSessionType,
    remainingSeconds: Seconds
  ): Promise<void> {
    if (!this.timerNotificationActive) {
      return;
    }

    try {
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
        wantAgent: this.returnWantAgent ?? undefined,
      };

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
      wantAgent: this.returnWantAgent ?? undefined,
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

  /**
   * Creates a WantAgent that opens the app when the notification is tapped.
   */
  private async createReturnWantAgent(): Promise<WantAgent> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.example.notes',
          abilityName: 'EntryAbility',
        },
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };

    return await wantAgent.getWantAgent(wantAgentInfo);
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
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }
}
