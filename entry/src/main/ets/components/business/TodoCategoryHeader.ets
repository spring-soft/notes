import { ThemeConfig } from '../../model/ThemeConfigModel';

/**
 * Category group header for the todo list.
 */
@Component
export struct TodoCategoryHeader {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop categoryName: string = '未分类';
  @Prop categoryColor: string = '#90A4AE';
  @Prop itemCount: number = 0;

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
