import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Circular progress ring for the pomodoro timer.
 *
 * Layers (bottom → top):
 *   1. Full-circle background track
 *   2. Path-drawn arc — a single SVG-style arc from 12-o'clock growing clockwise.
 *      strokeLineCap(Round) on the Path gives exactly ONE round cap at the arc's end.
 *   3. Leading dot — a filled Circle at the arc tip, rotated to exactly match.
 *
 * Unlike Circle + strokeDashArray (which creates visible artifacts at both the
 * start and end of the dash), a Path with explicit arc commands produces a clean
 * open stroke with a single cap.
 */
@Component
export struct PomodoroCircle {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop progress: number = 0;
  @Prop remainingTime: string = '25:00';
  @Prop sessionLabel: string = '专注';
  @Prop isRunning: boolean = false;

  // Fixed geometry: 280×280 container, 12 vp stroke width
  // Radius for stroke centerline = (280 − 12) / 2 = 134
  private readonly cx: number = 140;
  private readonly cy: number = 140;
  private readonly r: number = 134;

  /**
   * Builds an SVG arc path from 12-o'clock clockwise to the progress angle.
   *
   * The first two "M" commands (M 0 0 M 280 280) are empty moves that anchor
   * the Path viewport to exactly (0,0)–(280,280).  Without them ArkUI would
   * auto-size the viewport to the arc's own bounding-box, causing the drawing
   * to shift into the upper-left corner.
   */
  private arcCommands(): string {
    if (this.progress <= 0) {
      // Nothing to draw — return an empty path anchored to 280×280
      return 'M 0 0 M 280 280';
    }
    // Angles in radians: 0 = 3-o'clock, π/2 = 6-o'clock (y-down screen coords)
    // 12-o'clock = -π/2
    const startAngle: number = -Math.PI / 2;
    const endAngle: number = startAngle + this.progress * 2 * Math.PI;

    const x1: number = this.cx + this.r * Math.cos(startAngle);
    const y1: number = this.cy + this.r * Math.sin(startAngle);
    const x2: number = this.cx + this.r * Math.cos(endAngle);
    const y2: number = this.cy + this.r * Math.sin(endAngle);

    // large-arc-flag: 1 when arc sweeps more than 180°
    const largeArc: number = this.progress > 0.5 ? 1 : 0;

    return `M 0 0 M 280 280 M ${x1} ${y1} A ${this.r} ${this.r} 0 ${largeArc} 1 ${x2} ${y2}`;
  }

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
        .strokeWidth(12);

      // ══════ Layer 2: Progress arc (Path, single Round cap at end) ══════
      Path()
        .width('100%')
        .height('100%')
        .commands(this.arcCommands())
        .fill(Color.Transparent)
        .stroke(this.themeConfig.primaryColor)
        .strokeWidth(12)
        .strokeLineCap(LineCapStyle.Round);

      // ══════ Center content ══════
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
