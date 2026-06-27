import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { AppConstants } from '../../constants/AppConstants';

/**
 * Multi-line text editor for note content.
 * Uses internal @Local to avoid parent rebuild on every keystroke.
 * Monitors initialContent so content loaded asynchronously (e.g. from DB)
 * is displayed even after the component has already appeared.
 */
@ComponentV2
export struct NoteEditor {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param initialContent: string = '';
  @Param placeholder: string = '开始记录...';
  @Local localContent: string = '';
  private isUserEditing: boolean = false;
  @Event onContentChange: (value: string) => void = (_v: string) => {};

  aboutToAppear(): void {
    this.localContent = this.initialContent;
  }

  /**
   * Called by @Monitor when the parent updates initialContent (e.g. after async DB load).
   * Only syncs when the user is not actively typing to avoid cursor disruption.
   */
  @Monitor('initialContent')
  syncInitialContent(): void {
    if (!this.isUserEditing) {
      this.localContent = this.initialContent;
    }
  }

  build() {
    TextArea({ text: this.localContent, placeholder: this.placeholder })
      .fontSize(16 * this.themeConfig.fontScale)
      .fontColor(this.themeConfig.textColor)
      .placeholderColor(this.themeConfig.textSecondaryColor)
      .maxLength(AppConstants.MAX_NOTE_CONTENT_LENGTH)
      .backgroundColor(Color.Transparent)
      .borderWidth(0)
      .borderRadius(0)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .height('100%')
      .onChange((value: string) => {
        this.isUserEditing = true;
        this.localContent = value;
        this.onContentChange(value);
      });
  }
}
