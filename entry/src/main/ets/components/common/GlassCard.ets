import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';

/**
 * Immersive card with accent color stripe and system material depth.
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
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CARD))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CARD, this.themeConfig.isDarkMode));
  }
}
