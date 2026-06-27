import { ThemeConfig, ThemePreset } from '../model/ThemeConfigModel';

// Re-export ThemePreset for convenience
export { ThemePreset } from '../model/ThemeConfigModel';

/**
 * Predefined color palettes for theme presets.
 */
class ThemePresetMap {
  OCEAN_BLUE: ThemeConfig = {
    primaryColor: '#4A90D9',
    backgroundColor: '#E8F0FE',
    surfaceColor: '#FFFFFF',
    textColor: '#1A2530',
    textSecondaryColor: '#5F6B7A',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#4A90D9',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  SUNSET_ORANGE: ThemeConfig = {
    primaryColor: '#E8774A',
    backgroundColor: '#FFF0E8',
    surfaceColor: '#FFFFFF',
    textColor: '#2D1A10',
    textSecondaryColor: '#7A6055',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#E8774A',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  FOREST_GREEN: ThemeConfig = {
    primaryColor: '#4CAF50',
    backgroundColor: '#E8F5E9',
    surfaceColor: '#FFFFFF',
    textColor: '#1A2D1A',
    textSecondaryColor: '#557A55',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#4CAF50',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  LAVENDER_PURPLE: ThemeConfig = {
    primaryColor: '#7C5CBF',
    backgroundColor: '#F3E8FF',
    surfaceColor: '#FFFFFF',
    textColor: '#1F1530',
    textSecondaryColor: '#6B5A85',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#7C5CBF',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  CHERRY_PINK: ThemeConfig = {
    primaryColor: '#E91E63',
    backgroundColor: '#FDE8EE',
    surfaceColor: '#FFFFFF',
    textColor: '#2D1A22',
    textSecondaryColor: '#7A5565',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#E91E63',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  MIDNIGHT_TEAL: ThemeConfig = {
    primaryColor: '#00897B',
    backgroundColor: '#E0F2F1',
    surfaceColor: '#FFFFFF',
    textColor: '#1A2D2A',
    textSecondaryColor: '#557A75',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#00897B',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  WARM_AMBER: ThemeConfig = {
    primaryColor: '#FFA000',
    backgroundColor: '#FFF8E1',
    surfaceColor: '#FFFFFF',
    textColor: '#2D2510',
    textSecondaryColor: '#7A6B45',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#FFA000',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  SLATE_GRAY: ThemeConfig = {
    primaryColor: '#607D8B',
    backgroundColor: '#ECEFF1',
    surfaceColor: '#FFFFFF',
    textColor: '#1A2226',
    textSecondaryColor: '#556066',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#607D8B',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
  CUSTOM: ThemeConfig = {
    primaryColor: '#4A90D9',
    backgroundColor: '#E8F0FE',
    surfaceColor: '#FFFFFF',
    textColor: '#1A2530',
    textSecondaryColor: '#5F6B7A',
    glassOpacity: 0.5,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#4A90D9',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
    backgroundImageOpacity: 1.0,
  };
}

const presetMap: ThemePresetMap = new ThemePresetMap();

export function getThemeConfigByPreset(preset: ThemePreset): ThemeConfig {
  switch (preset) {
    case ThemePreset.OCEAN_BLUE:
      return presetMap.OCEAN_BLUE;
    case ThemePreset.SUNSET_ORANGE:
      return presetMap.SUNSET_ORANGE;
    case ThemePreset.FOREST_GREEN:
      return presetMap.FOREST_GREEN;
    case ThemePreset.LAVENDER_PURPLE:
      return presetMap.LAVENDER_PURPLE;
    case ThemePreset.CHERRY_PINK:
      return presetMap.CHERRY_PINK;
    case ThemePreset.MIDNIGHT_TEAL:
      return presetMap.MIDNIGHT_TEAL;
    case ThemePreset.WARM_AMBER:
      return presetMap.WARM_AMBER;
    case ThemePreset.SLATE_GRAY:
      return presetMap.SLATE_GRAY;
    case ThemePreset.CUSTOM:
    default:
      return presetMap.CUSTOM;
  }
}

export function getDarkThemeConfig(lightConfig: ThemeConfig): ThemeConfig {
  const darkConfig: ThemeConfig = {
    primaryColor: lightConfig.primaryColor,
    backgroundColor: '#121212',
    surfaceColor: '#1E1E1E',
    textColor: '#E8E8E8',
    textSecondaryColor: '#A0A0A0',
    glassOpacity: lightConfig.glassOpacity + 0.1,
    glassBlurRadius: lightConfig.glassBlurRadius,
    backgroundImageUri: lightConfig.backgroundImageUri,
    isDarkMode: true,
    accentColor: lightConfig.accentColor,
    fontScale: lightConfig.fontScale,
    borderRadius: lightConfig.borderRadius,
    materialLevel: lightConfig.materialLevel,
    immersiveEnabled: lightConfig.immersiveEnabled,
    backgroundImageOpacity: lightConfig.backgroundImageOpacity,
  };
  return darkConfig;
}
