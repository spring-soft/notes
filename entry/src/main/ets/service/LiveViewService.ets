import { liveViewManager } from '@kit.LiveViewKit';
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0002;
const TAG: string = 'LiveViewService';

/** Fixed live-view ID for the pomodoro timer. */
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
 * Uses the LAYOUT_TYPE_PROGRESS template with a timer field so the system
 * renders a capsule in the status bar and a countdown card in the
 * notification centre / lock screen.
 *
 * **Requirements on device:**
 * 1. AppGallery Connect → Live View Kit 权益已开通
 * 2. 系统设置 → 应用 → MemoFlow → 实况窗 已开启
 * 3. HarmonyOS 5.0+ 且在中国境内
 */
export class LiveViewService {
  private isActive: boolean = false;
  private currentConfig: liveViewManager.LiveView | null = null;
  private context: common.Context;
  private cachedWantAgent: WantAgent | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Checks whether Live View is enabled on the device.
   */
  async isEnabled(): Promise<boolean> {
    try {
      return await liveViewManager.isLiveViewEnabled();
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'isLiveViewEnabled failed: %{public}s', e.message);
      return false;
    }
  }

  /**
   * Starts a countdown Live View. Returns true on success.
   */
  async startLiveView(
    labels: LiveViewLabels,
    remainingMs: number,
    primaryColor: string
  ): Promise<boolean> {
    if (this.isActive) {
      await this.stopLiveView();
    }

    const enabled: boolean = await this.isEnabled();
    if (!enabled) {
      hilog.warn(DOMAIN, TAG, 'Live View is disabled — falling back to notification');
      return false;
    }

    try {
      const colorHex: string = this.colorToHex(primaryColor);
      const clickAction: WantAgent = await this.getOrCreateWantAgent();

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
            clickAction: clickAction,
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
              progress: this.msToProgress(remainingMs),
              color: '#' + colorHex,
              backgroundColor: '#' + colorHex + '33',
            } as liveViewManager.ProgressLayout,
            aliveTime: 7200,
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 1,
            title: labels.capsuleTitle,
            content: this.formatTimerText(remainingMs),
            backgroundColor: colorHex,
          },
        },
      };

      await liveViewManager.startLiveView(config);
      this.isActive = true;
      this.currentConfig = config;
      hilog.info(DOMAIN, TAG, 'Live View started: %{public}s', labels.title);
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'startLiveView failed: %{public}s', e.message);
      return false;
    }
  }

  /**
   * Updates the Live View countdown (resume from pause).
   */
  async updateLiveView(
    labels: LiveViewLabels,
    remainingMs: number,
    primaryColor: string
  ): Promise<boolean> {
    if (!this.isActive) {
      return await this.startLiveView(labels, remainingMs, primaryColor);
    }

    try {
      const colorHex: string = this.colorToHex(primaryColor);
      const clickAction: WantAgent = await this.getOrCreateWantAgent();

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
            clickAction: clickAction,
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
              progress: this.msToProgress(remainingMs),
              color: '#' + colorHex,
              backgroundColor: '#' + colorHex + '33',
            } as liveViewManager.ProgressLayout,
            aliveTime: 7200,
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 1,
            title: labels.capsuleTitle,
            content: this.formatTimerText(remainingMs),
            backgroundColor: colorHex,
          },
        },
      };

      await liveViewManager.updateLiveView(config);
      this.currentConfig = config;
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'updateLiveView failed: %{public}s', e.message);
      return false;
    }
  }

  /**
   * Pauses the Live View — keeps it visible without countdown animation.
   */
  async pauseLiveView(
    labels: LiveViewLabels,
    remainingMs: number,
    primaryColor: string
  ): Promise<boolean> {
    if (!this.isActive || this.currentConfig === null) {
      return false;
    }

    try {
      const colorHex: string = this.colorToHex(primaryColor);
      const clickAction: WantAgent = await this.getOrCreateWantAgent();

      const config: liveViewManager.LiveView = {
        id: POMODORO_LIVE_VIEW_ID,
        event: 'POMODORO_TIMER',
        liveViewData: {
          primary: {
            title: labels.title + ' · 已暂停',
            content: [
              { text: this.formatTimerText(remainingMs) } as liveViewManager.RichText,
            ],
            clickAction: clickAction,
            layoutData: {
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
              progress: this.msToProgress(remainingMs),
              color: '#' + colorHex,
              backgroundColor: '#' + colorHex + '33',
            } as liveViewManager.ProgressLayout,
            aliveTime: 7200,
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 2,
            title: labels.capsuleTitle + ' ⏸',
            content: this.formatTimerText(remainingMs),
            backgroundColor: colorHex,
          },
        },
      };

      await liveViewManager.updateLiveView(config);
      this.currentConfig = config;
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'pauseLiveView failed: %{public}s', e.message);
      return false;
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
      hilog.error(DOMAIN, TAG, 'stopLiveView failed: %{public}s', e.message);
    }
  }

  /**
   * Creates (and caches) a WantAgent for returning to the app on tap.
   */
  private async getOrCreateWantAgent(): Promise<WantAgent> {
    if (this.cachedWantAgent !== null) {
      return this.cachedWantAgent;
    }

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

    this.cachedWantAgent = await wantAgent.getWantAgent(wantAgentInfo);
    return this.cachedWantAgent;
  }

  /**
   * Converts remaining milliseconds to a progress percentage (inverted —
   * 100% = just started, 0% = time's up).
   */
  private msToProgress(remainingMs: number): number {
    // We use an approximate total based on the config (capped at 100).
    // The actual proportion doesn't need to be exact — the timer field
    // drives the countdown display; progress just colours the bar.
    return Math.min(100, Math.max(0, Math.floor(remainingMs / 36000)));
  }

  private formatTimerText(ms: number): string {
    const totalSecs: number = Math.floor(Math.max(0, ms) / 1000);
    const mins: number = Math.floor(totalSecs / 60);
    const secs: number = totalSecs % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  private colorToHex(hex: string): string {
    if (hex.startsWith('#')) {
      return hex.substring(1);
    }
    return hex;
  }
}
