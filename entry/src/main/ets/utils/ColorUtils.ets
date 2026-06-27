import { ColorHex } from '../model/AppConstantsModel';

/**
 * Converts a hex color string to RGBA format.
 * Supports #RGB, #RRGGBB, #AARRGGBB formats.
 */
export function hexToRgba(hex: ColorHex, alpha: number): string {
  let r: number = 0;
  let g: number = 0;
  let b: number = 0;

  const cleanHex: string = hex.replace('#', '');

  if (cleanHex.length === 3) {
    r = parseInt(cleanHex[0] + cleanHex[0], 16);
    g = parseInt(cleanHex[1] + cleanHex[1], 16);
    b = parseInt(cleanHex[2] + cleanHex[2], 16);
  } else if (cleanHex.length === 6) {
    r = parseInt(cleanHex.substring(0, 2), 16);
    g = parseInt(cleanHex.substring(2, 4), 16);
    b = parseInt(cleanHex.substring(4, 6), 16);
  } else if (cleanHex.length === 8) {
    r = parseInt(cleanHex.substring(2, 4), 16);
    g = parseInt(cleanHex.substring(4, 6), 16);
    b = parseInt(cleanHex.substring(6, 8), 16);
  }

  const a: number = Math.max(0, Math.min(1, alpha));
  return `rgba(${r}, ${g}, ${b}, ${a})`;
}

/**
 * Creates a glass-effect background color from a base color.
 * Light mode → low opacity, subtle overlay.
 * Dark mode → higher opacity, richer overlay.
 */
export function createGlassColor(
  baseColor: ColorHex,
  opacity: number,
  isDarkMode: boolean
): string {
  const r: number = parseInt(baseColor.substring(1, 3), 16);
  const g: number = parseInt(baseColor.substring(3, 5), 16);
  const b: number = parseInt(baseColor.substring(5, 7), 16);
  const alpha: number = isDarkMode ? opacity * 1.5 : opacity;
  const clampedAlpha: number = Math.max(0.02, Math.min(0.6, alpha));
  return `rgba(${r}, ${g}, ${b}, ${clampedAlpha})`;
}

/**
 * Lightens a hex color by a ratio (0-1).
 */
export function lightenColor(hex: ColorHex, ratio: number): ColorHex {
  const r: number = parseInt(hex.substring(1, 3), 16);
  const g: number = parseInt(hex.substring(3, 5), 16);
  const b: number = parseInt(hex.substring(5, 7), 16);

  const newR: number = Math.min(255, Math.floor(r + (255 - r) * ratio));
  const newG: number = Math.min(255, Math.floor(g + (255 - g) * ratio));
  const newB: number = Math.min(255, Math.floor(b + (255 - b) * ratio));

  return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`;
}

/**
 * Darkens a hex color by a ratio (0-1).
 */
export function darkenColor(hex: ColorHex, ratio: number): ColorHex {
  const r: number = parseInt(hex.substring(1, 3), 16);
  const g: number = parseInt(hex.substring(3, 5), 16);
  const b: number = parseInt(hex.substring(5, 7), 16);

  const newR: number = Math.max(0, Math.floor(r * (1 - ratio)));
  const newG: number = Math.max(0, Math.floor(g * (1 - ratio)));
  const newB: number = Math.max(0, Math.floor(b * (1 - ratio)));

  return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`;
}

/**
 * Checks if a hex color is considered "dark" (low luminance).
 */
export function isDarkColor(hex: ColorHex): boolean {
  const r: number = parseInt(hex.substring(1, 3), 16);
  const g: number = parseInt(hex.substring(3, 5), 16);
  const b: number = parseInt(hex.substring(5, 7), 16);

  const luminance: number = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance < 0.5;
}
