/**
 * Immersive material depth-hierarchy constants.
 *
 * Uses backdropBlur + semi-transparent backgrounds to create a layered
 * frosted-material effect (the systemMaterial / ImmersiveMaterial API
 * is not available in SDK API 24, so we emulate it with existing APIs).
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

  /**
   * Returns the backdropBlur radius (vp) for a given material level.
   */
  static getBlur(level: number): number {
    if (level >= 5) {
      return 30;
    }
    if (level >= 4) {
      return 24;
    }
    if (level >= 3) {
      return 16;
    }
    if (level >= 2) {
      return 8;
    }
    return 4;
  }

  /**
   * Returns the overlay background color for a given material level and mode.
   *
   * Opacity is intentionally low so ThemeBackground gradients + orbs show
   * through, giving backdropBlur real content to blur — this is what creates
   * the "frosted glass" depth effect rather than a flat solid surface.
   *
   * Higher levels = more opaque → stronger privacy / focus (dialog, sheet).
   */
  static getOverlayColor(level: number, isDark: boolean): string {
    if (level >= 5) {
      // Dialog / Sheet — needs readability, still shows depth
      return isDark ? 'rgba(20,20,20,0.72)' : 'rgba(255,255,255,0.65)';
    }
    if (level >= 4) {
      // FAB — prominent but translucent
      return isDark ? 'rgba(20,20,20,0.55)' : 'rgba(255,255,255,0.48)';
    }
    if (level >= 3) {
      // Cards — clearly see-through, moderate frost
      return isDark ? 'rgba(20,20,20,0.40)' : 'rgba(255,255,255,0.32)';
    }
    if (level >= 2) {
      // Headers / Search / Chips — light frost
      return isDark ? 'rgba(20,20,20,0.22)' : 'rgba(255,255,255,0.16)';
    }
    // Page background — barely-there tint, mostly transparent
    return isDark ? 'rgba(20,20,20,0.10)' : 'rgba(255,255,255,0.07)';
  }
}
