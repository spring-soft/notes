import { MusicViewModel, getMusicViewModel } from '../viewmodel/MusicViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Track, Playlist, PlayerState, MusicPageTab } from '../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { MusicTrackItem } from '../components/business/MusicTrackItem';
import { EmptyState } from '../components/common/EmptyState';
import { ICON } from '../utils/IconGlyphs';

/**
 * Main music tab page — track list, library browser, search.
 * Pattern follows NotesPage.ets exactly:
 *   NavDestination → Stack(Scroll+Column + pinned backdropBlur header + FAB)
 */
@ComponentV2
export struct MusicPage {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Consumer('themeVM') themeVM: ThemeViewModel = ThemeViewModel.placeholder;
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Consumer('isTablet') isTablet: boolean = false;
  @Local displayState: PlayerState = PlayerState.IDLE;
  @Local displayPositionMs: number = 0;
  @Local displayDurationMs: number = 0;
  @Local searchQuery: string = '';
  @Local isSearching: boolean = false;

  private viewModel: MusicViewModel = getMusicViewModel();

  aboutToAppear(): void {
    this.viewModel.setTickHandler((posMs: number, durMs: number, state: PlayerState) => {
      this.displayPositionMs = posMs;
      this.displayDurationMs = durMs;
      this.displayState = state;
    });
    if (this.viewModel.tracks.length === 0) {
      this.viewModel.loadTracks();
    }
  }

  aboutToDisappear(): void {
    this.viewModel.setTickHandler(null);
  }

  build() {
    NavDestination() {
      Stack() {
        // ═══════════════════════════════════════════════════════════
        // Layer 0: Full-screen scroll content
        // ═══════════════════════════════════════════════════════════
        if (this.viewModel.isLoadingTracks) {
          Column() {
            LoadingProgress()
              .width(48).height(48)
              .color(this.themeConfig.primaryColor);
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.Center);
        } else {
          Scroll() {
            Column() {
              // Spacer clears the floating header
              Blank().height(this.isSearching ? 116 : 80);

              // Sub-tab chips: TRACKS | ALBUMS | ARTISTS | PLAYLISTS | SEARCH
              Row() {
                this.tabChip('全部', MusicPageTab.TRACKS);
                this.tabChip('专辑', MusicPageTab.ALBUMS);
                this.tabChip('艺术家', MusicPageTab.ARTISTS);
                this.tabChip('歌单', MusicPageTab.PLAYLISTS);
                this.tabChip('搜索', MusicPageTab.SEARCH);
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 4, bottom: 8 });

              // Search bar (shown when SEARCH tab is active)
              if (this.viewModel.currentTab === MusicPageTab.SEARCH) {
                Row() {
                  TextInput({ text: this.searchQuery, placeholder: '搜索音乐...' })
                    .fontSize(14)
                    .fontColor(this.themeConfig.textColor)
                    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
                    .borderRadius(20)
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .layoutWeight(1)
                    .onChange((value: string) => {
                      this.searchQuery = value;
                    });
                  Button('搜索')
                    .fontSize(13)
                    .fontColor(this.themeConfig.primaryColor)
                    .backgroundColor(Color.Transparent)
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.viewModel.searchTracks(this.searchQuery);
                    });
                }
                .width('100%').padding({ left: 16, right: 16, bottom: 8 });
              }

              // Content based on currentTab
              if (this.viewModel.tracks.length === 0) {
                Column() {
                  Blank().height(40);
                  EmptyState({
                    icon: ICON.MUSIC,
                    title: '还没有音乐',
                    subtitle: '添加本地音乐或连接Navidrome服务',
                  });
                }
                .width('100%');
              } else {
                // Track list
                if (this.viewModel.currentTab === MusicPageTab.TRACKS
                  || this.viewModel.currentTab === MusicPageTab.SEARCH) {
                  ForEach(this.viewModel.tracks, (track: Track, index: number) => {
                    MusicTrackItem({
                      track: track,
                      isPlaying: this.viewModel.currentTrack !== null
                        && this.viewModel.currentTrack.id === track.id
                        && this.displayState === PlayerState.PLAYING,
                      index: index + 1,
                      onClick: () => {
                        this.viewModel.playTrack(track);
                      },
                      onMore: () => {
                        // TODO: show context menu (add to playlist, delete)
                      },
                    })
                      .width('100%')
                      .margin({ left: 10, right: 10, bottom: 6 });
                  }, (track: Track) => track.id);
                } else if (this.viewModel.currentTab === MusicPageTab.ALBUMS) {
                  // Albums view — simplified group by album name
                  this.albumGroupView();
                } else if (this.viewModel.currentTab === MusicPageTab.ARTISTS) {
                  // Artists view — simplified group by artist name
                  this.artistGroupView();
                } else if (this.viewModel.currentTab === MusicPageTab.PLAYLISTS) {
                  // Playlists view
                  this.playlistView();
                }
              }

              // Bottom spacer for MiniPlayer and FAB clearance
              Blank().height(140);
            }
            .width('100%').justifyContent(FlexAlign.Start);
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring).width('100%').height('100%');
        }

