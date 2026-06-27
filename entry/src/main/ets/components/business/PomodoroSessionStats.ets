import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';

/**
 * Today's pomodoro session statistics display.
 */
@ComponentV2
export struct PomodoroSessionStats {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param completedCount: number = 0;
  @Param totalMinutes: number = 0;

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
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CARD))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CARD, this.themeConfig.isDarkMode));
  }
}
