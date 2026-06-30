import {
  Track,
  Playlist,
  PlayerState,
  RepeatMode,
  MusicSource,
  MusicPageTab,
  NovidromeConfig,
  MusicPlayerConfig,
  SubsonicArtist,
  SubsonicAlbum,
  SubsonicSong,
  SubsonicSearchResult3,
  getDefaultNovidromeConfig,
} from '../model/MusicModel';
import { ID } from '../model/AppConstantsModel';
import { MusicRepository } from '../repository/MusicRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { MusicPlayerService } from '../service/MusicPlayerService';
import { NavidromeApiClient } from '../service/NavidromeApiClient';
import { MusicConstants, getDefaultMusicPlayerConfig } from '../constants/MusicConstants';
import { generateId } from '../utils/IdGenerator';

/**
 * Central orchestrator for the music player feature.
 * Exists as a module-level singleton so playback survives tab switches
 * (HarmonyOS Tabs destroys non-visible TabContent).
 *
 * Pattern matches PomodoroViewModel exactly: @ObservedV2 + @Trace +
 * tickHandler callback for UI sync + module-level singleton.
 */
@ObservedV2
export class MusicViewModel {
  // ── Playback State ──
  @Trace playerState: PlayerState = PlayerState.IDLE;
  @Trace currentTrack: Track | null = null;
  @Trace currentPositionMs: number = 0;
  @Trace durationMs: number = 0;
  @Trace volume: number = MusicConstants.DEFAULT_VOLUME;
  @Trace repeatMode: RepeatMode = MusicConstants.DEFAULT_REPEAT_MODE;
  @Trace shuffleEnabled: boolean = MusicConstants.DEFAULT_SHUFFLE;
  @Trace isMiniPlayerVisible: boolean = false;

  // ── Library ──
  @Trace tracks: Track[] = [];
  @Trace playlists: Playlist[] = [];
  @Trace isLoadingTracks: boolean = false;
  @Trace currentTab: MusicPageTab = MusicPageTab.TRACKS;

  // ── Navidrome State ──
  @Trace novidromeConfig: NovidromeConfig = getDefaultNovidromeConfig();
  @Trace novidromeConnected: boolean = false;
  @Trace novidromeArtists: SubsonicArtist[] = [];
  @Trace novidromeAlbums: SubsonicAlbum[] = [];
  @Trace novidromeSongs: SubsonicSong[] = [];
  @Trace novidromeAllSongs: SubsonicSong[] = [];
  @Trace novidromeSearchQuery: string = '';
  @Trace novidromeError: string = '';
  @Trace playbackError: string = '';

  // ── Favorites (local RDB playlist) ──
  @Trace favoritePlaylistId: string = '';
  @Trace favoriteTrackIds: string[] = [];
  @Trace favoriteTracks: Track[] = [];

  // ── Private services/repos ──
  private playerService: MusicPlayerService;
  private repository: MusicRepository;
  private settingsRepository: SettingsRepository;
  private novidromeClient: NavidromeApiClient | null = null;

  // ── UI callbacks (set by pages) ──
  private tickHandler: ((posMs: number, durMs: number, state: PlayerState) => void) | null = null;
  private miniPlayerHandler: ((posMs: number, durMs: number, state: PlayerState, visible: boolean) => void) | null = null;

  constructor(repository: MusicRepository, settingsRepository: SettingsRepository) {
    this.repository = repository;
    this.settingsRepository = settingsRepository;
    this.playerService = new MusicPlayerService();

    // Register player callbacks
    this.playerService.onStateChange((state: PlayerState) => {
      this.playerState = state;
      // Clear any stale error once playback starts successfully.
      // This prevents the red error banner from persisting after a
      // transient error (e.g. prepare() failure on one track) when
      // the next track plays fine.
      if (state === PlayerState.PLAYING) {
        this.playbackError = '';
      }
      this.notifyTick();
      this.notifyMiniPlayer();
    });

    this.playerService.onPositionUpdate((currentMs: number, totalMs: number) => {
      this.currentPositionMs = currentMs;
      this.durationMs = totalMs;
      this.notifyTick();
      this.notifyMiniPlayer();
    });

    this.playerService.onTrackEnd(() => {
      this.handleTrackEnd();
    });

    this.playerService.onError((message: string) => {
      this.playbackError = message;
      this.playerState = PlayerState.ERROR;
      this.notifyTick();
      this.notifyMiniPlayer();
    });
  }

