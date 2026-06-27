import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Solid button with press animation.
 *
 * @param label - Button text
 * @param icon - Optional system symbol or resource icon
 * @param type - 'primary' (accent-filled) or 'ghost' (transparent)
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
        ? (this.isPressed
          ? this.darken(this.themeConfig.primaryColor, 0.1)
          : this.themeConfig.primaryColor)
        : (this.isPressed
          ? (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.08)')
          : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)'))
    )
    .borderWidth(1)
    .borderColor(
      this.type === 'primary'
        ? 'rgba(255, 255, 255, 0.20)'
        : (this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.06)'
          : 'rgba(0, 0, 0, 0.06)')
    )
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

  private darken(hex: string, ratio: number): string {
    const r: number = parseInt(hex.substring(1, 3), 16);
    const g: number = parseInt(hex.substring(3, 5), 16);
    const b: number = parseInt(hex.substring(5, 7), 16);
    const nr: number = Math.max(0, Math.floor(r * (1 - ratio)));
    const ng: number = Math.max(0, Math.floor(g * (1 - ratio)));
    const nb: number = Math.max(0, Math.floor(b * (1 - ratio)));
    return `#${nr.toString(16).padStart(2, '0')}${ng.toString(16).padStart(2, '0')}${nb.toString(16).padStart(2, '0')}`;
  }
}
