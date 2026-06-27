import { ThemeConfig } from '../../model/ThemeConfigModel';
import { PomodoroState } from '../../model/PomodoroSessionModel';

/**
 * Circular progress ring for the pomodoro timer.
 * Uses a single continuous arc that fills clockwise from the 12-o'clock position,
 * with a rounded leading-edge cap for a smooth "filling" visual.
 *
 * The arc is implemented via strokeDashArray on a Circle — one dash segment whose
 * length equals (circumference × progress), with a gap that fills the remainder.
 * strokeDashOffset rotates the start point from the default 3-o'clock to 12-o'clock.
 */
@Component
export struct PomodoroCircle {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop progress: number = 0;
  @Prop remainingTime: string = '25:00';
  @Prop sessionLabel: string = '专注';
  @Prop isRunning: boolean = false;

  // Circle geometry — computed from fixed sizing (280×280, strokeWidth 12)
  private readonly circleRadius: number = 134;   // (280 - 12) / 2
  private readonly circumference: number = 2 * Math.PI * 134;

  build() {
    Stack() {
      // ── Background track ──
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(
          this.themeConfig.isDarkMode
            ? 'rgba(255,255,255,0.1)'
            : 'rgba(0,0,0,0.08)'
        )
        .strokeWidth(12)
        .strokeLineCap(LineCapStyle.Round);

      // ── Progress arc: single dash whose length grows with progress ──
      // Dash = progress × circumference, Gap = (1−progress) × circumference
      // so the total pattern always equals exactly one circumference — no wrapping.
      // Positive dashOffset shifts clockwise from the default 3-o'clock start.
      // We offset by −¼ circumference so the arc begins at 12-o'clock.
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(this.themeConfig.primaryColor)
        .strokeWidth(12)
        .strokeLineCap(LineCapStyle.Round)
        .strokeDashArray([
          this.circumference * this.progress,
          this.circumference * (1 - this.progress),
        ])
        .strokeDashOffset(-this.circumference / 4);

      // ── Center content ──
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
    .animation({ duration: 300, curve: Curve.Linear });
  }
}
