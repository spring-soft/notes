import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Reusable search input bar with solid styling.
 *
 * @param placeholder - Placeholder text (default: "搜索...")
 * @param query - Search query from parent
 * @param onQueryChange - Callback when query changes (replaces @Link)
 * @param onSearch - Callback when text changes
 * @param onClear - Callback when clear button pressed
 */
@ComponentV2
export struct SearchBar {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param placeholder: string = '搜索...';
  @Param query: string = '';
  @Event onQueryChange: (value: string) => void = (_v: string) => {
  };
  @Event onSearch: (value: string) => void = (_v: string) => {
  };
  @Event onClear: () => void = () => {
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
          this.onQueryChange(value);
          this.onSearch(value);
        });

      if (this.query !== '') {
        SymbolGlyph(ICON.CLOSE)
          .fontSize(18)
          .fontColor([this.themeConfig.textSecondaryColor])
          .margin({ left: 8 })
          .onClick(() => {
            this.onQueryChange('');
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
