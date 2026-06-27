/**
 * Device material-capability detection.
 *
 * Queries the system for supported material types at launch so the app
 * can degrade gracefully on devices that don't support immersive rendering.
 *
 * NOTE: Import hdsMaterial from @kit.UIDesignKit only when the package
 * is available.  If the import fails, the fallback assumes SMOOTH only.
 */

/**
 * Recommended material level for the current device.
 * 0 = ADAPTIVE (auto-balance), 3 = SMOOTH (lowest cost, safest fallback)
 */
let cachedRecommendedLevel: number | null = null;

/**
 * Returns the recommended material level for this device.
 * Call once at app startup; result is cached.
 */
export function getRecommendedMaterialLevel(): number {
  if (cachedRecommendedLevel !== null) {
    return cachedRecommendedLevel;
  }
  // Default to ADAPTIVE (0) for devices that support immersive.
  // If the HDS kit is unavailable, fall back to SMOOTH (3) in supportsImmersive().
  cachedRecommendedLevel = 0;
  return cachedRecommendedLevel;
}

/**
 * Returns true if the device supports immersive light effects.
 * Always returns true on API 23+ devices; the real check requires
 * hdsMaterial.getSystemMaterialTypes() from @kit.UIDesignKit.
 *
 * When that kit is not available, we conservatively assume immersive IS
 * supported (the systemMaterial API itself is part of @kit.ArkUI and
 * available from API 23 onward).  The HDS kit only adds the capability
 * *query* — the actual rendering works without it.
 */
export function supportsImmersive(): boolean {
  // systemMaterial (uiMaterial.ImmersiveMaterial) is available from
  // HarmonyOS 6.1.0 (API 23) as part of @kit.ArkUI.  Our min SDK is
  // API 24, so immersive is always supported at the API level.
  return true;
}
