import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Note, NoteSortOrder } from '../model/NoteModel';
import { ThemeConfig } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { NoteRepository } from '../repository/NoteRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { NoteCard } from '../components/business/NoteCard';
import { SearchBar } from '../components/common/SearchBar';
import { EmptyState } from '../components/common/EmptyState';
import { AppConstants, NavDestinationNames } from '../constants/AppConstants';
import { NavParams } from '../utils/NavParams';
import { ICON } from '../utils/IconGlyphs';

@Component
export struct NotesPage {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Consume('themeVM') themeVM: ThemeViewModel;
  @Consume('navStack') navStack: NavPathStack;
  @Consume('isTablet') isTablet: boolean;
  @State viewModel: NotesViewModel = new NotesViewModel(
    new NoteRepository(DatabaseHelper.getInstance().getStore())
  );
  @State searchQuery: string = '';
  @State showFilterMenu: boolean = false;
  @State refreshSignal: number = 0;
  @State viewMode: number = 0; // 0=list, 1=grid (tablet only)

  aboutToAppear(): void {
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
          if (this.refreshSignal >= 0) {
          }

        // ── Header ──
        Row() {
          Text('笔记')
            .fontSize(28 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeConfig.textColor);
          Blank();
          if (this.isTablet) {
            Button() {
              SymbolGlyph(this.viewMode === 0 ? ICON.VIEW_GRID : ICON.VIEW_LIST)
                .fontSize(22).fontColor([this.themeConfig.textColor]);
            }
            .width(40).height(40).borderRadius(20)
            .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CHIP))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CHIP, this.themeConfig.isDarkMode))
            .margin({ right: 8 })
            .onClick(() => { this.viewMode = this.viewMode === 0 ? 1 : 0; });
          }
          Button() {
            SymbolGlyph(ICON.MENU).fontSize(22).fontColor([this.themeConfig.textColor]);
          }
          .width(40).height(40).borderRadius(20)
          .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CHIP))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CHIP, this.themeConfig.isDarkMode))
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => { this.showFilterMenu = !this.showFilterMenu; });
        }
        .width('100%').padding({ left: 20, right: 20, top: 44, bottom: 0 });

        // ── Search ──
        Row() {
          SearchBar({
            placeholder: '搜索笔记...',
            query: $searchQuery,
            onSearch: (value: string) => { this.viewModel.setSearchQuery(value); this.refreshSignal++; },
            onClear: () => { this.viewModel.setSearchQuery(''); this.refreshSignal++; },
          });
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 8 });

        // ── Filter chips ──
        if (this.showFilterMenu) {
          Row() {
            this.filterChip('最新', NoteSortOrder.UPDATED_DESC);
            this.filterChip('最旧', NoteSortOrder.UPDATED_ASC);
            this.filterChip('A-Z', NoteSortOrder.TITLE_ASC);
          }
          .width('100%').padding({ left: 20, right: 20, bottom: 8 });
        }

        // ── Content ──
        if (this.viewModel.isLoading) {
          LoadingProgress().width(40).height(40).color(this.themeConfig.primaryColor).margin({ top: 100 });
        } else if (this.viewModel.filteredNotes.length === 0) {
          EmptyState({
            icon: ICON.EMPTY_NOTES, title: '还没有笔记', subtitle: '点击右下角按钮创建第一条笔记',
          });
        } else if (this.isTablet && this.viewMode === 1) {
          // ═══ Tablet Grid (2 columns) ═══
          Scroll() {
            Column() {
              ForEach(this.getNotePairs(), (pair: Note[], _pi: number) => {
                Row() {
                  ForEach(pair, (note: Note, _ni: number) => {
                    NoteCard({
                      note: note, gridMode: true,
                      onCardClick: () => { this.navigateToDetail(note.id); },
                    })
                    .layoutWeight(1)
                    .margin({ left: _ni === 0 ? 20 : 4, right: _ni === 0 ? 4 : 20 });
                  }, (note: Note) => note.id + 'gc_' + String(note.updatedAt) + '_' + String(this.refreshSignal));
                  if (pair.length === 1) {
                    Column().layoutWeight(1).margin({ left: 4, right: 20 });
                  }
                }
                .width('100%').margin({ bottom: 12 });
              }, (pair: Note[]) => 'pair_' + pair[0].id + '_' + String(pair.length) + '_' + String(this.refreshSignal));
            }
            .width('100%');
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring).width('100%').layoutWeight(1).padding({ top: 4 });
        } else {
          // ═══ Single Column List ═══
          Scroll() {
            Column() {
              ForEach(this.viewModel.filteredNotes, (note: Note, _idx: number) => {
                NoteCard({
                  note: note, gridMode: false,
                  onCardClick: () => { this.navigateToDetail(note.id); },
                })
                .width('100%')
                .margin({ left: 20, right: 20, bottom: 12 });
              }, (note: Note) => note.id + '_' + String(note.updatedAt) + '_' + String(this.refreshSignal));
            }
            .width('100%');
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring).width('100%').layoutWeight(1).padding({ top: 4 });
        }
      }
      .width('100%').height('100%');

      // ── FAB ──
      Button() {
        SymbolGlyph(ICON.PLUS).fontSize(28).fontColor(['#FFFFFF']);
      }
      .width(60).height(60).borderRadius(30)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.FAB))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.FAB, this.themeConfig.isDarkMode))
      .position({ right: 20, bottom: 20 })
      .onClick(() => { this.navigateToDetail(''); });
    }
    .width('100%').height('100%');
    }
    .hideTitleBar(true)
    .onShown(() => { this.refreshNotes(); })
    .backgroundColor(this.themeConfig.backgroundColor)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  @Builder
  filterChip(label: string, sortOrder: NoteSortOrder) {
    Text(label)
      .fontSize(13)
      .fontColor(this.viewModel.currentSortOrder === sortOrder ? '#FFFFFF' : this.themeConfig.textColor)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 }).borderRadius(16)
      .backgroundColor(this.viewModel.currentSortOrder === sortOrder
        ? this.themeConfig.primaryColor
        : Color.Transparent)
      .backdropBlur(
          this.viewModel.currentSortOrder === sortOrder
            ? 0
            : MaterialConstants.getBlur(MaterialConstants.CHIP)
        )
      .margin({ right: 8 })
      .onClick(() => { this.viewModel.setSortOrder(sortOrder); this.refreshNotes(); });
  }

  private getNotePairs(): Note[][] {
    const pairs: Note[][] = [];
    const notes: Note[] = this.viewModel.filteredNotes;
    let i: number = 0;
    while (i < notes.length) {
      const pair: Note[] = [notes[i]];
      i++;
      if (i < notes.length) {
        pair.push(notes[i]);
        i++;
      }
      pairs.push(pair);
    }
    return pairs;
  }

  private navigateToDetail(noteId: string): void {
    NavParams.noteId = noteId;
    this.navStack.pushPathByName('note_detail', {} as Record<string, Object>);
  }
}
