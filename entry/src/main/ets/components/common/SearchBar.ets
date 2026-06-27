import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Reusable search input bar with solid styling.
 *
 * @param placeholder - Placeholder text (default: "搜索...")
 * @param query - Two-way bound search query
 * @param onSearch - Callback when text changes
 * @param onClear - Callback when clear button pressed
 */
@Component
export struct SearchBar {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop placeholder: string = '搜索...';
  @Link query: string;
  onSearch: (value: string) => void = (_v: string) => {
  };
  onClear: () => void = () => {
  };

  build() {
    Row() {
      SymbolGlyph(ICON.SEARCH)
        .fontSize(18)
        .fontColor([this.themeConfig.textSecondaryColor])
        .margin({ right: 8 });

      TextInput({ text: this.query, placeholder: this.placeholder })
        .layoutWeight(1)
        .fontSize(16 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(Color.Transparent)
        .borderWidth(0)
        .onChange((value: string) => {
          this.query = value;
          this.onSearch(value);
        });

      if (this.query !== '') {
        SymbolGlyph(ICON.CLOSE)
          .fontSize(18)
          .fontColor([this.themeConfig.textSecondaryColor])
          .margin({ left: 8 })
          .onClick(() => {
            this.query = '';
            this.onClear();
          });
      }
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .borderRadius(this.themeConfig.borderRadius)
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SURFACE))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode));
  }
}
