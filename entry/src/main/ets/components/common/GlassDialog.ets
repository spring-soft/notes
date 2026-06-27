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
    Stack() {
      // ── Main dialog surface ──
      Column() {
        if (this.title !== '') {
          Text(this.title)
            .fontSize(20 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeConfig.textColor)
            .margin({ bottom: 12 });
        }

        if (this.message !== '') {
          Text(this.message)
            .fontSize(16 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .margin({ bottom: 24 });
        }

        Row() {
          if (this.showCancel) {
            Button(this.cancelLabel)
              .fontSize(16 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textColor)
              .backgroundColor('rgba(128, 128, 128, 0.12)')
              .borderRadius(this.themeConfig.borderRadius)
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .onClick(() => {
                this.onCancel();
                this.controller.close();
              })
              .margin({ right: 12 });
          }

          Button(this.confirmLabel)
            .fontSize(16 * this.themeConfig.fontScale)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeConfig.primaryColor)
            .borderRadius(this.themeConfig.borderRadius)
            .padding({ left: 24, right: 24, top: 10, bottom: 10 })
            .onClick(() => {
              this.onConfirm();
              this.controller.close();
            });
        }
        .justifyContent(FlexAlign.End)
        .width('100%');
      }
      .padding(24)
      .borderRadius(this.themeConfig.borderRadius + 4)
      .backgroundColor(
        createGlassColor(
          this.themeConfig.surfaceColor,
          this.themeConfig.glassOpacity * 1.5,
          this.themeConfig.isDarkMode
        )
      )
      .backdropBlur(this.themeConfig.glassBlurRadius * 2)
      .borderWidth(1)
      .borderColor(
        this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.12)'
          : 'rgba(255, 255, 255, 0.35)'
      );

      // ── Specular highlight ──
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(this.themeConfig.borderRadius + 4)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.05)'
              : 'rgba(255, 255, 255, 0.20)', 0.0],
            ['rgba(255, 255, 255, 0.0)', 0.5],
          ],
        })
        .hitTestBehavior(HitTestMode.None);
    }
    .constraintSize({ maxWidth: 380 })
    .shadow({
      radius: 30,
      color: 'rgba(0, 0, 0, 0.35)',
      offsetY: 8,
    });
  }
}
