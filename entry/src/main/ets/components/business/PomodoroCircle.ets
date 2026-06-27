import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Circular progress ring for the pomodoro timer.
 *
 * Layers (bottom → top):
 *   1. Full-circle background track (Circle, transparent fill, subtle stroke)
 *   2. Progress arc (Circle, strokeDashArray, Butt cap — no visible endpoints)
 *   3. Single rotating dot (small filled Circle in a Column rotated around center)
 *   4. Center text (remaining time + session label)
 *
 * The dot traces the leading edge of the progress arc.  Both the dash-array
 * Circle and the dot Column are animated so the dot appears to smoothly
 * "push" the arc clockwise.
 */
@Component
export struct PomodoroCircle {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop progress: number = 0;
  @Prop remainingTime: string = '25:00';
  @Prop sessionLabel: string = '专注';
  @Prop isRunning: boolean = false;

  // Fixed geometry: 280×280 container, 12 vp stroke width
  // Circle radius at the stroke center-line = 140 vp
  private readonly containerSize: number = 280;
  private readonly strokeWidth: number = 12;
  private readonly circleRadius: number = 140;
  private readonly circumference: number = 2 * Math.PI * 140;

  build() {
    Stack() {
      // ══════ Layer 1: Background track ══════
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(
          this.themeConfig.isDarkMode
            ? 'rgba(255,255,255,0.1)'
            : 'rgba(0,0,0,0.08)'
        )
        .strokeWidth(this.strokeWidth);

      // ══════ Layer 2: Progress arc (dash-array, no caps) ══════
      // strokeDashArray: [drawn, gap] where drawn = progress × circumference.
      // Rotated -90° so the dash starts at 12-o'clock and grows clockwise.
      Circle()
        .width('100%')
        .height('100%')
        .fill(Color.Transparent)
        .stroke(this.themeConfig.primaryColor)
        .strokeWidth(this.strokeWidth)
        .strokeDashArray([this.progress * this.circumference, this.circumference])
        .strokeLineCap(LineCapStyle.Butt)
        .rotate({ angle: -90 });

      // ══════ Layer 3: Rotating dot at the leading edge of the arc ══════
      // The Column is 280×280; a 12×12 Circle sits at the top center.
      // translate(y: -6) shifts the dot up so its center lands at y=0
      // (distance 140 vp from the Column's rotation center → on the stroke
      // center-line).  The Column rotates by progress×360°, keeping the dot
      // exactly at the growing tip of the progress arc.
      Column() {
        Circle()
          .width(this.strokeWidth)
          .height(this.strokeWidth)
          .fill(this.themeConfig.primaryColor)
          .translate({ y: -(this.strokeWidth / 2) });
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .rotate({ angle: this.progress * 360 })
      .visibility(this.progress > 0 ? Visibility.Visible : Visibility.Hidden);

      // ══════ Layer 4: Center content ══════
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
    .width(this.containerSize)
    .height(this.containerSize)
    .animation({ duration: 1000, curve: Curve.Linear });
  }
}
