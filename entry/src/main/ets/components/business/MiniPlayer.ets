import { Track, PlayerState } from '../../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { MusicViewModel, getMusicViewModel } from '../../viewmodel/MusicViewModel';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Persistent mini player bar visible across all tabs when music is playing.
 * Self-contained: subscribes to MusicViewModel directly via miniPlayerHandler,
 * so it updates independently of which page is visible.
 *
 * Rendered in Index.ets as a global overlay above the tab bar.
 */
@ComponentV2
export struct MiniPlayer {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Local visible: boolean = false;
  @Local playerState: PlayerState = PlayerState.IDLE;
  @Local positionMs: number = 0;
  @Local durationMs: number = 0;
  @Local updateSignal: number = 0;
  @Event onTap: () => void = () => {};

  private viewModel: MusicViewModel = getMusicViewModel();

  aboutToAppear(): void {
    this.viewModel.setMiniPlayerHandler((posMs: number, durMs: number, state: PlayerState, visible: boolean) => {
      this.positionMs = posMs;
      this.durationMs = durMs;
      this.playerState = state;
      this.visible = visible;
      this.updateSignal++;
    });
  }

  aboutToDisappear(): void {
    this.viewModel.setMiniPlayerHandler(null);
  }

  build() {
    if (this.visible && this.viewModel.currentTrack !== null) {
      Column() {
        // Thin progress bar at top
        Progress({
          value: this.getProgressPercent(),
          total: 100,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(2)
          .color(this.themeConfig.primaryColor)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode));

        Row() {
          // Album art
          if (this.viewModel.currentTrack.albumArtUri !== '') {
            Image(this.viewModel.currentTrack.albumArtUri)
              .width(40)
              .height(40)
              .borderRadius(6)
              .objectFit(ImageFit.Cover)
              .onClick(() => {
                this.onTap();
              });
          } else {
            Column() {
              SymbolGlyph(ICON.MUSIC)
                .fontSize(18)
                .fontColor([this.themeConfig.textSecondaryColor]);
            }
            .width(40)
            .height(40)
            .borderRadius(6)
            .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onTap();
            });
          }

          // Title + Artist (tappable)
          Column() {
            Text(this.viewModel.currentTrack.title !== '' ? this.viewModel.currentTrack.title : '未知曲目')
              .fontSize(14 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Text(this.viewModel.currentTrack.artist !== '' ? this.viewModel.currentTrack.artist : '未知艺术家')
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })
          .onClick(() => {
            this.onTap();
          });

          // Play/Pause
          Button() {
            SymbolGlyph(this.playerState === PlayerState.PLAYING ? ICON.PAUSE : ICON.PLAY)
              .fontSize(22)
              .fontColor([this.themeConfig.primaryColor]);
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.viewModel.playPause();
          });

          // Next
          Button() {
            SymbolGlyph(ICON.NEXT)
              .fontSize(20)
              .fontColor([this.themeConfig.primaryColor]);
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(Color.Transparent)
          .margin({ left: 4 })
          .onClick(() => {
            this.viewModel.playNext();
          });
        }
        .width('100%')
        .height(56)
        .padding({ left: 12, right: 8 });
      }
      .width('100%')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THICK))
      .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THICK, this.themeConfig.isDarkMode))
      .transition(TransitionEffect.OPACITY.animation({ duration: 250 }));
    }
  }

  private getProgressPercent(): number {
    if (this.durationMs <= 0) {
      return 0;
    }
    return (this.positionMs / this.durationMs) * 100;
  }
}
