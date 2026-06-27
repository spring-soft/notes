/**
 * Named color constants used throughout the app.
 */
export class ColorConstants {
  // Preset accent colors for color picker
  static readonly PRESET_COLORS: string[] = [
    '#4A90D9',
    '#E8774A',
    '#4CAF50',
    '#7C5CBF',
    '#E91E63',
    '#00897B',
    '#FFA000',
    '#607D8B',
  ];

  // Glass effect
  static readonly GLASS_BORDER_LIGHT: string = 'rgba(255, 255, 255, 0.25)';
  static readonly GLASS_BORDER_DARK: string = 'rgba(255, 255, 255, 0.08)';
  static readonly GLASS_SHADOW_LIGHT: string = 'rgba(0, 0, 0, 0.08)';
  static readonly GLASS_SHADOW_DARK: string = 'rgba(0, 0, 0, 0.3)';

  // Base
  static readonly WHITE: string = '#FFFFFF';
  static readonly BLACK: string = '#000000';
  static readonly TRANSPARENT: string = '#00FFFFFF';

  // Status
  static readonly SUCCESS: string = '#4CAF50';
  static readonly WARNING: string = '#FFA000';
  static readonly ERROR: string = '#F44336';
}
