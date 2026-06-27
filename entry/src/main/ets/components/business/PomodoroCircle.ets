import { ThemeConfig } from '../../model/ThemeConfigModel';
import { PomodoroState } from '../../model/PomodoroSessionModel';

/**
 * Circular progress ring for the pomodoro timer.
 *
 * Three stacked layers:
 *   1. Background track — subtle full-circle ring
 *   2. Progress arc — single dash that grows clockwise (flat caps)
 *   3. Leading dot — a small filled circle at the tip, rotated to match progress
 *
 * The arc starts at 12-o'clock (via rotate -90°) and fills clockwise.
 * A separate dot element (not a stroke cap) ensures exactly ONE visible dot
 * regardless of progress value.
 */
@Component
export struct PomodoroCircle {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop progress: number = 0;
  @Prop remainingTime: string = '25:00';
  @Prop sessionLabel: string = '专注';
  @Prop isRunning: boolean = false;

  // Circle geometry — computed from fixed sizing (280×280, strokeWidth 12)
  private readonly circumference: number = 2 * Math.PI * 134;

  build() {
    Stack() {
      // ── Layer 1: Background track ──
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(
          this.themeConfig.isDarkMode
            ? 'rgba(255,255,255,0.1)'
            : 'rgba(0,0,0,0.08)'
        )
        .strokeWidth(12);

      // ── Layer 2: Progress arc (flat caps — no dots from stroke) ──
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(this.themeConfig.primaryColor)
        .strokeWidth(12)
        .strokeLineCap(LineCapStyle.Butt)
        .strokeDashArray([
          this.circumference * this.progress,
          this.circumference * (1 - this.progress),
        ])
        .rotate({ angle: -90 });

      // ── Layer 3: Leading dot — one small filled circle rotated to the arc tip ──
      // A 280×280 Column with justifyContent(Start) places the dot at the top
      // (12-o'clock).  Rotating the entire Column by progress×360° spins the dot
      // clockwise around the centre, tracking the leading edge of the arc.
      Column() {
        Circle()
          .width(12)
          .height(12)
          .fill(this.themeConfig.primaryColor);
      }
      .width(280)
      .height(280)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .rotate({ angle: this.progress * 360 })
      .visibility(
        this.progress <= 0
          ? Visibility.Hidden
          : Visibility.Visible
      );

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
