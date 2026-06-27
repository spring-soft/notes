import { Note } from '../../model/NoteModel';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { formatRelativeTime } from '../../utils/DateUtils';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Note card with solid background, color tag border, and shadow.
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
          Text(ICON.PIN)
            .fontSize(12)
            .fontColor(this.themeConfig.primaryColor)
            .margin({ left: 8 });
        }
      }
      .margin({ top: this.gridMode ? 6 : 10 });
    }
    .width('100%')
    .padding(this.gridMode ? 12 : 16)
    .borderRadius(this.themeConfig.borderRadius)
    .backgroundColor(this.themeConfig.surfaceColor)
    .border({
      width: { left: this.gridMode ? 3 : 4 },
      color: this.note.colorTag,
      style: BorderStyle.Solid,
    })
    .borderWidth({
      top: 1,
      right: 1,
      bottom: 1,
    })
    .borderColor({
      top: this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.06)'
        : 'rgba(0, 0, 0, 0.06)',
      right: this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.06)'
        : 'rgba(0, 0, 0, 0.06)',
      bottom: this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.06)'
        : 'rgba(0, 0, 0, 0.06)',
    })
    .shadow({
      radius: this.gridMode ? 4 : 6,
      color: this.themeConfig.isDarkMode
        ? 'rgba(0, 0, 0, 0.20)'
        : 'rgba(0, 0, 0, 0.06)',
      offsetY: 1,
    })
    .onClick(() => {
      this.onCardClick();
    });
  }
}
