import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Loading indicator with optional message.
 *
 * @param message - Optional loading text
 */
@Component
export struct LoadingSpinner {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop message: string = '加载中...';

  build() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.themeConfig.primaryColor);

      if (this.message !== '') {
        Text(this.message)
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 12 });
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: 60, bottom: 60 });
  }
}
