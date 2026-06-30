import { PlayerState, RepeatMode } from '../../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Playback control buttons: shuffle, prev, play/pause, next, repeat.
 * Pattern follows PomodoroControls.ets.
 */
@ComponentV2
export struct MusicControls {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param playerState: PlayerState = PlayerState.IDLE;
  @Param repeatMode: RepeatMode = RepeatMode.REPEAT_ALL;
  @Param shuffleEnabled: boolean = false;
  @Event onPlayPause: () => void = () => {};
  @Event onNext: () => void = () => {};
  @Event onPrevious: () => void = () => {};
  @Event onToggleRepeat: () => void = () => {};
  @Event onToggleShuffle: () => void = () => {};

  build() {
    Row() {
      // Shuffle
      Button() {
        SymbolGlyph(ICON.SHUFFLE)
          .fontSize(20)
          .fontColor(this.shuffleEnabled
            ? [this.themeConfig.primaryColor]
            : [this.themeConfig.textSecondaryColor]);
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onToggleShuffle();
      });

      Blank();

      // Previous
      Button() {
        SymbolGlyph(ICON.PREVIOUS)
          .fontSize(28)
          .fontColor([this.themeConfig.primaryColor]);
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SURFACE))
      .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
      .onClick(() => {
        this.onPrevious();
      });

      Blank().width(8);

      // Play/Pause (larger, FAB-style)
      Button() {
        SymbolGlyph(this.playerState === PlayerState.PLAYING ? ICON.PAUSE : ICON.PLAY)
          .fontSize(32)
          .fontColor([this.themeConfig.primaryColor]);
      }
      .width(72)
      .height(72)
      .borderRadius(36)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.FAB))
      .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.FAB, this.themeConfig.isDarkMode))
      .onClick(() => {
        this.onPlayPause();
      });

      Blank().width(8);

      // Next
      Button() {
        SymbolGlyph(ICON.NEXT)
          .fontSize(28)
          .fontColor([this.themeConfig.primaryColor]);
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SURFACE))
      .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
      .onClick(() => {
        this.onNext();
      });

      Blank();

      // Repeat (with mode indicator)
      Button() {
        SymbolGlyph(this.repeatMode === RepeatMode.REPEAT_ONE ? ICON.REPEAT_ONE : ICON.REPEAT)
          .fontSize(20)
          .fontColor(this.repeatMode !== RepeatMode.OFF
            ? [this.themeConfig.primaryColor]
            : [this.themeConfig.textSecondaryColor]);
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onToggleRepeat();
      });
    }
    .justifyContent(FlexAlign.SpaceEvenly)
    .width('100%')
    .padding({ left: 16, right: 16 });
  }
}