  private notifyTick(): void {
    if (this.tickHandler !== null) {
      this.tickHandler(this.currentPositionMs, this.durationMs, this.playerState);
    }
  }

  private notifyMiniPlayer(): void {
    if (this.miniPlayerHandler !== null) {
      this.miniPlayerHandler(
        this.currentPositionMs,
        this.durationMs,
        this.playerState,
        this.isMiniPlayerVisible
      );
    }
  }

  /**
   * Registers a callback that the page uses to update its @Local fields.
   * Pattern matches PomodoroViewModel.setTickHandler.
   */
  setTickHandler(handler: ((posMs: number, durMs: number, state: PlayerState) => void) | null): void {
    this.tickHandler = handler;
  }

  /**
   * Registers a callback for the MiniPlayer global overlay in Index.ets.
   */
  setMiniPlayerHandler(handler: ((posMs: number, durMs: number, state: PlayerState, visible: boolean) => void) | null): void {
    this.miniPlayerHandler = handler;
  }

  // ── Initialization ──

  async initialize(): Promise<void> {
    // Load persisted configs
    const musicConfig: MusicPlayerConfig = await this.settingsRepository.loadMusicPlayerConfig();
    this.volume = musicConfig.volume;
    this.repeatMode = musicConfig.repeatMode;
    this.shuffleEnabled = musicConfig.shuffleEnabled;
    this.playerService.setVolume(musicConfig.volume);

    this.novidromeConfig = await this.settingsRepository.loadNovidromeConfig();
    if (this.novidromeConfig.enabled && this.novidromeConfig.serverUrl !== '') {
      this.createNovidromeClient();
    }

    await this.loadTracks();
    await this.loadPlaylists();
    await this.ensureFavoritePlaylist();
  }

  // ── Track Library ──

  async loadTracks(): Promise<void> {
    this.isLoadingTracks = true;
    this.tracks = await this.repository.getAllTracks();
    this.isLoadingTracks = false;
  }

  async loadTracksBySource(source: MusicSource): Promise<void> {
    this.tracks = await this.repository.getTracksBySource(source);
  }

  async searchTracks(query: string): Promise<void> {
    if (query.trim() === '') {
      await this.loadTracks();
    } else {
      this.tracks = await this.repository.searchTracks(query);
    }
  }

  async deleteTrack(id: ID): Promise<void> {
    await this.repository.deleteTrack(id);
    if (this.currentTrack !== null && this.currentTrack.id === id) {
      this.playerService.stop();
      this.currentTrack = null;
      this.isMiniPlayerVisible = false;
    }
    await this.loadTracks();
  }

  // ── Playback Control ──

  async playTrack(track: Track): Promise<void> {
    // Resolve stream URL for Navidrome tracks
    if (track.source === MusicSource.NOVIDROME && this.novidromeClient !== null && track.serverTrackId !== '') {
      track.fileUri = this.novidromeClient.getStreamUrl(track.serverTrackId);
    }

    try {
      this.playbackError = '';
      await this.playerService.loadTrack(track);
      this.currentTrack = track;
      this.playerService.play();
      this.isMiniPlayerVisible = true;
      await this.savePlayerConfig();
      this.notifyTick();
    } catch (err) {
      this.playbackError = '播放失败: ' + (err as Error).message;
      this.playerState = PlayerState.ERROR;
      this.notifyTick();
    }
  }

  playPause(): void {
    if (this.playerState === PlayerState.PLAYING) {
      this.playerService.pause();
    } else if (this.playerState === PlayerState.PAUSED || this.playerState === PlayerState.STOPPED
      || this.playerState === PlayerState.LOADING) {
      this.playerService.play();
    }
  }

  playNext(): void {
    if (this.tracks.length === 0) {
      return;
    }

    const currentIndex: number = this.getCurrentTrackIndex();
    let nextIndex: number = -1;

    if (this.shuffleEnabled && this.tracks.length > 1) {
      // Pick a random track different from current
      let randomIdx: number = currentIndex;
      while (randomIdx === currentIndex && this.tracks.length > 1) {
        randomIdx = Math.floor(Math.random() * this.tracks.length);
      }
      nextIndex = randomIdx;
    } else {
      nextIndex = currentIndex + 1;
      if (nextIndex >= this.tracks.length) {
        if (this.repeatMode === RepeatMode.REPEAT_ALL) {
          nextIndex = 0;
        } else {
          this.playerService.stop();
          return;
        }
      }
    }

    if (nextIndex >= 0 && nextIndex < this.tracks.length) {
      this.playTrack(this.tracks[nextIndex]);
    }
  }

