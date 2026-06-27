import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Solid card with accent color stripe and shadow.
 *
 * @param colorTag - Optional left-edge accent color stripe
 * @param padding - Inner padding
 * @param content - BuilderParam slot
 */
@Component
export struct GlassCard {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop colorTag: string = '';
  @Prop padding: number = 16;
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
  }

  build() {
    Row() {
      // Accent color stripe
      if (this.colorTag !== '') {
        Column()
          .width(4)
          .height('100%')
          .backgroundColor(this.colorTag)
          .borderRadius(2)
          .margin({ right: 12 });
      }

      Column() {
        this.content();
      }
      .layoutWeight(1);
    }
    .padding(this.padding)
    .borderRadius(this.themeConfig.borderRadius)
    .backgroundColor(this.themeConfig.surfaceColor)
    .borderWidth(1)
    .borderColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.06)'
        : 'rgba(0, 0, 0, 0.06)'
    )
    .shadow({
      radius: 8,
      color: this.themeConfig.isDarkMode
        ? 'rgba(0, 0, 0, 0.25)'
        : 'rgba(0, 0, 0, 0.06)',
      offsetY: 2,
    });
  }
}
