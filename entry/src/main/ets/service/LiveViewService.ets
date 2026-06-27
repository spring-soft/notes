import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0002;
const TAG: string = 'LiveViewService';

/** Fixed live-view ID for the pomodoro timer (only one at a time). */
const POMODORO_LIVE_VIEW_ID: number = 2001;

/**
 * Labels passed between ViewModel and LiveViewService.
 */
export interface LiveViewLabels {
  title: string;
  capsuleTitle: string;
}

/**
 * Live View (实况窗 / 灵动岛) service for the pomodoro timer.
 *
 * When the timer is running, the system renders a capsule in the status bar
 * (around the front-camera cutout — "灵动岛") and a card in the notification
 * centre / lock screen, showing the countdown.  Tapping either returns the
 * user to the app.
 *
 * The Live View is created on timer start, updated on pause / resume, and
 * stopped when the session ends.
 */
export class LiveViewService {
  private isActive: boolean = false;
  private currentConfig: liveViewManager.LiveView | null = null;

  /**
   * Starts a countdown Live View for a work or break session.
   */
  async startLiveView(
    labels: LiveViewLabels,
    remainingMs: number,
    primaryColor: string
  ): Promise<void> {
    if (this.isActive) {
      await this.stopLiveView();
    }

    try {
      const config: liveViewManager.LiveView = {
        id: POMODORO_LIVE_VIEW_ID,
        event: 'POMODORO_TIMER',
        timer: {
          time: remainingMs,
          isCountdown: true,
        },
        liveViewData: {
          primary: {
            title: labels.title,
            content: [
              { text: '${placeholder.timer}' } as liveViewManager.RichText,
            ],
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
            } as liveViewManager.ProgressLayout,
            aliveTime: 7200,
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 1,
            title: labels.capsuleTitle,
            content: this.formatTimerText(remainingMs),
            backgroundColor: this.colorToHex(primaryColor),
          },
        },
      };

      await liveViewManager.startLiveView(config);
      this.isActive = true;
      this.currentConfig = config;
      hilog.info(DOMAIN, TAG, 'Live View started: %{public}s, %{public}d ms',
        labels.title, remainingMs);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to start Live View: %{public}s', e.message);
    }
  }

  /**
   * Updates the Live View countdown (e.g. after pause → resume).
   */
  async updateLiveView(
    labels: LiveViewLabels,
    remainingMs: number,
    primaryColor: string
  ): Promise<void> {
    if (!this.isActive) {
      await this.startLiveView(labels, remainingMs, primaryColor);
      return;
    }

    try {
      const config: liveViewManager.LiveView = {
        id: POMODORO_LIVE_VIEW_ID,
        event: 'POMODORO_TIMER',
        timer: {
          time: remainingMs,
          isCountdown: true,
        },
        liveViewData: {
          primary: {
            title: labels.title,
            content: [
              { text: '${placeholder.timer}' } as liveViewManager.RichText,
            ],
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
            } as liveViewManager.ProgressLayout,
            aliveTime: 7200,
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 1,
            title: labels.capsuleTitle,
            content: this.formatTimerText(remainingMs),
            backgroundColor: this.colorToHex(primaryColor),
          },
        },
      };

      await liveViewManager.updateLiveView(config);
      this.currentConfig = config;
      hilog.info(DOMAIN, TAG, 'Live View updated: %{public}s, %{public}d ms',
        labels.title, remainingMs);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to update Live View: %{public}s', e.message);
    }
  }

  /**
   * Pauses the Live View — keeps it visible but marks it as paused.
   */
  async pauseLiveView(
    labels: LiveViewLabels,
    remainingMs: number,
    primaryColor: string
  ): Promise<void> {
    if (!this.isActive || this.currentConfig === null) {
      return;
    }

    try {
      const config: liveViewManager.LiveView = {
        id: POMODORO_LIVE_VIEW_ID,
        event: 'POMODORO_TIMER',
        liveViewData: {
          primary: {
            title: labels.title + ' · 已暂停',
            content: [
              { text: this.formatTimerText(remainingMs) } as liveViewManager.RichText,
            ],
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
            } as liveViewManager.ProgressLayout,
            aliveTime: 7200,
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 2,
            title: labels.capsuleTitle + ' ⏸',
            content: this.formatTimerText(remainingMs),
            backgroundColor: this.colorToHex(primaryColor),
          },
        },
      };

      await liveViewManager.updateLiveView(config);
      this.currentConfig = config;
      hilog.info(DOMAIN, TAG, 'Live View paused: %{public}s', labels.title);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to pause Live View: %{public}s', e.message);
    }
  }

  /**
   * Stops and removes the Live View.
   */
  async stopLiveView(): Promise<void> {
    if (!this.isActive || this.currentConfig === null) {
      return;
    }

    try {
      await liveViewManager.stopLiveView(this.currentConfig);
      this.isActive = false;
      this.currentConfig = null;
      hilog.info(DOMAIN, TAG, 'Live View stopped');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to stop Live View: %{public}s', e.message);
    }
  }

  /**
   * Formats milliseconds as MM:SS for capsule display.
   */
  private formatTimerText(ms: number): string {
    const totalSecs: number = Math.floor(Math.max(0, ms) / 1000);
    const mins: number = Math.floor(totalSecs / 60);
    const secs: number = totalSecs % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  /**
   * Removes the leading # from a hex colour so the capsule background is valid.
   */
  private colorToHex(hex: string): string {
    if (hex.startsWith('#')) {
      return hex.substring(1);
    }
    return hex;
  }
}
