import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';

/**
 * Immersive text input field with translucent background.
 *
 * @param placeholder - Placeholder text
 * @param text - Text value from parent
 * @param onTextChange - Callback when text changes (replaces @Link)
 * @param maxLength - Maximum character length
 * @param type - Input type: 'text', 'number', 'password'
 * @param multiline - Enable multi-line input
 * @param onChange - Text change callback
 */
@ComponentV2
export struct GlassTextField {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param placeholder: string = '';
  @Param text: string = '';
  @Event onTextChange: (value: string) => void = (_v: string) => {
  };
  @Param maxLength: number = 500;
  @Param type: InputType = InputType.Normal;
  @Param multiline: boolean = false;
  @Event onChange: (value: string) => void = (_v: string) => {
  };

  build() {
    if (this.multiline) {
      TextArea({ text: this.text, placeholder: this.placeholder })
        .maxLength(this.maxLength)
        .fontSize(16 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
        .borderRadius(this.themeConfig.borderRadius)
        .padding(16)
        .borderWidth(1)
        .borderColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(0, 0, 0, 0.08)'
        )
        .onChange((value: string) => {
          this.onTextChange(value);
          this.onChange(value);
        });
    } else {
      TextInput({ text: this.text, placeholder: this.placeholder })
        .maxLength(this.maxLength)
        .type(this.type)
        .fontSize(16 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
        .borderRadius(this.themeConfig.borderRadius)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderWidth(1)
        .borderColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(0, 0, 0, 0.08)'
        )
        .onChange((value: string) => {
          this.onTextChange(value);
          this.onChange(value);
        });
    }
  }
}
