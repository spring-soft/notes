import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';

/**
 * Category group header for the todo list.
 */
@ComponentV2
export struct TodoCategoryHeader {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param categoryName: string = '未分类';
  @Param categoryColor: string = '#90A4AE';
  @Param itemCount: number = 0;

  build() {
    Row() {
      // Color dot
      Column()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.categoryColor)
        .margin({ right: 8 });

      Text(this.categoryName)
        .fontSize(15 * this.themeConfig.fontScale)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeConfig.textColor);

      Text(`(${this.itemCount})`)
        .fontSize(13 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textSecondaryColor)
        .margin({ left: 6 });
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 8 });
  }
}
