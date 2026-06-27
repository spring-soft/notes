import { ThemeConfig } from '../../model/ThemeConfigModel';
import { PomodoroState } from '../../model/PomodoroSessionModel';

/**
 * Circular progress ring for the pomodoro timer.
 * Renders an animated SVG arc showing elapsed/total progress.
 */
@Component
export struct PomodoroCircle {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop progress: number = 0;
  @Prop remainingTime: string = '25:00';
  @Prop sessionLabel: string = '专注';
  @Prop isRunning: boolean = false;

  build() {
    Stack() {
      // Background track circle (using ArkUI Circle)
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)')
        .strokeWidth(12)
        .strokeDashOffset(0);

      // Progress arc (using a simple visual approach with two half-circles)
      // For simplicity, render as a ring-like shape
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(this.themeConfig.primaryColor)
        .strokeWidth(12)
        .strokeDashArray([this.progress * 100, 100 - this.progress * 100])
        .strokeDashOffset(0)
        .strokeLineCap(LineCapStyle.Round);

      // Center content
      Column() {
        Text(this.remainingTime)
          .fontSize(48 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor)
          .fontFamily('HarmonyOS-Sans');

        Text(this.sessionLabel)
          .fontSize(16 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 8 })
          .opacity(0.8);
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);
    }
    .width(280)
    .height(280)
    .animation({ duration: 1000, curve: Curve.Linear });
  }
}
