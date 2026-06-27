import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';

/**
 * Immersive button with system-provided press deformation.
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
    .backdropBlur(MaterialConstants.getBlur(
      this.type === 'primary' ? MaterialConstants.FAB : MaterialConstants.SURFACE
    ))
    .backgroundColor(MaterialConstants.getOverlayColor(
      this.type === 'primary' ? MaterialConstants.FAB : MaterialConstants.SURFACE,
      this.themeConfig.isDarkMode
    ))
    .opacity(this.disabled ? 0.4 : 1.0)
    .onClick(() => {
      if (!this.disabled) {
        this.onButtonClick();
      }
    });
  }
}
