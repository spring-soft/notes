import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Note, NoteSortOrder } from '../model/NoteModel';
import { ThemeConfig } from '../model/ThemeConfigModel';
import { NoteRepository } from '../repository/NoteRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { NoteCard } from '../components/business/NoteCard';
import { SearchBar } from '../components/common/SearchBar';
import { EmptyState } from '../components/common/EmptyState';
import { AppConstants, NavDestinationNames } from '../constants/AppConstants';
import { NavParams } from '../utils/NavParams';
import { ICON } from '../utils/IconGlyphs';

/**
 * Notes list page with search, filter, and grid/list layout.
 */
@Component
export struct NotesPage {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Consume('themeVM') themeVM: ThemeViewModel;
  @Consume('navStack') navStack: NavPathStack;
  @State viewModel: NotesViewModel = new NotesViewModel(
    new NoteRepository(DatabaseHelper.getInstance().getStore())
  );
  @State searchQuery: string = '';
  @State showFilterMenu: boolean = false;
  @State refreshSignal: number = 0;

  aboutToAppear(): void {
    // Register a callback so NoteDetailPage can trigger an immediate refresh
    // before popping — this is more reliable than NavDestination.onShown.
    NavParams.triggerNotesRefresh = () => {
      this.refreshNotes();
    };
    this.refreshNotes();
  }

  private async refreshNotes(): Promise<void> {
    await this.viewModel.loadNotes();
    this.refreshSignal++;
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // Read signal to trigger rebuild on data changes
          if (this.refreshSignal >= 0) {
          }

        // Header row
        Row() {
          Text('笔记')
            .fontSize(28 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeConfig.textColor);

          Blank();

          // Sort/filter button
          Button() {
            Text(ICON.MENU)
              .fontSize(22)
              .fontColor(this.themeConfig.textColor);
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(
            this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.08)'
              : 'rgba(0, 0, 0, 0.06)'
          )
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.showFilterMenu = !this.showFilterMenu;
          });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 44, bottom: 0 });

        // Search bar
        Row() {
          SearchBar({
            placeholder: '搜索笔记...',
            query: $searchQuery,
            onSearch: (value: string) => {
              this.viewModel.setSearchQuery(value);
              this.refreshSignal++;
            },
            onClear: () => {
              this.viewModel.setSearchQuery('');
              this.refreshSignal++;
            },
          });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 8 });

        // Filter chips
        if (this.showFilterMenu) {
          Row() {
            this.filterChip('最新', NoteSortOrder.UPDATED_DESC);
            this.filterChip('最旧', NoteSortOrder.UPDATED_ASC);
            this.filterChip('A-Z', NoteSortOrder.TITLE_ASC);
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 8 })
          .animation({ duration: 200, curve: Curve.EaseInOut });
        }

        // Notes list — uses Scroll+Column instead of List+ListItem
        // because List+ForEach has rendering bugs in some HarmonyOS
        // versions where only the first child renders.
        if (this.viewModel.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.themeConfig.primaryColor)
            .margin({ top: 100 });
        } else if (this.viewModel.filteredNotes.length === 0) {
          EmptyState({
            icon: ICON.EMPTY_NOTES,
            title: '还没有笔记',
            subtitle: '点击右下角按钮创建第一条笔记',
          });
        } else {
          Scroll() {
            Column() {
              ForEach(this.viewModel.filteredNotes, (note: Note, _idx: number) => {
                Column() {
                  NoteCard({
                    note: note,
                    onCardClick: () => {
                      this.navigateToDetail(note.id);
                    },
                  });
                }
                .width('100%')
                .padding({ left: 20, right: 20, bottom: 12 });
              }, (note: Note) => note.id + '_' + String(note.updatedAt) + '_' + String(this.refreshSignal));
            }
            .width('100%');
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .layoutWeight(1)
          .padding({ top: 4 });
        }
      }
      .width('100%')
      .height('100%');

      // FAB for new note
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
          this.navigateToDetail('');
        });
      }
      .position({ right: 20, bottom: 20 });
    }
    .width('100%')
    .height('100%');
    }
    .hideTitleBar(true)
    .onShown(() => {
      this.refreshNotes();
    })
    .backgroundColor(this.themeConfig.backgroundColor)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  @Builder
  categoryGroupHeader(category: string) {
    Row() {
      Text(category)
        .fontSize(13 * this.themeConfig.fontScale)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeConfig.textSecondaryColor)
        .textCase(TextCase.UpperCase);
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 8, bottom: 6 })
    .backgroundColor(this.themeConfig.backgroundColor);
  }

  @Builder
  filterChip(label: string, sortOrder: NoteSortOrder) {
    Text(label)
      .fontSize(13)
      .fontColor(this.viewModel.currentSortOrder === sortOrder ? '#FFFFFF' : this.themeConfig.textColor)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(
        this.viewModel.currentSortOrder === sortOrder
          ? this.themeConfig.primaryColor
          : (this.themeConfig.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)')
      )
      .margin({ right: 8 })
      .onClick(() => {
        this.viewModel.setSortOrder(sortOrder);
        this.refreshNotes();
      });
  }

  private navigateToDetail(noteId: string): void {
    NavParams.noteId = noteId;
    const emptyParams: Record<string, Object> = {};
    this.navStack.pushPathByName('note_detail', emptyParams);
  }
}

