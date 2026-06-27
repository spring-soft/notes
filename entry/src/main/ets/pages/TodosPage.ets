import { TodosViewModel } from '../viewmodel/TodosViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { ReminderViewModel } from '../viewmodel/ReminderViewModel';
import { TodoItem, TodoCategory, TodoPriority, TodoFilterType } from '../model/TodoModel';
import { ThemeConfig } from '../model/ThemeConfigModel';
import { TodoRepository } from '../repository/TodoRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { ReminderService } from '../service/ReminderService';
import { common } from '@kit.AbilityKit';
import { TodoItemView } from '../components/business/TodoItem';
import { TodoCategoryHeader } from '../components/business/TodoCategoryHeader';
import { TodoAddSheet } from '../components/business/TodoAddSheet';
import { EmptyState } from '../components/common/EmptyState';
import { ICON } from '../utils/IconGlyphs';

/**
 * Todos list page with category grouping, filter tabs, and add sheet.
 */
@Component
export struct TodosPage {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @State viewModel: TodosViewModel = new TodosViewModel(
    new TodoRepository(DatabaseHelper.getInstance().getStore())
  );
  @State showAddSheet: boolean = false;
  @State activeTab: number = 0;
  @State showCategoryManager: boolean = false;
  @State newCategoryName: string = '';
  @State newCategoryColor: string = '#4A90D9';

  aboutToAppear(): void {
    this.viewModel.loadData();
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // Header
          Row() {
            Text('待办')
              .fontSize(28 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 44, bottom: 12 });

          // Filter tabs
          Row() {
            this.filterTab('全部', 0, TodoFilterType.ALL);
            this.filterTab('未完成', 1, TodoFilterType.ACTIVE);
            this.filterTab('已完成', 2, TodoFilterType.COMPLETED);

            Blank();

            // Category manager toggle
            Button() {
              Text(this.showCategoryManager ? ICON.CLOSE : ICON.MENU)
                .fontSize(16)
                .fontColor(this.themeConfig.textSecondaryColor);
            }
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor(
              this.themeConfig.isDarkMode
                ? 'rgba(255, 255, 255, 0.08)'
                : 'rgba(0, 0, 0, 0.04)'
            )
            .onClick(() => {
              this.showCategoryManager = !this.showCategoryManager;
            });
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 8 });

