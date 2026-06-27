import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Today's pomodoro session statistics display.
 */
@Component
export struct PomodoroSessionStats {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop completedCount: number = 0;
  @Prop totalMinutes: number = 0;

  build() {
    Row() {
      // Completed count
      Column() {
        Text(this.completedCount.toString())
          .fontSize(28 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor);

        Text('已完成')
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 4 });
      }
      .layoutWeight(1);

      // Divider
      Column()
        .width(1)
        .height(40)
        .backgroundColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.1)'
            : 'rgba(0, 0, 0, 0.1)'
        );

      // Total minutes
      Column() {
        Text(this.totalMinutes.toString())
          .fontSize(28 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor);

        Text('专注分钟')
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 4 });
      }
      .layoutWeight(1);
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 24, right: 24 })
    .borderRadius(this.themeConfig.borderRadius)
    .backgroundColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.06)'
        : 'rgba(255, 255, 255, 0.4)'
    )
    .backdropBlur(this.themeConfig.glassBlurRadius)
    .borderWidth(1)
    .borderColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.08)'
        : 'rgba(255, 255, 255, 0.2)'
    );
  }
}
