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
