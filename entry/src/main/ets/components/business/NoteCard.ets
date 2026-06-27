import { Note } from '../../model/NoteModel';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { formatRelativeTime } from '../../utils/DateUtils';
import { createGlassColor } from '../../utils/ColorUtils';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Liquid-glass note card for the list.
 * Shows title, content snippet, date, pin status, and color tag.
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
  onCardClick: () => void = () => {
  };

  build() {
    Stack() {
      // ── Main card surface ──
      Column() {
        // Title
        Text(this.note.title !== '' ? this.note.title : '无标题')
          .fontSize(17 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        // Content preview
        if (this.note.content !== '') {
          Text(this.note.content)
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 });
        }

        // Footer
        Row() {
          Text(formatRelativeTime(this.note.updatedAt))
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .opacity(0.7);

          if (this.note.isPinned) {
            Text(ICON.PIN)
              .fontSize(12)
              .fontColor(this.themeConfig.primaryColor)
              .margin({ left: 8 });
          }
        }
        .margin({ top: 10 });
      }
      .width('100%')
      .padding(16)
      .borderRadius(this.themeConfig.borderRadius)
      .backgroundColor(
        createGlassColor(
          this.themeConfig.surfaceColor,
          this.themeConfig.glassOpacity,
          this.themeConfig.isDarkMode
        )
      )
      .backdropBlur(this.themeConfig.glassBlurRadius)
      .border({
        width: { left: 4 },
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
          ? 'rgba(255, 255, 255, 0.08)'
          : 'rgba(255, 255, 255, 0.22)',
        right: this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.08)'
          : 'rgba(255, 255, 255, 0.22)',
        bottom: this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.08)'
          : 'rgba(255, 255, 255, 0.22)',
      });

      // ── Specular highlight (top-left shine) ──
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(this.themeConfig.borderRadius)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.04)'
              : 'rgba(255, 255, 255, 0.15)', 0.0],
            ['rgba(255, 255, 255, 0.0)', 0.5],
          ],
        })
        .hitTestBehavior(HitTestMode.None);
    }
    .borderRadius(this.themeConfig.borderRadius)
    .shadow({
      radius: 6,
      color: this.themeConfig.isDarkMode
        ? 'rgba(0, 0, 0, 0.30)'
        : 'rgba(0, 0, 0, 0.04)',
      offsetY: 1,
    })
    .clip(true)
    .onClick(() => {
      this.onCardClick();
    });
  }
}
