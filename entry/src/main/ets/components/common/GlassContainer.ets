import { ThemeConfig } from '../../model/ThemeConfigModel';
import { createGlassColor } from '../../utils/ColorUtils';

/**
 * Core liquid-glass container component.
 *
 * Layered rendering for realistic glass:
 *   1. Backdrop blur — frosted glass base
 *   2. Semi-transparent fill — tinted surface
 *   3. Top-left highlight — light scattering (specular)
 *   4. Inner border glow — soft edge refraction
 *   5. Outer shadow — depth separation
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
    Stack() {
      // ── Layer 1: Main glass surface ──
      Column() {
        this.content();
      }
      .padding(this.padding)
      .borderRadius(this.effectiveRadius)
      .backgroundColor(
        createGlassColor(
          this.themeConfig.surfaceColor,
          this.themeConfig.glassOpacity,
          this.themeConfig.isDarkMode
        )
      )
      .backdropBlur(this.themeConfig.glassBlurRadius * this.elevation)
      .border({
        width: 1,
        color: this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.10)'
          : 'rgba(255, 255, 255, 0.30)',
        style: BorderStyle.Solid,
      })
      .shadow({
        radius: 8 + this.elevation * 6,
        color: this.themeConfig.isDarkMode
          ? 'rgba(0, 0, 0, 0.40)'
          : 'rgba(0, 0, 0, 0.06)',
        offsetY: 2 + this.elevation * 2,
      });

      // ── Layer 2: Top-left specular highlight (light scattering) ──
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(this.effectiveRadius)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.06)'
              : 'rgba(255, 255, 255, 0.25)', 0.0],
            ['rgba(255, 255, 255, 0.0)', 0.45],
            ['rgba(0, 0, 0, 0.0)', 0.55],
            [this.themeConfig.isDarkMode
              ? 'rgba(0, 0, 0, 0.12)'
              : 'rgba(0, 0, 0, 0.03)', 1.0],
          ],
        })
        .hitTestBehavior(HitTestMode.None);

      // ── Layer 3: Inner edge glow ring (refraction simulation) ──
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(this.effectiveRadius)
        .border({
          width: 1,
          color: this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.04)'
            : 'rgba(255, 255, 255, 0.15)',
          style: BorderStyle.Solid,
        })
        .padding(1)
        .hitTestBehavior(HitTestMode.None);
    }
    .borderRadius(this.effectiveRadius);
  }

  private get effectiveRadius(): number {
    return this.borderRadius > 0 ? this.borderRadius : this.themeConfig.borderRadius;
  }
}
