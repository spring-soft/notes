import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ThemeConfig } from '../model/ThemeConfigModel';
import { PomodoroConfig } from '../model/PomodoroSessionModel';
import { AppConstants } from '../constants/AppConstants';
import { getDefaultPomodoroConfig } from '../constants/PomodoroConstants';
import { getThemeConfigByPreset, ThemePreset } from '../constants/ThemeConstants';

const KEY_THEME_CONFIG: string = 'theme_config';
const KEY_THEME_PRESET: string = 'theme_preset';
const KEY_POMODORO_CONFIG: string = 'pomodoro_config';

export class SettingsRepository {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  private async getPreferences(): Promise<preferences.Preferences> {
    return preferences.getPreferences(this.context, AppConstants.PREFERENCES_NAME);
  }

  // ── Theme ──

  async saveThemeConfig(config: ThemeConfig): Promise<void> {
    const pref: preferences.Preferences = await this.getPreferences();
    const json: string = JSON.stringify(config);
    await pref.put(KEY_THEME_CONFIG, json);
    await pref.flush();
  }

  async loadThemeConfig(): Promise<ThemeConfig> {
    const pref: preferences.Preferences = await this.getPreferences();
    const json: string = await pref.get(KEY_THEME_CONFIG, '') as string;
    if (json !== '') {
      const config: ThemeConfig = JSON.parse(json) as ThemeConfig;
      // Backward-compatible defaults for fields added in v2.0
      if (config.materialLevel === undefined) {
        config.materialLevel = 0;
      }
      if (config.immersiveEnabled === undefined) {
        config.immersiveEnabled = true;
      }
      if (config.backgroundImageOpacity === undefined) {
        config.backgroundImageOpacity = 1.0;
      }
      return config;
    }
    return getThemeConfigByPreset(ThemePreset.OCEAN_BLUE);
  }

  async saveThemePreset(preset: ThemePreset): Promise<void> {
    const pref: preferences.Preferences = await this.getPreferences();
    await pref.put(KEY_THEME_PRESET, preset);
    await pref.flush();
  }

  async loadThemePreset(): Promise<ThemePreset> {
    const pref: preferences.Preferences = await this.getPreferences();
    const value: number = await pref.get(KEY_THEME_PRESET, ThemePreset.OCEAN_BLUE) as number;
    return value as ThemePreset;
  }

  // ── Pomodoro ──

  async savePomodoroConfig(config: PomodoroConfig): Promise<void> {
    const pref: preferences.Preferences = await this.getPreferences();
    const json: string = JSON.stringify(config);
    await pref.put(KEY_POMODORO_CONFIG, json);
    await pref.flush();
  }

  async loadPomodoroConfig(): Promise<PomodoroConfig> {
    const pref: preferences.Preferences = await this.getPreferences();
    const json: string = await pref.get(KEY_POMODORO_CONFIG, '') as string;
    if (json !== '') {
      return JSON.parse(json) as PomodoroConfig;
    }
    return getDefaultPomodoroConfig();
  }

  async clearAll(): Promise<void> {
    const pref: preferences.Preferences = await this.getPreferences();
    await pref.delete(KEY_THEME_CONFIG);
    await pref.delete(KEY_THEME_PRESET);
    await pref.delete(KEY_POMODORO_CONFIG);
    await pref.flush();
  }
}
