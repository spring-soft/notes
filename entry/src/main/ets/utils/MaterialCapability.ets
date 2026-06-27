import { hdsMaterial } from '@kit.UIDesignKit';

/**
 * Device material-capability detection.
 *
 * Uses the real hdsMaterial.getSystemMaterialTypes() API (available from
 * API 23 / HarmonyOS 6.1.0) to query whether the device supports immersive
 * material rendering, and returns the recommended quality level.
 *
 * The systemMaterial (ArkUI universal attribute) requires API 26, but
 * HDS component systemMaterialEffect is available from API 23 onward.
 */

/** Cached device-supported material types. */
let cachedMaterialTypes: Array<hdsMaterial.MaterialType> | null = null;

/**
 * Queries the system for supported material types.
 * Result is cached after the first call.
 */
function getSystemMaterialTypes(): Array<hdsMaterial.MaterialType> {
  if (cachedMaterialTypes === null) {
    try {
      cachedMaterialTypes = hdsMaterial.getSystemMaterialTypes();
    } catch (_e) {
      // Fall back to empty array on older devices where the API might throw
      cachedMaterialTypes = [];
    }
  }
  return cachedMaterialTypes;
}

/**
 * Returns true if the device supports immersive light effects.
 * Requires the IMMERSIVE material type in the system capability set.
 */
export function supportsImmersive(): boolean {
  const types: Array<hdsMaterial.MaterialType> = getSystemMaterialTypes();
  return types.includes(hdsMaterial.MaterialType.IMMERSIVE);
}

/** Cached recommended material level. */
let cachedRecommendedLevel: hdsMaterial.MaterialLevel | null = null;

/**
 * Returns the recommended material level for this device.
 * - EXQUISITE: full material fidelity (high-end devices)
 * - ADAPTIVE: system auto-balance (recommended for most devices)
 * - SMOOTH: minimal cost (low-end devices or IMMERSIVE unsupported)
 *
 * Result is cached after the first call.
 */
export function getRecommendedMaterialLevel(): hdsMaterial.MaterialLevel {
  if (cachedRecommendedLevel !== null) {
    return cachedRecommendedLevel;
  }

  const types: Array<hdsMaterial.MaterialType> = getSystemMaterialTypes();
  if (types.includes(hdsMaterial.MaterialType.IMMERSIVE)) {
    // Device supports immersive — prefer adaptive (system auto-balance)
    cachedRecommendedLevel = hdsMaterial.MaterialLevel.ADAPTIVE;
  } else {
    // No immersive support — fall back to smooth (lowest cost, safest)
    cachedRecommendedLevel = hdsMaterial.MaterialLevel.SMOOTH;
  }
  return cachedRecommendedLevel;
}
