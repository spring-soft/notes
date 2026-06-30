import { MusicViewModel, getMusicViewModel } from '../viewmodel/MusicViewModel';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { Track, SubsonicSong, SubsonicAlbum, SubsonicArtist, Playlist, PlayerState, MusicSource } from '../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../model/ThemeConfigModel';
import { MaterialConstants } from '../constants/MaterialConstants';
import { ICON } from '../utils/IconGlyphs';
import { MusicRepository } from '../repository/MusicRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';

/**
 * Music page — pure Navidrome streaming browser with multi-tab browsing.
 *
 * Four browse modes:
 *   全部歌曲 — flat list of all Navidrome songs, tap to play.
 *   歌手     — artist list → albums → songs.
 *   专辑     — album list (newest first) → songs.
 *   歌单     — local playlists (including ❤️ 收藏 favorites).
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

  // ── Browse state ──
  // browseTab:  0=全部歌曲  1=歌手  2=专辑  3=歌单
  @Local browseTab: number = 2;
  // browseLevel: 0=top-level list, 1=drill-down (albums for artist), 2=songs
  @Local browseLevel: number = 0;
  @Local selectedArtistId: string = '';
  @Local selectedArtistName: string = '';
  @Local selectedAlbumId: string = '';
  @Local selectedAlbumName: string = '';
  @Local selectedPlaylistId: string = '';
  @Local selectedPlaylistName: string = '';
  @Local isLoading: boolean = false;
  @Local pageReady: boolean = false;
  @Local favoriteSignal: number = 0; // incremented after toggle to force re-render

  // ── Custom playlist dialogs ──
  @Local showCreateSheet: boolean = false;
  @Local newPlaylistName: string = '';
  @Local showAddSheet: boolean = false;
  @Local addSheetSongId: string = '';
  @Local addSheetSongTitle: string = '';
  @Local showDeleteConfirm: boolean = false;
  @Local deletePlaylistId: string = '';
  @Local deletePlaylistName: string = '';

  private viewModel: MusicViewModel = getMusicViewModel();

  // ── Lifecycle ──

  aboutToAppear(): void {
    this.viewModel.setTickHandler((posMs: number, durMs: number, state: PlayerState) => {
      this.displayPositionMs = posMs;
      this.displayDurationMs = durMs;
      this.displayState = state;
    });

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

    if (!this.viewModel.novidromeConnected) {
      const connected: boolean = await this.viewModel.connectNovidrome();
      if (!connected) {
        this.isLoading = false;
        this.pageReady = true;
        return;
      }
    }

    // Load default tab content (albums)
    await this.viewModel.browseNovidromeAlbums();
    this.isLoading = false;
    this.pageReady = true;
  }

  // ── Tab-specific data loaders ──

  private async switchTab(tab: number): Promise<void> {
    if (tab === this.browseTab) {
      return;
    }
    this.isLoading = true;
    this.browseTab = tab;
    this.browseLevel = 0;
    this.selectedArtistId = '';
    this.selectedAlbumId = '';
    this.selectedPlaylistId = '';

    if (tab === 0) {
      // All songs — expensive, show loading
      await this.viewModel.browseNovidromeAllSongs();
    } else if (tab === 1) {
      await this.viewModel.browseNovidromeArtists();
    } else if (tab === 2) {
      await this.viewModel.browseNovidromeAlbums();
    } else if (tab === 3) {
      // Playlists — already loaded in ViewModel, just refresh
      await this.viewModel.loadPlaylists();
    } else {
      // Favorites (tab 4)
      await this.viewModel.loadFavoriteTracks();
    }
    this.isLoading = false;
  }

  private async loadAlbumSongs(albumId: string): Promise<void> {
    await this.viewModel.browseNovidromeSongs(albumId);
    this.isLoading = false;
  }

  // ── Header helpers ──

  private getHeaderTitle(): string {
    if (this.browseLevel >= 1) {
      if (this.selectedAlbumName !== '') {
        return this.selectedAlbumName;
      }
      if (this.selectedArtistName !== '') {
        return this.selectedArtistName;
      }
      if (this.selectedPlaylistName !== '') {
        return this.selectedPlaylistName;
      }
    }
    return '音乐';
  }

  private isBrowseLevelTop(): boolean {
    return this.browseLevel === 0;
  }

  private goBack(): void {
    this.isLoading = true;
    if (this.browseLevel === 2) {
      // Go from songs → album list (for artist tab)
      this.browseLevel = 1;
      this.viewModel.novidromeSongs = [];
      this.isLoading = false;
    } else if (this.browseLevel === 1) {
      this.browseLevel = 0;
      this.selectedAlbumId = '';
      this.selectedAlbumName = '';
      this.selectedArtistId = '';
      this.selectedArtistName = '';
      this.selectedPlaylistId = '';
      this.selectedPlaylistName = '';
      this.viewModel.novidromeSongs = [];
      this.isLoading = false;
    }
  }

  // ── Build ──

  build() {
    NavDestination() {
      Stack() {
        // ═══════════════════════════════════════════════════════════
        // Layer 0: Full-screen scrollable content
        // ═══════════════════════════════════════════════════════════
        Scroll() {
          Column() {
            // Spacer clears the floating header + tab chips
            Blank().height(this.isBrowseLevelTop() ? 138 : 80);

            // ── Content ──
            if (!this.pageReady) {
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
                  .onClick(() => { this.initNavidrome(); });
              }
              .width('100%');
            } else {
              // Connected — content based on browseTab + browseLevel
              this.contentArea();
            }

            // Bottom spacer for MiniPlayer clearance
            Blank().height(140);
          }
          .width('100%').justifyContent(FlexAlign.Start);
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring).width('100%').height('100%');

        // ═══════════════════════════════════════════════════════════
        // Layer 1: Floating header (title + tab chips + gradient)
        // ═══════════════════════════════════════════════════════════
        Column() {
          // Title row
          Row() {
            if (!this.isBrowseLevelTop()) {
              SymbolGlyph(ICON.BACK)
                .fontSize(18)
                .fontColor([this.themeConfig.primaryColor])
                .margin({ right: 10 })
                .onClick(() => { this.goBack(); });
            }
            Text(this.getHeaderTitle())
              .fontSize(this.isBrowseLevelTop() ? 24 : 18 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1)
              .layoutWeight(1);
            if (this.isBrowseLevelTop()) {
              if (this.viewModel.novidromeConnected) {
                SymbolGlyph(ICON.STREAM)
                  .fontSize(16)
                  .fontColor([this.themeConfig.primaryColor]);
                Blank().width(6);
              }
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 0 });

          // Tab chips (only visible at top level)
          if (this.isBrowseLevelTop()) {
            Row() {
              this.tabChip('全部歌曲', 0);
              this.tabChip('歌手', 1);
              this.tabChip('专辑', 2);
              this.tabChip('歌单', 3);
              this.tabChip('收藏', 4, ICON.HEART_FILL);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 6, bottom: 4 });
          }

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
        // Layer 2: Playback error banner
        // Only shown when the player is actively in ERROR state AND
        // there is a non-empty error message — avoids stale errors
        // appearing as a red bar during normal playback.
        // ═══════════════════════════════════════════════════════════
        if (this.displayState === PlayerState.ERROR
          && this.viewModel.playbackError !== '') {
          Row() {
            Text(this.viewModel.playbackError)
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.isDarkMode ? '#FFCDD2' : '#B71C1C')
              .maxLines(2)
              .layoutWeight(1);
            Button() {
              SymbolGlyph(ICON.CLOSE)
                .fontSize(14)
                .fontColor([this.themeConfig.isDarkMode ? '#FFCDD2' : '#B71C1C']);
            }
              .backgroundColor(Color.Transparent)
              .width(32).height(32)
              .onClick(() => { this.viewModel.playbackError = ''; });
          }
          .width('100%')
          .padding({ left: 16, right: 8, top: 8, bottom: 8 })
          .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
          .backgroundColor(MaterialConstants.getOverlayColor(
            MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
          .position({ left: 0, right: 0, bottom: 0 })
          .zIndex(99);
        }

        // ═══════════════════════════════════════════════════════════
        // Layer 3: FAB — open full player (reflects playback state)
        // ═══════════════════════════════════════════════════════════
        if (this.viewModel.currentTrack !== null) {
          Button() {
            SymbolGlyph(this.displayState === PlayerState.PLAYING
              ? ICON.MUSIC_LIST : ICON.PLAY)
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
            this.navStack.pushPathByName('music_player',
              {} as Record<string, Object>, false);
          });
        }

        // ═══════════════════════════════════════════════════════════
        // Layer 4: Overlay dialogs (create playlist, add-to-playlist,
        // delete confirmation)
        // ═══════════════════════════════════════════════════════════

        // ── Create playlist dialog ──
        if (this.showCreateSheet) {
          this.createPlaylistOverlay();
        }

        // ── Add to playlist sheet ──
        if (this.showAddSheet) {
          this.addToPlaylistOverlay();
        }

        // ── Delete playlist confirmation ──
        if (this.showDeleteConfirm) {
          this.deletePlaylistOverlay();
        }
      }
    }
    .hideTitleBar(true)
    .backgroundColor(MaterialConstants.getOverlayColor(
      MaterialConstants.ULTRA_THIN, this.themeConfig.isDarkMode))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }

  // ── Tab Chip ──

  @Builder
  tabChip(label: string, tabIndex: number, icon?: Resource) {
    Row() {
      if (icon !== undefined) {
        SymbolGlyph(icon)
          .fontSize(13)
          .fontColor(this.browseTab === tabIndex
            ? ['#FFFFFF']
            : [this.themeConfig.textSecondaryColor])
          .margin({ right: 4 });
      }
      Text(label)
        .fontSize(13 * this.themeConfig.fontScale)
        .fontWeight(this.browseTab === tabIndex ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.browseTab === tabIndex
          ? '#FFFFFF'
          : this.themeConfig.textSecondaryColor);
    }
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .borderRadius(16)
    .backgroundColor(this.browseTab === tabIndex
      ? this.themeConfig.primaryColor
      : Color.Transparent)
    .backdropBlur(this.browseTab === tabIndex
      ? 0
      : MaterialConstants.getBlur(MaterialConstants.CHIP))
    .margin({ right: 8 })
    .onClick(() => { this.switchTab(tabIndex); });
  }

  // ── Content Area ──

  @Builder
  contentArea() {
    // Stack both levels simultaneously — visibility toggle avoids DOM
    // destroy/create ghosting; opacity animation provides smooth crossfade.
    // hitTestBehavior prevents clicks on the hidden layer.
    Stack() {
      // Level 0 — Top-level lists (varies by tab)
      Column() {
        this.topLevelContent();
      }
      .width('100%')
      .opacity(this.browseLevel === 0 && !this.isLoading ? 1 : 0)
      .hitTestBehavior(this.browseLevel === 0
        ? HitTestMode.Default : HitTestMode.None)
      .animation({ duration: 200, curve: Curve.EaseInOut });

      // Level 1/2 — Song list (shared across tabs, uses novidromeSongs)
      Column() {
        this.songListContent();
      }
      .width('100%')
      .opacity(this.browseLevel >= 1 && !this.isLoading ? 1 : 0)
      .hitTestBehavior(this.browseLevel >= 1
        ? HitTestMode.Default : HitTestMode.None)
      .animation({ duration: 200, curve: Curve.EaseInOut });

      // Loading overlay
      if (this.isLoading) {
        Column() {
          Blank().height(60);
          LoadingProgress()
            .width(40).height(40)
            .color(this.themeConfig.primaryColor);
          Text(this.browseLevel === 0 ? '加载中...' : '加载歌曲...')
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .margin({ top: 12 });
        }
        .width('100%');
      }
    }
    .width('100%');
  }

  // ── Top-Level Content (level=0, varies by browseTab) ──

  @Builder
  topLevelContent() {
    if (this.browseTab === 0) {
      // 全部歌曲
      this.allSongsSection();
    } else if (this.browseTab === 1) {
      // 歌手
      this.artistsSection();
    } else if (this.browseTab === 2) {
      // 专辑
      this.albumsSection();
    } else if (this.browseTab === 3) {
      // 歌单
      this.playlistsSection();
    } else {
      // 收藏
      this.favoritesSection();
    }
  }

  // ── 全部歌曲 Section ──

  @Builder
  allSongsSection() {
    Column() {
      // Error banner
      if (this.viewModel.novidromeError !== '') {
        this.errorBanner(() => { this.switchTab(0); });
      }

      if (this.viewModel.novidromeAllSongs.length === 0 && !this.isLoading) {
        Blank().height(40);
        Text('没有找到歌曲')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor);
      }

      Text(String(this.viewModel.novidromeAllSongs.length) + ' 首歌曲')
        .fontSize(12 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textSecondaryColor)
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
        .visibility(this.viewModel.novidromeAllSongs.length > 0
          ? Visibility.Visible : Visibility.None);

      ForEach(this.viewModel.novidromeAllSongs, (song: SubsonicSong, idx: number) => {
        this.songRow(song, idx, this.viewModel.novidromeAllSongs, true);
      }, (song: SubsonicSong) => song.id + '_all_' + String(this.favoriteSignal));
    }
    .width('100%');
  }

  // ── 歌手 Section ──

  @Builder
  artistsSection() {
    Column() {
      if (this.viewModel.novidromeError !== '') {
        this.errorBanner(() => { this.switchTab(1); });
      }

      if (this.viewModel.novidromeArtists.length === 0 && !this.isLoading) {
        Blank().height(40);
        Text('没有找到歌手')
          .fontSize(14 * this.themeConfig.fontScale)
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
        .backgroundColor(MaterialConstants.getOverlayColor(
          MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
        .margin({ left: 10, right: 10, bottom: 8 })
        .onClick(() => {
          this.isLoading = true;
          this.selectedArtistId = artist.id;
          this.selectedArtistName = artist.name;
          this.browseLevel = 1;
          this.loadArtistAlbums(artist.id);
        });
      }, (artist: SubsonicArtist) => artist.id);
    }
    .width('100%');
  }

  private async loadArtistAlbums(artistId: string): Promise<void> {
    await this.viewModel.browseNovidromeAlbums(artistId);
    this.isLoading = false;
  }

  // ── 专辑 Section ──

  @Builder
  albumsSection() {
    Column() {
      if (this.viewModel.novidromeError !== '') {
        this.errorBanner(() => { this.switchTab(2); });
      }

      if (this.viewModel.novidromeAlbums.length === 0 && !this.isLoading) {
        Blank().height(40);
        Text('没有找到专辑')
          .fontSize(14 * this.themeConfig.fontScale)
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

  // ── 歌单 Section ──

  @Builder
  playlistsSection() {
    Column() {
      // 新建歌单 button
      Row() {
        SymbolGlyph(ICON.PLUS)
          .fontSize(15)
          .fontColor([this.themeConfig.primaryColor])
          .margin({ right: 8 });
        Text('新建歌单')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeConfig.primaryColor);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .borderRadius(this.themeConfig.borderRadius)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
      .backgroundColor(MaterialConstants.getOverlayColor(
        MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
      .margin({ left: 10, right: 10, bottom: 12 })
      .onClick(() => {
        this.newPlaylistName = '';
        this.showCreateSheet = true;
      });

      if (this.viewModel.playlists.length === 0) {
        Blank().height(20);
        Text('还没有歌单')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor);
        Text('点击上方按钮创建歌单')
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 4 });
      }

      ForEach(this.viewModel.playlists, (playlist: Playlist, _idx: number) => {
        Row() {
          Column() {
            Text(playlist.name)
              .fontSize(15 * this.themeConfig.fontScale)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeConfig.textColor)
              .maxLines(1);
            Text(playlist.trackCount !== undefined
              ? String(playlist.trackCount) + ' 首歌曲'
              : '加载中...')
              .fontSize(12 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .margin({ top: 2 });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          // Delete button (only for user-created playlists, not favorites)
          if (playlist.name !== '❤️ 收藏') {
            SymbolGlyph(ICON.CLOSE)
              .fontSize(14)
              .fontColor([this.themeConfig.textSecondaryColor])
              .margin({ right: 8 })
              .onClick(() => {
                this.deletePlaylistId = playlist.id;
                this.deletePlaylistName = playlist.name;
                this.showDeleteConfirm = true;
              });
          }

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
          this.isLoading = true;
          this.selectedPlaylistId = playlist.id;
          this.selectedPlaylistName = playlist.name;
          this.browseLevel = 1;
          this.loadPlaylistTracks(playlist.id);
        });
      }, (playlist: Playlist) => playlist.id);
    }
    .width('100%');
  }

  // ── 收藏 Section ──

  @Builder
  favoritesSection() {
    Column() {
      if (this.viewModel.favoriteTracks.length === 0 && !this.isLoading) {
        Blank().height(40);
        SymbolGlyph(ICON.HEART)
          .fontSize(36)
          .fontColor([this.themeConfig.textSecondaryColor]);
        Text('还没有收藏歌曲')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 12 });
        Text('在歌曲上点击 ❤️ 即可收藏')
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ top: 4 });
      }

      Text(String(this.viewModel.favoriteTracks.length) + ' 首收藏')
        .fontSize(12 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textSecondaryColor)
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
        .visibility(this.viewModel.favoriteTracks.length > 0
          ? Visibility.Visible : Visibility.None);

      ForEach(this.viewModel.favoriteTracks, (track: Track, idx: number) => {
        this.favoriteTrackRow(track, idx);
      }, (track: Track) => track.id + '_fav_' + String(this.favoriteSignal));
    }
    .width('100%');
  }

  @Builder
  favoriteTrackRow(track: Track, idx: number) {
    Row() {
      // Track number / play icon — show STREAM icon for currently playing track
      if (this.isFavoriteCurrentTrack(track) && this.displayState === PlayerState.PLAYING) {
        SymbolGlyph(ICON.STREAM)
          .fontSize(13)
          .fontColor([this.themeConfig.primaryColor])
          .width(28);
      } else {
        Text(String(idx + 1))
          .fontSize(13 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .width(28)
          .fontFamily('monospace')
          .textAlign(TextAlign.Center);
      }

      // Title + artist
      Column() {
        Text(track.title)
          .fontSize(14 * this.themeConfig.fontScale)
          .fontWeight(this.isFavoriteCurrentTrack(track) ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isFavoriteCurrentTrack(track)
            ? this.themeConfig.primaryColor
            : this.themeConfig.textColor)
          .maxLines(1);
        Text(track.artist)
          .fontSize(11 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .maxLines(1)
          .margin({ top: 1 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 });

      // Duration
      Text(this.formatDurationMs(track.durationMs))
        .fontSize(12 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textSecondaryColor);

      // Unfavorite button
      SymbolGlyph(ICON.HEART_FILL)
        .fontSize(16)
        .fontColor(['#E57373'])
        .margin({ left: 10 })
        .onClick(() => {
          this.viewModel.toggleFavoriteTrack(track.id);
          this.favoriteSignal++;
          // Reload favorites after toggle to reflect removal
          setTimeout(() => {
            this.viewModel.loadFavoriteTracks();
          }, 100);
        });

      // Add-to-playlist button
      SymbolGlyph(ICON.PLUS)
        .fontSize(14)
        .fontColor([this.themeConfig.textSecondaryColor])
        .margin({ left: 4 })
        .onClick(() => {
          this.addSheetSongId = track.id;
          this.addSheetSongTitle = track.title;
          this.showAddSheet = true;
        });

      // Now-playing indicator
      if (this.isFavoriteCurrentTrack(track)
        && this.displayState === PlayerState.PLAYING) {
        SymbolGlyph(ICON.STREAM)
          .fontSize(14)
          .fontColor([this.themeConfig.primaryColor])
          .margin({ left: 6 });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .borderRadius(this.themeConfig.borderRadius)
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
    .backgroundColor(MaterialConstants.getOverlayColor(
      MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
    .margin({ left: 10, right: 10, bottom: 4 })
    .onClick(() => {
      // Play the favorited track within the favorites context
      this.viewModel.tracks = this.viewModel.favoriteTracks;
      this.viewModel.playTrack(track);
      this.navStack.pushPathByName('music_player',
        {} as Record<string, Object>, false);
    });
  }

  private async loadPlaylistTracks(playlistId: string): Promise<void> {
    const tracks: Track[] = await this.viewModel.getPlaylistTracks(playlistId);
    // Convert tracks to SubsonicSong-like items
    const songs: SubsonicSong[] = [];
    for (let i: number = 0; i < tracks.length; i++) {
      const t: Track = tracks[i];
      songs.push({
        id: t.id,
        parent: '',
        title: t.title,
        album: t.album,
        artist: t.artist,
        track: i + 1,
        coverArt: '',
        size: 0,
        contentType: '',
        suffix: '',
        duration: t.durationMs > 0 ? Math.floor(t.durationMs / 1000) : 0,
        bitRate: 0,
        path: '',
        playCount: 0,
        discNumber: 1,
        created: '',
        albumId: '',
        artistId: '',
        type: 'music',
        isVideo: false,
      });
    }
    this.viewModel.novidromeSongs = songs;
    this.isLoading = false;
  }

  // ── Song List Content (level >= 1) ──

  @Builder
  songListContent() {
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
              if (this.selectedAlbumId !== '') {
                this.loadAlbumSongs(this.selectedAlbumId);
              } else if (this.selectedPlaylistId !== '') {
                this.loadPlaylistTracks(this.selectedPlaylistId);
              }
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
        Text('没有歌曲')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor);
      }

      ForEach(this.viewModel.novidromeSongs, (song: SubsonicSong, idx: number) => {
        this.songRow(song, idx, this.viewModel.novidromeSongs, true);
      }, (song: SubsonicSong) => song.id + '_detail_' + String(this.favoriteSignal));
    }
    .width('100%');
  }

  // ── Reusable Song Row ──

  @Builder
  songRow(song: SubsonicSong, idx: number, contextSongs: SubsonicSong[], showFavorite: boolean) {
    Row() {
      // Track number / play icon — show STREAM icon for currently playing track
      if (this.isCurrentSong(song) && this.displayState === PlayerState.PLAYING) {
        SymbolGlyph(ICON.STREAM)
          .fontSize(13)
          .fontColor([this.themeConfig.primaryColor])
          .width(28);
      } else {
        Text(String(idx + 1))
          .fontSize(13 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .width(28)
          .fontFamily('monospace')
          .textAlign(TextAlign.Center);
      }

      // Title + artist
      Column() {
        Text(song.title)
          .fontSize(14 * this.themeConfig.fontScale)
          .fontWeight(this.isCurrentSong(song) ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isCurrentSong(song)
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

      // Favorite button
      if (showFavorite) {
        SymbolGlyph(this.viewModel.isTrackFavorited(song.id)
          ? ICON.HEART_FILL : ICON.HEART)
          .fontSize(16)
          .fontColor(this.viewModel.isTrackFavorited(song.id)
            ? ['#E57373']
            : [this.themeConfig.textSecondaryColor])
          .margin({ left: 10 })
          .onClick(() => {
            this.viewModel.toggleFavoriteTrack(song.id);
            // Force re-render to update heart icon state
            this.favoriteSignal++;
          });
      } else {
        Blank().width(14).margin({ left: 10 });
      }

      // Add-to-playlist button
      SymbolGlyph(ICON.PLUS)
        .fontSize(14)
        .fontColor([this.themeConfig.textSecondaryColor])
        .margin({ left: 4 })
        .onClick(() => {
          this.addSheetSongId = song.id;
          this.addSheetSongTitle = song.title;
          this.showAddSheet = true;
        });

      // Now-playing indicator
      if (this.isCurrentSong(song) && this.displayState === PlayerState.PLAYING) {
        SymbolGlyph(ICON.STREAM)
          .fontSize(14)
          .fontColor([this.themeConfig.primaryColor])
          .margin({ left: 6 });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .borderRadius(this.themeConfig.borderRadius)
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
    .backgroundColor(MaterialConstants.getOverlayColor(
      MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
    .margin({ left: 10, right: 10, bottom: 4 })
    .onClick(() => {
      this.viewModel.playNovidromeTrack(song, contextSongs);
      // Navigate to full-screen Now Playing page after starting playback.
      this.navStack.pushPathByName('music_player',
        {} as Record<string, Object>, false);
    });
  }

  // ── Error Banner ──

  @Builder
  errorBanner(retryAction: () => void) {
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
        .onClick(() => { retryAction(); });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 });
  }

  // ── Helpers ──

  private isCurrentSong(song: SubsonicSong): boolean {
    return this.viewModel.currentTrack !== null
      && this.viewModel.currentTrack.id === song.id;
  }

  private isFavoriteCurrentTrack(track: Track): boolean {
    return this.viewModel.currentTrack !== null
      && this.viewModel.currentTrack.id === track.id;
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

  private formatDurationMs(ms: number): string {
    if (ms <= 0) {
      return '--:--';
    }
    const totalSec: number = Math.floor(ms / 1000);
    const mins: number = Math.floor(totalSec / 60);
    const secs: number = totalSec % 60;
    const secStr: string = secs < 10 ? '0' + String(secs) : String(secs);
    return String(mins) + ':' + secStr;
  }

  // ── Overlay: Create Playlist Dialog ──

  @Builder
  createPlaylistOverlay() {
    Column() {
      Column() {
        Text('新建歌单')
          .fontSize(18 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor)
          .margin({ bottom: 16 });

        TextInput({ text: this.newPlaylistName, placeholder: '歌单名称' })
          .fontSize(15 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor)
          .placeholderColor(this.themeConfig.textSecondaryColor)
          .backgroundColor(
            this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.08)'
              : 'rgba(0, 0, 0, 0.04)'
          )
          .borderRadius(this.themeConfig.borderRadius)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .borderWidth(1)
          .borderColor(
            this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.08)'
              : 'rgba(0, 0, 0, 0.06)'
          )
          .margin({ bottom: 18 })
          .onChange((value: string) => {
            this.newPlaylistName = value;
          });

        Row() {
          Button('取消')
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textColor)
            .backgroundColor('rgba(128, 128, 128, 0.15)')
            .borderRadius(this.themeConfig.borderRadius)
            .layoutWeight(1)
            .padding({ top: 9, bottom: 9 })
            .onClick(() => {
              this.showCreateSheet = false;
              this.newPlaylistName = '';
            });

          Blank().width(14);

          Button('创建')
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeConfig.primaryColor)
            .borderRadius(this.themeConfig.borderRadius)
            .layoutWeight(1)
            .padding({ top: 9, bottom: 9 })
            .onClick(() => {
              this.doCreatePlaylist();
            });
        }
        .width('100%');
      }
      .width(300)
      .padding(22)
      .borderRadius(this.themeConfig.borderRadius + 4)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.DIALOG))
      .backgroundColor(MaterialConstants.getOverlayColor(
        MaterialConstants.DIALOG, this.themeConfig.isDarkMode));
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.4)')
    .zIndex(200)
    .onClick(() => {
      this.showCreateSheet = false;
      this.newPlaylistName = '';
    });
  }

  // ── Overlay: Add to Playlist Sheet ──

  @Builder
  addToPlaylistOverlay() {
    Column() {
      // Bottom sheet card
      Column() {
        // Header
        Row() {
          Text('添加到歌单')
            .fontSize(17 * this.themeConfig.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeConfig.textColor)
            .layoutWeight(1);
          SymbolGlyph(ICON.CLOSE)
            .fontSize(16)
            .fontColor([this.themeConfig.textSecondaryColor])
            .onClick(() => {
              this.showAddSheet = false;
            });
        }
        .width('100%')
        .margin({ bottom: 10 });

        // Song name subtitle
        Text(this.addSheetSongTitle)
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .maxLines(1)
          .margin({ bottom: 14 });

        // Playlist list
        Column() {
          if (this.viewModel.playlists.length === 0) {
            Text('还没有歌单，请先创建')
              .fontSize(13 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.textSecondaryColor)
              .padding({ top: 8, bottom: 8 });
          }

          ForEach(this.viewModel.playlists, (playlist: Playlist, _idx: number) => {
            // Skip the favorites playlist — it's handled by the heart button
            if (playlist.name === '❤️ 收藏') {
              // Still show it but as the favorites toggle
              Row() {
                SymbolGlyph(this.viewModel.isTrackFavorited(this.addSheetSongId)
                  ? ICON.HEART_FILL : ICON.HEART)
                  .fontSize(16)
                  .fontColor(this.viewModel.isTrackFavorited(this.addSheetSongId)
                    ? ['#E57373']
                    : [this.themeConfig.textSecondaryColor])
                  .margin({ right: 10 });

                Text('收藏')
                  .fontSize(14 * this.themeConfig.fontScale)
                  .fontColor(this.themeConfig.textColor)
                  .layoutWeight(1);
              }
              .width('100%')
              .padding({ left: 4, right: 4, top: 10, bottom: 10 })
              .borderRadius(8)
              .onClick(() => {
                this.viewModel.toggleFavoriteTrack(this.addSheetSongId);
                this.favoriteSignal++;
                this.showAddSheet = false;
              });
            } else {
              Row() {
                SymbolGlyph(ICON.MUSIC_LIST)
                  .fontSize(15)
                  .fontColor([this.themeConfig.textSecondaryColor])
                  .margin({ right: 10 });

                Column() {
                  Text(playlist.name)
                    .fontSize(14 * this.themeConfig.fontScale)
                    .fontColor(this.themeConfig.textColor)
                    .maxLines(1);
                  Text(playlist.trackCount !== undefined
                    ? String(playlist.trackCount) + ' 首'
                    : '')
                    .fontSize(11 * this.themeConfig.fontScale)
                    .fontColor(this.themeConfig.textSecondaryColor);
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);
              }
              .width('100%')
              .padding({ left: 4, right: 4, top: 10, bottom: 10 })
              .borderRadius(8)
              .onClick(() => {
                this.doTogglePlaylistMembership(playlist.id, playlist.name);
              });
            }
          }, (playlist: Playlist) => playlist.id);

          // Quick create new playlist
          Row() {
            SymbolGlyph(ICON.PLUS)
              .fontSize(15)
              .fontColor([this.themeConfig.primaryColor])
              .margin({ right: 10 });
            Text('新建歌单')
              .fontSize(14 * this.themeConfig.fontScale)
              .fontColor(this.themeConfig.primaryColor);
          }
          .width('100%')
          .padding({ left: 4, right: 4, top: 12, bottom: 4 })
          .borderRadius(8)
          .margin({ top: 4 })
          .onClick(() => {
            this.showAddSheet = false;
            this.newPlaylistName = '';
            this.showCreateSheet = true;
          });
        }
        .width('100%');
      }
      .width('100%')
      .padding(20)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SHEET))
      .backgroundColor(MaterialConstants.getOverlayColor(
        MaterialConstants.SHEET, this.themeConfig.isDarkMode))
      .constraintSize({ maxHeight: 480 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .backgroundColor('rgba(0, 0, 0, 0.4)')
    .zIndex(200)
    .onClick(() => {
      this.showAddSheet = false;
    });
  }

  // ── Overlay: Delete Playlist Confirmation ──

  @Builder
  deletePlaylistOverlay() {
    Column() {
      Column() {
        Text('删除歌单')
          .fontSize(18 * this.themeConfig.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor)
          .margin({ bottom: 10 });

        Text('确定要删除「' + this.deletePlaylistName + '」吗？\n歌曲不会被删除，仅移除歌单本身。')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ bottom: 18 });

        Row() {
          Button('取消')
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textColor)
            .backgroundColor('rgba(128, 128, 128, 0.15)')
            .borderRadius(this.themeConfig.borderRadius)
            .layoutWeight(1)
            .padding({ top: 9, bottom: 9 })
            .onClick(() => {
              this.showDeleteConfirm = false;
            });

          Blank().width(14);

          Button('删除')
            .fontSize(14 * this.themeConfig.fontScale)
            .fontColor('#FFFFFF')
            .backgroundColor('#E57373')
            .borderRadius(this.themeConfig.borderRadius)
            .layoutWeight(1)
            .padding({ top: 9, bottom: 9 })
            .onClick(() => {
              this.doDeletePlaylist();
            });
        }
        .width('100%');
      }
      .width(300)
      .padding(22)
      .borderRadius(this.themeConfig.borderRadius + 4)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.DIALOG))
      .backgroundColor(MaterialConstants.getOverlayColor(
        MaterialConstants.DIALOG, this.themeConfig.isDarkMode));
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.4)')
    .zIndex(200)
    .onClick(() => {
      this.showDeleteConfirm = false;
    });
  }

  // ── Playlist action helpers ──

  private async doCreatePlaylist(): Promise<void> {
    const name: string = this.newPlaylistName.trim();
    if (name === '') {
      return;
    }
    this.showCreateSheet = false;
    this.newPlaylistName = '';
    await this.viewModel.createPlaylist(name);
    await this.viewModel.loadPlaylists();
  }

  private async doDeletePlaylist(): Promise<void> {
    this.showDeleteConfirm = false;
    await this.viewModel.deletePlaylist(this.deletePlaylistId);
    await this.viewModel.loadPlaylists();
    this.deletePlaylistId = '';
    this.deletePlaylistName = '';
  }

  private async doTogglePlaylistMembership(playlistId: string, playlistName: string): Promise<void> {
    this.showAddSheet = false;
    // Check if track is already in playlist and toggle
    const musicRepo: MusicRepository = new MusicRepository(
      DatabaseHelper.getInstance().getStore()
    );
    const isInPlaylist: boolean = await musicRepo.isTrackInPlaylist(
      playlistId, this.addSheetSongId
    );
    if (isInPlaylist) {
      await musicRepo.removeTrackFromPlaylist(playlistId, this.addSheetSongId);
    } else {
      await this.viewModel.addToPlaylist(playlistId, this.addSheetSongId);
    }
    // Refresh playlist track counts
    await this.viewModel.loadPlaylists();
  }
}