          // Category manager
          if (this.showCategoryManager) {
            Column() {
              Text('管理分组')
                .fontSize(13 * this.themeConfig.fontScale)
                .fontColor(this.themeConfig.textSecondaryColor)
                .width('100%')
                .margin({ bottom: 8 });

              // Existing categories
              Row() {
                Scroll() {
                  Row() {
                    ForEach(this.viewModel.categories, (cat: TodoCategory, _idx: number) => {
                      Row() {
                        Column()
                          .width(8)
                          .height(8)
                          .borderRadius(4)
                          .backgroundColor(cat.colorHex)
                          .margin({ right: 6 });

                        Text(cat.name)
                          .fontSize(13)
                          .fontColor(this.themeConfig.textColor);

                        Button() {
                          Text(ICON.CLOSE)
                            .fontSize(10)
                            .fontColor(this.themeConfig.textSecondaryColor);
                        }
                        .width(18)
                        .height(18)
                        .borderRadius(9)
                        .backgroundColor('rgba(128,128,128,0.15)')
                        .margin({ left: 6 })
                        .onClick(() => {
                          this.viewModel.deleteCategory(cat.id);
                        });
                      }
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .borderRadius(14)
                      .backgroundColor(
                        this.themeConfig.isDarkMode
                          ? 'rgba(255,255,255,0.06)'
                          : 'rgba(0,0,0,0.04)'
                      )
                      .margin({ right: 8 });
                    }, (cat: TodoCategory) => cat.id);
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .layoutWeight(1);
              }
              .width('100%')
              .margin({ bottom: 8 });

              // Add new category
              Row() {
                TextInput({ text: this.newCategoryName, placeholder: '新分组名称' })
                  .fontSize(13 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textColor)
                  .placeholderColor(this.themeConfig.textSecondaryColor)
                  .backgroundColor(
                    this.themeConfig.isDarkMode
                      ? 'rgba(255,255,255,0.08)'
                      : 'rgba(0,0,0,0.04)'
                  )
                  .borderRadius(14)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.newCategoryName = value;
                  });

                // Color presets for new category
                Row() {
                  this.categoryColorDot('#F44336');
                  this.categoryColorDot('#FF9800');
                  this.categoryColorDot('#4CAF50');
                  this.categoryColorDot('#2196F3');
                  this.categoryColorDot('#9C27B0');
                }
                .margin({ left: 8, right: 8 });

                Button('创建')
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.themeConfig.primaryColor)
                  .borderRadius(14)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .onClick(() => {
                    if (this.newCategoryName.trim() !== '') {
                      this.viewModel.createCategory(this.newCategoryName.trim(), this.newCategoryColor);
                      this.newCategoryName = '';
                    }
                  });
              }
              .width('100%');
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 8 })
            .animation({ duration: 200, curve: Curve.EaseInOut });
          }

          // Todo list grouped by category
          if (this.viewModel.filteredTodos.length === 0) {
            EmptyState({
              icon: ICON.TODOS,
              title: this.activeTab === 2 ? '没有已完成的待办' : '没有待办事项',
              subtitle: '点击右下角按钮添加新的待办',
            });
          } else {
            List() {
              // Group todos by category
              LazyForEach(this.createCategoryDataSource(), (categoryId: string, _index: number) => {
                ListItemGroup({ header: this.categoryHeader(categoryId) }) {
                  LazyForEach(this.createTodoDataSource(categoryId), (todo: TodoItem, _idx: number) => {
                    ListItem() {
                      TodoItemView({
                        todo: todo,
                        onToggle: () => {
                          this.viewModel.toggleComplete(todo.id);
                        },
                        onItemClick: () => {
                          // Open detail/edit
                        },
                      });
                    }
                  }, (todo: TodoItem) => todo.id);
                };
              }, (categoryId: string) => categoryId);
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring);
          }
        }
        .width('100%')
        .height('100%');

        // FAB
        Stack() {
          Button() {
            Text(ICON.PLUS)
              .fontSize(28)
              .fontColor('#FFFFFF');
          }
          .width(60)
          .height(60)
          .borderRadius(30)
          .backgroundColor(this.themeConfig.primaryColor)
          .shadow({
            radius: 16,
            color: this.themeConfig.primaryColor + '40',
            offsetY: 4,
          })
          .onClick(() => {
            this.showAddSheet = true;
          });
        }
        .position({ right: 20, bottom: 20 });

        // Add todo bottom sheet
        if (this.showAddSheet) {
          Column() {
            TodoAddSheet({
              categories: this.viewModel.categories,
              onSave: (title: string, _description: string, priority: TodoPriority, categoryId: string, customCategoryName: string) => {
                if (title.trim() !== '') {
                  this.handleTodoSave(title, _description, priority, categoryId, customCategoryName);
                  this.showAddSheet = false;
                }
              },
              onCancel: () => {
                this.showAddSheet = false;
              },
            });
          }
          .borderRadius({ topLeft: 20, topRight: 20 })
          .backgroundColor(this.themeConfig.surfaceColor)
          .backdropBlur(this.themeConfig.glassBlurRadius)
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.3)', offsetY: -4 })
          .position({ left: 0, right: 0, bottom: 0 })
          .transition(
            TransitionEffect.translate({ y: 400 })
              .animation({ duration: 300, curve: Curve.EaseOut })
          );
        }
      }
      .width('100%')
      .height('100%');
    }
    .hideTitleBar(true)
    .onShown(() => {
      this.viewModel.loadData();
    })
    .backgroundColor(this.themeConfig.backgroundColor)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  @Builder
  filterTab(label: string, index: number, filter: TodoFilterType) {
    Text(label)
      .fontSize(14 * this.themeConfig.fontScale)
      .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.activeTab === index ? this.themeConfig.primaryColor : this.themeConfig.textSecondaryColor)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(
        this.activeTab === index
          ? (this.themeConfig.isDarkMode
            ? this.themeConfig.primaryColor + '30'
            : this.themeConfig.primaryColor + '1A')
          : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
      )
      .margin({ right: 10 })
      .onClick(() => {
        this.activeTab = index;
        this.viewModel.setFilter(filter);
      });
  }

  @Builder
  categoryColorDot(color: string) {
    Column()
      .width(20)
      .height(20)
      .borderRadius(10)
      .backgroundColor(color)
      .borderWidth(this.newCategoryColor === color ? 3 : 0)
      .borderColor(
        this.themeConfig.isDarkMode
          ? 'rgba(255,255,255,0.6)'
          : 'rgba(0,0,0,0.3)'
      )
      .margin({ left: 2, right: 2 })
      .onClick(() => {
        this.newCategoryColor = color;
      });
  }

  @Builder
  categoryHeader(categoryId: string) {
    if (categoryId === '__uncategorized__') {
      TodoCategoryHeader({
        categoryName: '未分类',
        categoryColor: '#90A4AE',
        itemCount: this.getTodoCount(categoryId),
      });
    } else {
      TodoCategoryHeader({
        categoryName: this.getCategoryName(categoryId),
        categoryColor: this.getCategoryColor(categoryId),
        itemCount: this.getTodoCount(categoryId),
      });
    }
  }

  private async handleTodoSave(
    title: string,
    description: string,
    priority: TodoPriority,
    categoryId: string,
    customCategoryName: string
  ): Promise<void> {
    let finalCategoryId: string = categoryId;

    // If user typed or selected a category name, materialize it (get or create)
    if (customCategoryName.trim() !== '') {
      const category: TodoCategory = await this.viewModel.getOrCreateCategory(
        customCategoryName.trim(),
        '#4A90D9'
      );
      finalCategoryId = category.id;
    }

    await this.viewModel.createTodo(title, description, priority, finalCategoryId, 0, 0, 0);
  }

  private getCategoryName(categoryId: string): string {
    const cat: TodoCategory | undefined = this.viewModel.findCategoryById(categoryId);
    return cat !== undefined ? cat.name : '未分类';
  }

  private getCategoryColor(categoryId: string): string {
    const cat: TodoCategory | undefined = this.viewModel.findCategoryById(categoryId);
    return cat !== undefined ? cat.colorHex : '#90A4AE';
  }

  private getTodoCount(categoryId: string): number {
    let count: number = 0;
    for (const todo of this.viewModel.filteredTodos) {
      if (categoryId === '__uncategorized__') {
        const found: boolean = this.viewModel.categories.some(
          (c: TodoCategory) => c.id === todo.categoryId
        );
        if (!found) {
          count++;
        }
      } else if (todo.categoryId === categoryId) {
        count++;
      }
    }
    return count;
  }

  private createCategoryDataSource(): CategoryDataSource {
    const categories: string[] = [];
    for (const cat of this.viewModel.categories) {
      categories.push(cat.id);
    }
    categories.push('__uncategorized__');
    return new CategoryDataSource(categories);
  }

  private createTodoDataSource(categoryId: string): TodoDataSource {
    const todos: TodoItem[] = [];
    for (const todo of this.viewModel.filteredTodos) {
      if (categoryId === '__uncategorized__') {
        const found: boolean = this.viewModel.categories.some(
          (c: TodoCategory) => c.id === todo.categoryId
        );
        if (!found) {
          todos.push(todo);
        }
      } else if (todo.categoryId === categoryId) {
        todos.push(todo);
      }
    }
    return new TodoDataSource(todos);
  }
}

class CategoryDataSource implements IDataSource {
  private data: string[];
  private listeners: DataChangeListener[] = [];

  constructor(data: string[]) {
    this.data = data;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): string {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }
}

class TodoDataSource implements IDataSource {
  private data: TodoItem[];
  private listeners: DataChangeListener[] = [];

  constructor(data: TodoItem[]) {
    this.data = data;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): TodoItem {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }
}
