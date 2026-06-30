import { MusicViewModel, getMusicViewModel } from '../viewmodel/MusicViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Track, SubsonicSong, SubsonicAlbum, PlayerState, MusicSource } from '../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { ICON } from '../utils/IconGlyphs';

/**
 * Music page — pure Navidrome streaming browser.
 *
 * No local library tabs.  The page is the Navidrome remote library:
 *   Albums (newest first) → tap album → Songs → tap song → stream.
 *
 * Architecture matches NotesPage pattern:
 *   NavDestination → Stack(Scroll+Column + floating backdropBlur header + FAB)
 */
@ComponentV2
export struct MusicPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('themeVM') themeVM: ThemeViewModel = ThemeViewModel.placeholder;
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Consumer('isTablet') isTablet: boolean = false;

  // ── Playback display state (synced via tickHandler) ──
  @Local displayState: PlayerState = PlayerState.IDLE;
  @Local displayPositionMs: number = 0;
  @Local displayDurationMs: number = 0;

  // ── Navidrome browse state ──
  @Local browseLevel: number = 0;          // 0=albums, 1=songs
  @Local selectedAlbumId: string = '';
  @Local selectedAlbumName: string = '';
  @Local isLoading: boolean = false;
  @Local pageReady: boolean = false;       // true after initial load attempt

  private viewModel: MusicViewModel = getMusicViewModel();

  // ── Lifecycle ──

  aboutToAppear(): void {
    this.viewModel.setTickHandler((posMs: number, durMs: number, state: PlayerState) => {
      this.displayPositionMs = posMs;
      this.displayDurationMs = durMs;
      this.displayState = state;
    });

    // Auto-connect and load albums if Navidrome is configured
    if (this.viewModel.novidromeConfig.enabled
      && this.viewModel.novidromeConfig.serverUrl !== '') {
      this.initNavidrome();
    } else {
      this.pageReady = true;
    }
  }

  aboutToDisappear(): void {
    this.viewModel.setTickHandler(null);
  }

  private async initNavidrome(): Promise<void> {
    this.isLoading = true;
    this.pageReady = false;

    // Ensure we have a connection
    if (!this.viewModel.novidromeConnected) {
      const connected: boolean = await this.viewModel.connectNovidrome();
      if (!connected) {
        this.isLoading = false;
        this.pageReady = true;
        return;
      }
    }

    // Load all albums (newest first)
    await this.viewModel.browseNovidromeAlbums();
    this.isLoading = false;
    this.pageReady = true;
  }

  private async loadAlbumSongs(albumId: string): Promise<void> {
    // isLoading already set by caller (before browseLevel change) to
    // prevent ghosting. We just load data and clear the flag.
    await this.viewModel.browseNovidromeSongs(albumId);
    this.isLoading = false;
  }

  // ── Build ──

  build() {
    NavDestination() {
      Stack() {
        // ═══════════════════════════════════════════════════════════
        // Layer 0: Full-screen scroll content
        // ═══════════════════════════════════════════════════════════
        Scroll() {
          Column() {
            // Spacer clears the floating header
            Blank().height(80);

            // ── Content ──
            if (!this.pageReady) {
              // Initial page load
              Column() {
                Blank().height(80);
                LoadingProgress()
                  .width(40).height(40)
                  .color(this.themeConfig.primaryColor);
                Text('连接 Navidrome...')
                  .fontSize(14 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textSecondaryColor)
                  .margin({ top: 12 });
              }
              .width('100%');
            } else if (!this.viewModel.novidromeConfig.enabled
              || this.viewModel.novidromeConfig.serverUrl === '') {
              // Not configured
              Column() {
                Blank().height(60);
                SymbolGlyph(ICON.STREAM)
                  .fontSize(48)
                  .fontColor([this.themeConfig.textSecondaryColor]);
                Text('Navidrome 未配置')
                  .fontSize(17 * this.themeConfig.fontScale)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeConfig.textColor)
                  .margin({ top: 16 });
                Text('请在设置中配置 Navidrome 服务器连接')
                  .fontSize(13 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textSecondaryColor)
                  .margin({ top: 6 });
              }
              .width('100%');
            } else if (!this.viewModel.novidromeConnected && !this.isLoading) {
              // Connection failed
              Column() {
                Blank().height(60);
                SymbolGlyph(ICON.STREAM)
                  .fontSize(48)
                  .fontColor([this.themeConfig.textSecondaryColor]);
                Text('无法连接到 Navidrome')
                  .fontSize(17 * this.themeConfig.fontScale)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeConfig.textColor)
                  .margin({ top: 16 });
                if (this.viewModel.novidromeError !== '') {
                  Text(this.viewModel.novidromeError)
                    .fontSize(12 * this.themeConfig.fontScale)
                    .fontColor('#E57373')
                    .maxLines(3)
                    .textAlign(TextAlign.Center)
                    .padding({ left: 24, right: 24 })
                    .margin({ top: 8 });
                }
                Button('重试')
                  .fontSize(14)
                  .fontColor(this.themeConfig.primaryColor)
                  .backgroundColor(MaterialConstants.getOverlayColor(
                    MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
                  .borderRadius(8)
                  .padding({ left: 24, right: 24, top: 8, bottom: 8 })
                  .margin({ top: 16 })
                  .onClick(() => {
                    this.initNavidrome();
                  });
              }
              .width('100%');
            } else {
              // Connected — both views stay mounted in a Stack with
              // Visibility switching.  No if/else destroy/create →
              // no layout animation → no ghosting/movement of old window.
              Stack() {
                // Album list layer
                Column() {
                  this.albumListView();
                }
                .width('100%')
                .visibility(this.browseLevel === 0 && !this.isLoading
                  ? Visibility.Visible : Visibility.None);

                // Song list layer
                Column() {
                  this.songListView();
                }
                .width('100%')
                .visibility(this.browseLevel === 1 && !this.isLoading
                  ? Visibility.Visible : Visibility.None);

                // Loading overlay — appears on top during data fetches
                if (this.isLoading) {
                  Column() {
                    Blank().height(60);
                    LoadingProgress()
                      .width(40).height(40)
                      .color(this.themeConfig.primaryColor);
                    Text(this.browseLevel === 0 ? '加载专辑...' : '加载歌曲...')
                      .fontSize(14 * this.themeConfig.fontScale)
                      .fontColor(this.themeConfig.textSecondaryColor)
                      .margin({ top: 12 });
                  }
                  .width('100%');
                }
              }
              .width('100%');
            }

            // Bottom spacer for MiniPlayer clearance
            Blank().height(140);
          }
          .width('100%').justifyContent(FlexAlign.Start);
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring).width('100%').height('100%');

        // ═══════════════════════════════════════════════════════════
        // Layer 1: Floating header
        // ═══════════════════════════════════════════════════════════
        Column() {
          Row() {
            if (this.browseLevel === 1) {
              // Song-list header: back + album name
              SymbolGlyph(ICON.BACK)
                .fontSize(18)
                .fontColor([this.themeConfig.primaryColor])
                .margin({ right: 10 })
                .onClick(() => {
                  // Visibility switch is instant — no ghosting.
                  this.isLoading = true;
                  this.browseLevel = 0;
                  this.selectedAlbumId = '';
                  this.selectedAlbumName = '';
                  this.viewModel.novidromeSongs = [];
                  this.isLoading = false;
                });
              Text(this.selectedAlbumName)
                .fontSize(18 * this.themeConfig.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeConfig.textColor)
                .maxLines(1)
                .layoutWeight(1);
            } else {
              Text('音乐')
                .fontSize(24 * this.themeConfig.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeConfig.textColor);
              Blank();
              // Navidrome connected indicator
              if (this.viewModel.novidromeConnected) {
                SymbolGlyph(ICON.STREAM)
                  .fontSize(16)
                  .fontColor([this.themeConfig.primaryColor]);
                Blank().width(6);
              }
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 2 });

          // Gradient fade below header
          Column()
            .width('100%')
            .height(24)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                [MaterialConstants.getOverlayColor(MaterialConstants.THIN,
                  this.themeConfig.isDarkMode), 0.0],
                [this.themeConfig.isDarkMode
                  ? 'rgba(20,20,20,0.00)' : 'rgba(255,255,255,0.00)', 1.0],
              ],
            });
        }
        .position({ top: 0, left: 0, right: 0 })
        .padding({ top: 30 })
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
        .backgroundColor(MaterialConstants.getOverlayColor(
          MaterialConstants.THIN, this.themeConfig.isDarkMode));

        // ═══════════════════════════════════════════════════════════
        // Layer 2: FAB — open full player
        // ═══════════════════════════════════════════════════════════
        if (this.viewModel.currentTrack !== null) {
          Button() {
            SymbolGlyph(ICON.PLAY)
              .fontSize(28)
              .fontColor([this.themeConfig.primaryColor]);
          }
          .width(60).height(60).borderRadius(30)
          .position({
            right: 20,
            bottom: this.viewModel.isMiniPlayerVisible ? 84 : 20,
          })
          .backdropBlur(MaterialConstants.getBlur(MaterialConstants.FAB))
          .backgroundColor(MaterialConstants.getOverlayColor(
            MaterialConstants.FAB, this.themeConfig.isDarkMode))
          .onClick(() => {
            this.navStack.pushPathByName('music_player', {} as Record<string, Object>);
          });
        }
      }
    }
    .hideTitleBar(true)
    .backgroundColor(MaterialConstants.getOverlayColor(
      MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  // ── Album List ──

  @Builder
  albumListView() {
    Column() {
      // Error banner
      if (this.viewModel.novidromeError !== '') {
        Row() {
          Text(this.viewModel.novidromeError)
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor('#E57373')
            .maxLines(2)
            .layoutWeight(1);
          Button('重试')
            .fontSize(12)
            .fontColor(this.themeConfig.primaryColor)
            .backgroundColor(Color.Transparent)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => {
              this.initNavidrome();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 8 });
      }

      if (this.viewModel.novidromeAlbums.length === 0) {
        Blank().height(40);
        Text('没有找到专辑')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor);
      }

      ForEach(this.viewModel.novidromeAlbums, (album: SubsonicAlbum, _idx: number) => {
        Row() {
          // Album art placeholder + text
          Column() {
            Text(album.name)
              .fontSize(15 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1);
            Row() {
              if (album.artist !== undefined && album.artist !== '') {
                Text(album.artist)
                  .fontSize(12 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textSecondaryColor)
                  .maxLines(1);
              }
              if (album.year > 0) {
                Text(' · ' + String(album.year))
                  .fontSize(12 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textSecondaryColor);
              }
              Text(' · ' + String(album.songCount) + ' 首')
                .fontSize(12 * this.themeConfig.fontScale)
                .fontColor(this.themeConfig.textSecondaryColor);
            }
            .margin({ top: 2 });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          SymbolGlyph(ICON.BACK)
            .fontSize(14)
            .fontColor([this.themeConfig.textSecondaryColor])
            .rotate({ angle: 180 });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .borderRadius(this.themeConfig.borderRadius)
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
        .backgroundColor(MaterialConstants.getOverlayColor(
          MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
        .margin({ left: 10, right: 10, bottom: 8 })
        .onClick(() => {
          // isLoading FIRST — shows loading overlay before level switch,
          // preventing the empty song list from rendering for one frame.
          this.isLoading = true;
          this.selectedAlbumId = album.id;
          this.selectedAlbumName = album.name;
          this.browseLevel = 1;
          this.loadAlbumSongs(album.id);
        });
      }, (album: SubsonicAlbum) => album.id);
    }
    .width('100%');
  }

  // ── Song List ──

  @Builder
  songListView() {
    Column() {
      // Error banner
      if (this.viewModel.novidromeError !== '') {
        Row() {
          Text(this.viewModel.novidromeError)
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor('#E57373')
            .maxLines(2)
            .layoutWeight(1);
          Button('重试')
            .fontSize(12)
            .fontColor(this.themeConfig.primaryColor)
            .backgroundColor(Color.Transparent)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => {
              this.loadAlbumSongs(this.selectedAlbumId);
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 8 });
      }

      // Song count subtitle
      if (this.viewModel.novidromeSongs.length > 0 && !this.isLoading) {
        Text(String(this.viewModel.novidromeSongs.length) + ' 首歌曲')
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .padding({ left: 16, right: 16, top: 4, bottom: 8 });
      }

      if (this.viewModel.novidromeSongs.length === 0 && !this.isLoading) {
        Blank().height(20);
        Text('此专辑中没有歌曲')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor);
      }

      ForEach(this.viewModel.novidromeSongs, (song: SubsonicSong, _idx: number) => {
        Row() {
          // Track number
          Text(String(song.track > 0 ? song.track : _idx + 1))
            .fontSize(13 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .width(28)
            .textAlign(TextAlign.Center);

          // Title + artist
          Column() {
            Text(song.title)
              .fontSize(14 * this.themeConfig.fontScale)
              .fontWeight(this.viewModel.currentTrack !== null
                && this.viewModel.currentTrack.id === song.id
                ? FontWeight.Bold
                : FontWeight.Normal)
              .fontColor(this.viewModel.currentTrack !== null
                && this.viewModel.currentTrack.id === song.id
                ? this.themeConfig.primaryColor
                : this.themeConfig.textColor)
              .maxLines(1);
            Text(song.artist !== undefined ? song.artist : '')
              .fontSize(11 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .maxLines(1)
              .margin({ top: 1 });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 8 });

          // Duration
          Text(this.formatDuration(song.duration))
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor);

          // Now-playing indicator
          if (this.viewModel.currentTrack !== null
            && this.viewModel.currentTrack.id === song.id
            && this.displayState === PlayerState.PLAYING) {
            SymbolGlyph(ICON.STREAM)
              .fontSize(14)
              .fontColor([this.themeConfig.primaryColor])
              .margin({ left: 10 });
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderRadius(this.themeConfig.borderRadius)
        .margin({ left: 10, right: 10, bottom: 4 })
        .onClick(() => {
          // Stream directly — no import needed
          const track: Track = {
            id: song.id,
            title: song.title,
            artist: song.artist !== undefined ? song.artist : 'Unknown Artist',
            album: song.album !== undefined ? song.album : '',
            durationMs: song.duration !== undefined ? song.duration * 1000 : 0,
            fileUri: '',
            albumArtUri: '',
            source: MusicSource.NOVIDROME,
            serverTrackId: song.id,
            dateAdded: Date.now(),
          };
          this.viewModel.playTrack(track);
        });
      }, (song: SubsonicSong) => song.id);
    }
    .width('100%');
  }

  // ── Helpers ──

  private formatDuration(seconds: number): string {
    if (seconds <= 0) {
      return '--:--';
    }
    const mins: number = Math.floor(seconds / 60);
    const secs: number = seconds % 60;
    const secStr: string = secs < 10 ? '0' + String(secs) : String(secs);
    return String(mins) + ':' + secStr;
  }
}
