import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';

/**
 * Empty state placeholder with icon and message.
 * Displayed when a list has no items.
 *
 * @param icon - SymbolGlyph Resource (use ICON.EMPTY_*)
 * @param title - Main empty message
 * @param subtitle - Subtitle hint
 */
@ComponentV2
export struct EmptyState {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param icon: Resource = $r('sys.symbol.circle');
  @Param title: string = '暂无内容';
  @Param subtitle: string = '';

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(72)
        .fontColor([this.themeConfig.textSecondaryColor])
        .opacity(0.4)
        .margin({ bottom: 16 });

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
