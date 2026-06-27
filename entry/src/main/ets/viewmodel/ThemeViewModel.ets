import { ThemeConfig, ThemePreset } from '../model/ThemeConfigModel';
import { ColorHex } from '../model/AppConstantsModel';
import { SettingsRepository } from '../repository/SettingsRepository';
import { getDarkThemeConfig, getThemeConfigByPreset } from '../constants/ThemeConstants';
import { MaterialConstants } from '../constants/MaterialConstants';
import { updateSystemBarStyle } from '../service/WindowService';
import { common } from '@kit.AbilityKit';

/**
 * Manages the application theme state.
 * Designed to be @ObservedV2 and @Provided from the root Index component.
 */
@ObservedV2
export class ThemeViewModel {
  @Trace themeConfig: ThemeConfig;
  @Trace currentPreset: ThemePreset = ThemePreset.OCEAN_BLUE;
  private settingsRepository: SettingsRepository;
  private appContext: common.Context | null = null;
  private themeChangeListener: ((config: ThemeConfig) => void) | null = null;

  /** Compile-time placeholder — @Provider always overrides before any @Consumer reads it. */
  static readonly placeholder: ThemeViewModel = new ThemeViewModel(null! as SettingsRepository);

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
    MaterialConstants.applyUserPreferences(savedConfig.glassBlurRadius, savedConfig.glassOpacity, savedConfig.immersiveEnabled);
    this.notifySystemBar();
  }

  /**
   * Returns a full copy of the current theme config as a fresh object literal.
   * Centralizes the field list so adding a new ThemeConfig field only requires
   * updating this one method (not every mutation method).
   */
  private cloneConfig(): ThemeConfig {
    return {
      primaryColor: this.themeConfig.primaryColor,
      backgroundColor: this.themeConfig.backgroundColor,
      surfaceColor: this.themeConfig.surfaceColor,
      textColor: this.themeConfig.textColor,
      textSecondaryColor: this.themeConfig.textSecondaryColor,
      glassOpacity: this.themeConfig.glassOpacity,
      glassBlurRadius: this.themeConfig.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      backgroundImageOpacity: this.themeConfig.backgroundImageOpacity,
      isDarkMode: this.themeConfig.isDarkMode,
      accentColor: this.themeConfig.accentColor,
      fontScale: this.themeConfig.fontScale,
      borderRadius: this.themeConfig.borderRadius,
      materialLevel: this.themeConfig.materialLevel,
      immersiveEnabled: this.themeConfig.immersiveEnabled,
    };
  }

  /**
   * Commits a config mutation: assigns, marks CUSTOM preset, and persists.
   */
  private commitConfig(cfg: ThemeConfig): void {
    this.themeConfig = cfg;
    this.currentPreset = ThemePreset.CUSTOM;
    this.saveTheme();
  }

  /**
   * Applies a theme preset.
   */
  applyPreset(preset: ThemePreset): void {
    let config: ThemeConfig = getThemeConfigByPreset(preset);
    if (this.themeConfig.isDarkMode) {
      config = getDarkThemeConfig(config);
    }
    // Preserve custom background image on preset switch
    config = {
      primaryColor: config.primaryColor,
      backgroundColor: config.backgroundColor,
      surfaceColor: config.surfaceColor,
      textColor: config.textColor,
      textSecondaryColor: config.textSecondaryColor,
      glassOpacity: config.glassOpacity,
      glassBlurRadius: config.glassBlurRadius,
      backgroundImageUri: this.themeConfig.backgroundImageUri,
      backgroundImageOpacity: this.themeConfig.backgroundImageOpacity,
      isDarkMode: config.isDarkMode,
      accentColor: config.accentColor,
      fontScale: config.fontScale,
      borderRadius: config.borderRadius,
      materialLevel: config.materialLevel,
      immersiveEnabled: config.immersiveEnabled,
    };
    this.themeConfig = config;
    this.currentPreset = preset;
    this.saveTheme();
  }

  /**
   * Updates the primary/accent color.
   */
  updatePrimaryColor(color: ColorHex): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.primaryColor = color;
    cfg.accentColor = color;
    this.commitConfig(cfg);
  }

  /**
   * Updates the glass opacity.
   */
  updateGlassOpacity(opacity: number): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.glassOpacity = opacity;
    this.commitConfig(cfg);
  }

  /**
   * Updates the glass blur radius.
   */
  updateBlurRadius(radius: number): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.glassBlurRadius = radius;
    this.commitConfig(cfg);
  }

  /**
   * Updates the border radius.
   */
  updateBorderRadius(radius: number): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.borderRadius = radius;
    this.commitConfig(cfg);
  }

  /**
   * Updates the font scale.
   */
  updateFontScale(scale: number): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.fontScale = scale;
    this.commitConfig(cfg);
  }

  /**
   * Sets a custom background image.
   */
  updateBackgroundImage(uri: string): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.backgroundImageUri = uri;
    this.commitConfig(cfg);
  }

  /**
   * Removes the custom background image.
   */
  removeBackgroundImage(): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.backgroundImageUri = '';
    this.commitConfig(cfg);
  }

  /**
   * Updates the opacity of the user-uploaded background image.
   */
  updateBackgroundImageOpacity(opacity: number): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.backgroundImageOpacity = opacity;
    this.commitConfig(cfg);
  }

  /**
   * Updates the material rendering quality level.
   */
  updateMaterialLevel(level: number): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.materialLevel = level;
    this.commitConfig(cfg);
  }

  /**
   * Toggles immersive light effects on/off.
   */
  updateImmersiveEnabled(enabled: boolean): void {
    const cfg: ThemeConfig = this.cloneConfig();
    cfg.immersiveEnabled = enabled;
    this.commitConfig(cfg);
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
      const cfg: ThemeConfig = {
        primaryColor: lightConfig.primaryColor,
        backgroundColor: lightConfig.backgroundColor,
        surfaceColor: lightConfig.surfaceColor,
        textColor: lightConfig.textColor,
        textSecondaryColor: lightConfig.textSecondaryColor,
        glassOpacity: lightConfig.glassOpacity,
        glassBlurRadius: lightConfig.glassBlurRadius,
        backgroundImageUri: this.themeConfig.backgroundImageUri,
        backgroundImageOpacity: this.themeConfig.backgroundImageOpacity,
        isDarkMode: lightConfig.isDarkMode,
        accentColor: lightConfig.accentColor,
        fontScale: lightConfig.fontScale,
        borderRadius: lightConfig.borderRadius,
        materialLevel: this.themeConfig.materialLevel,
        immersiveEnabled: this.themeConfig.immersiveEnabled,
      };
      this.themeConfig = cfg;
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
   * Saves the current theme to Preferences and syncs MaterialConstants.
   * Called by every mutation path — centralizes applyUserPreferences so
   * no individual mutation method needs to remember it.
   */
  private saveTheme(): void {
    MaterialConstants.applyUserPreferences(
      this.themeConfig.glassBlurRadius,
      this.themeConfig.glassOpacity,
      this.themeConfig.immersiveEnabled
    );
    this.settingsRepository.saveThemeConfig(this.themeConfig);
    this.settingsRepository.saveThemePreset(this.currentPreset);
    this.notifySystemBar();
    this.notifyThemeChange();
  }
}
