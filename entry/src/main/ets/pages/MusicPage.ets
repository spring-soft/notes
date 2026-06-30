import { MusicViewModel, getMusicViewModel } from '../viewmodel/MusicViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Track, Playlist, PlayerState, MusicPageTab, MusicSource, SubsonicSong, SubsonicArtist, SubsonicAlbum } from '../model/MusicModel';
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
  // Navidrome browse state
  @Local isBrowsingNovidrome: boolean = false;
  @Local novidromeBrowseLevel: number = -1;
  @Local novidromeSelectedArtistId: string = '';
  @Local novidromeSelectedArtistName: string = '';
  @Local novidromeSelectedAlbumId: string = '';
  @Local novidromeSelectedAlbumName: string = '';
  @Local novidromeIsBrowsing: boolean = false;
  @Local novidromeImportingId: string = '';
  @Local novidromeImportingAlbum: boolean = false;

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
    // Auto-enter Navidrome browse if configured and local library is empty
    if (this.viewModel.novidromeConfig.enabled
      && this.viewModel.novidromeConfig.serverUrl !== ''
      && this.viewModel.tracks.length === 0) {
      this.enterNovidromeBrowse();
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

              // Navidrome banner — shown when connected and not browsing
              if (this.viewModel.novidromeConnected && !this.isBrowsingNovidrome
                && this.viewModel.currentTab === MusicPageTab.TRACKS) {
                Row() {
                  SymbolGlyph(ICON.STREAM)
                    .fontSize(16)
                    .fontColor([this.themeConfig.primaryColor]);
                  Text('Navidrome 已连接')
                    .fontSize(14 * this.themeConfig.fontScale)
                    .fontColor(this.themeConfig.textColor)
                    .margin({ left: 8 })
                    .layoutWeight(1);
                  Button('浏览音乐')
                    .fontSize(13)
                    .fontColor(this.themeConfig.primaryColor)
                    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
                    .borderRadius(8)
                    .padding({ left: 14, right: 14, top: 5, bottom: 5 })
                    .onClick(() => {
                      this.enterNovidromeBrowse();
                    });
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 6, bottom: 10 });
              }

              // Content based on currentTab
              if (this.isBrowsingNovidrome) {
                this.novidromeBrowseView();
              } else if (this.viewModel.tracks.length === 0) {
                Column() {
                  Blank().height(40);
                  if (this.viewModel.novidromeConfig.enabled && this.viewModel.novidromeConfig.serverUrl !== '') {
                    EmptyState({
                      icon: ICON.STREAM,
                      title: '曲库为空',
                      subtitle: '点击下方按钮浏览 Navidrome 远程音乐',
                    });
                    Button('浏览 Navidrome')
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .backgroundColor(this.themeConfig.primaryColor)
                      .borderRadius(20)
                      .padding({ left: 24, right: 24, top: 10, bottom: 10 })
                      .margin({ top: 12 })
                      .onClick(() => {
                        this.enterNovidromeBrowse();
                      });
                  } else {
                    EmptyState({
                      icon: ICON.MUSIC,
                      title: '还没有音乐',
                      subtitle: '添加本地音乐或连接Navidrome服务',
                    });
                  }
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
                      onItemClick: () => {
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
    ForEach(this.getUniqueAlbums(), (album: string, _idx: number) => {
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
            onItemClick: () => {
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
    ForEach(this.getUniqueArtists(), (artist: string, _idx: number) => {
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
            onItemClick: () => {
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
            Text(String(playlist.trackCount !== undefined ? playlist.trackCount : 0) + ' 首')
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

  // ── Navidrome Browse ──

  private async enterNovidromeBrowse(): Promise<void> {
    this.isBrowsingNovidrome = true;
    this.novidromeBrowseLevel = 0;
    this.novidromeSelectedArtistId = '';
    this.novidromeSelectedArtistName = '';
    this.novidromeSelectedAlbumId = '';
    this.novidromeSelectedAlbumName = '';

    // Auto-connect if not already connected
    if (!this.viewModel.novidromeConnected) {
      this.novidromeIsBrowsing = true;
      const connected: boolean = await this.viewModel.connectNovidrome();
      if (!connected) {
        this.novidromeIsBrowsing = false;
        return;
      }
    }

    this.novidromeIsBrowsing = true;
    await this.viewModel.browseNovidromeArtists();
    this.novidromeIsBrowsing = false;
  }

  private async loadNovidromeAlbums(artistId: string): Promise<void> {
    this.novidromeIsBrowsing = true;
    await this.viewModel.browseNovidromeAlbums(artistId);
    this.novidromeIsBrowsing = false;
  }

  private async loadNovidromeSongs(albumId: string): Promise<void> {
    this.novidromeIsBrowsing = true;
    await this.viewModel.browseNovidromeSongs(albumId);
    this.novidromeIsBrowsing = false;
  }

  private async importNovidromeSong(song: SubsonicSong): Promise<void> {
    this.novidromeImportingId = song.id;
    await this.viewModel.importNovidromeTrack(song);
    this.novidromeImportingId = '';
  }

  private async importNovidromeAlbumAll(): Promise<void> {
    this.novidromeImportingAlbum = true;
    await this.viewModel.importNovidromeAlbum(this.novidromeSelectedAlbumId);
    this.novidromeImportingAlbum = false;
  }

  // ── Navidrome Browse Views ──

  @Builder
  novidromeBrowseView() {
    // Not configured
    if (!this.viewModel.novidromeConfig.enabled || this.viewModel.novidromeConfig.serverUrl === '') {
      Column() {
        Blank().height(60);
        EmptyState({
          icon: ICON.STREAM,
          title: 'Navidrome 未配置',
          subtitle: '请先在设置中配置 Navidrome 连接',
        });
      }
      .width('100%');
    } else if (this.novidromeIsBrowsing) {
      // Loading
      Column() {
        Blank().height(60);
        LoadingProgress()
          .width(40).height(40)
          .color(this.themeConfig.primaryColor);
        Text('加载中...')
          .fontSize(14)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 12 });
      }
      .width('100%');
    } else if (!this.viewModel.novidromeConnected) {
      // Connection failed
      Column() {
        Blank().height(60);
        EmptyState({
          icon: ICON.STREAM,
          title: '无法连接到 Navidrome',
          subtitle: '请检查服务器地址和网络连接',
        });
        Button('重试')
          .fontSize(14)
          .fontColor(this.themeConfig.primaryColor)
          .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
          .borderRadius(8)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .margin({ top: 16 })
          .onClick(() => {
            this.enterNovidromeBrowse();
          });
      }
      .width('100%');
    } else if (this.novidromeBrowseLevel === 0) {
      // Level 0: Artists
      this.novidromeArtistList();
    } else if (this.novidromeBrowseLevel === 1) {
      // Level 1: Albums
      this.novidromeAlbumList();
    } else if (this.novidromeBrowseLevel === 2) {
      // Level 2: Songs
      this.novidromeSongList();
    }
  }

  @Builder
  novidromeArtistList() {
    Column() {
      // Exit browse button
      Row() {
        SymbolGlyph(ICON.BACK)
          .fontSize(16)
          .fontColor([this.themeConfig.primaryColor])
          .margin({ right: 8 })
          .onClick(() => {
            this.isBrowsingNovidrome = false;
          });
        Text('返回曲库')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 });

      if (this.viewModel.novidromeArtists.length === 0) {
        Blank().height(40);
        Text('没有找到艺术家')
          .fontSize(14)
          .fontColor(this.themeConfig.textSecondaryColor);
      }
      ForEach(this.viewModel.novidromeArtists, (artist: SubsonicArtist, _idx: number) => {
        Row() {
          Column() {
            Text(artist.name)
              .fontSize(15 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1);
            Text(String(artist.albumCount) + ' 张专辑')
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
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
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
        .margin({ left: 10, right: 10, bottom: 8 })
        .onClick(() => {
          this.novidromeIsBrowsing = true;
          this.novidromeSelectedArtistId = artist.id;
          this.novidromeSelectedArtistName = artist.name;
          this.novidromeBrowseLevel = 1;
          this.loadNovidromeAlbums(artist.id);
        });
      }, (artist: SubsonicArtist) => artist.id);
    }
    .width('100%');
  }

  @Builder
  novidromeAlbumList() {
    Column() {
      // Back navigation row
      Row() {
        SymbolGlyph(ICON.BACK)
          .fontSize(16)
          .fontColor([this.themeConfig.primaryColor])
          .margin({ right: 8 })
          .onClick(() => {
            this.novidromeBrowseLevel = 0;
          });
        Text(this.novidromeSelectedArtistName)
          .fontSize(16 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.textColor)
          .maxLines(1)
          .layoutWeight(1);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 });

      if (this.viewModel.novidromeAlbums.length === 0) {
        Blank().height(20);
        Text('没有找到专辑')
          .fontSize(14)
          .fontColor(this.themeConfig.textSecondaryColor);
      }
      ForEach(this.viewModel.novidromeAlbums, (album: SubsonicAlbum, _idx: number) => {
        Row() {
          Column() {
            Text(album.name)
              .fontSize(15 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1);
            Text(String(album.songCount) + ' 首 · ' + String(album.year > 0 ? album.year : ''))
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
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
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
        .margin({ left: 10, right: 10, bottom: 8 })
        .onClick(() => {
          this.novidromeIsBrowsing = true;
          this.novidromeSelectedAlbumId = album.id;
          this.novidromeSelectedAlbumName = album.name;
          this.novidromeBrowseLevel = 2;
          this.loadNovidromeSongs(album.id);
        });
      }, (album: SubsonicAlbum) => album.id);
    }
    .width('100%');
  }

  @Builder
  novidromeSongList() {
    Column() {
      // Back navigation row
      Row() {
        SymbolGlyph(ICON.BACK)
          .fontSize(16)
          .fontColor([this.themeConfig.primaryColor])
          .margin({ right: 8 })
          .onClick(() => {
            this.novidromeBrowseLevel = 1;
          });
        Column() {
          Text(this.novidromeSelectedAlbumName)
            .fontSize(16 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeConfig.textColor)
            .maxLines(1);
          if (this.viewModel.novidromeSongs.length > 0) {
            Text(String(this.viewModel.novidromeSongs.length) + ' 首')
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 1 });
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        // Import all button
        if (this.viewModel.novidromeSongs.length > 0 && !this.novidromeImportingAlbum) {
          Button('导入全部')
            .fontSize(13)
            .fontColor(this.themeConfig.primaryColor)
            .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
            .borderRadius(8)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .onClick(() => {
              this.importNovidromeAlbumAll();
            });
        }
        if (this.novidromeImportingAlbum) {
          LoadingProgress()
            .width(28).height(28)
            .color(this.themeConfig.primaryColor);
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 });

      if (this.viewModel.novidromeSongs.length === 0 && !this.novidromeIsBrowsing) {
        Blank().height(20);
        Text('没有找到歌曲')
          .fontSize(14)
          .fontColor(this.themeConfig.textSecondaryColor);
      }
      ForEach(this.viewModel.novidromeSongs, (song: SubsonicSong, _idx: number) => {
        Row() {
          Column() {
            Text(song.title)
              .fontSize(14 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1);
            Text(song.artist + ' · ' + this.formatDuration(song.duration))
              .fontSize(11 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 2 })
              .maxLines(1);
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          // Import button or spinner
          if (this.novidromeImportingId === song.id) {
            LoadingProgress()
              .width(24).height(24)
              .color(this.themeConfig.primaryColor);
          } else {
            Button('导入')
              .fontSize(12)
              .fontColor(this.themeConfig.primaryColor)
              .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
              .borderRadius(7)
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .onClick(() => {
                this.importNovidromeSong(song);
              });
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderRadius(this.themeConfig.borderRadius)
        .margin({ left: 10, right: 10, bottom: 6 })
        .onClick(() => {
          // Play directly (stream without importing)
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

      // Bottom spacer for import-all button clearance
      Blank().height(20);
    }
    .width('100%');
  }

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
