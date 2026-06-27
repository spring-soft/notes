import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0002;
const TAG: string = 'BackgroundTaskService';

/**
 * Service for managing background continuous tasks.
 * Used to keep the pomodoro timer running when the app is in the background.
 *
 * TODO: Implement proper background task management using the correct
 * HarmonyOS NEXT API. The current implementation is a stub.
 * Use:
 *   import { wantAgent } from '@kit.AbilityKit';
 *   import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
 */
export class BackgroundTaskService {
  private isTaskRunning: boolean = false;
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Requests a continuous background task to keep the timer alive.
   * TODO: Implement with correct backgroundTaskManager API.
   */
  async requestContinuousTask(): Promise<void> {
    if (this.isTaskRunning) {
      return;
    }

    // TODO: Implement background task request
    // The proper approach requires:
    // 1. Creating a WantAgent with wantAgent.getWantAgent()
    // 2. Calling backgroundTaskManager.startContinuousTask()
    // For now, mark the task as running so the timer logic works.
    this.isTaskRunning = true;
    hilog.info(DOMAIN, TAG, 'Continuous background task stub: marked as running');
  }

  /**
   * Stops the continuous background task.
   * TODO: Implement with correct backgroundTaskManager API.
   */
  async stopContinuousTask(): Promise<void> {
    if (!this.isTaskRunning) {
      return;
    }

    // TODO: Implement proper stop via backgroundTaskManager.stopContinuousTask()
    this.isTaskRunning = false;
    hilog.info(DOMAIN, TAG, 'Continuous background task stub: marked as stopped');
  }

  /**
   * Returns whether a continuous task is currently active.
   */
  get isActive(): boolean {
    return this.isTaskRunning;
  }
}
