import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Empty state placeholder with icon and message.
 * Displayed when a list has no items.
 *
 * @param icon - Unicode icon character (text-based)
 * @param title - Main empty message
 * @param subtitle - Subtitle hint
 */
@Component
export struct EmptyState {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop icon: string = '';
  @Prop title: string = '暂无内容';
  @Prop subtitle: string = '';

  build() {
    Column() {
      if (this.icon !== '') {
        Text(this.icon)
          .fontSize(72)
          .fontColor(this.themeConfig.textSecondaryColor)
          .opacity(0.4)
          .margin({ bottom: 16 });
      }

      Text(this.title)
        .fontSize(18 * this.themeConfig.fontScale)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeConfig.textSecondaryColor)
        .margin({ bottom: 8 });

      if (this.subtitle !== '') {
        Text(this.subtitle)
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .opacity(0.7);
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: 80, bottom: 80 });
  }
}
