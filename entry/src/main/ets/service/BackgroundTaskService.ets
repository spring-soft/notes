import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0002;
const TAG: string = 'BackgroundTaskService';

/**
 * Service for managing continuous background tasks so the pomodoro timer
 * keeps ticking when the app is minimised or the screen is off.
 *
 * Uses backgroundTaskManager.startBackgroundRunning with TASK_KEEPING mode,
 * the standard approach for short-term computational tasks like a timer.
 */
export class BackgroundTaskService {
  private isTaskRunning: boolean = false;
  private context: common.Context;
  private cachedWantAgent: WantAgent | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Requests a continuous background task to keep the process alive.
   * Does nothing if a task is already active.
   */
  async requestContinuousTask(): Promise<void> {
    if (this.isTaskRunning) {
      return;
    }

    try {
      if (this.cachedWantAgent === null) {
        this.cachedWantAgent = await this.createWantAgent();
      }

      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.TASK_KEEPING,
        this.cachedWantAgent
      );
      this.isTaskRunning = true;
      hilog.info(DOMAIN, TAG, 'Background task started');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to start background task: %{public}s', e.message);
    }
  }

  /**
   * Stops the continuous background task.
   * Does nothing if no task is active.
   */
  async stopContinuousTask(): Promise<void> {
    if (!this.isTaskRunning) {
      return;
    }

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      this.isTaskRunning = false;
      hilog.info(DOMAIN, TAG, 'Background task stopped');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to stop background task: %{public}s', e.message);
    }
  }

  /**
   * Returns whether a continuous task is currently active.
   */
  get isActive(): boolean {
    return this.isTaskRunning;
  }

  /**
   * Creates a WantAgent that brings the user back to the app when they tap
   * the ongoing notification.
   */
  private async createWantAgent(): Promise<WantAgent> {
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
}
