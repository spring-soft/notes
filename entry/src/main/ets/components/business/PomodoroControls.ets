import { ThemeConfig } from '../../model/ThemeConfigModel';
import { PomodoroState } from '../../model/PomodoroSessionModel';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Control buttons for the pomodoro timer: start/pause, reset, skip.
 * The play/pause button animates smoothly between states.
 */
@Component
export struct PomodoroControls {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop currentState: PomodoroState = PomodoroState.IDLE;
  @Prop isRunning: boolean = false;
  @Prop stateSignal: number = 0;
  @State private animScale: number = 1.0;
  onStartPause: () => void = () => {
  };
  onReset: () => void = () => {
  };
  onSkip: () => void = () => {
  };

  build() {
    Row() {
      // Reset button
      Button() {
        Text(ICON.RESET)
          .fontSize(22)
          .fontColor(this.themeConfig.textColor);
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor(
        this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.1)'
          : 'rgba(0, 0, 0, 0.06)'
      )
      .onClick(() => {
        this.onReset();
      });

      Blank().width(24);

      // Start / Pause button (larger, primary) with animated icon transition
      // Using @Prop isRunning + @Prop stateSignal (both from parent @State)
      // ensures ArkUI always re-evaluates on every state tick.
      Button() {
        Text(this.isRunning ? ICON.PAUSE_BARS : ICON.PLAY)
          .fontSize(28)
          .fontColor('#FFFFFF')
          .scale({ x: this.animScale, y: this.animScale })
          .animation({ duration: 200, curve: Curve.EaseInOut });
      }
      .width(72)
      .height(72)
      .borderRadius(36)
      .backgroundColor(this.themeConfig.primaryColor)
      .shadow({
        radius: 16,
        color: this.themeConfig.primaryColor + '40',
        offsetY: 4,
      })
      .animation({ duration: 300, curve: Curve.EaseInOut })
      .onClick(() => {
        // Trigger a brief scale-down animation on each press
        this.animScale = 0.85;
        this.onStartPause();
        // Reset scale after a short delay
        setTimeout(() => {
          this.animScale = 1.0;
        }, 150);
      });

      Blank().width(24);

      // Skip button
      Button() {
        Text(ICON.SKIP)
          .fontSize(22)
          .fontColor(this.themeConfig.textColor);
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor(
        this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.1)'
          : 'rgba(0, 0, 0, 0.06)'
      )
      .onClick(() => {
        this.onSkip();
      });
    }
    .justifyContent(FlexAlign.Center);
  }

}
