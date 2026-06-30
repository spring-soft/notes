import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Note, NoteSortOrder } from '../model/NoteModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { NoteRepository } from '../repository/NoteRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { NoteCard } from '../components/business/NoteCard';
import { SearchBar } from '../components/common/SearchBar';
import { EmptyState } from '../components/common/EmptyState';
import { AppConstants, NavDestinationNames } from '../constants/AppConstants';
import { NavParams } from '../utils/NavParams';
import { ICON } from '../utils/IconGlyphs';

@ComponentV2
export struct NotesPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('themeVM') themeVM: ThemeViewModel = ThemeViewModel.placeholder;
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Consumer('isTablet') isTablet: boolean = false;
  @Local viewModel: NotesViewModel = new NotesViewModel(
    new NoteRepository(DatabaseHelper.getInstance().getStore())
  );
  @Local searchQuery: string = '';
  @Local showFilterMenu: boolean = false;
  @Local refreshSignal: number = 0;
  @Local viewMode: number = 0; // 0=list, 1=grid (tablet only)

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
        // ═══════════════════════════════════════════════════════════
        // Layer 0: Full-screen scroll content — notes start from top
        // ═══════════════════════════════════════════════════════════
        if (this.viewModel.isLoading) {
          Column() {
            LoadingProgress()
              .width(48).height(48)
              .color(this.themeConfig.primaryColor);
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.Center);
        } else if (this.viewModel.filteredNotes.length === 0) {
          Column() {
            // Spacer for floating header clearance
            Blank().height(this.showFilterMenu ? 120 : 84);
            EmptyState({
              icon: ICON.EMPTY_NOTES,
              title: '还没有笔记',
              subtitle: '点击右下角按钮创建第一条笔记',
            });
          }
          .width('100%').height('100%');
        } else if (this.isTablet && this.viewMode === 1) {
          // Tablet Grid: 3-column
          Scroll() {
            Column() {
              // Spacer — clears the floating header
              Blank().height(this.showFilterMenu ? 108 : 72);
              ForEach(this.getNoteTriplets(), (triplet: Note[], _ti: number) => {
                Row() {
                  ForEach(triplet, (note: Note, _ni: number) => {
                    Column() {
                      NoteCard({
                        note: note, gridMode: true,
                        onCardClick: () => { this.navigateToDetail(note.id); },
                      })
                      .width('100%').height('100%');
                    }
                    .layoutWeight(1).aspectRatio(1)
                    .margin({ left: _ni === 0 ? 10 : 4, right: _ni === 2 ? 10 : 4 });
                  }, (note: Note) => 'g3_' + note.id + '_' + String(this.refreshSignal));
                  if (triplet.length < 3) {
                    Column().layoutWeight(1).aspectRatio(1);
                  }
                  if (triplet.length < 2) {
                    Column().layoutWeight(1).aspectRatio(1);
                  }
                }
                .width('100%').margin({ bottom: 6 });
              }, (triplet: Note[]) => 't3_' + String(triplet[0].id) + '_' + String(this.refreshSignal));
            }
            .width('100%').justifyContent(FlexAlign.Start);
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring).width('100%').height('100%');
        } else {
          // Phone + Tablet List: single-column
          Scroll() {
            Column() {
              // Spacer — clears the floating header
              Blank().height(this.showFilterMenu ? 108 : 72);
              ForEach(this.viewModel.filteredNotes, (note: Note, _idx: number) => {
                NoteCard({
                  note: note, gridMode: false,
                  onCardClick: () => { this.navigateToDetail(note.id); },
                })
                .width('100%')
                .margin({ left: 10, right: 10, bottom: 6 });
              }, (note: Note) => note.id + '_s1_' + String(note.updatedAt) + '_' + String(this.refreshSignal));
              // Bottom spacer for FAB clearance
              Blank().height(80);
            }
            .width('100%').justifyContent(FlexAlign.Start);
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring).width('100%').height('100%');
        }

        // ═══════════════════════════════════════════════════════════
        // Layer 1: Floating header — translucent, overlays on scroll
        // ═══════════════════════════════════════════════════════════
        Column() {
          // Title row
          Row() {
            Text('笔记')
              .fontSize(24 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor);
            Blank();
            if (this.isTablet) {
              Button() {
                SymbolGlyph(this.viewMode === 0 ? ICON.VIEW_GRID : ICON.VIEW_LIST)
                  .fontSize(20).fontColor([this.themeConfig.textColor]);
              }
              .width(36).height(36).borderRadius(18)
              .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CHIP))
              .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CHIP, this.themeConfig.isDarkMode))
              .margin({ right: 6 })
              .onClick(() => { this.viewMode = this.viewMode === 0 ? 1 : 0; });
            }
            Button() {
              SymbolGlyph(ICON.MENU).fontSize(20).fontColor([this.themeConfig.textColor]);
            }
            .width(36).height(36).borderRadius(18)
            .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CHIP))
            .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CHIP, this.themeConfig.isDarkMode))
            .hitTestBehavior(HitTestMode.Block)
            .onClick(() => { this.showFilterMenu = !this.showFilterMenu; });
          }
          .width('100%').padding({ left: 20, right: 20, top: 4, bottom: 2 });

          // Search
          Row() {
            SearchBar({
              placeholder: '搜索笔记...',
              query: this.searchQuery,
              onQueryChange: (value: string) => { this.searchQuery = value; },
              onSearch: (value: string) => { this.viewModel.setSearchQuery(value); this.refreshSignal++; },
              onClear: () => { this.viewModel.setSearchQuery(''); this.refreshSignal++; },
            });
          }
          .width('100%').padding({ left: 20, right: 20, top: 0, bottom: 0 });

          // Filter chips (conditional)
          if (this.showFilterMenu) {
            Row() {
              this.filterChip('最新', NoteSortOrder.UPDATED_DESC);
              this.filterChip('最旧', NoteSortOrder.UPDATED_ASC);
              this.filterChip('A-Z', NoteSortOrder.TITLE_ASC);
            }
            .width('100%').padding({ left: 20, right: 20, bottom: 6 });
          }

          // Gradient fade below floating header
          Column()
            .width('100%')
            .height(24)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                [MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode), 0.0],
                [this.themeConfig.isDarkMode ? 'rgba(20,20,20,0.00)' : 'rgba(255,255,255,0.00)', 1.0],
              ],
            });
        }
        .position({ top: 0, left: 0, right: 0 })
        .padding({ top: 30 }) // status bar clearance
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode));

        // ═══════════════════════════════════════════════════════════
        // Layer 2: FAB
        // ═══════════════════════════════════════════════════════════
        Button() {
          SymbolGlyph(ICON.PLUS).fontSize(28).fontColor([this.themeConfig.primaryColor]);
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
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
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

  private getNoteTriplets(): Note[][] {
    const triplets: Note[][] = [];
    const notes: Note[] = this.viewModel.filteredNotes;
    let i: number = 0;
    while (i < notes.length) {
      const triplet: Note[] = [];
      for (let j: number = 0; j < 3 && i < notes.length; j++) {
        triplet.push(notes[i]);
        i++;
      }
      triplets.push(triplet);
    }
    return triplets;
  }

  private navigateToDetail(noteId: string): void {
    NavParams.noteId = noteId;
    // animated: true — enables the default Navigation push transition
    // (slide-from-right) which provides smooth visual continuity.
    this.navStack.pushPathByName('note_detail',
      {} as Record<string, Object>, true);
  }
}
