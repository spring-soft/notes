import { TodoPriority, TodoItem, TodoCategory, PRESET_TODO_CATEGORIES } from '../../model/TodoModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { ID } from '../../model/AppConstantsModel';

/**
 * Bottom sheet / inline form for adding a new todo item.
 */
@ComponentV2
export struct TodoAddSheet {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param categories: TodoCategory[] = [];
  @Local title: string = '';
  @Local description: string = '';
  @Local selectedPriority: TodoPriority = TodoPriority.MEDIUM;
  @Local selectedCategoryId: string = '';
  @Local showPriorityPicker: boolean = false;
  @Local showCategoryPicker: boolean = false;
  @Local customCategoryName: string = '';
  @Local selectedCategoryColor: string = '#4A90D9';

  @Event onSave: (title: string, description: string, priority: TodoPriority, categoryId: ID, customCategoryName: string) => void =
    (_t: string, _d: string, _p: TodoPriority, _c: ID, _cn: string) => {
    };
  @Event onCancel: () => void = () => {
  };

  build() {
    Column() {
      // Title
      Text('新建待办')
        .fontSize(20 * this.themeConfig.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeConfig.textColor)
        .margin({ bottom: 20 });

      // Title input
      TextInput({ text: this.title, placeholder: '待办标题' })
        .fontSize(16 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(0, 0, 0, 0.04)'
        )
        .borderRadius(this.themeConfig.borderRadius)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderWidth(1)
        .borderColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(0, 0, 0, 0.06)'
        )
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.title = value;
        });

      // Description input
      TextArea({ text: this.description, placeholder: '描述 (可选)' })
        .fontSize(14 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textColor)
        .placeholderColor(this.themeConfig.textSecondaryColor)
        .backgroundColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(0, 0, 0, 0.04)'
        )
        .borderRadius(this.themeConfig.borderRadius)
        .padding(16)
        .borderWidth(1)
        .borderColor(
          this.themeConfig.isDarkMode
            ? 'rgba(255, 255, 255, 0.08)'
            : 'rgba(0, 0, 0, 0.06)'
        )
        .height(80)
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.description = value;
        });

      // Category section — custom name input + filtered chips
      Column() {
        Row() {
          Text('分组')
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textColor)
            .margin({ bottom: 6 });
        }
        .width('100%');

        // Text input for custom category name
        TextInput({ text: this.customCategoryName, placeholder: '输入分组名称，或从下方选择' })
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor)
          .placeholderColor(this.themeConfig.textSecondaryColor)
          .backgroundColor(
            this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.08)'
              : 'rgba(0, 0, 0, 0.04)'
          )
          .borderRadius(this.themeConfig.borderRadius)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .borderWidth(1)
          .borderColor(
            this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.08)'
              : 'rgba(0, 0, 0, 0.06)'
          )
          .margin({ bottom: 8 })
          .onChange((value: string) => {
            this.customCategoryName = value;
            this.selectedCategoryId = '';
          });

        // Preset category chips (always shown)
        if (this.customCategoryName.trim() === '' || this.getFilteredPresets().length > 0) {
          Scroll() {
            Row() {
              ForEach(this.getFilteredPresets(), (presetName: string, _idx: number) => {
                Text(presetName)
                  .fontSize(13)
                  .fontColor((this.selectedCategoryId === presetName || this.customCategoryName === presetName)
                    ? '#FFFFFF' : this.themeConfig.textColor)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .borderRadius(14)
                  .backgroundColor((this.selectedCategoryId === presetName || this.customCategoryName === presetName)
                    ? this.themeConfig.primaryColor
                    : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'))
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.customCategoryName = presetName;
                    this.selectedCategoryId = presetName;
                    this.selectedCategoryColor = this.themeConfig.primaryColor;
                  });
              }, (presetName: string) => presetName);
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off);
        }

        // Existing user-created category chips filtered by typed text
        if (this.categories.length > 0) {
          Scroll() {
            Row() {
              ForEach(this.getFilteredCategories(), (cat: TodoCategory, _idx: number) => {
                Text(cat.name)
                  .fontSize(13)
                  .fontColor(this.selectedCategoryId === cat.id
                    ? '#FFFFFF'
                    : this.themeConfig.textColor)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .borderRadius(14)
                  .backgroundColor(this.selectedCategoryId === cat.id
                    ? cat.colorHex
                    : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'))
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.selectedCategoryId = cat.id;
                    this.customCategoryName = cat.name;
                    this.selectedCategoryColor = cat.colorHex;
                  });
              }, (cat: TodoCategory) => cat.id);
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off);
        }
      }
      .width('100%')
      .margin({ bottom: 12 });

      // Priority selector
      Row() {
        Text('优先级')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor)
          .width(60);

        Row() {
          this.priorityChip(TodoPriority.LOW, '低');
          this.priorityChip(TodoPriority.MEDIUM, '中');
          this.priorityChip(TodoPriority.HIGH, '高');
        }
        .layoutWeight(1);
      }
      .width('100%')
      .margin({ bottom: 12 });

      // Action buttons
      Row() {
        Button('取消')
          .fontSize(16 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor)
          .backgroundColor('rgba(128, 128, 128, 0.15)')
          .borderRadius(this.themeConfig.borderRadius)
          .layoutWeight(1)
          .onClick(() => {
            this.onCancel();
          });

        Blank().width(12);

        Button('保存')
          .fontSize(16 * this.themeConfig.fontScale)
          .fontColor('#FFFFFF')
          .backgroundColor(this.themeConfig.primaryColor)
          .borderRadius(this.themeConfig.borderRadius)
          .layoutWeight(1)
          .onClick(() => {
            this.onSave(this.title, this.description, this.selectedPriority, this.selectedCategoryId, this.customCategoryName);
          });
      }
      .width('100%')
      .margin({ top: 8 });
    }
    .padding(24)
  }

  @Builder
  priorityChip(priority: TodoPriority, label: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.selectedPriority === priority
        ? '#FFFFFF'
        : this.themeConfig.textColor)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(20)
      .backgroundColor(this.selectedPriority === priority
        ? this.getPriorityColor(priority)
        : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'))
      .margin({ right: 8 })
      .onClick(() => {
        this.selectedPriority = priority;
      });
  }

  private getFilteredPresets(): string[] {
    if (this.customCategoryName.trim() === '') {
      const result: string[] = [];
      for (const preset of PRESET_TODO_CATEGORIES) {
        result.push(preset);
      }
      return result;
    }
    const query: string = this.customCategoryName.trim().toLowerCase();
    const filtered: string[] = [];
    for (const preset of PRESET_TODO_CATEGORIES) {
      if (preset.toLowerCase().includes(query)) {
        filtered.push(preset);
      }
    }
    return filtered;
  }

  private getFilteredCategories(): TodoCategory[] {
    if (this.customCategoryName.trim() === '') {
      const result: TodoCategory[] = [];
      for (const cat of this.categories) {
        result.push(cat);
      }
      return result;
    }
    const query: string = this.customCategoryName.trim().toLowerCase();
    const filtered: TodoCategory[] = [];
    for (const cat of this.categories) {
      if (cat.name.toLowerCase().includes(query)) {
        filtered.push(cat);
      }
    }
    return filtered;
  }

  private getPriorityColor(priority: TodoPriority): string {
    switch (priority) {
      case TodoPriority.HIGH:
        return '#F44336';
      case TodoPriority.MEDIUM:
        return '#FFA000';
      case TodoPriority.LOW:
      default:
        return '#4CAF50';
    }
  }
}
