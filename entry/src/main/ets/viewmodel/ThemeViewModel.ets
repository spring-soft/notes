import { ThemeConfig, ThemePreset } from '../model/ThemeConfigModel';
import { ColorHex } from '../model/AppConstantsModel';
import { SettingsRepository } from '../repository/SettingsRepository';
import { getDarkThemeConfig, getThemeConfigByPreset } from '../constants/ThemeConstants';
import { updateSystemBarStyle } from '../service/WindowService';
import { common } from '@kit.AbilityKit';

/**
 * Manages the application theme state.
 * Designed to be @Observed and @Provided from the root Index component.
 */
@Observed
export class ThemeViewModel {
  themeConfig: ThemeConfig;
  currentPreset: ThemePreset = ThemePreset.OCEAN_BLUE;
  private settingsRepository: SettingsRepository;
  private appContext: common.Context | null = null;
  private themeChangeListener: ((config: ThemeConfig) => void) | null = null;

  constructor(settingsRepository: SettingsRepository, context?: common.Context) {
    this.settingsRepository = settingsRepository;
    this.themeConfig = getThemeConfigByPreset(ThemePreset.OCEAN_BLUE);
    if (context !== undefined) {
      this.appContext = context;
    }
  }

  setContext(context: common.Context): void {
    this.appContext = context;
  }

  /**
   * Registers a callback fired whenever themeConfig changes.
   * Index uses this to sync its @Provide('themeConfig') with themeVM.
   */
  setThemeChangeListener(listener: (config: ThemeConfig) => void): void {
    this.themeChangeListener = listener;
  }

  private notifyThemeChange(): void {
    if (this.themeChangeListener !== null) {
      this.themeChangeListener(this.themeConfig);
    }
  }

  /**
   * Loads saved theme from preferences. Call in aboutToAppear().
   */
  async loadTheme(): Promise<void> {
    const savedConfig: ThemeConfig = await this.settingsRepository.loadThemeConfig();
    const savedPreset: ThemePreset = await this.settingsRepository.loadThemePreset();
    this.currentPreset = savedPreset;
    this.themeConfig = savedConfig;
    this.notifySystemBar();
  }

  /**
   * Applies a theme preset.
   */
  applyPreset(preset: ThemePreset): void {
    let config: ThemeConfig = getThemeConfigByPreset(preset);
    if (this.themeConfig.isDarkMode) {
      config = getDarkThemeConfig(config);
    }
    // Preserve custom background image
    const newConfig: ThemeConfig = {
      primaryColor: config.primaryColor,
      backgroundColor: config.backgroundColor,
      surfaceColor: config.surfaceColor,
      textColor: config.textColor,
      textSecondaryColor: config.textSecondaryColor,
      glassOpacity: config.glassOpacity,
      glassBlurRadius: config.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      isDarkMode: config.isDarkMode,
      accentColor: config.accentColor,
      fontScale: config.fontScale,
      borderRadius: config.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = preset;
    this.saveTheme();
  }

  /**
   * Updates the primary/accent color.
   */
  updatePrimaryColor(color: ColorHex): void {
    const newConfig: ThemeConfig = {
      primaryColor: color,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: color,
      fontScale: this.themeConfig.fontScale,
      borderRadius: this.themeConfig.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Updates the glass opacity.
   */
  updateGlassOpacity(opacity: number): void {
    const newConfig: ThemeConfig = {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: opacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: this.themeConfig.fontScale,
      borderRadius: this.themeConfig.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Updates the glass blur radius.
   */
  updateBlurRadius(radius: number): void {
    const newConfig: ThemeConfig = {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: radius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: this.themeConfig.fontScale,
      borderRadius: this.themeConfig.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Updates the border radius.
   */
  updateBorderRadius(radius: number): void {
    const newConfig: ThemeConfig = {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: this.themeConfig.fontScale,
      borderRadius: radius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Updates the font scale.
   */
  updateFontScale(scale: number): void {
    const newConfig: ThemeConfig = {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: scale,
      borderRadius: this.themeConfig.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Sets a custom background image.
   */
  updateBackgroundImage(uri: string): void {
    const newConfig: ThemeConfig = {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: uri,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: this.themeConfig.fontScale,
      borderRadius: this.themeConfig.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Removes the custom background image.
   */
  removeBackgroundImage(): void {
    const newConfig: ThemeConfig = {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: '',
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: this.themeConfig.fontScale,
      borderRadius: this.themeConfig.borderRadius,
    };
    this.themeConfig = newConfig;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Toggles dark mode.
   */
  toggleDarkMode(): void {
    const newDarkMode: boolean = !this.themeConfig.isDarkMode;
    if (newDarkMode) {
      this.themeConfig = getDarkThemeConfig(this.themeConfig);
    } else {
      const lightConfig: ThemeConfig = getThemeConfigByPreset(this.currentPreset);
      const newConfig: ThemeConfig = {
        primaryColor: lightConfig.primaryColor,
        backgroundColor: lightConfig.backgroundColor,
        surfaceColor: lightConfig.surfaceColor,
        textColor: lightConfig.textColor,
        textSecondaryColor: lightConfig.textSecondaryColor,
        glassOpacity: lightConfig.glassOpacity,
        glassBlurRadius: lightConfig.glassBlurRadius,
        backgroundImageUri: this.themeConfig.backgroundImageUri,
        isDarkMode: lightConfig.isDarkMode,
        accentColor: lightConfig.accentColor,
        fontScale: lightConfig.fontScale,
        borderRadius: lightConfig.borderRadius,
      };
      this.themeConfig = newConfig;
    }
    this.notifySystemBar();
    this.saveTheme();
  }

  private notifySystemBar(): void {
    if (this.appContext !== null) {
      updateSystemBarStyle(this.themeConfig.isDarkMode, this.appContext);
    }
  }

  /**
   * Saves the current theme to Preferences.
   */
  private saveTheme(): void {
    this.settingsRepository.saveThemeConfig(this.themeConfig);
    this.settingsRepository.saveThemePreset(this.currentPreset);
    this.notifySystemBar();
    this.notifyThemeChange();
  }
}
