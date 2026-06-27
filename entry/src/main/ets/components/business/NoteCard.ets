import { Note } from '../../model/NoteModel';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { formatRelativeTime } from '../../utils/DateUtils';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Immersive note card with color-tag stripe and system material depth.
 * On tablet the material is lighter (THIN) to avoid overwhelming the wider layout.
 *
 * Two visual modes:
 *   gridMode=false — list card with title + 1-line preview + footer
 *   gridMode=true  — ultra-compact grid card with title + footer (no preview)
 */
@Component
export struct NoteCard {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Consume('isTablet') isTabletCard: boolean = false;
  @Prop note: Note = {
    id: '',
    title: '',
    content: '',
    createdAt: 0,
    updatedAt: 0,
    colorTag: '#4A90D9',
    isPinned: false,
    categoryId: '未分类',
  };
  @Prop gridMode: boolean = false;
  onCardClick: () => void = () => {
  };

  build() {
    Row() {
      // Accent color stripe — thin left-edge indicator
      Column()
        .width(3)
        .height('100%')
        .backgroundColor(this.note.colorTag)
        .borderRadius(2)
        .margin({ right: 8 });

      // Content — grid mode is ultra-compact, list mode shows preview
      Column() {
        // Title (always visible)
        Text(this.note.title !== '' ? this.note.title : '无标题')
          .fontSize((this.gridMode ? 12 : 14) * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        // Content preview — only in list mode (to keep cards short)
        if (!this.gridMode && this.note.content !== '') {
          Text(this.note.content)
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 3 });
        }

        // Footer — time + optional pin
        Row() {
          Text(formatRelativeTime(this.note.updatedAt))
            .fontSize(11 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .opacity(0.7);

          if (this.note.isPinned) {
            SymbolGlyph(ICON.PIN)
              .fontSize(10)
              .fontColor([this.themeConfig.primaryColor])
              .margin({ left: 4 });
          }
        }
        .margin({ top: this.gridMode ? 2 : 4 });
      }
      .layoutWeight(1);
    }
    .width('100%')
    .padding(this.gridMode ? 6 : 10)
    .borderRadius(this.themeConfig.borderRadius)
    .backdropBlur(MaterialConstants.getBlur(
      this.isTabletCard ? MaterialConstants.THIN : MaterialConstants.CARD
    ))
    .backgroundColor(MaterialConstants.getOverlayColor(
      this.isTabletCard ? MaterialConstants.THIN : MaterialConstants.CARD,
      this.themeConfig.isDarkMode
    ))
    .onClick(() => {
      this.onCardClick();
    });
  }
}
