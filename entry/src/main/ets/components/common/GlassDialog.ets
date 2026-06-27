import { ThemeConfig, ThemePreset } from '../../model/ThemeConfigModel';
import { getThemeConfigByPreset } from '../../constants/ThemeConstants';
import { createGlassColor } from '../../utils/ColorUtils';

/**
 * Custom liquid-glass dialog with specular highlight and deep shadow.
 * Receives themeConfig via parameter (not @Consume) because @CustomDialog
 * is rendered in an overlay outside the component tree.
 *
 * Usage:
 *   controller: CustomDialogController = new CustomDialogController({
 *     builder: GlassDialog({ themeConfig: ..., title: '...', message: '...', onConfirm: () => {} }),
 *   });
 */
@CustomDialog
export struct GlassDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: this });
  themeConfig: ThemeConfig = getThemeConfigByPreset(ThemePreset.OCEAN_BLUE);
  title: string = '';
  message: string = '';
  confirmLabel: string = '确认';
  cancelLabel: string = '取消';
  showCancel: boolean = true;
  onConfirm: () => void = () => {
  };
  onCancel: () => void = () => {
  };

  build() {
    Column() {
      if (this.title !== '') {
        Text(this.title)
          .fontSize(20 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor)
          .margin({ bottom: 10 });
      }

      if (this.message !== '') {
        Text(this.message)
          .fontSize(15 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ bottom: 18 });
      }

      Row() {
        if (this.showCancel) {
          Button(this.cancelLabel)
            .fontSize(15 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textColor)
            .backgroundColor('rgba(128, 128, 128, 0.12)')
            .borderRadius(this.themeConfig.borderRadius)
            .padding({ left: 18, right: 18, top: 9, bottom: 9 })
            .onClick(() => {
              this.onCancel();
              this.controller.close();
            });
        }

        if (this.showCancel) {
          Blank().width(16);
        }

        Button(this.confirmLabel)
          .fontSize(15 * this.themeConfig.fontScale)
          .fontColor('#FFFFFF')
          .backgroundColor(this.themeConfig.primaryColor)
          .borderRadius(this.themeConfig.borderRadius)
          .padding({ left: 22, right: 22, top: 9, bottom: 9 })
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          });
      }
      .justifyContent(FlexAlign.Center)
      .width('100%');
    }
    .width(340)
    .padding(20)
    .borderRadius(this.themeConfig.borderRadius + 4)
    // Combined glass background + specular highlight in one gradient
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [
        [this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.06)'
          : 'rgba(255, 255, 255, 0.22)', 0.0],
        [createGlassColor(
          this.themeConfig.surfaceColor,
          this.themeConfig.glassOpacity * 1.5,
          this.themeConfig.isDarkMode
        ), 0.18],
        [createGlassColor(
          this.themeConfig.surfaceColor,
          this.themeConfig.glassOpacity * 1.5,
          this.themeConfig.isDarkMode
        ), 1.0],
      ],
    })
    .backdropBlur(this.themeConfig.glassBlurRadius * 2)
    .borderWidth(1)
    .borderColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.12)'
        : 'rgba(255, 255, 255, 0.35)'
    )
    .constraintSize({ maxWidth: 380, maxHeight: 300 })
    .shadow({
      radius: 30,
      color: 'rgba(0, 0, 0, 0.35)',
      offsetY: 8,
    })
    .clip(true);
  }
}
