import { ThemeConfig } from '../../model/ThemeConfigModel';
import { createGlassColor } from '../../utils/ColorUtils';

/**
 * Liquid-glass card with accent color stripe, specular highlight, and depth shadow.
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
    Stack() {
      // ── Main card surface ──
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
      .backgroundColor(
        createGlassColor(
          this.themeConfig.surfaceColor,
          this.themeConfig.glassOpacity,
          this.themeConfig.isDarkMode
        )
      )
      .backdropBlur(this.themeConfig.glassBlurRadius)
      .borderWidth(1)
      .borderColor(
        this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.08)'
          : 'rgba(255, 255, 255, 0.22)'
      );

      // ── Top-left specular highlight ──
      Row()
        .width('100%')
        .height('100%')
        .borderRadius(this.themeConfig.borderRadius)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.04)'
              : 'rgba(255, 255, 255, 0.18)', 0.0],
            ['rgba(255, 255, 255, 0.0)', 0.4],
          ],
        })
        .hitTestBehavior(HitTestMode.None);

      // ── Bottom shadow overlay ──
      Row()
        .width('100%')
        .height('100%')
        .borderRadius(this.themeConfig.borderRadius)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(0, 0, 0, 0.0)', 0.6],
            [this.themeConfig.isDarkMode
              ? 'rgba(0, 0, 0, 0.15)'
              : 'rgba(0, 0, 0, 0.03)', 1.0],
          ],
        })
        .hitTestBehavior(HitTestMode.None);
    }
    .borderRadius(this.themeConfig.borderRadius)
    .shadow({
      radius: 10,
      color: this.themeConfig.isDarkMode
        ? 'rgba(0, 0, 0, 0.35)'
        : 'rgba(0, 0, 0, 0.05)',
      offsetY: 2,
    });
  }
}
