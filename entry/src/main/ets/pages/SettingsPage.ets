import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { ThemeConfig, ThemePreset, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { PomodoroConfig } from '../model/PomodoroSessionModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { SettingsRepository } from '../repository/SettingsRepository';
import { common } from '@kit.AbilityKit';
import { ColorPickerComponent } from '../components/business/ColorPicker';
import { ImagePickerButton } from '../components/business/ImagePickerButton';
import { getThemeConfigByPreset } from '../constants/ThemeConstants';
import { PomodoroConstants } from '../constants/PomodoroConstants';

/**
 * Slider type enum — determines display format and themeVM update behavior.
 */
enum SliderType {
  BORDER_RADIUS = 2,
  WORK_MINUTES = 3,
  SHORT_BREAK = 4,
  LONG_BREAK = 5,
  LONG_BREAK_INTERVAL = 6,
  BLUR_RADIUS = 7,
  GLASS_OPACITY = 8,
  IMAGE_OPACITY = 9,
}

/**
 * Settings page with theme customization, pomodoro config, and background image.
 */
@ComponentV2
export struct SettingsPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('themeVM') themeVM: ThemeViewModel = ThemeViewModel.placeholder;
  @Local selectedPreset: ThemePreset = ThemePreset.OCEAN_BLUE;
  @Local workMinutes: number = 25;
  @Local shortBreakMinutes: number = 5;
  @Local longBreakMinutes: number = 15;
  @Local longBreakInterval: number = 4;
  @Local borderRadiusValue: number = 16;
  @Local blurRadiusValue: number = 20;
  @Local glassOpacityValue: number = 50; // percentage, 0–100
  @Local imageOpacityValue: number = 100; // percentage, 0–100

  aboutToAppear(): void {
    this.selectedPreset = this.themeVM.currentPreset;
    this.borderRadiusValue = this.themeConfig.borderRadius;
    this.blurRadiusValue = this.themeConfig.glassBlurRadius;
    this.glassOpacityValue = Math.round(this.themeConfig.glassOpacity * 100);
    this.imageOpacityValue = Math.round(this.themeConfig.backgroundImageOpacity * 100);
    this.loadSavedPomodoroConfig();
  }

  /**
   * Save immediately on every slider change — no debounce.
   * Debouncing with setTimeout was unsafe because Tabs destroys this
   * component on tab switch, causing the timer callback to be dropped.
   */
  private schedulePomodoroSave(): void {
    const config: PomodoroConfig = {
      workDuration: this.workMinutes * 60,
      shortBreakDuration: this.shortBreakMinutes * 60,
      longBreakDuration: this.longBreakMinutes * 60,
      longBreakInterval: this.longBreakInterval,
    };
    this.savePomodoroConfigToPreferences(config);
  }

  private createSettingsRepo(): SettingsRepository {
    const context: common.Context = this.getUIContext().getHostContext() as common.Context;
    const appContext: common.Context = context.getApplicationContext();
    return new SettingsRepository(appContext);
  }

  private async savePomodoroConfigToPreferences(config: PomodoroConfig): Promise<void> {
    const repo: SettingsRepository = this.createSettingsRepo();
    await repo.savePomodoroConfig(config);
  }

  private async loadSavedPomodoroConfig(): Promise<void> {
    const repo: SettingsRepository = this.createSettingsRepo();
    const saved: PomodoroConfig = await repo.loadPomodoroConfig();
    this.workMinutes = Math.floor(saved.workDuration / 60);
    this.shortBreakMinutes = Math.floor(saved.shortBreakDuration / 60);
    this.longBreakMinutes = Math.floor(saved.longBreakDuration / 60);
    this.longBreakInterval = saved.longBreakInterval;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          // Header — immersive blur surface
          Row() {
            Text('设置')
              .fontSize(28 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 44, bottom: 16 })
          .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode));

          // ── Appearance Section ──
          this.sectionHeader('主题配色');

          Column() {
            // Theme presets
            Text('预设主题')
              .fontSize(14 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ bottom: 10 });

            Grid() {
              GridItem() {
                this.presetSwatch(ThemePreset.OCEAN_BLUE, '#4A90D9', '海洋蓝');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.SUNSET_ORANGE, '#E8774A', '日落橙');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.FOREST_GREEN, '#4CAF50', '森林绿');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.LAVENDER_PURPLE, '#7C5CBF', '薰衣草');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.CHERRY_PINK, '#E91E63', '樱桃粉');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.MIDNIGHT_TEAL, '#00897B', '深夜青');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.WARM_AMBER, '#FFA000', '暖琥珀');
              };
              GridItem() {
                this.presetSwatch(ThemePreset.SLATE_GRAY, '#607D8B', '石板灰');
              };
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(12)
            .columnsGap(12)
            .width('100%');
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Appearance Settings ──
          this.sectionHeader('外观设置');

          Column() {
            SettingSliderComponent({
              label: '圆角大小',
              value: this.borderRadiusValue,
              onValueChange: (val: number) => { this.borderRadiusValue = val; },
              min: 4,
              max: 32,
              step: 1,
              sliderType: SliderType.BORDER_RADIUS,
            });

            // Dark mode toggle
            Row() {
              Text('深色模式')
                .fontSize(15 * this.themeConfig.fontScale)
                .fontColor(this.themeConfig.textColor);

              Blank();

              Toggle({
                type: ToggleType.Switch,
                isOn: this.themeConfig.isDarkMode,
              })
                .selectedColor(this.themeConfig.primaryColor)
                .onChange((isOn: boolean) => {
                  this.themeVM.toggleDarkMode();
                });
            }
            .width('100%')
            .margin({ top: 12 });
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Frosted Glass Section ──
          this.sectionHeader('毛玻璃效果');

          Column() {
            SettingSliderComponent({
              label: '模糊强度',
              value: this.blurRadiusValue,
              onValueChange: (val: number) => { this.blurRadiusValue = val; },
              min: 0,
              max: 60,
              step: 2,
              sliderType: SliderType.BLUR_RADIUS,
            });
            SettingSliderComponent({
              label: '材质透明度',
              value: this.glassOpacityValue,
              onValueChange: (val: number) => { this.glassOpacityValue = val; },
              min: 5,
              max: 100,
              step: 5,
              sliderType: SliderType.GLASS_OPACITY,
            });
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Immersive Material Section ──
          this.sectionHeader('沉浸光感');

          Column() {
            // Toggle: enable/disable immersive material
            Row() {
              Text('启用沉浸光感')
                .fontSize(15 * this.themeConfig.fontScale)
                .fontColor(this.themeConfig.textColor)
                .layoutWeight(1);

              Toggle({
                type: ToggleType.Switch,
                isOn: this.themeConfig.immersiveEnabled,
              })
                .selectedColor(this.themeConfig.primaryColor)
                .onChange((isOn: boolean) => {
                  this.themeVM.updateImmersiveEnabled(isOn);
                });
            }
            .width('100%');

            // Material quality selector
            Text('材质质量')
              .fontSize(13 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 16, bottom: 8 });

            Row() {
              this.materialLevelChip('自适应', 0);
              this.materialLevelChip('精致', 1);
              this.materialLevelChip('柔和', 2);
              this.materialLevelChip('流畅', 3);
            }
            .width('100%');
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Background Section ──
          this.sectionHeader('背景图片');

          Column() {
            ImagePickerButton({
              currentImageUri: this.themeConfig.backgroundImageUri,
              onImagePicked: (uri: string) => {
                this.themeVM.updateBackgroundImage(uri);
              },
              onImageRemoved: () => {
                this.themeVM.removeBackgroundImage();
              },
            });

            if (this.themeConfig.backgroundImageUri !== '') {
              Column()
                .width('100%')
                .height(1)
                .backgroundColor(
                  this.themeConfig.isDarkMode
                    ? 'rgba(255,255,255,0.08)'
                    : 'rgba(0,0,0,0.06)'
                )
                .margin({ top: 12, bottom: 12 });

              SettingSliderComponent({
                label: '图片透明度',
                value: this.imageOpacityValue,
                onValueChange: (val: number) => { this.imageOpacityValue = val; },
                min: 10,
                max: 100,
                step: 5,
                sliderType: SliderType.IMAGE_OPACITY,
              });
            }
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Pomodoro Section ──
          this.sectionHeader('番茄钟');

          Column() {
            SettingSliderComponent({
              label: '专注时长 (分钟)',
              value: this.workMinutes,
              onValueChange: (val: number) => { this.workMinutes = val; },
              min: PomodoroConstants.MIN_WORK_DURATION / 60,
              max: PomodoroConstants.MAX_WORK_DURATION / 60,
              step: 1,
              sliderType: SliderType.WORK_MINUTES,
              onSliderChanged: () => {
                this.schedulePomodoroSave();
              },
            });
            SettingSliderComponent({
              label: '短休息 (分钟)',
              value: this.shortBreakMinutes,
              onValueChange: (val: number) => { this.shortBreakMinutes = val; },
              min: PomodoroConstants.MIN_BREAK_DURATION / 60,
              max: PomodoroConstants.MAX_BREAK_DURATION / 60,
              step: 1,
              sliderType: SliderType.SHORT_BREAK,
              onSliderChanged: () => {
                this.schedulePomodoroSave();
              },
            });
            SettingSliderComponent({
              label: '长休息 (分钟)',
              value: this.longBreakMinutes,
              onValueChange: (val: number) => { this.longBreakMinutes = val; },
              min: PomodoroConstants.MIN_BREAK_DURATION / 60,
              max: PomodoroConstants.MAX_BREAK_DURATION / 60,
              step: 1,
              sliderType: SliderType.LONG_BREAK,
              onSliderChanged: () => {
                this.schedulePomodoroSave();
              },
            });
            SettingSliderComponent({
              label: '长休息间隔 (次)',
              value: this.longBreakInterval,
              onValueChange: (val: number) => { this.longBreakInterval = val; },
              min: 2,
              max: 8,
              step: 1,
              sliderType: SliderType.LONG_BREAK_INTERVAL,
              onSliderChanged: () => {
                this.schedulePomodoroSave();
              },
            });
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── About Section ──
          this.sectionHeader('关于');

          Column() {
            Text('MemoFlow')
              .fontSize(16 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor);

            Text('版本 2.0.0 · HarmonyOS NEXT')
              .fontSize(13 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 4 });
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode))
          .margin({ left: 20, right: 20, bottom: 40 });

          // Bottom spacer
          Blank().height(80);
        }
        .width('100%');
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .hideTitleBar(true)
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  @Builder
  sectionHeader(title: string) {
    Text(title)
      .fontSize(13 * this.themeConfig.fontScale)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.themeConfig.textSecondaryColor)
      .textCase(TextCase.UpperCase)
      .padding({ left: 24, right: 24, top: 0, bottom: 8 });
  }

  @Builder
  materialLevelChip(label: string, level: number) {
    Text(label)
      .fontSize(13 * this.themeConfig.fontScale)
      .fontWeight(this.themeConfig.materialLevel === level ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(
        this.themeConfig.materialLevel === level
          ? this.themeConfig.primaryColor
          : this.themeConfig.textSecondaryColor
      )
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .borderRadius(14)
      .backgroundColor(
        this.themeConfig.materialLevel === level
          ? (this.themeConfig.isDarkMode
            ? this.themeConfig.primaryColor + '30'
            : this.themeConfig.primaryColor + '1A')
          : Color.Transparent
      )
      .margin({ right: 8 })
      .onClick(() => {
        this.themeVM.updateMaterialLevel(level);
      });
  }

  @Builder
  presetSwatch(preset: ThemePreset, color: string, label: string) {
    Column() {
      Circle()
        .width(40)
        .height(40)
        .fill(color);

      Text(label)
        .fontSize(11)
        .fontColor(this.themeConfig.textSecondaryColor)
        .margin({ top: 6 })
        .maxLines(1);
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.selectedPreset = preset;
      this.themeVM.applyPreset(preset);
      this.borderRadiusValue = this.themeConfig.borderRadius;
      this.blurRadiusValue = this.themeConfig.glassBlurRadius;
      this.glassOpacityValue = Math.round(this.themeConfig.glassOpacity * 100);
      this.imageOpacityValue = Math.round(this.themeConfig.backgroundImageOpacity * 100);
    });
  }

}

