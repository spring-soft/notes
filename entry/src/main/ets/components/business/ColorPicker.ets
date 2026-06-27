import { ThemeConfig } from '../../model/ThemeConfigModel';
import { ColorHex } from '../../model/AppConstantsModel';
import { ColorConstants } from '../../constants/ColorConstants';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Color swatch grid picker for selecting accent colors.
 */
@Component
export struct ColorPickerComponent {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop selectedColor: ColorHex = '#4A90D9';
  onColorSelect: (color: ColorHex) => void = (_c: ColorHex) => {
  };

  build() {
    Grid() {
      ForEach(ColorConstants.PRESET_COLORS, (color: ColorHex, _index: number) => {
        GridItem() {
          Stack() {
            Circle()
              .width(44)
              .height(44)
              .fill(color);

            if (color === this.selectedColor) {
              Text(ICON.CHECK)
                .fontSize(20)
                .fontColor(this.isDarkColor(color) ? '#FFFFFF' : '#000000');
            }
          }
          .onClick(() => {
            this.onColorSelect(color);
          });
        };
      }, (color: ColorHex) => color);
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsGap(16)
    .columnsGap(16)
    .width('100%');
  }

  private isDarkColor(hex: ColorHex): boolean {
    const r: number = parseInt(hex.substring(1, 3), 16);
    const g: number = parseInt(hex.substring(3, 5), 16);
    const b: number = parseInt(hex.substring(5, 7), 16);
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255 < 0.5;
  }
}
