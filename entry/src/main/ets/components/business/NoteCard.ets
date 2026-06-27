import { Note } from '../../model/NoteModel';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { formatRelativeTime } from '../../utils/DateUtils';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Immersive note card with color-tag stripe and system material depth.
 */
@Component
export struct NoteCard {
  @Consume('themeConfig') themeConfig: ThemeConfig;
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
      // Accent color stripe
      Column()
        .width(this.gridMode ? 3 : 4)
        .height('100%')
        .backgroundColor(this.note.colorTag)
        .borderRadius(2)
        .margin({ right: this.gridMode ? 8 : 12 });

      // Content
      Column() {
        // Title
        Text(this.note.title !== '' ? this.note.title : '无标题')
          .fontSize((this.gridMode ? 14 : 17) * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        // Content preview
        if (this.note.content !== '') {
          Text(this.note.content)
            .fontSize((this.gridMode ? 12 : 14) * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .maxLines(this.gridMode ? 1 : 2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: this.gridMode ? 4 : 6 });
        }

        // Footer
        Row() {
          Text(formatRelativeTime(this.note.updatedAt))
            .fontSize((this.gridMode ? 11 : 12) * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .opacity(0.7);

          if (this.note.isPinned) {
            SymbolGlyph(ICON.PIN)
              .fontSize(12)
              .fontColor([this.themeConfig.primaryColor])
              .margin({ left: 8 });
          }
        }
        .margin({ top: this.gridMode ? 6 : 10 });
      }
      .layoutWeight(1);
    }
    .width('100%')
    .padding(this.gridMode ? 10 : 14)
    .borderRadius(this.themeConfig.borderRadius)
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CARD))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CARD, this.themeConfig.isDarkMode))
    .onClick(() => {
      this.onCardClick();
    });
  }
}
