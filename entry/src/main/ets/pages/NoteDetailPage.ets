import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Note, NOTE_CATEGORIES } from '../model/NoteModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { NoteRepository } from '../repository/NoteRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { NoteEditor } from '../components/business/NoteEditor';
import { ColorPickerComponent } from '../components/business/ColorPicker';
import { GlassDialog } from '../components/common/GlassDialog';
import { AppConstants } from '../constants/AppConstants';
import { NavParams } from '../utils/NavParams';
import { ICON } from '../utils/IconGlyphs';
import { now } from '../utils/DateUtils';
import { generateId } from '../utils/IdGenerator';

/**
 * Note create / edit / view page.
 * Hosted as a NavDestination inside a parent Navigation component.
 */
@ComponentV2
export struct NoteDetailPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Local viewModel: NotesViewModel = new NotesViewModel(
    new NoteRepository(DatabaseHelper.getInstance().getStore())
  );
  @Local noteId: string = '';
  @Local title: string = '';
  @Local content: string = '';
  @Local colorTag: string = '#4A90D9';
  @Local categoryId: string = '未分类';
  @Local customCategoryName: string = '';
  @Local isNew: boolean = true;
  @Local showDeleteDialog: boolean = false;
  @Local showColorPicker: boolean = false;
  @Local hasChanges: boolean = false;
  @Local isSaving: boolean = false;
  @Local isDeleting: boolean = false;
  private loadedNote: Note | null = null;
  private dialogController: CustomDialogController | null = null;

  aboutToAppear(): void {
    // Create dialog controller after @Consume themeConfig is resolved
    this.dialogController = new CustomDialogController({
      builder: GlassDialog({
        themeConfig: this.themeConfig,
        title: '删除笔记',
        message: '确定要删除这条笔记吗？此操作不可撤销。',
        confirmLabel: '删除',
        onConfirm: () => {
          // GlassDialog will close itself via controller.close() after
          // onConfirm returns.  We just set the flag so @Watch triggers
          // the actual delete after the dialog close animation starts.
          this.isDeleting = true;
        },
      }),
      autoCancel: true,
      customStyle: true,
      alignment: DialogAlignment.Center,
    });

    // Read noteId from shared NavParams (set by NotesPage before pushing)
    const id: string = NavParams.noteId;
    NavParams.noteId = '';
    if (id !== '') {
      this.noteId = id;
      this.isNew = false;
      this.loadNote(id);
    }
  }

  private async loadNote(id: string): Promise<void> {
    const note: Note | null = await this.viewModel.loadNoteById(id);
    if (note !== null) {
      this.loadedNote = note;
      this.title = note.title;
      this.content = note.content;
      this.colorTag = note.colorTag;
      this.categoryId = note.categoryId;
      // Only show custom category name if it's not a preset
      const isPreset: boolean = this.isPresetCategory(note.categoryId);
      if (!isPreset && note.categoryId !== '' && note.categoryId !== '未分类') {
        this.customCategoryName = note.categoryId;
      }
    }
  }

  private async saveNote(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      // Determine final category: custom name takes precedence over preset
      const finalCategory: string = this.customCategoryName.trim() !== ''
        ? this.customCategoryName.trim()
        : this.categoryId;

      if (this.isNew) {
        await this.viewModel.createNote(this.title, this.content, this.colorTag, finalCategory);
      } else {
        const existing: Note | null = this.loadedNote;
        if (existing !== null) {
          const updated: Note = {
            id: existing.id,
            title: this.title,
            content: this.content,
            colorTag: this.colorTag,
            createdAt: existing.createdAt,
            updatedAt: now(),
            isPinned: existing.isPinned,
            categoryId: finalCategory,
          };
          await this.viewModel.updateNote(updated);
        }
      }
      this.hasChanges = false;
      NavParams.needsNotesRefresh = true;
      // Trigger NotesPage refresh BEFORE popping so the list is already
      // up-to-date when the user returns (onShown is unreliable).
      NavParams.triggerNotesRefresh();
      this.navStack.pop(false);
    } catch (err) {
      console.error('NoteDetailPage.saveNote: save failed - ' + String(err));
    } finally {
      this.isSaving = false;
    }
  }

  /**
   * Called by @Monitor when the delete dialog is confirmed and isDeleting
   * becomes true.  Performs the actual DB delete and stack pop after the
   * dialog close animation has started (avoiding overlapping animations).
   */
  @Monitor('isDeleting')
  handleDelete(): void {
    if (this.isDeleting) {
      this.deleteNote();
    }
  }

  private async deleteNote(): Promise<void> {
    if (!this.isNew) {
      try {
        await this.viewModel.deleteNote(this.noteId);
      } catch (err) {
        console.error('NoteDetailPage.deleteNote: delete failed - ' + String(err));
        return;
      }
    }
    NavParams.needsNotesRefresh = true;
    NavParams.triggerNotesRefresh();
    this.navStack.pop(false);
  }

  private isPresetCategory(category: string): boolean {
    for (const preset of NOTE_CATEGORIES) {
      if (preset === category) {
        return true;
      }
    }
    return false;
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
        // Top bar — immersive blur surface
        Row() {
          Button() {
            SymbolGlyph(ICON.BACK)
              .fontSize(28)
              .fontColor([this.themeConfig.textColor]);
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CHIP))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CHIP, this.themeConfig.isDarkMode))
          .onClick(() => {
            this.navStack.pop(false);
          });

          Blank();

          // Color tag button
          Button() {
            Circle()
              .width(20)
              .height(20)
              .fill(this.colorTag);
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backdropBlur(MaterialConstants.getBlur(MaterialConstants.CHIP))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.CHIP, this.themeConfig.isDarkMode))
          .margin({ right: 8 })
          .onClick(() => {
            this.showColorPicker = !this.showColorPicker;
          });

          // Save button
          Button(this.isSaving ? '保存中...' : '保存')
            .fontSize(15 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeConfig.primaryColor)
            .borderRadius(this.themeConfig.borderRadius)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .enabled(!this.isSaving)
            .opacity(this.isSaving ? 0.6 : 1.0)
            .onClick(() => {
              this.saveNote();
            });

          if (!this.isNew) {
            // Delete button
            Button() {
              SymbolGlyph(ICON.DELETE)
                .fontSize(20)
                .fontColor(['#F44336']);
            }
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor('rgba(244, 67, 54, 0.1)')
            .margin({ left: 8 })
            .onClick(() => {
              const ctrl: CustomDialogController | null = this.dialogController;
              if (ctrl !== null) {
                ctrl.open();
              }
            });
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 44, bottom: 8 })
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode));

        // Gradient fade below header
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

        // Color picker dropdown
        if (this.showColorPicker) {
          Column() {
            ColorPickerComponent({
              selectedColor: this.colorTag,
              onColorSelect: (color: string) => {
                this.colorTag = color;
                this.hasChanges = true;
                this.showColorPicker = false;
              },
            });
          }
          .padding(16)
          .animation({ duration: 200, curve: Curve.EaseInOut });
        }

        // Title input
        TextInput({ text: this.title, placeholder: '标题' })
          .fontSize(24 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor)
          .placeholderColor(this.themeConfig.textSecondaryColor)
          .backgroundColor(Color.Transparent)
          .borderWidth(0)
          .maxLength(AppConstants.MAX_NOTE_TITLE_LENGTH)
          .padding({ left: 20, right: 20, top: 12, bottom: 0 })
          .onChange((value: string) => {
            this.title = value;
            this.hasChanges = true;
          });

        // Category section — custom input + preset chips
        Column() {
          // Custom category input
          TextInput({ text: this.customCategoryName, placeholder: '自定义分组（可选）' })
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textColor)
            .placeholderColor(this.themeConfig.textSecondaryColor)
            .backgroundColor(Color.Transparent)
            .borderWidth(0)
            .padding({ left: 20, right: 20, top: 0, bottom: 4 })
            .onChange((value: string) => {
              this.customCategoryName = value;
              if (value.trim() !== '') {
                this.categoryId = value.trim();
                this.hasChanges = true;
              }
            });

          // Preset category chips
          Row() {
            Text('预设')
              .fontSize(13 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ right: 8 });

            Scroll() {
              Row() {
                ForEach(NOTE_CATEGORIES, (cat: string, _idx: number) => {
                  Text(cat)
                    .fontSize(13 * this.themeConfig.fontScale)
                    .fontWeight(this.categoryId === cat ? FontWeight.Medium : FontWeight.Normal)
                    .fontColor(this.categoryId === cat ? '#FFFFFF' : this.themeConfig.textColor)
                    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                    .borderRadius(14)
                    .backgroundColor(
                      this.categoryId === cat
                        ? this.themeConfig.primaryColor
                        : Color.Transparent
                    )
                    .backdropBlur(
          this.categoryId === cat
            ? 0
            : MaterialConstants.getBlur(MaterialConstants.CHIP)
        )
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.categoryId = cat;
                      this.customCategoryName = '';
                      this.hasChanges = true;
                    });
                }, (cat: string) => cat);
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .layoutWeight(1);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 8 });
        }
        .width('100%');

        // Content editor
        Column() {
          NoteEditor({
            initialContent: this.content,
            placeholder: '开始记录...',
            onContentChange: (value: string) => {
              this.content = value;
              this.hasChanges = true;
            },
          });
        }
        .layoutWeight(1)
        .padding({ left: 20, right: 20, top: 8 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);

        // Deleting overlay — shown while the delete DB operation completes
        if (this.isDeleting) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color(this.themeConfig.primaryColor);
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('rgba(0, 0, 0, 0.35)');
        }
      }
      .width('100%')
      .height('100%');
    }
    .hideTitleBar(true)
;
  }
}
