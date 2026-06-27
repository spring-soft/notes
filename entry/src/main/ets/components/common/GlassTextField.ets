import { ThemeConfig } from '../../model/ThemeConfigModel';
import { createGlassColor } from '../../utils/ColorUtils';

/**
 * Glass-effect text input field.
 *
 * @param placeholder - Placeholder text
 * @param text - Two-way bound text value
 * @param maxLength - Maximum character length
 * @param type - Input type: 'text', 'number', 'password'
 * @param multiline - Enable multi-line input
 * @param onChange - Text change callback
 */
@Component
export struct GlassTextField {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop placeholder: string = '';
  @Link text: string;
  @Prop maxLength: number = 500;
  @Prop type: InputType = InputType.Normal;
  @Prop multiline: boolean = false;
  onChange: (value: string) => void = (_v: string) => {
  };

  build() {
    if (this.multiline) {
      TextArea({ text: this.text, placeholder: this.placeholder })
        .maxLength(this.maxLength)
        .fontSize(16 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(
          createGlassColor(
            this.themeConfig.surfaceColor,
            this.themeConfig.glassOpacity * 0.5,
            this.themeConfig.isDarkMode
          )
        )
        .borderRadius(this.themeConfig.borderRadius)
        .padding(16)
        .borderWidth(1)
        .borderColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(255, 255, 255, 0.2)'
        )
        .onChange((value: string) => {
          this.text = value;
          this.onChange(value);
        });
    } else {
      TextInput({ text: this.text, placeholder: this.placeholder })
        .maxLength(this.maxLength)
        .type(this.type)
        .fontSize(16 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(
          createGlassColor(
            this.themeConfig.surfaceColor,
            this.themeConfig.glassOpacity * 0.5,
            this.themeConfig.isDarkMode
          )
        )
        .borderRadius(this.themeConfig.borderRadius)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderWidth(1)
        .borderColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(255, 255, 255, 0.2)'
        )
        .onChange((value: string) => {
          this.text = value;
          this.onChange(value);
        });
    }
  }
}