        // ═══════════════════════════════════════════════════════════
        // Layer 1: Floating header
        // ═══════════════════════════════════════════════════════════
        Column() {
          Row() {
            Text('音乐')
              .fontSize(24 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor);
            Blank();
            // Navidrome connection status
            if (this.viewModel.novidromeConnected) {
              SymbolGlyph(ICON.STREAM)
                .fontSize(16)
                .fontColor([this.themeConfig.primaryColor]);
              Blank().width(6);
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
                [MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode), 0.0],
                [this.themeConfig.isDarkMode ? 'rgba(20,20,20,0.00)' : 'rgba(255,255,255,0.00)', 1.0],
              ],
            });
        }
        .position({ top: 0, left: 0, right: 0 })
        .padding({ top: 30 })
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THIN))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THIN, this.themeConfig.isDarkMode));

        // ═══════════════════════════════════════════════════════════
        // Layer 2: FAB — add music / connect Navidrome
        // ═══════════════════════════════════════════════════════════
        Button() {
          SymbolGlyph(ICON.PLUS)
            .fontSize(28)
            .fontColor([this.themeConfig.primaryColor]);
        }
        .width(60).height(60).borderRadius(30)
        .position({ right: 20, bottom: this.viewModel.isMiniPlayerVisible ? 84 : 20 })
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.FAB))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.FAB, this.themeConfig.isDarkMode))
        .onClick(() => {
          this.openFullPlayer();
        });
      }
    }
    .hideTitleBar(true)
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  // ── Sub-tab Chips ──

  @Builder
  tabChip(label: string, tab: MusicPageTab) {
    Text(label)
      .fontSize(13 * this.themeConfig.fontScale)
      .fontWeight(this.viewModel.currentTab === tab ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.viewModel.currentTab === tab
        ? this.themeConfig.primaryColor
        : this.themeConfig.textSecondaryColor)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .borderRadius(14)
      .backgroundColor(this.viewModel.currentTab === tab
        ? this.themeConfig.primaryColor + '20'
        : Color.Transparent)
      .margin({ right: 8 })
      .animation({ duration: 200, curve: Curve.EaseInOut })
      .onClick(() => {
        this.viewModel.currentTab = tab;
      });
  }

  // ── Album Group View ──

  @Builder
  albumGroupView() {
    const albums: string[] = this.getUniqueAlbums();
    ForEach(albums, (album: string, _idx: number) => {
      Column() {
        Text(album !== '' ? album : '未知专辑')
          .fontSize(16 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .padding({ left: 16, top: 12, bottom: 6 });
        ForEach(this.getTracksByAlbum(album), (track: Track, _j: number) => {
          MusicTrackItem({
            track: track,
            isPlaying: this.viewModel.currentTrack !== null
              && this.viewModel.currentTrack.id === track.id
              && this.displayState === PlayerState.PLAYING,
            index: _j + 1,
            onClick: () => {
              this.viewModel.playTrack(track);
            },
          })
            .width('100%')
            .margin({ left: 10, right: 10, bottom: 4 });
        }, (track: Track) => track.id);
      }
      .width('100%')
      .margin({ bottom: 12 });
    }, (album: string) => album);
  }

  // ── Artist Group View ──

  @Builder
  artistGroupView() {
    const artists: string[] = this.getUniqueArtists();
    ForEach(artists, (artist: string, _idx: number) => {
      Column() {
        Text(artist !== '' ? artist : '未知艺术家')
          .fontSize(16 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .padding({ left: 16, top: 12, bottom: 6 });
        ForEach(this.getTracksByArtist(artist), (track: Track, _j: number) => {
          MusicTrackItem({
            track: track,
            isPlaying: this.viewModel.currentTrack !== null
              && this.viewModel.currentTrack.id === track.id
              && this.displayState === PlayerState.PLAYING,
            index: _j + 1,
            onClick: () => {
              this.viewModel.playTrack(track);
            },
          })
            .width('100%')
            .margin({ left: 10, right: 10, bottom: 4 });
        }, (track: Track) => track.id);
      }
      .width('100%')
      .margin({ bottom: 12 });
    }, (artist: string) => artist);
  }

  // ── Playlist View ──

  @Builder
  playlistView() {
    ForEach(this.viewModel.playlists, (playlist: Playlist, _idx: number) => {
      Column() {
        Row() {
          SymbolGlyph(ICON.MUSIC_LIST)
            .fontSize(20)
            .fontColor([this.themeConfig.primaryColor]);
          Column() {
            Text(playlist.name)
              .fontSize(15 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1);
            const count: number = playlist.trackCount !== undefined ? playlist.trackCount : 0;
            Text(String(count) + ' 首')
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 2 });
          }
          .margin({ left: 12 })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .borderRadius(this.themeConfig.borderRadius)
        .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
        .onClick(() => {
          this.viewModel.playPlaylist(playlist.id);
        });
      }
      .width('100%')
      .padding({ left: 10, right: 10, bottom: 6 });
    }, (playlist: Playlist) => playlist.id);
  }

  // ── Helpers ──

  private openFullPlayer(): void {
    this.navStack.pushPathByName('music_player', {} as Record<string, Object>);
  }

  private getUniqueAlbums(): string[] {
    const seen: Set<string> = new Set();
    const albums: string[] = [];
    for (let i: number = 0; i < this.viewModel.tracks.length; i++) {
      const album: string = this.viewModel.tracks[i].album;
      if (!seen.has(album)) {
        seen.add(album);
        albums.push(album);
      }
    }
    return albums;
  }

  private getUniqueArtists(): string[] {
    const seen: Set<string> = new Set();
    const artists: string[] = [];
    for (let i: number = 0; i < this.viewModel.tracks.length; i++) {
      const artist: string = this.viewModel.tracks[i].artist;
      if (!seen.has(artist)) {
        seen.add(artist);
        artists.push(artist);
      }
    }
    return artists;
  }

  private getTracksByAlbum(album: string): Track[] {
    const result: Track[] = [];
    for (let i: number = 0; i < this.viewModel.tracks.length; i++) {
      if (this.viewModel.tracks[i].album === album) {
        result.push(this.viewModel.tracks[i]);
      }
    }
    return result;
  }

  private getTracksByArtist(artist: string): Track[] {
    const result: Track[] = [];
    for (let i: number = 0; i < this.viewModel.tracks.length; i++) {
      if (this.viewModel.tracks[i].artist === artist) {
        result.push(this.viewModel.tracks[i]);
      }
    }
    return result;
  }
}
