import { TodoItem as TodoItemModel, TodoPriority } from '../../model/TodoModel';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { formatDateLabel } from '../../utils/DateUtils';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Single todo item row with checkbox, title, priority indicator, and due date.
 */
@Component
export struct TodoItemView {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop todo: TodoItemModel = {
    id: '',
    title: '',
    description: '',
    isCompleted: false,
    priority: TodoPriority.MEDIUM,
    categoryId: '',
    reminderTime: 0,
    reminderRepeatType: 0,
    createdAt: 0,
    dueDate: 0,
    completedAt: 0,
  };
  onToggle: () => void = () => {
  };
  onItemClick: () => void = () => {
  };

  build() {
    Row() {
      // Checkbox
      Checkbox({ name: this.todo.id, group: 'todos' })
        .select(this.todo.isCompleted)
        .selectedColor(this.themeConfig.primaryColor)
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .width(22)
        .height(22)
        .onChange((_value: boolean) => {
          this.onToggle();
        });

      // Priority indicator
      Column()
        .width(4)
        .height(36)
        .borderRadius(2)
        .backgroundColor(this.getPriorityColor())
        .margin({ left: 12, right: 12 });

      // Title + description + metadata
      Column() {
        Text(this.todo.title)
          .fontSize(16 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor)
          .decoration({ type: this.todo.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
          .opacity(this.todo.isCompleted ? 0.5 : 1.0);

        if (this.todo.description !== '') {
          Text(this.todo.description)
            .fontSize(13 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 });
        }

        Row() {
          if (this.todo.dueDate > 0) {
            Text(formatDateLabel(this.todo.dueDate))
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor);

            if (this.todo.reminderTime > 0) {
              SymbolGlyph(ICON.ALARM)
                .fontSize(12)
                .fontColor([this.themeConfig.primaryColor])
                .margin({ left: 6 });
            }
          }
        }
        .margin({ top: 4 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      this.onItemClick();
    })
    .animation({ duration: 200, curve: Curve.EaseInOut });
  }

  private getPriorityColor(): string {
    switch (this.todo.priority) {
      case TodoPriority.HIGH:
        return '#F44336';
      case TodoPriority.MEDIUM:
        return '#FFA000';
      case TodoPriority.LOW:
      default:
        return '#90A4AE';
    }
  }
}
