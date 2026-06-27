import { ColorHex } from './AppConstantsModel';

export interface ThemeConfig {
  primaryColor: ColorHex;
  backgroundColor: ColorHex;
  surfaceColor: ColorHex;
  textColor: ColorHex;
  textSecondaryColor: ColorHex;
  glassOpacity: number;
  glassBlurRadius: number;
  backgroundImageUri: string;
  isDarkMode: boolean;
  accentColor: ColorHex;
  fontScale: number;
  borderRadius: number;
  /** Material rendering quality: 0=ADAPTIVE, 1=EXQUISITE, 2=GENTLE, 3=SMOOTH */
  materialLevel: number;
  /** Master toggle for all immersive light effects */
  immersiveEnabled: boolean;
}

export const DEFAULT_THEME_CONFIG: ThemeConfig = {
  primaryColor: '#4A90D9',
  backgroundColor: '#F5F7FA',
  surfaceColor: '#FFFFFF',
  textColor: '#1A1A1A',
  textSecondaryColor: '#8E8E93',
  glassOpacity: 0.5,
  glassBlurRadius: 20,
  backgroundImageUri: '',
  isDarkMode: false,
  accentColor: '#4A90D9',
  fontScale: 1.0,
  borderRadius: 16,
  materialLevel: 0,
  immersiveEnabled: true,
};

export enum ThemePreset {
  OCEAN_BLUE = 0,
  SUNSET_ORANGE = 1,
  FOREST_GREEN = 2,
  LAVENDER_PURPLE = 3,
  CHERRY_PINK = 4,
  MIDNIGHT_TEAL = 5,
  WARM_AMBER = 6,
  SLATE_GRAY = 7,
  CUSTOM = 8,
}
