import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { ThemeConfig, ThemePreset } from '../model/ThemeConfigModel';
import { PomodoroConfig } from '../model/PomodoroSessionModel';
import { PomodoroViewModel } from '../viewmodel/PomodoroViewModel';
import { SettingsRepository } from '../repository/SettingsRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { NotificationService } from '../service/NotificationService';
import { BackgroundTaskService } from '../service/BackgroundTaskService';
import { PomodoroRepository } from '../repository/PomodoroRepository';
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
}

/**
 * Settings page with theme customization, pomodoro config, and background image.
 */
@Component
export struct SettingsPage {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Consume('themeVM') themeVM: ThemeViewModel;
  @State pomodoroVM: PomodoroViewModel = this.createPomodoroVM();
  @State selectedPreset: ThemePreset = ThemePreset.OCEAN_BLUE;
  @State workMinutes: number = 25;
  @State shortBreakMinutes: number = 5;
  @State longBreakMinutes: number = 15;
  @State longBreakInterval: number = 4;
  @State borderRadiusValue: number = 16;

  aboutToAppear(): void {
    this.selectedPreset = this.themeVM.currentPreset;
    this.borderRadiusValue = this.themeConfig.borderRadius;
  }

  private createPomodoroVM(): PomodoroViewModel {
    const context: common.Context = this.getUIContext().getHostContext() as common.Context;
    const appContext: common.Context = context.getApplicationContext();
    return new PomodoroViewModel(
      new PomodoroRepository(DatabaseHelper.getInstance().getStore()),
      new SettingsRepository(appContext),
      new NotificationService(appContext),
      new BackgroundTaskService(appContext)
    );
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          // Header
          Row() {
            Text('设置')
              .fontSize(28 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 44, bottom: 16 });

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
          .backgroundColor(this.themeConfig.surfaceColor)
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Appearance Settings ──
          this.sectionHeader('外观设置');

          Column() {
            SettingSliderComponent({
              label: '圆角大小',
              value: $borderRadiusValue,
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
          .backgroundColor(this.themeConfig.surfaceColor)
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
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(this.themeConfig.surfaceColor)
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── Pomodoro Section ──
          this.sectionHeader('番茄钟');

          Column() {
            SettingSliderComponent({
              label: '专注时长 (分钟)',
              value: $workMinutes,
              min: PomodoroConstants.MIN_WORK_DURATION / 60,
              max: PomodoroConstants.MAX_WORK_DURATION / 60,
              step: 1,
              sliderType: SliderType.WORK_MINUTES,
            });
            SettingSliderComponent({
              label: '短休息 (分钟)',
              value: $shortBreakMinutes,
              min: PomodoroConstants.MIN_BREAK_DURATION / 60,
              max: PomodoroConstants.MAX_BREAK_DURATION / 60,
              step: 1,
              sliderType: SliderType.SHORT_BREAK,
            });
            SettingSliderComponent({
              label: '长休息 (分钟)',
              value: $longBreakMinutes,
              min: PomodoroConstants.MIN_BREAK_DURATION / 60,
              max: PomodoroConstants.MAX_BREAK_DURATION / 60,
              step: 1,
              sliderType: SliderType.LONG_BREAK,
            });
            SettingSliderComponent({
              label: '长休息间隔 (次)',
              value: $longBreakInterval,
              min: 2,
              max: 8,
              step: 1,
              sliderType: SliderType.LONG_BREAK_INTERVAL,
            });

            Button('保存番茄钟设置')
              .fontSize(14 * this.themeConfig.fontScale)
              .fontColor('#FFFFFF')
              .backgroundColor(this.themeConfig.primaryColor)
              .borderRadius(this.themeConfig.borderRadius)
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .margin({ top: 12 })
              .onClick(() => {
                const config: PomodoroConfig = {
                  workDuration: this.workMinutes * 60,
                  shortBreakDuration: this.shortBreakMinutes * 60,
                  longBreakDuration: this.longBreakMinutes * 60,
                  longBreakInterval: this.longBreakInterval,
                };
                this.pomodoroVM.saveConfig(config);
              });
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(this.themeConfig.surfaceColor)
          .margin({ left: 20, right: 20, bottom: 16 });

          // ── About Section ──
          this.sectionHeader('关于');

          Column() {
            Text('MemoFlow')
              .fontSize(16 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor);

            Text('版本 1.1.0 · HarmonyOS NEXT')
              .fontSize(13 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 4 });
          }
          .padding(16)
          .borderRadius(this.borderRadiusValue)
          .backgroundColor(this.themeConfig.surfaceColor)
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
    .backgroundColor(this.themeConfig.backgroundColor)
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
    });
  }

}

/**
 * Reusable setting slider component with two-way @Link binding.
 */
@Component
struct SettingSliderComponent {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Consume('themeVM') themeVM: ThemeViewModel;
  @Link value: number;
  @Prop label: string = '';
  @Prop min: number = 0;
  @Prop max: number = 100;
  @Prop step: number = 1;
  @Prop sliderType: SliderType = SliderType.BORDER_RADIUS;

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
          this.value = newValue;
          this.notifyChange(newValue);
        });
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  private formatDisplay(): string {
    return String(Math.floor(this.value));
  }

  private notifyChange(newValue: number): void {
    if (this.sliderType === SliderType.BORDER_RADIUS) {
      this.themeVM.updateBorderRadius(newValue);
    }
    // Pomodoro sliders: parent @State syncs automatically via @Link,
    // saved later via "保存番茄钟设置" button
  }
}
