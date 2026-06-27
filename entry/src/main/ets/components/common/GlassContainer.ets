import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Solid surface container component.
 *
 * @param borderRadius - Corner radius (defaults to themeConfig.borderRadius)
 * @param padding - Inner padding (default 16)
 * @param elevation - Depth level: 1=low, 2=mid, 3=high
 * @param content - BuilderParam slot for child content
 */
@Component
export struct GlassContainer {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop borderRadius: number = -1;
  @Prop padding: number = 16;
  @Prop elevation: number = 1;
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
  }

  build() {
    Column() {
      this.content();
    }
    .padding(this.padding)
    .borderRadius(this.effectiveRadius)
    .backgroundColor(this.themeConfig.surfaceColor)
    .border({
      width: 1,
      color: this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.08)'
        : 'rgba(0, 0, 0, 0.06)',
      style: BorderStyle.Solid,
    })
    .shadow({
      radius: 8 + this.elevation * 6,
      color: this.themeConfig.isDarkMode
        ? 'rgba(0, 0, 0, 0.30)'
        : 'rgba(0, 0, 0, 0.06)',
      offsetY: 2 + this.elevation * 2,
    });
  }

  private get effectiveRadius(): number {
    return this.borderRadius > 0 ? this.borderRadius : this.themeConfig.borderRadius;
  }
}