  playPrevious(): void {
    if (this.tracks.length === 0) {
      return;
    }

    const currentIndex: number = this.getCurrentTrackIndex();
    // If more than 3 seconds in, restart current track
    if (this.currentPositionMs > 3000) {
      this.playerService.seekTo(0);
      return;
    }

    let prevIndex: number = currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = this.tracks.length - 1;
    }
    this.playTrack(this.tracks[prevIndex]);
  }

  seekTo(positionMs: number): void {
    this.playerService.seekTo(positionMs);
  }

  setVolume(level: number): void {
    this.volume = Math.max(0, Math.min(1, level));
    this.playerService.setVolume(this.volume);
    this.savePlayerConfig();
  }

  toggleRepeatMode(): void {
    if (this.repeatMode === RepeatMode.OFF) {
      this.repeatMode = RepeatMode.REPEAT_ALL;
    } else if (this.repeatMode === RepeatMode.REPEAT_ALL) {
      this.repeatMode = RepeatMode.REPEAT_ONE;
    } else {
      this.repeatMode = RepeatMode.OFF;
    }
    this.savePlayerConfig();
  }

  toggleShuffle(): void {
    this.shuffleEnabled = !this.shuffleEnabled;
    this.savePlayerConfig();
  }

  private handleTrackEnd(): void {
    if (this.repeatMode === RepeatMode.REPEAT_ONE) {
      this.playerService.seekTo(0);
      this.playerService.play();
    } else {
      this.playNext();
    }
  }

  private getCurrentTrackIndex(): number {
    if (this.currentTrack === null) {
      return -1;
    }
    for (let i: number = 0; i < this.tracks.length; i++) {
      if (this.tracks[i].id === this.currentTrack.id) {
        return i;
      }
    }
    return -1;
  }

  // ── Playlist Management ──

  async loadPlaylists(): Promise<void> {
    this.playlists = await this.repository.getAllPlaylists();
    // Load track counts
    for (let i: number = 0; i < this.playlists.length; i++) {
      const tracks: Track[] = await this.repository.getTracksForPlaylist(this.playlists[i].id);
      this.playlists[i].trackCount = tracks.length;
    }
  }

  async createPlaylist(name: string): Promise<void> {
    const playlist: Playlist = {
      id: generateId(),
      name: name,
      createdAt: Date.now(),
    };
    await this.repository.createPlaylist(playlist);
    await this.loadPlaylists();
  }

  async deletePlaylist(id: ID): Promise<void> {
    await this.repository.deletePlaylist(id);
    await this.loadPlaylists();
  }

  async addToPlaylist(playlistId: ID, trackId: ID): Promise<void> {
    await this.repository.addTrackToPlaylist(playlistId, trackId);
    await this.loadPlaylists();
  }

  async getPlaylistTracks(playlistId: ID): Promise<Track[]> {
    return await this.repository.getTracksForPlaylist(playlistId);
  }

  async playPlaylist(playlistId: ID): Promise<void> {
    const playlistTracks: Track[] = await this.repository.getTracksForPlaylist(playlistId);
    if (playlistTracks.length > 0) {
      this.tracks = playlistTracks;
      await this.playTrack(playlistTracks[0]);
    }
  }

  // ── Navidrome Integration ──

  private createNovidromeClient(): void {
    this.novidromeClient = new NavidromeApiClient(this.novidromeConfig);
  }

  async connectNovidrome(): Promise<boolean> {
    if (this.novidromeClient === null) {
      this.createNovidromeClient();
    }
    if (this.novidromeClient === null) {
      return false;
    }
    this.novidromeConnected = await this.novidromeClient.ping();
    return this.novidromeConnected;
  }

  getNovidromeError(): string {
    if (this.novidromeClient !== null) {
      return this.novidromeClient.lastError;
    }
    return 'Navidrome 客户端未初始化';
  }

  async updateNovidromeConfig(config: NovidromeConfig): Promise<void> {
    this.novidromeConfig = config;
    await this.settingsRepository.saveNovidromeConfig(config);
    if (config.enabled && config.serverUrl !== '') {
      this.createNovidromeClient();
    } else {
      this.novidromeClient = null;
      this.novidromeConnected = false;
    }
  }

  async browseNovidromeArtists(): Promise<void> {
    if (this.novidromeClient === null) {
      this.novidromeError = 'Navidrome 客户端未初始化';
      return;
    }
    try {
      this.novidromeError = '';
      this.novidromeArtists = await this.novidromeClient.getArtists();
    } catch (err) {
      this.novidromeArtists = [];
      this.novidromeError = '加载艺术家失败: ' + (err as Error).message;
    }
  }

  async browseNovidromeAlbums(artistId?: string): Promise<void> {
    if (this.novidromeClient === null) {
      this.novidromeError = 'Navidrome 客户端未初始化';
      return;
    }
    try {
      this.novidromeError = '';
      this.novidromeAlbums = await this.novidromeClient.getAlbums(artistId);
    } catch (err) {
      this.novidromeAlbums = [];
      this.novidromeError = '加载专辑失败: ' + (err as Error).message;
    }
  }

  async browseNovidromeSongs(albumId: string): Promise<void> {
    if (this.novidromeClient === null) {
      this.novidromeError = 'Navidrome 客户端未初始化';
      return;
    }
    try {
      this.novidromeError = '';
      this.novidromeSongs = await this.novidromeClient.getSongs(albumId);
    } catch (err) {
      this.novidromeSongs = [];
      this.novidromeError = '加载歌曲失败: ' + (err as Error).message;
    }
  }

  async browseNovidromeAllSongs(): Promise<void> {
    if (this.novidromeClient === null) {
      this.novidromeError = 'Navidrome 客户端未初始化';
      return;
    }
    try {
      this.novidromeError = '';
      this.novidromeAllSongs = await this.novidromeClient.getAllSongs();
    } catch (err) {
      this.novidromeAllSongs = [];
      this.novidromeError = '加载歌曲失败: ' + (err as Error).message;
    }
  }

  // ── Favorites (local RDB playlist) ──

  /**
   * Finds or creates the "❤️ 收藏" playlist for favorites.
   * Called once during initialize() and after any playlist mutation.
   */
  async ensureFavoritePlaylist(): Promise<void> {
    // Look for existing favorites playlist by name
    for (let i: number = 0; i < this.playlists.length; i++) {
      if (this.playlists[i].name === '❤️ 收藏') {
        this.favoritePlaylistId = this.playlists[i].id;
        // Load its track IDs
        const tracks: Track[] = await this.repository.getTracksForPlaylist(this.favoritePlaylistId);
        this.favoriteTrackIds = [];
        for (let j: number = 0; j < tracks.length; j++) {
          this.favoriteTrackIds.push(tracks[j].id);
        }
        return;
      }
    }
    // Create it
    const playlistId: string = generateId();
    const playlist: Playlist = {
      id: playlistId,
      name: '❤️ 收藏',
      createdAt: Date.now(),
    };
    await this.repository.createPlaylist(playlist);
    this.favoritePlaylistId = playlistId;
    this.favoriteTrackIds = [];
    await this.loadPlaylists();
  }

  isTrackFavorited(trackId: string): boolean {
    for (let i: number = 0; i < this.favoriteTrackIds.length; i++) {
      if (this.favoriteTrackIds[i] === trackId) {
        return true;
      }
    }
    return false;
  }

  async loadFavoriteTracks(): Promise<void> {
    if (this.favoritePlaylistId === '') {
      await this.ensureFavoritePlaylist();
    }
    if (this.favoritePlaylistId === '') {
      this.favoriteTracks = [];
      return;
    }
    this.favoriteTracks = await this.repository.getTracksForPlaylist(this.favoritePlaylistId);
  }

  async toggleFavoriteTrack(trackId: string): Promise<void> {
    if (this.favoritePlaylistId === '') {
      await this.ensureFavoritePlaylist();
    }
    if (this.favoritePlaylistId === '') {
      return;
    }

    if (this.isTrackFavorited(trackId)) {
      // Remove from favorites
      await this.repository.removeTrackFromPlaylist(this.favoritePlaylistId, trackId);
      const newIds: string[] = [];
      for (let i: number = 0; i < this.favoriteTrackIds.length; i++) {
        if (this.favoriteTrackIds[i] !== trackId) {
          newIds.push(this.favoriteTrackIds[i]);
        }
      }
      this.favoriteTrackIds = newIds;
    } else {
      // Add to favorites
      await this.repository.addTrackToPlaylist(this.favoritePlaylistId, trackId);
      this.favoriteTrackIds.push(trackId);
    }
    await this.loadPlaylists();
  }

  async searchNovidrome(query: string): Promise<void> {
    if (this.novidromeClient === null) {
      return;
    }
    try {
      this.novidromeSearchQuery = query;
      const result: SubsonicSearchResult3 = await this.novidromeClient.search3(query);
      // Convert search results to tracks
      const foundTracks: Track[] = [];
      if (result.song !== undefined) {
        for (let i: number = 0; i < result.song.length; i++) {
          foundTracks.push(this.subsonicSongToTrack(result.song[i]));
        }
      }
      this.tracks = foundTracks;
    } catch (_err) {
      this.tracks = [];
    }
  }

  /**
   * Plays a Navidrome song with proper next/prev support.
   * Converts the provided song list to Track[] so playNext/playPrevious
   * can navigate within the current browsing context.
   */
  async playNovidromeTrack(song: SubsonicSong, contextSongs: SubsonicSong[]): Promise<void> {
    // Convert all context songs to tracks for next/prev navigation
    const trackList: Track[] = [];
    let targetIndex: number = 0;
    for (let i: number = 0; i < contextSongs.length; i++) {
      const t: Track = this.subsonicSongToTrack(contextSongs[i]);
      trackList.push(t);
      if (contextSongs[i].id === song.id) {
        targetIndex = i;
      }
    }
    this.tracks = trackList;

    // Play the target track (playTrack handles stream URL resolution)
    await this.playTrack(trackList[targetIndex]);
  }

  async importNovidromeTrack(song: SubsonicSong): Promise<Track> {
    const track: Track = this.subsonicSongToTrack(song);
    // Check if already in library
    const existing: Track | null = await this.repository.getTrackById(track.id);
    if (existing !== null) {
      return existing;
    }
    await this.repository.insertTrack(track);
    await this.loadTracks();
    return track;
  }

  async importNovidromeAlbum(albumId: string): Promise<number> {
    if (this.novidromeSongs.length === 0) {
      return 0;
    }
    let importedCount: number = 0;
    for (let i: number = 0; i < this.novidromeSongs.length; i++) {
      const track: Track = await this.importNovidromeTrack(this.novidromeSongs[i]);
      if (track !== null) {
        importedCount++;
      }
    }
    return importedCount;
  }

  private subsonicSongToTrack(song: SubsonicSong): Track {
    let albumArtUrl: string = '';
    if (this.novidromeClient !== null && song.coverArt !== undefined && song.coverArt !== '') {
      albumArtUrl = this.novidromeClient.getCoverArtUrl(song.coverArt, 300);
    }

    return {
      id: song.id,
      title: song.title,
      artist: song.artist !== undefined ? song.artist : 'Unknown Artist',
      album: song.album !== undefined ? song.album : '',
      durationMs: song.duration !== undefined ? song.duration * 1000 : 0,
      fileUri: '',
      albumArtUri: albumArtUrl,
      source: MusicSource.NOVIDROME,
      serverTrackId: song.id,
      dateAdded: Date.now(),
    };
  }

  // ── Persistence ──

  private async savePlayerConfig(): Promise<void> {
    const config: MusicPlayerConfig = {
      volume: this.volume,
      repeatMode: this.repeatMode,
      shuffleEnabled: this.shuffleEnabled,
      lastTrackId: this.currentTrack !== null ? this.currentTrack.id : '',
      lastPosition: this.currentPositionMs,
    };
    await this.settingsRepository.saveMusicPlayerConfig(config);
  }

  // ── Cleanup ──

  destroy(): void {
    this.playerService.destroy();
    this.tickHandler = null;
  }
}

// ── Module-level singleton ──────────────────────────────────────────────
// MusicPage is destroyed/recreated on tab switch because HarmonyOS Tabs
// tears down non-visible TabContent. Storing the ViewModel at module level
// keeps playback alive when the user switches tabs.

let _instance: MusicViewModel | null = null;

export function initMusicViewModel(
  repository: MusicRepository,
  settingsRepository: SettingsRepository
): MusicViewModel {
  if (_instance === null) {
    _instance = new MusicViewModel(repository, settingsRepository);
  }
  return _instance;
}

export function getMusicViewModel(): MusicViewModel {
  if (_instance === null) {
    throw new Error('MusicViewModel not initialized — call initMusicViewModel first');
  }
  return _instance;
}
