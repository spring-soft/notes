import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { lightenColor } from '../../utils/ColorUtils';

/**
 * Full-screen adaptive background with depth.
 *
 * Two modes:
 *   Custom image:   User photo fills the screen (respects backgroundImageOpacity).
 *                   Gradient + orbs are hidden so the image is fully visible.
 *   Default:        Theme gradient + soft light orbs for depth.
 *                   Glass components above blur this rich background.
 *
 * Tablet / split-screen: uses `objectFit(ImageFit.Cover)` which handles
 * aspect-ratio changes gracefully.
 */
@ComponentV2
export struct ThemeBackground {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('isTablet') isTablet: boolean = false;

  build() {
    Stack() {
      // ═══ Mode 1: Custom background image ═══
      if (this.themeConfig.backgroundImageUri !== '') {
        Image(this.themeConfig.backgroundImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .brightness(this.themeConfig.isDarkMode ? 0.35 : 0.9)
          .saturate(this.themeConfig.isDarkMode ? 0.5 : 1.0)
          .opacity(this.themeConfig.backgroundImageOpacity);

        // Subtle dark/light scrim over the image for text readability
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(
            this.themeConfig.isDarkMode
              ? 'rgba(0,0,0,0.25)'
              : 'rgba(255,255,255,0.15)'
          );
      } else {
        // ═══ Mode 2: Default theme gradient + orbs ═══
        // Layer 2a: Theme gradient
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              [this.themeConfig.backgroundColor, 0.0],
              [lightenColor(this.themeConfig.primaryColor, 0.6), 0.35],
              [this.themeConfig.backgroundColor, 0.7],
              [this.themeConfig.primaryColor + '18', 1.0],
            ],
          });

        // Layer 2b: Top-left ambient orb
        Circle()
          .width(this.isTablet ? 320 : 280)
          .height(this.isTablet ? 320 : 280)
          .fill(this.themeConfig.primaryColor + '15')
          .blur(60)
          .position({ x: -60, y: -40 });

        // Layer 2c: Bottom-right ambient orb
        Circle()
          .width(this.isTablet ? 240 : 200)
          .height(this.isTablet ? 240 : 200)
          .fill(this.themeConfig.accentColor + '12')
          .blur(50)
          .position({ x: '60%', y: '70%' });

        // Layer 2d: Center accent orb
        Circle()
          .width(160)
          .height(160)
          .fill(this.themeConfig.primaryColor + '0A')
          .blur(40)
          .position({ x: '30%', y: '40%' });
      }
    }
    .width('100%')
    .height('100%');
  }
}
