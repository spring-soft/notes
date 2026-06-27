import { PomodoroViewModel } from '../viewmodel/PomodoroViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { PomodoroSessionType, PomodoroState, PomodoroConfig } from '../model/PomodoroSessionModel';
import { ThemeConfig } from '../model/ThemeConfigModel';
import { PomodoroRepository } from '../repository/PomodoroRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { NotificationService } from '../service/NotificationService';
import { BackgroundTaskService } from '../service/BackgroundTaskService';
import { common } from '@kit.AbilityKit';
import { PomodoroCircle } from '../components/business/PomodoroCircle';
import { PomodoroControls } from '../components/business/PomodoroControls';
import { PomodoroSessionStats } from '../components/business/PomodoroSessionStats';

/**
 * Pomodoro timer page with circular progress, controls, and session stats.
 * Timer state (@State) is updated directly by the setInterval tick callback
 * to reliably trigger ArkUI re-renders.
 */
@Component
export struct PomodoroPage {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @State viewModel: PomodoroViewModel = this.createViewModel();
  @State displayRemaining: number = 0;
  @State displayProgress: number = 0;
  @State displayState: PomodoroState = PomodoroState.IDLE;
  @State stateUpdateSignal: number = 0;
  // Separate @State copies of config durations — updated on init / config change
  // so the session-type chips ALWAYS show the latest values without relying on
  // @Observed nested-property tracking through @State viewModel.
  @State chipWorkSecs: number = 25 * 60;
  @State chipShortSecs: number = 5 * 60;
  @State chipLongSecs: number = 15 * 60;

  aboutToAppear(): void {
    this.viewModel.setTickHandler((remaining: number, progress: number, state: PomodoroState) => {
      this.displayRemaining = remaining;
      this.displayProgress = progress;
      this.displayState = state;
      this.stateUpdateSignal++;
    });
    this.viewModel.initialize().then(() => {
      this.syncChipDurations();
      this.stateUpdateSignal++;
    });
  }

  aboutToDisappear(): void {
    this.viewModel.destroy();
  }

  /**
   * Reloads pomodoro config from persistent storage.
   * Called when the page becomes visible again (e.g. after switching back
   * from Settings tab where durations may have been changed).
   */
  private async refreshConfig(): Promise<void> {
    await this.viewModel.reloadConfig();
    // Sync @State with reloaded values so session-type chips re-render
    this.displayRemaining = this.viewModel.remainingSeconds;
    this.displayProgress = this.viewModel.progress;
    this.displayState = this.viewModel.currentState;
    this.syncChipDurations();
    this.stateUpdateSignal++;
  }

  /**
   * Copies ViewModel config durations into @State fields so the
   * session-type chips always display up-to-date numbers.
   */
  private syncChipDurations(): void {
    this.chipWorkSecs = this.viewModel.config.workDuration;
    this.chipShortSecs = this.viewModel.config.shortBreakDuration;
    this.chipLongSecs = this.viewModel.config.longBreakDuration;
  }

  private createViewModel(): PomodoroViewModel {
    const context: common.Context = this.getUIContext().getHostContext() as common.Context;
    const appContext: common.Context = context.getApplicationContext();
    return new PomodoroViewModel(
      new PomodoroRepository(DatabaseHelper.getInstance().getStore()),
      new SettingsRepository(appContext),
      new NotificationService(appContext),
      new BackgroundTaskService(appContext)
    );
  }

  build() {
    NavDestination() {
      Column() {

        // Header
        Row() {
          Text('专注')
            .fontSize(28 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeConfig.textColor);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 44, bottom: 12 });

        // Session type selector
        Row() {
          this.sessionTypeChip(PomodoroSessionType.WORK, '专注', this.chipWorkSecs);
          this.sessionTypeChip(PomodoroSessionType.SHORT_BREAK, '短休息', this.chipShortSecs);
          this.sessionTypeChip(PomodoroSessionType.LONG_BREAK, '长休息', this.chipLongSecs);
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
        .justifyContent(FlexAlign.SpaceEvenly);

        // Timer circle — uses @State displayProgress/displayRemaining for real-time updates
        Column() {
          PomodoroCircle({
            progress: this.displayProgress,
            remainingTime: this.formatRemaining(),
            sessionLabel: this.viewModel.getSessionLabel(),
            isRunning: this.isTimerRunning(),
          });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 32 });

        // Controls — uses @State displayState for button state
        PomodoroControls({
          currentState: this.displayState,
          isRunning: this.isTimerRunning(),
          stateSignal: this.stateUpdateSignal,
          onStartPause: () => {
            if (this.isTimerRunning()) {
              this.viewModel.pauseTimer();
            } else {
              this.viewModel.startTimer();
            }
          },
          onReset: () => {
            this.viewModel.resetTimer();
          },
          onSkip: () => {
            this.viewModel.skipToNext();
          },
        });

        // Today's stats
        Column() {
          PomodoroSessionStats({
            completedCount: this.viewModel.todayCompletedCount,
            totalMinutes: this.viewModel.todayTotalMinutes,
          });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 32 });
      }
      .width('100%')
      .height('100%');
    }
    .onShown(() => {
      this.refreshConfig();
    })
    .hideTitleBar(true)
    .backgroundColor(this.themeConfig.backgroundColor)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  @Builder
  sessionTypeChip(type: PomodoroSessionType, label: string, durationSeconds: number) {
    Column() {
      Text(label)
        .fontSize(14 * this.themeConfig.fontScale)
        .fontWeight(this.viewModel.currentType === type ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(
          this.viewModel.currentType === type
            ? this.themeConfig.primaryColor
            : this.themeConfig.textSecondaryColor
        );

      Text(`${Math.floor(durationSeconds / 60)} 分钟`)
        .fontSize(12 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textSecondaryColor)
        .opacity(0.7)
        .margin({ top: 2 });
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .borderRadius(this.themeConfig.borderRadius)
    .backgroundColor(
      this.viewModel.currentType === type
        ? (this.themeConfig.isDarkMode
          ? this.themeConfig.primaryColor + '25'
          : this.themeConfig.primaryColor + '15')
        : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
    )
    .borderWidth(this.viewModel.currentType === type ? 1.5 : 0)
    .borderColor(
      this.viewModel.currentType === type
        ? this.themeConfig.primaryColor
        : Color.Transparent
    )
    .onClick(() => {
      if (!this.isTimerRunning()) {
        this.viewModel.setSessionType(type);
      }
    });
  }

  private isTimerRunning(): boolean {
    return this.displayState === PomodoroState.WORKING ||
      this.displayState === PomodoroState.SHORT_BREAK_RUNNING ||
      this.displayState === PomodoroState.LONG_BREAK_RUNNING;
  }

  private formatRemaining(): string {
    const mins: number = Math.floor(this.displayRemaining / 60);
    const secs: number = this.displayRemaining % 60;
    const mm: string = mins < 10 ? '0' + String(mins) : String(mins);
    const ss: string = secs < 10 ? '0' + String(secs) : String(secs);
    return mm + ':' + ss;
  }
}