/**
 * Reusable setting slider component with @Param + @Event.
 */
@ComponentV2
struct SettingSliderComponent {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('themeVM') themeVM: ThemeViewModel = ThemeViewModel.placeholder;
  @Param value: number = 0;
  @Event onValueChange: (val: number) => void = (_v: number) => {
  };
  @Param label: string = '';
  @Param min: number = 0;
  @Param max: number = 100;
  @Param step: number = 1;
  @Param sliderType: SliderType = SliderType.BORDER_RADIUS;
  @Event onSliderChanged: () => void = () => {
  };

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor);

        Blank();

        Text(this.formatDisplay())
          .fontSize(14 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.primaryColor);
      }
      .width('100%');

      Slider({
        value: this.value,
        min: this.min,
        max: this.max,
        step: this.step,
      })
        .width('100%')
        .blockColor(this.themeConfig.primaryColor)
        .trackColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.15)'
            : 'rgba(0, 0, 0, 0.1)'
        )
        .selectedColor(this.themeConfig.primaryColor)
        .trackThickness(4)
        .onChange((newValue: number) => {
          this.onValueChange(newValue);
          this.notifyChange(newValue);
        });
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  private formatDisplay(): string {
    if (this.sliderType === SliderType.GLASS_OPACITY ||
      this.sliderType === SliderType.IMAGE_OPACITY) {
      return String(Math.floor(this.value)) + '%';
    }
    return String(Math.floor(this.value));
  }

  private notifyChange(newValue: number): void {
    if (this.sliderType === SliderType.BORDER_RADIUS) {
      this.themeVM.updateBorderRadius(newValue);
    } else if (this.sliderType === SliderType.BLUR_RADIUS) {
      this.themeVM.updateBlurRadius(newValue);
    } else if (this.sliderType === SliderType.GLASS_OPACITY) {
      this.themeVM.updateGlassOpacity(newValue / 100);
    } else if (this.sliderType === SliderType.IMAGE_OPACITY) {
      this.themeVM.updateBackgroundImageOpacity(newValue / 100);
    } else {
      // Pomodoro slider types: trigger immediate debounced save via callback
      this.onSliderChanged();
    }
  }
}
