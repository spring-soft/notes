import { PomodoroViewModel, getPomodoroViewModel } from '../viewmodel/PomodoroViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { PomodoroSessionType, PomodoroState, PomodoroConfig } from '../model/PomodoroSessionModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { PomodoroCircle } from '../components/business/PomodoroCircle';
import { PomodoroControls } from '../components/business/PomodoroControls';
import { PomodoroSessionStats } from '../components/business/PomodoroSessionStats';

/**
 * Pomodoro timer page with circular progress, controls, and session stats.
 *
 * The PomodoroViewModel is a module-level singleton (initialised by Index)
 * so the timer survives tab switches — Tabs destroys non-visible TabContent.
 */
@ComponentV2
export struct PomodoroPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Local displayRemaining: number = 0;
  @Local displayProgress: number = 0;
  @Local displayState: PomodoroState = PomodoroState.IDLE;
  @Local stateUpdateSignal: number = 0;
  @Local currentType: PomodoroSessionType = PomodoroSessionType.WORK;

  private viewModel: PomodoroViewModel = getPomodoroViewModel();

  aboutToAppear(): void {
    // Reload config from Preferences BEFORE syncing display state.
    // onShown() is unreliable across tab switches (Tabs destroys/recreates
    // non-visible TabContent), so we reload here where it's guaranteed to run.
    this.viewModel.setTickHandler((remaining: number, progress: number, state: PomodoroState) => {
      this.displayRemaining = remaining;
      this.displayProgress = progress;
      this.displayState = state;
      this.currentType = this.viewModel.currentType;
      this.stateUpdateSignal++;
    });
    this.reloadAndSync();
  }

  aboutToDisappear(): void {
    // Only unregister the tick callback — the singleton ViewModel and its
    // timer must stay alive so the countdown continues across tab switches.
    this.viewModel.setTickHandler(null);
  }

  /**
   * Reloads config from Preferences and syncs all @State display fields.
   * Called from aboutToAppear (guaranteed) and onShown (backup).
   */
  private async reloadAndSync(): Promise<void> {
    await this.viewModel.reloadConfig();
    this.displayRemaining = this.viewModel.remainingSeconds;
    this.displayProgress = this.viewModel.progress;
    this.displayState = this.viewModel.currentState;
    this.currentType = this.viewModel.currentType;
    this.stateUpdateSignal++;
  }

  build() {
    NavDestination() {
      Stack() {
        // ═══════════════════════════════════════════════════════════
        // Layer 0: Full-screen scrollable content
        // ═══════════════════════════════════════════════════════════
        Scroll() {
          Column() {
            // Spacer — clears the floating header + gradient mask
            Blank().height(140);

            // Session type selector
            Row() {
              this.sessionTypeChip(PomodoroSessionType.WORK, '专注', 0);
              this.sessionTypeChip(PomodoroSessionType.SHORT_BREAK, '短休息', 0);
              this.sessionTypeChip(PomodoroSessionType.LONG_BREAK, '长休息', 0);
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
            .padding({ top: 20, bottom: 32 })
            .animation({ duration: 300, curve: Curve.EaseInOut });

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
          .width('100%');
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);

        // ═══════════════════════════════════════════════════════════
        // Layer 1: Floating header — frosted glass, pinned at top
        //
        // backdropBlur is binary in ArkUI (on/off), so we mask the
        // blur VISIBILITY with a gradient overlay: the blur is always
        // active across the entire header Column, but the gradient
        // fades from opaque (blur clearly visible) to transparent
        // (blur invisible, content looks clear).  This creates the
        // illusion of a gradual blur-to-clear transition.
        // ═══════════════════════════════════════════════════════════
        Column() {
          // Title area
          Row() {
            Text('专注')
              .fontSize(28 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 0, bottom: 4 });

          // Gradient mask — bridges frosted header to clear content.
          // backdropBlur is binary; the gradient overlay makes blur
          // visibility fade gradually by masking with decreasing opacity.
          Column()
            .width('100%')
            .height(72)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                [MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode), 0.0],
                [this.themeConfig.isDarkMode ? 'rgba(20,20,20,0.00)' : 'rgba(255,255,255,0.00)', 1.0],
              ],
            });
        }
        .position({ top: 0, left: 0, right: 0 })
        .padding({ top: 44 })
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode));
      }
      .width('100%')
      .height('100%');
    }
    .onShown(() => {
      this.reloadAndSync();
    })
    .hideTitleBar(true)
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  @Builder
  sessionTypeChip(type: PomodoroSessionType, label: string, durationSeconds: number) {
    Column() {
      Text(label)
        .fontSize(14 * this.themeConfig.fontScale)
        .fontWeight(this.currentType === type ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(
          this.currentType === type
            ? this.themeConfig.primaryColor
            : this.themeConfig.textSecondaryColor
        );
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .borderRadius(this.themeConfig.borderRadius)
    .backgroundColor(
      this.currentType === type
        ? (this.themeConfig.isDarkMode
          ? this.themeConfig.primaryColor + '25'
          : this.themeConfig.primaryColor + '15')
        : Color.Transparent
    )
    .borderWidth(this.currentType === type ? 1.5 : 1)
    .borderColor(
      this.currentType === type
        ? this.themeConfig.primaryColor
        : this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.12)'
          : 'rgba(0, 0, 0, 0.08)'
    )
    .animation({ duration: 250, curve: Curve.EaseInOut })
    .onClick(() => {
      if (this.displayState === PomodoroState.IDLE) {
        this.viewModel.setSessionType(type);
        this.currentType = type;
        this.displayRemaining = this.viewModel.remainingSeconds;
        this.displayProgress = this.viewModel.progress;
        this.stateUpdateSignal++;
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
