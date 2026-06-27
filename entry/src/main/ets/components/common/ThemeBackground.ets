import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';

/**
 * Full-screen adaptive background with depth.
 *
 * Three layers from bottom to top:
 *   1. Custom image (optional) — user's chosen photo
 *   2. Colored gradient overlay — theme-tinted
 *   3. Soft light orbs — floating ambient light blobs for depth
 *
 * The glass components above this will blur this rich background.
 */
@ComponentV2
export struct ThemeBackground {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;

  build() {
    Stack() {
      // ── Layer 1: Custom image (if set) ──
      if (this.themeConfig.backgroundImageUri !== '') {
        Image(this.themeConfig.backgroundImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .brightness(this.themeConfig.isDarkMode ? 0.35 : 0.85)
          .saturate(this.themeConfig.isDarkMode ? 0.5 : 1.0);
      }

      // ── Layer 2: Theme gradient ──
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [this.themeConfig.backgroundColor, 0.0],
            [this.lighten(this.themeConfig.primaryColor, 0.6), 0.35],
            [this.themeConfig.backgroundColor, 0.7],
            [this.themeConfig.primaryColor + '18', 1.0],
          ],
        });

      // ── Layer 3a: Top-left ambient orb (large, soft) ──
      Circle()
        .width(280)
        .height(280)
        .fill(this.themeConfig.primaryColor + '15')
        .blur(60)
        .position({ x: -60, y: -40 });

      // ── Layer 3b: Bottom-right ambient orb (smaller, warmer) ──
      Circle()
        .width(200)
        .height(200)
        .fill(this.themeConfig.accentColor + '12')
        .blur(50)
        .position({ x: '60%', y: '70%' });

      // ── Layer 3c: Center accent orb (for glass to catch) ──
      if (this.themeConfig.backgroundImageUri === '') {
        Circle()
          .width(160)
          .height(160)
          .fill(this.themeConfig.primaryColor + '0A')
          .blur(40)
          .position({ x: '30%', y: '40%' });
      }
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 });
  }

  private lighten(hex: string, ratio: number): string {
    const r: number = parseInt(hex.substring(1, 3), 16);
    const g: number = parseInt(hex.substring(3, 5), 16);
    const b: number = parseInt(hex.substring(5, 7), 16);
    const nr: number = Math.min(255, Math.floor(r + (255 - r) * ratio));
    const ng: number = Math.min(255, Math.floor(g + (255 - g) * ratio));
    const nb: number = Math.min(255, Math.floor(b + (255 - b) * ratio));
    return `#${nr.toString(16).padStart(2, '0')}${ng.toString(16).padStart(2, '0')}${nb.toString(16).padStart(2, '0')}`;
  }
}
