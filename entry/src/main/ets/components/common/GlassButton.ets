import { ThemeConfig } from '../../model/ThemeConfigModel';
import { createGlassColor } from '../../utils/ColorUtils';

/**
 * Liquid-glass button with specular highlight and press animation.
 *
 * Layers:
 *   1. Colored glass fill (primary for filled, surface for ghost)
 *   2. Top-left specular highlight
 *   3. Backdrop blur
 *
 * @param label - Button text
 * @param icon - Optional system symbol or resource icon
 * @param type - 'primary' (accent-filled) or 'ghost' (transparent glass)
 * @param disabled - Grayed out / non-interactive
 * @param onClick - Click callback
 */
@Component
export struct GlassButton {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop label: string = '';
  @Prop icon: ResourceStr = '';
  @Prop type: string = 'primary';
  @Prop disabled: boolean = false;
  onButtonClick: () => void = () => {
  };

  @State isPressed: boolean = false;

  build() {
    Stack() {
      // ── Main button surface ──
      Row() {
        if (this.icon !== '' && this.icon !== undefined) {
          Image(this.icon)
            .width(20)
            .height(20)
            .fillColor(this.type === 'primary' ? '#FFFFFF' : this.themeConfig.primaryColor)
            .margin({ right: this.label !== '' ? 8 : 0 });
        }
        if (this.label !== '') {
          Text(this.label)
            .fontSize(16 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.type === 'primary' ? '#FFFFFF' : this.themeConfig.textColor);
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .borderRadius(this.themeConfig.borderRadius)
      .backgroundColor(
        this.type === 'primary'
          ? this.themeConfig.primaryColor
          : createGlassColor(
            this.themeConfig.surfaceColor,
            this.themeConfig.glassOpacity,
            this.themeConfig.isDarkMode
          )
      )
      .backdropBlur(this.themeConfig.glassBlurRadius)
      .borderWidth(1)
      .borderColor(
        this.type === 'primary'
          ? 'rgba(255, 255, 255, 0.30)'
          : (this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(255, 255, 255, 0.25)')
      );

      // ── Specular highlight (top-left shine) ──
      Row()
        .width('100%')
        .height('100%')
        .borderRadius(this.themeConfig.borderRadius)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [this.type === 'primary'
              ? 'rgba(255, 255, 255, 0.18)'
              : 'rgba(255, 255, 255, 0.10)', 0.0],
            ['rgba(255, 255, 255, 0.0)', 0.6],
          ],
        })
        .hitTestBehavior(HitTestMode.None);

      // ── Press overlay ──
      if (this.isPressed) {
        Row()
          .width('100%')
          .height('100%')
          .borderRadius(this.themeConfig.borderRadius)
          .backgroundColor('rgba(0, 0, 0, 0.08)')
          .hitTestBehavior(HitTestMode.None);
      }
    }
    .borderRadius(this.themeConfig.borderRadius)
    .opacity(this.disabled ? 0.4 : 1.0)
    .scale({ x: this.isPressed ? 0.96 : 1.0, y: this.isPressed ? 0.96 : 1.0 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .shadow(
      this.type === 'primary' ? {
        radius: 12,
        color: this.themeConfig.primaryColor + '40',
        offsetY: 4,
      } : {
        radius: 0,
        color: Color.Transparent,
        offsetY: 0,
      }
    )
    .onTouch((event: TouchEvent) => {
      if (this.disabled) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onClick(() => {
      if (!this.disabled) {
        this.onButtonClick();
      }
    });
  }
}
