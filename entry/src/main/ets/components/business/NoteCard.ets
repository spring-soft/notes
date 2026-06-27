import { Note } from '../../model/NoteModel';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { formatRelativeTime } from '../../utils/DateUtils';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Lightweight note card — accent stripe + subtle surface, no heavy blur frame.
 *
 * gridMode=false — list: title + 1-line preview + footer
 * gridMode=true  — grid: title + footer only (ultra-compact)
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

      // Content
      Column() {
        Text(this.note.title !== '' ? this.note.title : '无标题')
          .fontSize((this.gridMode ? 12 : 14) * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        if (!this.gridMode && this.note.content !== '') {
          Text(this.note.content)
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 3 });
        }

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
    .borderRadius(8)
    .backgroundColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.04)'
        : 'rgba(0, 0, 0, 0.02)'
    )
    .onClick(() => {
      this.onCardClick();
    });
  }
}
