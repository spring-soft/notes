import { MusicViewModel, getMusicViewModel } from '../viewmodel/MusicViewModel';
import { PlayerState } from '../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { MusicControls } from '../components/business/MusicControls';
import { ICON } from '../utils/IconGlyphs';

/**
 * Full-screen now playing page. Pushed onto the Music tab's NavPathStack
 * when the user taps the MiniPlayer or a track.
 *
 * Pattern follows PomodoroPage.ets:
 *   NavDestination → Stack(Scroll+Column + pinned backdropBlur header)
 */
@ComponentV2
export struct MusicPlayerPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Local displayState: PlayerState = PlayerState.IDLE;
  @Local displayPositionMs: number = 0;
  @Local displayDurationMs: number = 0;
  @Local stateSignal: number = 0;

  private viewModel: MusicViewModel = getMusicViewModel();

  aboutToAppear(): void {
    this.viewModel.setTickHandler((posMs: number, durMs: number, state: PlayerState) => {
      this.displayPositionMs = posMs;
      this.displayDurationMs = durMs;
      this.displayState = state;
      this.stateSignal++;
    });
  }

  aboutToDisappear(): void {
    this.viewModel.setTickHandler(null);
  }

  build() {
    NavDestination() {
      Stack() {
        // ═══════════════════════════════════════════════════════════
        // Layer 0: Scroll content — album art, info, controls
        // ═══════════════════════════════════════════════════════════
        Scroll() {
          Column() {
            // Clear the pinned header
            Blank().height(76);

            // Album art — large centered image with shadow effect
            Stack() {
              if (this.viewModel.currentTrack !== null && this.viewModel.currentTrack.albumArtUri !== '') {
                Image(this.viewModel.currentTrack.albumArtUri)
                  .width(260)
                  .height(260)
                  .borderRadius(16)
                  .objectFit(ImageFit.Cover);
              } else {
                Column() {
                  SymbolGlyph(ICON.MUSIC)
                    .fontSize(72)
                    .fontColor([this.themeConfig.textSecondaryColor]);
                }
                .width(260)
                .height(260)
                .borderRadius(16)
                .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center);
              }
            }
            .width(280)
            .height(280)
            .margin({ top: 20, bottom: 28 });

            // Track info
            Text(this.viewModel.currentTrack !== null ? this.viewModel.currentTrack.title : '')
              .fontSize(22 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .width('90%');

            Text(this.viewModel.currentTrack !== null ? this.viewModel.currentTrack.artist : '')
              .fontSize(16 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .maxLines(1)
              .margin({ top: 6 });

            if (this.viewModel.currentTrack !== null && this.viewModel.currentTrack.album !== '') {
              Text(this.viewModel.currentTrack.album)
                .fontSize(14 * this.themeConfig.fontScale)
                .fontColor(this.themeConfig.textSecondaryColor)
                .opacity(0.7)
                .margin({ top: 2 });
            }

            // Progress bar with time labels
            Column() {
              Slider({
                value: this.getSeekPercent(),
                min: 0,
                max: 100,
                step: 0.1,
              })
                .width('100%')
                .trackColor(this.themeConfig.primaryColor + '30')
                .selectedColor(this.themeConfig.primaryColor)
                .onChange((value: number) => {
                  const seekMs: number = (value / 100) * this.displayDurationMs;
                  this.viewModel.seekTo(seekMs);
                });

              Row() {
                Text(this.formatMs(this.displayPositionMs))
                  .fontSize(12 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textSecondaryColor)
                  .opacity(0.6);

                Blank();

                Text(this.formatMs(this.displayDurationMs))
                  .fontSize(12 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textSecondaryColor)
                  .opacity(0.6);
              }
              .width('100%');
            }
            .padding({ left: 24, right: 24, top: 28 });

            // Music controls (play/pause/prev/next/repeat/shuffle)
            Column() {
              MusicControls({
                playerState: this.displayState,
                repeatMode: this.viewModel.repeatMode,
                shuffleEnabled: this.viewModel.shuffleEnabled,
                onPlayPause: () => {
                  this.viewModel.playPause();
                },
                onNext: () => {
                  this.viewModel.playNext();
                },
                onPrevious: () => {
                  this.viewModel.playPrevious();
                },
                onToggleRepeat: () => {
                  this.viewModel.toggleRepeatMode();
                },
                onToggleShuffle: () => {
                  this.viewModel.toggleShuffle();
                },
              });
            }
            .width('100%')
            .padding({ top: 28, bottom: 20 });

            // Volume slider
            Row() {
              const isMuted: boolean = this.viewModel.volume === 0;
              SymbolGlyph(isMuted ? ICON.VOLUME_MUTE : ICON.VOLUME)
                .fontSize(18)
                .fontColor([this.themeConfig.textSecondaryColor]);

              Slider({
                value: this.viewModel.volume * 100,
                min: 0,
                max: 100,
                step: 1,
              })
                .width('100%')
                .trackColor(this.themeConfig.primaryColor + '30')
                .selectedColor(this.themeConfig.primaryColor)
                .onChange((value: number) => {
                  this.viewModel.setVolume(value / 100);
                });

              Text(String(Math.round(this.viewModel.volume * 100)) + '%')
                .fontSize(12 * this.themeConfig.fontScale)
                .fontColor(this.themeConfig.textSecondaryColor)
                .width(40)
                .textAlign(TextAlign.End);
            }
            .width('100%')
            .padding({ left: 24, right: 24, bottom: 8 });

            Blank().height(40);
          }
          .width('100%')
          .justifyContent(FlexAlign.Start);
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height('100%');

        // ═══════════════════════════════════════════════════════════
        // Layer 1: Pinned header with back button
        // ═══════════════════════════════════════════════════════════
        Column() {
          Row() {
            Button() {
              SymbolGlyph(ICON.BACK)
                .fontSize(20)
                .fontColor([this.themeConfig.textColor]);
            }
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.navStack.pop();
            });

            Text('正在播放')
              .fontSize(18 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor)
              .margin({ left: 8 });
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4 });
        }
        .position({ top: 0, left: 0, right: 0 })
        .padding({ top: 30 })
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode));
      }
    }
    .hideTitleBar(true)
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode));
  }

  private getSeekPercent(): number {
    if (this.displayDurationMs <= 0) {
      return 0;
    }
    return (this.displayPositionMs / this.displayDurationMs) * 100;
  }

  private formatMs(ms: number): string {
    if (ms <= 0) {
      return '00:00';
    }
    const totalSec: number = Math.floor(ms / 1000);
    const min: number = Math.floor(totalSec / 60);
    const sec: number = totalSec % 60;
    let result: string = '';
    if (min < 10) {
      result += '0';
    }
    result += String(min) + ':';
    if (sec < 10) {
      result += '0';
    }
    result += String(sec);
    return result;
  }
}
