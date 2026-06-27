import { ThemeConfig } from '../../model/ThemeConfigModel';
import { AppConstants } from '../../constants/AppConstants';

/**
 * Multi-line text editor for note content.
 * Uses internal @State to avoid parent rebuild on every keystroke.
 * Watches initialContent so content loaded asynchronously (e.g. from DB)
 * is displayed even after the component has already appeared.
 */
@Component
export struct NoteEditor {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop @Watch('syncInitialContent') initialContent: string = '';
  @Prop placeholder: string = '开始记录...';
  @State localContent: string = '';
  private isUserEditing: boolean = false;
  onContentChange: (value: string) => void = (_v: string) => {};

  aboutToAppear(): void {
    this.localContent = this.initialContent;
  }

  /**
   * Called by @Watch when the parent updates initialContent (e.g. after async DB load).
   * Only syncs when the user is not actively typing to avoid cursor disruption.
   */
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
