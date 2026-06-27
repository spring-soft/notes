/**
 * Immersive material depth-hierarchy constants.
 *
 * Uses backdropBlur + semi-transparent backgrounds to create a layered
 * frosted-material effect (the systemMaterial / ImmersiveMaterial API
 * is not available in SDK API 24, so we emulate it with existing APIs).
 *
 * The static `blurMultiplier` and `opacityMultiplier` fields are set by
 * ThemeViewModel whenever the user adjusts blur/opacity in Settings.
 * All getBlur() / getOverlayColor() calls automatically reflect the
 * current user preference without needing per-component changes.
 *
 * Depth hierarchy:
 *   Layer 5 (top):    Dialog, BottomSheet   → ULTRA_THICK  (blur 30, high opacity)
 *   Layer 4:          FAB buttons            → THICK        (blur 24)
 *   Layer 3:          Cards, containers      → REGULAR      (blur 16)
 *   Layer 2:          Search, chips, headers → THIN         (blur 8)
 *   Layer 1:          Page background        → ULTRA_THIN   (blur 4)
 *   Layer 0 (canvas): ThemeBackground        → none
 */
export class MaterialConstants {
  // ── Style level identifiers ──
  static readonly ULTRA_THICK: number = 5;
  static readonly THICK: number = 4;
  static readonly REGULAR: number = 3;
  static readonly THIN: number = 2;
  static readonly ULTRA_THIN: number = 1;

  // ── Depth-hierarchy style assignments ──
  static readonly DIALOG: number = MaterialConstants.ULTRA_THICK;
  static readonly SHEET: number = MaterialConstants.ULTRA_THICK;
  static readonly FAB: number = MaterialConstants.THICK;
  static readonly CARD: number = MaterialConstants.REGULAR;
  static readonly CONTAINER_LOW: number = MaterialConstants.REGULAR;
  static readonly CONTAINER_MID: number = MaterialConstants.THICK;
  static readonly CONTAINER_HIGH: number = MaterialConstants.ULTRA_THICK;
  static readonly SURFACE: number = MaterialConstants.THIN;
  static readonly HEADER: number = MaterialConstants.THIN;
  static readonly CHIP: number = MaterialConstants.THIN;
  static readonly PAGE_BG: number = MaterialConstants.ULTRA_THIN;

  // ── User-adjustable multipliers (set by ThemeViewModel) ──
  /** Multiplier for blur radius.  1.0 = neutral (glassBlurRadius = 20). */
  static blurMultiplier: number = 1.0;
  /** Multiplier for overlay alpha.  1.0 = neutral (glassOpacity = 0.5). */
  static opacityMultiplier: number = 1.0;

  /**
   * Applies the user's glassBlurRadius / glassOpacity preferences as
   * global multipliers so every component picks them up automatically.
   */
  static applyUserPreferences(glassBlurRadius: number, glassOpacity: number): void {
    MaterialConstants.blurMultiplier = glassBlurRadius / 20.0;
    MaterialConstants.opacityMultiplier = glassOpacity / 0.5;
  }

  /**
   * Returns the backdropBlur radius (vp) for a given material level,
   * scaled by the user's blur preference.
   */
  static getBlur(level: number): number {
    let base: number;
    if (level >= 5) {
      base = 30;
    } else if (level >= 4) {
      base = 24;
    } else if (level >= 3) {
      base = 16;
    } else if (level >= 2) {
      base = 8;
    } else {
      base = 4;
    }
    return Math.max(0, Math.round(base * MaterialConstants.blurMultiplier));
  }

  /**
   * Returns the overlay background color for a given material level and mode,
   * with alpha scaled by the user's opacity preference.
   *
   * Opacity is intentionally low so ThemeBackground gradients + orbs show
   * through, giving backdropBlur real content to blur — this is what creates
   * the "frosted glass" depth effect rather than a flat solid surface.
   *
   * Higher levels = more opaque → stronger privacy / focus (dialog, sheet).
   */
  static getOverlayColor(level: number, isDark: boolean): string {
    let baseAlpha: number;
    if (level >= 5) {
      baseAlpha = isDark ? 0.72 : 0.65;
    } else if (level >= 4) {
      baseAlpha = isDark ? 0.55 : 0.48;
    } else if (level >= 3) {
      baseAlpha = isDark ? 0.40 : 0.32;
    } else if (level >= 2) {
      baseAlpha = isDark ? 0.22 : 0.16;
    } else {
      baseAlpha = isDark ? 0.10 : 0.07;
    }
    const alpha: number = Math.min(1.0, Math.max(0.0,
      baseAlpha * MaterialConstants.opacityMultiplier));
    const a: string = alpha.toFixed(2);
    const rgb: string = isDark ? '20,20,20,' : '255,255,255,';
    return 'rgba(' + rgb + a + ')';
  }
}
