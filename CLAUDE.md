# MemoFlow Project Context

## Project
- **Name**: MemoFlow — HarmonyOS NEXT memo app with immersive depth UI
- **Path**: `E:\program\notes`
- **Version**: 2.1.0
- **Platform**: HarmonyOS NEXT 6.1.1 (SDK API 24), Stage model
- **Language**: ArkTS strict mode (no `any`/`unknown`, no spread `...`, no indexed access `obj['key']`)
- **State Management**: V2 (全局迁移完成 — `@ComponentV2`, `@Local`, `@Param`, `@Event`, `@Provider`, `@Consumer`, `@ObservedV2`, `@Trace`, `@Monitor`)
- **Target**: phone + tablet (responsive breakpoints at 600/840 vp)
- **Build**: DevEco Studio → `hvigorw assembleHap`

## Architecture

### Navigation (per-tab Navigation pattern)
```
Index.ets (@Entry, @ComponentV2, @Provider source)
├── HdsTabs (5 tabs, barPosition: End, barOverlap)
│   ├── TabContent[0] → Navigation(navStack[0]) → NotesPage
│   ├── TabContent[1] → Navigation(navStack[1]) → TodosPage
│   ├── TabContent[2] → Navigation(navStack[2]) → PomodoroPage
│   ├── TabContent[3] → Navigation(navStack[3]) → SettingsPage
│   └── TabContent[4] → Navigation(navStack[4]) → MusicPage
├── Stack wrapper with MiniPlayer overlay (global, above tab bar)
└── Tablet: Row(sideNav 240vp + content area with per-section Navigation + MiniPlayer)
```

### Page routing
- Only `Index.ets` is `@Entry` (in main_pages.json)
- All sub-pages are `@ComponentV2 struct` wrapped in `NavDestination(){}`
- Navigation uses `navDestination(builder)` — builder checks `name` param
- `NavParams` static class for parameter passing (no indexed access)
- `navStack.pushPathByName('note_detail', {})` — requires 2 args
- `navStack.pop()` to go back

### State management (@Provider/@Consumer V2)
```
Index provides:
  @Provider('themeConfig') themeConfig: ThemeConfig
  @Provider('themeVM') themeVM: ThemeViewModel
  @Provider('navStack') currentNavStack: NavPathStack
  @Provider('isTablet') isTablet: boolean
  @Local themeUpdateSignal: number  ← forces re-render when theme changes
```
- 29 components consume `@Consumer('themeConfig')` (with `DEFAULT_THEME_CONFIG` default)
- `@BuilderParam` does NOT pass `@Provider` down (renders in caller's context)
- Theme change chain: slider → themeVM.update*() → saveTheme() → notifyThemeChange() → Index listener → @Provider update + themeUpdateSignal++
- `@Event` required on all callback properties set by parent components
- `@CustomDialog` (GlassDialog) remains unchanged — not part of V1/V2 state management

### UI Style (v2.0.0 — HDS real material + backdropBlur fallback)
- **HdsTabs** (@kit.UIDesignKit, API 23+): `barFloatingStyle({ systemMaterialEffect })` — real GPU-level immersive material (NOT CSS blur). Uses `hdsMaterial.MaterialType.ADAPTIVE` + `hdsMaterial.MaterialLevel.ADAPTIVE` for system auto-balance.
- **Non-HDS components**: Use layered `backdropBlur()` + semi-transparent backgrounds as fallback (real `systemMaterial` on ArkUI components requires API 26, project targets API 24)
- 5-tier depth hierarchy: ULTRA_THIN(4px) → THIN(8px) → REGULAR(16px) → THICK(24px) → ULTRA_THICK(30px)
- `MaterialConstants.ets` provides `getBlur(level)` and `getOverlayColor(level, isDark)` helpers
- `MaterialCapability.ets` uses real `hdsMaterial.getSystemMaterialTypes()` for device capability detection
- Manual press animations replaced by backdropBlur-based interactive feedback (GlassButton simplified)
- Card accent stripes are now inner Column elements (NoteCard, GlassCard) — not border-based
- No `backdropBlur` on ThemeBackground (it's the canvas) — only on foreground surfaces
- **Page headers**: all 5 pages have backdropBlur(THIN) on header Row for immersive frosted effect
- **Tablet sidebar**: backdropBlur(THICK) material surface with border separator
- **Settings → 沉浸光感**: Toggle (immersiveEnabled) + material level chip picker (ADAPTIVE/EXQUISITE/GENTLE/SMOOTH) persisted via ThemeViewModel

### Notes data flow
```
NotesPage.aboutToAppear() → refreshNotes()
  → viewModel.loadNotes()  (queries RDB)
  → applyFilters() → filteredNotes updated
  → refreshSignal++ → triggers build() re-execute
  → Scroll + Column + ForEach renders all notes

NoteDetailPage save/delete:
  → await DB operation
  → NavParams.triggerNotesRefresh()  (calls NotesPage.refreshNotes() BEFORE pop)
  → navStack.pop()
```
- **NavParams.triggerNotesRefresh callback** — NotesPage registers it in aboutToAppear(), NoteDetailPage calls it before popping. Bypasses unreliable NavDestination.onShown().
- **Scroll+Column+ForEach** instead of List+ListItemGroup+ForEach — List+ListItem has a HarmonyOS rendering bug where only the first child renders.
- **refreshSignal** (@State number) increments after loadNotes() completes to force UI rebuild.
- NoteEditor uses `@Watch('syncInitialContent')` to display async-loaded content (DB load completes after component is already visible).

### Tablet Notes layout (v1.1.0)
- `@Provide('isTablet')` detected via `onAreaChange` breakpoint calculation
- `@State viewMode: number` — 0=list, 1=grid (tablet only, toggled via header button)
- List mode: Scroll+Column+ForEach, NoteCard `.width('100%').margin({ left: 20, right: 20, bottom: 12 })`
- Grid mode: `getNotePairs()` splits notes into 2-column Row pairs, NoteCard `.layoutWeight(1)`
- Grid NoteCard: compact (title 14fp, content 12fp maxLines 1, padding 12, border-left 3px, shadow 4)
- ICON.VIEW_GRID='▦', ICON.VIEW_LIST='☰'

### Database
- `DatabaseHelper` singleton → `relationalStore.RdbStore`
- 8 tables: notes, todo_categories, todos, pomodoro_sessions, voice_memos, music_tracks, music_playlists, music_playlist_tracks
- `SettingsRepository` uses Preferences for theme/pomodoro config
- DB initialized in `Index.initializeApp()` BEFORE any UI renders
- `initPromise` deduplicates concurrent initialize() calls (EntryAbility fire-and-forget + Index awaited)
- `migrateDatabase()` handles schema upgrades: ALTER TABLE ADD COLUMN with error tolerance (column may already exist)

### Todos data flow
```
TodosPage.aboutToAppear() / onShown()
  → viewModel.loadData()
  → loads categories + todos from RDB
  → CategoryDataSource + TodoDataSource for LazyForEach grouped list

TodoAddSheet save:
  → handleTodoSave() in TodosPage
  → getOrCreateCategory(name, color) if custom name typed
  → viewModel.createTodo() with final categoryId
  → loadData() to refresh list
```
- Category grouping: `ListItemGroup` with `header` builder per category
- `PRESET_TODO_CATEGORIES`: ['工作', '个人', '购物', '学习', '健康', '其他']
- Custom category: TextInput + getOrCreateCategory() materializes name into UUID-based category
- Category manager UI: create/delete categories inline with color dots

### Music data flow
```
MusicPage.aboutToAppear()
  → register tickHandler → updates @Local displayState/PositionMs/DurationMs
  → initNavidrome() → connectNovidrome() ping → browseNovidromeAlbums() (default tab)
  → 5 Tab Chips: 全部歌曲/歌手/专辑/歌单/❤️收藏
    - 全部歌曲: getAllSongs() → browseNovidromeAllSongs() → novidromeAllSongs → playNovidromeTrack()
    - 歌手: getArtists() → browseNovidromeArtists() → tap artist → browseNovidromeAlbums(id) → tap album → songs → play
    - 专辑: getAlbumList2 → browseNovidromeAlbums() → tap album → browseNovidromeSongs(id) → play
    - 歌单: loadPlaylists() → tap playlist → getPlaylistTracks(id) → play
    - ❤️收藏: loadFavoriteTracks() → 显示收藏曲目 → playTrack()（取消收藏点击 ❤️→自动刷新列表）
  → Tab 切换懒加载：switchTab() 仅在切换到目标 tab 时才拉取数据

MusicPage.playTrack(track):
  → viewModel.playNovidromeTrack(song, contextSongs)  (sets this.tracks for next/prev)
  → playerService.loadTrack(track)  (sets AVPlayer url — Navidrome HTTP stream URL)
  → playerService.play()  (may defer via autoPlayWhenReady if not yet prepared)
  → isMiniPlayerVisible = true → MiniPlayer appears globally

MiniPlayer (global overlay in Index.ets):
  → Self-contained: subscribes to MusicViewModel via miniPlayerHandler
  → Tap → switch to tab[4] + push 'music_player' NavDestination
  → Play/pause/next call viewModel directly

MusicPlayerPage (full-screen Now Playing):
  → TickHandler for live position/duration
  → MusicControls: shuffle/prev/play-pause/next/repeat
  → Seek via Slider (0-100%), volume via Slider

Navidrome integration (pure streaming — no local import needed):
  → SettingsPage: server URL + username + password + test connection
  → NavidromeApiClient: Subsonic REST API with MD5(password+salt) auth
  → MusicPage: 4-tab browse → songs → direct stream (no local RDB dependency)
  → Stream URL resolved and played via AVPlayer HTTP streaming
  → generateAuthParamsNoFormat() for binary endpoints (stream, coverArt) — no &f=json
  → MiniPlayer global overlay shows now-playing track

Favorites (local RDB playlist):
  → "❤️ 收藏" playlist auto-created on first favorite
  → Heart icon (ICON.HEART/HEART_FILL) on each song row
  → toggleFavoriteTrack() adds/removes from favorites playlist
  → Favorites appear in 歌单 tab alongside other playlists
```
- **MusicViewModel singleton** — module-level `initMusicViewModel()`/`getMusicViewModel()`, survives tab switches
- **MiniPlayer global overlay** — rendered in Index.ets Stack (phone: above tab bar, tablet: bottom of content area), self-contained with own handler
- **Subsonic API** — `ping()`, `getArtists()`, `getAlbums()`, `getSongs()`, `search3()`, `getStreamUrl()`, `getCoverArtUrl()`
- **Repeat modes**: OFF → REPEAT_ALL → REPEAT_ONE cycling
- **Shuffle**: random next track from full list
- **Permissions**: `ohos.permission.INTERNET` + `ohos.permission.READ_MEDIA`

## Key Files

| File | Role |
|------|------|
| `pages/Index.ets` | Root, @Provide source, tab+nav layout, theme sync, tablet detection |
| `pages/NotesPage.ets` | Notes list with search, sort filter, FAB, tablet grid/list toggle |
| `pages/NoteDetailPage.ets` | Note create/edit NavDestination, delete via GlassDialog with customStyle |
| `pages/SettingsPage.ets` | Theme presets (8 colors), dark mode toggle, pomodoro config, background image |
| `pages/TodosPage.ets` | Todos grouped list with filter tabs, add sheet, category manager |
| `pages/PomodoroPage.ets` | Pomodoro timer with start/pause/reset, session stats |
| `viewmodel/ThemeViewModel.ets` | @ObservedV2, Listener pattern, cloneConfig/commitConfig helpers, applyUserPreferences centralized in saveTheme() |
| `viewmodel/NotesViewModel.ets` | @Observed, CRUD, search, sort, filter |
| `repository/DatabaseHelper.ets` | RDB singleton, getStore() throws if not initialized |
| `repository/NoteRepository.ets` | Notes SQL CRUD |
| `repository/SettingsRepository.ets` | Preferences read/write for theme + pomodoro |
| `utils/IconGlyphs.ets` | ICON static class — 28+ Unicode icon chars (added EDIT, VIEW_GRID, VIEW_LIST) |
| `utils/NavParams.ets` | Static noteId + needsNotesRefresh + triggerNotesRefresh callback |
| `utils/ColorUtils.ets` | hexToRgba, lightenColor, darkenColor, isDarkColor (createGlassColor removed) |
| `components/business/NoteCard.ets` | Immersive card with inner accent stripe + backdropBlur depth |
| `components/business/NoteEditor.ets` | TextArea with @Watch sync, borderRadius(0), isUserEditing guard |
| `components/business/TodoAddSheet.ets` | Bottom sheet: custom category TextInput + preset chips + filtered user chips |
| `components/business/TodoItem.ets` | Todo list item with backdropBlur card depth |
| `components/common/GlassDialog.ets` | CustomDialog — ULTRA_THICK backdropBlur depth, customStyle:true, themeConfig via param |
| `components/common/GlassContainer.ets` | Immersive container with elevation-mapped backdropBlur depth |
| `components/common/GlassCard.ets` | Immersive card with inner accent stripe + backdropBlur depth |
| `components/common/GlassButton.ets` | Immersive button with backdropBlur (no manual press animation) |
| `components/common/SearchBar.ets` | Search input with THIN backdropBlur surface |
| `constants/AppConstants.ets` | Version 2.0.0, route names, limits |
| `constants/MaterialConstants.ets` | 5-tier depth hierarchy constants + getBlur()/getOverlayColor() helpers |
| `utils/MaterialCapability.ets` | Device material detection via real `hdsMaterial.getSystemMaterialTypes()` |
| `model/MusicModel.ets` | Track, Playlist, NovidromeConfig, MusicPlayerConfig interfaces + Subsonic response types |
| `constants/MusicConstants.ets` | Music defaults (volume, repeatMode, shuffle), Navidrome API version, UI constants |
| `repository/MusicRepository.ets` | RDB CRUD for tracks, playlists, playlist-track junction (JOIN query) |
| `service/NavidromeApiClient.ets` | Subsonic REST API client — MD5 auth, getAllSongs(), getStreamUrl() uses no-f=json generator, batch album fetch |
| `service/MusicPlayerService.ets` | AVPlayer wrapper — release()+createAVPlayer() per track, state machine, prepare() on initialized, 30s load timeout |
| `viewmodel/MusicViewModel.ets` | @ObservedV2 singleton — playback, 5-tab browse, favorites playlist, favoriteTracks, playNovidromeTrack() for next/prev nav, @Trace playbackError |
| `pages/MusicPage.ets` | Pure Navidrome streaming browser — 5-tab (全部歌曲/歌手/专辑/歌单/❤️收藏) + favorites heart, Stack+Visibility anti-ghost |
| `pages/MusicPlayerPage.ets` | Full-screen Now Playing NavDestination — album art, controls, seek (no volume slider; prev button in header) |
| `components/business/MusicTrackItem.ets` | Track row with album art thumbnail, title, artist, duration |
| `components/business/MusicControls.ets` | Playback controls: shuffle, prev, play/pause, next, repeat |
| `components/business/MiniPlayer.ets` | Global mini player bar — self-contained, subscribes to MusicViewModel, play/pause/prev/next |

## Fixed Bugs (all verified with BUILD SUCCESSFUL)

1. **Add button crash** — `router.back()` → `navStack.pop()` (NoteDetailPage is NavDestination, not router page)
2. **Tabs unresponsive** — Navigation-wraps-Tabs → per-tab Navigation architecture
3. **@Provide navStack crash** — @BuilderParam doesn't propagate @Provide → moved to Index directly
4. **Save not appearing in list** — LazyForEach data source recreated each build → persistent DataSource + reloadData() + onShown refresh
5. **Sliders no visual effect** — Glass containers used @Consume (unreliable across NavDestination) → local @State + themeUpdateSignal
6. **Dark mode works, sliders don't** — Same root cause as #5, fixed by local @State approach
7. **Status bar overlaps content** — expandSafeArea included TOP → removed TOP + 44vp top padding on all page headers
8. **Filter menu (☰) no response** — click intercepted → added hitTestBehavior(HitTestMode.Block)
9. **TextArea clips text at edges** — default borderRadius → added borderRadius(0) + internal padding
10. **@Provide + @State can't combine** — used separate @State themeUpdateSignal variable
11. **Notes save not appearing (Round A/B/C)** — Multiple root causes:
    - NavDestination had 2 root children (Column + Stack FAB), violating single-child rule → wrapped in single Stack
    - NoteEditor initialContent prop updated async but @State localContent never resynced → added @Watch('syncInitialContent') with isUserEditing guard
    - ForEach keys were static (just note.id) → keys changed only on full rebuild → added refreshSignal + updatedAt to key
    - NavDestination.onShown() unreliable after navStack.pop() → added NavParams.triggerNotesRefresh callback: NotesPage registers it, NoteDetailPage calls it BEFORE popping
12. **Only one note displayed in list** — List+ListItem+ForEach has a HarmonyOS rendering bug where only the first child renders → replaced with Scroll+Column+ForEach (flat list, no grouping). Also moved .margin() from ListItem to inner Column.padding() to avoid ListItem margin layout issues.
13. **Delete note UI glitch** — GlassDialog's onClick calls both onConfirm() and controller.close(), causing overlapping dialog-close and nav-pop animations → onConfirm only sets isDeleting flag, @Watch('handleDelete') triggers actual delete+pop after dialog close starts. Added deleting overlay (LoadingProgress on semi-transparent bg).
14. **Note categories not customizable** — Added custom category TextInput + preset category chips (NOTE_CATEGORIES) in NoteDetailPage. User can type custom name or tap preset chip.
15. **Todo categories not customizable** — Added custom category TextInput + preset chips (PRESET_TODO_CATEGORIES = ['工作','个人','购物','学习','健康','其他']) + filtered user-created chips in TodoAddSheet. Added getOrCreateCategory() and findCategoryByName() to TodosViewModel.
16. **Todo description not viewable after creation** — Added description Text below title in TodoItem component with maxLines(2) and ellipsis overflow.
17. **Pomodoro start button no animation** — Added @State animScale for press animation (1.0→0.85→1.0) and ICON.PAUSE_BARS ('❚❚') for pause state.
18. **Database migration for category_id** — Added migrateDatabase() with ALTER TABLE ADD COLUMN for COL_NOTES_CATEGORY_ID on existing DB files. Added defensive getColumnIndex check in rowToNote().
19. **DatabaseHelper concurrent init race** — EntryAbility (fire-and-forget) and Index (awaited) both call initialize() → added initPromise field for deduplication.
20. **App icon** — Changed from $media:layered_image to $media:111.png in AppScope/app.json5 and module.json5.
21. **Tablet UI layout — one card per screen** — List+ListItem+ForEach bug combined with GlassContainer causing cards to stretch full height → rewrote NotesPage with Scroll+Column+ForEach, removed GlassContainer wrapper, added tablet grid/list toggle, NoteCard gridMode compact variant.
22. **GlassDialog tablet full-screen stretch** — @CustomDialog system container + Stack specular highlight .height('100%') caused dialog to fill screen on tablet → added customStyle:true, removed Stack+specular highlight, added explicit .width(340), constraintSize maxWidth/maxHeight, compact padding.
23. **All liquid glass effects removed** — User disliked glass effects → removed backdropBlur() across all 16 files, removed createGlassColor(), removed all specular highlight Stack overlays, removed glass sliders (opacity/blur) from SettingsPage, flattened all multi-layer glass components to single-layer solid surface.
24. **Pomodoro config not persisted after app restart** — SettingsPage initialized work/short/long break minutes from hardcoded defaults (25/5/15) ignoring saved preferences → added `loadSavedPomodoroConfig()` in `aboutToAppear()` that reads `PomodoroConfig` from `SettingsRepository` and populates @State sliders.
25. **Pomodoro timer durations not refreshing after settings change** (4 rounds) — Round 1: added `NavDestination.onShown()` + `PomodoroViewModel.reloadConfig()`. Round 2: added explicit `@State chipWorkSecs/chipShortSecs/chipLongSecs` synced via `syncChipDurations()`. Round 3: removed "保存番茄钟设置" button; added `onSliderChanged` callback + `schedulePomodoroSave()` + `persistConfig()` for immediate save-on-slide. Round 4: card duration text removed entirely (user preference) — `sessionTypeChip` now only shows label (专注/短休息/长休息), removed `@State chip*` fields and `syncChipDurations()`.
26. **Pomodoro start/pause button state not updating** (2 rounds) — Round 1: added `@State stateUpdateSignal` counter. Round 2: added `@Prop isRunning: boolean` + `@Prop stateSignal: number` to `PomodoroControls`; parent passes `this.isTimerRunning()` and `this.stateUpdateSignal`.
27. **Pomodoro circle uses multi-dash rotating animation** (4 rounds) — Round 1: circumference-based formula. Round 2: `.rotate({ angle: -90 })` for 12-o'clock start. Round 3: `strokeLineCap(Round)`→`Butt` + separate rotating dot Column. Round 4: `strokeDashArray` arc inherently creates visible artifacts at both dash ends (flat Butt caps look like cuts); replaced entirely with `Path` + SVG arc commands (`M … A …`) + `strokeLineCap(Round)` — Path draws an open stroke so Round cap only applies to the single arc endpoint, giving exactly ONE dot.
28. **Custom background image picker not working** — `DocumentViewPicker` → `photoAccessHelper.PhotoViewPicker`.
29. **Pomodoro config not persisted after app restart** — SettingsPage initialized sliders from hardcoded defaults → added `loadSavedPomodoroConfig()` in `aboutToAppear()`.
30. **Pomodoro timer resets when switching session types** — `setSessionType()` unconditionally called `timerService.reset()` → changed to conditional: only reset when `timerService.running || timerService.active` (PAUSED state); IDLE state skips reset and only updates type+duration.
31. **通知栏和实况窗做不好，全删了** — Removed all notification, Live View, and background task code because they didn't work reliably: deleted `NotificationService.ets`, `LiveViewService.ets`, `BackgroundTaskService.ets`; stripped all notification/LiveView/background-task logic from `PomodoroViewModel`; simplified `PomodoroPage.createViewModel()` and `SettingsPage.createPomodoroVM()` to only pass Repository + SettingsRepository; removed `NOTIFICATION_TIMER_ID`, `NOTIFICATION_SESSION_COMPLETE_ID` from `AppConstants`; removed `NOTIFICATION_UPDATE_INTERVAL_MS` from `PomodoroConstants`. Pomodoro timer now runs purely in-app with no system notifications or background keep-alive.
32. **Pomodoro 计时器改为挂钟时间戳驱动** — 原来用 `setInterval` + `remainingSeconds--` 递减，后台节流导致计时漂移。改为记录 `startTimestamp` + `pausedElapsed`，每次 tick 用 `Date.now()` 计算剩余时间。暂停时累加已过秒数到 `pausedElapsed`，恢复时重置 `startTimestamp`。计时精度不再依赖 setInterval 回调频率，切 tab 和退后台都不影响。
33. **计时器切 tab 重置修复** — HarmonyOS Tabs 会销毁非可见 TabContent，导致 PomodoroPage 的 aboutToDisappear → destroy() 销毁计时器，切回时 createViewModel() 重建全新 ViewModel → 计时重置。改为模块级单例：`initPomodoroViewModel()`/`getPomodoroViewModel()` 在 Index.initializeApp() 中创建一次，切 tab 时 PomodoroPage 只注销 tickHandler 不销毁 VM。SettingsPage 改为直接用 SettingsRepository 保存配置，不再创建多余的 PomodoroViewModel。
34. **v2.0 UI 升级：全项目应用沉浸深度材质** — 操作规范文档指引使用 HDS 沉浸光感组件，但 SDK API 24 不支持 `systemMaterial`/`ImmersiveMaterial` API。降级方案：用 `backdropBlur()` + 半透明背景模拟 5 级深度层级（ULTRA_THIN 4px → ULTRA_THICK 30px）。新建 `MaterialConstants.ets` 提供 `getBlur(level)` 和 `getOverlayColor(level, isDark)` 统一管理深度效果。20 个组件文件升级为 backdropBlur 模式：GlassCard(REGULAR)、GlassContainer(elevation映射)、GlassButton(THICK/THIN, 移除手动press动画)、GlassDialog(ULTRA_THICK)、SearchBar(THIN)、NoteCard(REGULAR+色条重构为内嵌Column)、TodoItem(REGULAR)、PomodoroSessionStats(REGULAR)、PomodoroControls(THICK/THIN)、ImagePickerButton(THIN)、ReminderPicker(THIN)、NotesPage(FAB+Chip)、TodosPage(FAB+Sheet+筛选)、PomodoroPage(类型Chip)、NoteDetailPage(顶栏+分类Chip)。ThemeConfig 新增 `materialLevel` 和 `immersiveEnabled` 字段。
35. **Tabs → HdsTabs 沉浸悬浮标签栏** — 操作规范文档确认 SDK API 24 支持 `@kit.UIDesignKit` (HdsTabs/HdsNavigation 从 API 23 起可用，`systemMaterial` 通用组件需 API 26)。`Tabs` → `HdsTabs` + `HdsTabsController`，添加 `barOverlap(true)` + `barBackgroundBlurStyle(Thick)` 实现底部标签栏沉浸模糊效果。保留 `tabBarBuilder` 自定义图标标签（`BottomTabBarStyle` 在 API 24 中不存在）。**升级**: `barBackgroundBlurStyle(Thick)` → `barFloatingStyle({ systemMaterialEffect })` 使用真正的 GPU 物理光感材质替代 CSS 模糊。
36. **番茄钟模式切换 Chip UI 不跟随** — `sessionTypeChip` 中使用 `this.viewModel.currentType` 判断选中态，但 `viewModel` 不是 `@State`，切模式后 ArkUI 不触发重渲染。添加 `@State currentType`，在 `onClick` 中同步 `this.currentType = type` 并更新 `displayRemaining`/`displayProgress`/`stateUpdateSignal`。
37. **NoteCard 卡片过大** — 非网格模式内边距 16px 过于宽松，减至 14px（网格模式 10px），多卡片列表更紧凑。
38. **Phase 3: 页面标题栏沉浸光感** — 5 个页面 (NotesPage/TodosPage/PomodoroPage/SettingsPage/NoteDetailPage) 的 Header Row 添加 `backdropBlur(THIN 8px)` + 半透明背景覆盖，实现弱毛玻璃标题栏效果。SettingsPage 补充缺失的 MaterialConstants import。
39. **Phase 4: 平板侧边栏材质化** — HdsSideBar 构造器 API 在 SDK 24 中与文档预期不符（sideBarPanelBuilder/contentPanelBuilder 不存在于构造器类型，.sideBar() 链式方法不存在），采用降级方案：保留自定义 Row(240vp sidebar + content) 布局，sidebar Column 升级为 backdropBlur(THICK 24px) + 半透明覆盖 + 保留边框分隔线。Index.ets 新增 MaterialConstants import。
40. **Phase 5: 设置页沉浸光感控件** — 新增「沉浸光感」设置区：启用/禁用 Toggle → themeVM.updateImmersiveEnabled()；材质质量四选一 Chip（自适应/精致/柔和/流畅）→ themeVM.updateMaterialLevel()。版本号显示同步为 2.0.0。
41. **包名修改** — `com.example.notes` → `com.lychee.memosflow`（AppScope/app.json5 bundleName）。
42. **全局状态管理 V1 → V2 迁移**（31 文件）— 按操作规范要求替换所有 V1 装饰器：`@ComponentV2`/`@Local`/`@Param`/`@Event`/`@Provider`/`@Consumer`/`@ObservedV2`/`@Trace`/`@Monitor`。`$` 双向绑定改为 `@Param`+`@Event` 回调。`DEFAULT_THEME_CONFIG` 供 `@Consumer` 编译占位。回调属性必须加 `@Event` 否则编译失败。`@CustomDialog` 保持不动。
43. **HdsTabs 真正沉浸光感材质** — `barBackgroundBlurStyle(Thick)`（CSS 高斯模糊）→ `barFloatingStyle({ systemMaterialEffect })`（GPU 物理光感材质）。`hdsMaterial.MaterialType.ADAPTIVE` + `hdsMaterial.MaterialLevel.ADAPTIVE` 让系统自动平衡效果与性能。`MaterialCapability.ets` 改用真实 `hdsMaterial.getSystemMaterialTypes()` API 检测设备能力（不再硬编码 `true`）。注：`BottomTabBarStyle` 在 SDK 24 仍不存在，保留自定义 `tabBarBuilder`；`systemMaterial` 通用组件属性需 API 26，非 HDS 组件继续使用 `backdropBlur` 降级。
44. **修复毛玻璃不透明问题** — 根因：页面 NavDestination 和卡片使用纯色 `backgroundColor`（`#F5F7FA`/`#FFFFFF`），完全遮挡 ThemeBackground 渐变光球，导致 backdropBlur 无内容可模糊（模糊纯白 = 纯白）。修复：① `MaterialConstants.getOverlayColor` 不透明度全面降低（THICK: 88→48%, REGULAR: 62→32%, THIN: 40→16%, ULTRA_THIN: 18→7%）；② 所有页面 NavDestination → `getOverlayColor(ULTRA_THIN)`；③ SettingsPage 6 个卡片 → `getOverlayColor(THIN)`；④ GlassTextField → `getOverlayColor(SURFACE)`。现在 ThemeBackground 渐变光球可穿透半透明层，backdropBlur 有真实色彩可模糊。
45. **模糊度/透明度自定义滑块** — `MaterialConstants` 新增 `blurMultiplier` 和 `opacityMultiplier` 全局倍率，`getBlur()`/`getOverlayColor()` 自动读取。`ThemeViewModel` 在 `updateGlassOpacity`/`updateBlurRadius`/`applyPreset`/`loadTheme` 中调用 `MaterialConstants.applyUserPreferences()` 同步倍率。SettingsPage 新增「毛玻璃效果」区域：模糊强度滑块（0-60, 默认 20）→ `updateBlurRadius()`；材质透明度滑块（5-100%, 默认 50%）→ `updateGlassOpacity()`。切换预设主题时自动同步滑块。所有 25+ 个 backdropBlur 调用点无需修改即可自动反映用户偏好。
46. **笔记页置顶布局** — 重构 NotesPage：移除固定 header+search+filter+scroll 层叠布局，改为 Scroll（全屏，从顶部开始）+ 浮动 translucent header overlay。标题栏和搜索栏缩小（fontSize 28→24, 按钮 40→36, 内边距缩减），浮动在 Scroll 上方，滚动时笔记穿透半透明 header。笔记列表从距顶部 ~120vp 缩减至 ~72vp。底部新增 80vp spacer 防止最后一条笔记被 FAB 遮挡。
47. **沉浸光感开关生效 + 背景图片修复** — ① `immersiveEnabled` 接入 `MaterialConstants.applyUserPreferences()`：关闭时 blur=0、opacity×3（表面变回纯平设计），开启时恢复用户模糊/透明度设置；② `ThemeBackground` 重写：自定义图片模式下隐藏渐变和光球（之前它们遮挡了用户图片），仅保留微弱 scrim 保证文字可读，`objectFit(Cover)` 兼容平板分屏宽高比变化，光球在平板模式稍大；③ 新增 `backgroundImageOpacity` 字段 + 设置页滑块（10%-100%），控制自定义背景图不透明度；④ `ThemeConfig` 新增 `backgroundImageOpacity` 字段，全链路贯通（model/presets/dark-theme/viewmodel/repository）。
48. **ThemeViewModel 大量 copy-paste 去重** — 11 个 mutation 方法各自枚举全部 15 个 ThemeConfig 字段（~260 行样板代码），添加新字段需同时修改 11 个方法。重构：提取 `cloneConfig()`（集中管理字段列表）+ `commitConfig(cfg)`（统一赋值+标记CUSTOM+持久化），每个 mutation 方法从 ~20 行缩减为 3-4 行。`MaterialConstants.applyUserPreferences()` 移动至 `saveTheme()`，所有 mutation 路径现在一致调用，消除 ad-hoc 散布。
49. **IconGlyphs PAUSE_BARS 与 PAUSE 重复** — 两者都是 `$r('sys.symbol.pause_fill')`，移除 PAUSE_BARS，PomodoroControls 改用 ICON.PAUSE。
50. **ThemeBackground private lighten() 与 ColorUtils.lightenColor 重复** — 移除私有方法，改用已有的 `lightenColor` 工具函数。
51. **SettingsPage schedulePomodoroSave 命名误导** — 方法立即保存无任何调度/防抖，重命名为 `persistPomodoroConfig`。
52. **待办退出后消失** — 根因：`TodosPage.onSave` 回调中 `handleTodoSave()` 没有 `await`，`showAddSheet = false` 在 DB 写入完成前就关闭了 sheet。`handleTodoSave` 是 fire-and-forget——用户点保存后 sheet 立即关闭，async 的 DB insert 在后台执行。如果用户在 DB 落盘前退出 app，todo 只存在内存里从未持久化。修复：① `onSave` 改为 async 并在关闭 sheet 前 `await handleTodoSave()`；② 新增 `isSaving` 状态防止重复提交；③ 新增 `refreshSignal` 计数，在 `loadData()` 完成后 +1 强制 UI 重建；④ `refreshSignal` 加入 LazyForEach key 确保异步数据到达后列表重新渲染；⑤ 抽取 `loadTodos()` 方法统一 `aboutToAppear` 和 `onShown` 调用，避免双重 `loadData` 竞态。
54. **页面模糊效果增强：卡片加模糊 + header 渐变过渡** — 用户反馈：① SettingsPage 所有卡片（主题配色、外观设置、毛玻璃效果、沉浸光感、背景图片、番茄钟、关于共 7 个 section）只有 `backgroundColor` 没有 `backdropBlur`，卡片完全无模糊；② 5 个页面 header 的 `backdropBlur(THIN)` 太死板——硬边矩形模糊，与下方内容无过渡。修复：① SettingsPage 全部 7 张卡片添加 `.backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))`；② 5 个页面 header 下方各新增 24-28vp 渐变过渡 Column（`linearGradient`：header 色 → `Color.Transparent`），实现从模糊区到清晰内容的平滑淡出。 — 三个根因：① ThemeBackground 光球全部在屏幕中上部（y: -40 / 40% / 70%），tab 栏位于底部（y: 85%+），背后只有 ~9% 透明度的微弱底色，GPU 材质无内容可采样；② `materialType: ADAPTIVE` 在设备不支持 IMMERSIVE 时静默退化到近乎不可见；③ 缺少 `gradientMask` 过渡层。修复：① ThemeBackground 新增底部两个光球（y: 80% 180vp + y: 88% 120vp），确保 tab 栏背后有丰富渐变色供材质采样；② `phoneLayout()` 改用 `supportsImmersive()` 运行时检测，支持时 `IMMERSIVE + EXQUISITE`，不支持时 `NONE` 避免无效材质开销；③ 新增 `gradientMask({ maskColor, maskHeight: 96 })` 创建内容到 tab 栏的平滑过渡；④ `tabBarBuilder` 选中 tab 增加 `primaryColor + '12-20%'` 半透明底色 pill + 250ms 动画，无论 GPU 材质是否渲染都提供可见的视觉反馈。
55. **TodoRepository 显式事务移除 + WAL checkpoint + post-insert 验证** — 笔记保存可持久化但待办不行：① 移除 TodoRepository 全部 6 个写操作的显式事务（`beginTransaction`/`commit`/`rollBack`），改为与 NoteRepository 完全一致的 plain `await this.store.insert/update/delete()`——NoteRepository 无事务能持久化，显式事务反而可能引入 WAL 刷新时序问题；② 新增 `PRAGMA wal_checkpoint(FULL)` 在执行 insert 后强制 WAL 刷盘（catch 忽略不支持的实现）；③ `createTodo` 新增 post-insert 读回验证（`getById` 确认数据可读）。
56. **Header 渐变过渡重构（无极模糊边界）** — 根因：TodosPage/PomodoroPage/SettingsPage 的 header 只有 inner title Row 有 `backgroundColor`，outer Column 无背景色但 backdropBlur 在 outer Column——导致梯度渐变从 16% 透明叠加开始且底色为透明，backdropBlur 的二元开/关边界在 header 底边形成可见切割线。修复：① 三个页面的 `backgroundColor` 从 inner title Row 移到 outer Column（匹配 NotesPage 验证过的模式），使整个 header 区域有统一 frosted 底色；② 最终去掉所有梯度 Column，header 模糊干净截止于标题栏边缘；③ spacer 调整至 80vp（后进一步调至 88vp）。
57. **待办保存架构重构：save logic 移入 TodoAddSheet** — 根因：笔记的 save button 和 async save logic 都在 NoteDetailPage 同一组件内，可以直接 `await`。待办的 save button 在 TodoAddSheet（子组件），save logic 在 TodosPage（父组件），通过 `@Event` 通信——`@Event` 要求 `=> void` 返回类型，导致 async 保存无法被 await。修复：将保存逻辑（`doSave()`）移入 TodoAddSheet 自身——像 `NoteDetailPage.saveNote()` 一样，`doSave()` 是 `private async` 方法直接 `await viewModel.createTodo()`，完成后才调用 `@Event onSaved` 通知父组件关 sheet。TodosPage 只需传 `viewModel` 给 sheet + onSaved 关 sheet，不再有 `handleTodoSave`。
58. **新增音乐播放器功能（5th tab）** — 完整音乐播放模块：① 本地音乐文件回放（AVPlayer + file:// URI）；② 全功能播放器 UI（Now Playing 全屏页 + 全局 MiniPlayer 悬浮条）；③ **Navidrome/Subsonic 流媒体集成** — MD5 认证、REST API（getArtists/getAlbums/getSongs/search3/stream）、可配置服务器地址+用户名+密码；④ 3 张新 RDB 表（music_tracks/music_playlists/music_playlist_tracks）；⑤ MusicViewModel 模块级单例（切 tab 不中断播放）；⑥ SettingsPage 新增"音乐服务"配置区（Toggle + TextInput + 测试连接）；⑦ 5 个新 UI 组件（MusicTrackItem/MusicControls/MiniPlayer + 2 页面）；⑧ 17 个新文件 + 8 个修改文件；⑨ 权限：INTERNET + READ_MEDIA。
59. **Navidrome 设置页无法连接（3 轮修复）** — 四个根因：① HarmonyOS NEXT 默认拦截 HTTP 明文流量（`cleartextTraffic` 未开启）；② `ping()` catch 块丢弃了错误信息，用户只看到泛泛「✗ 连接失败」；③ **MD5 实现 padding 数组大小 bug** — `paddedLen` 公式算出的是 32-bit 字数但 `new Array(paddedLen)` 把字数当字节数，密码 >8 字符时 bitLen 覆盖 input 字节，MD5 错误 → 认证失败；④ **Subsonic JSON 响应 envelope 未解包** — Navidrome 返回 `{"subsonic-response":{"status":"ok",...}}`，但代码直接读 `parsed.status` 而非 `parsed['subsonic-response']['status']`，`undefined === 'ok'` 永远 false → ping/getArtists/getAlbums/getSongs/search3 全部静默失败。修复：① module.json5 新增 `"network":{"cleartextTraffic":true}`；② NavidromeApiClient 新增 `lastError` 字段 + `getNovidromeError()` 暴露错误；③ SettingsPage 显示具体错误；④ 修正 `md5Hash` 数组大小为 `wordCount*4`；⑤ 新增 `unwrap()` helper 解包 `subsonic-response` envelope，`ping()`/`parseResponse()`/`getAlbums()`/`getSongs()` 全部改为先 unwrap 再访问字段。
60. **Navidrome 连接成功但音乐页无内容（4 轮修复）** — 根因：MusicPage 只展示本地 RDB 曲库，没有 Navidrome 远程浏览/导入 UI。修复：① MusicPage 新增 Navidrome 3 级层级浏览（艺术家→专辑→歌曲）集成在「全部」tab 内，连通状态显示「Navidrome 已连接」横幅+「浏览音乐」按钮；② 浏览视图使用 `isBrowsingNovidrome` 标志控制显隐，艺术家列表可「返回曲库」退出浏览；③ 歌曲行支持「导入」按钮（单曲入库）+「导入全部」按钮（整张专辑入库）；④ MusicViewModel 新增 `importNovidromeAlbum()` 批量导入方法；⑤ aboutToAppear 中如已配置且曲库为空自动进入浏览；⑥ 修复层级切换残影 bug：`novidromeIsBrowsing = true` 必须在 `novidromeBrowseLevel` 变更之前设置，防止旧数据先渲染再被 loading 覆盖。
62. **Navidrome 音乐点击播放无响应** — 根因：`getStreamUrl()` 和 `getCoverArtUrl()` 使用了 `generateAuthParams()`（含 `&f=json`），stream endpoint 接收 `f=json` 后可能返回 JSON 错误而非二进制音频数据，导致 AVPlayer 无法解码。修复：① 新增 `generateAuthParamsNoFormat()` 方法（不含 `&f=json`），`getStreamUrl()` 和 `getCoverArtUrl()` 改用此方法；② `MusicPlayerService.loadTrack()` 始终 `reset()` + `setVolume()` 确保干净的播放周期和音量；③ `play()` 方法新增 `initialized`/`idle` 状态处理——这些状态下设置 `autoPlayWhenReady` 标志延迟到 'prepared' 时自动播放。
63. **音乐页面多维度分类浏览 + 收藏歌单** — 原来只能按专辑浏览，操作不便。修复：① MusicPage 新增 4 个 Tab Chip（全部歌曲/歌手/专辑/歌单），默认选中「专辑」；② 全部歌曲：`NavidromeApiClient.getAllSongs()` 取全部专辑→批量并发取歌→聚合为扁平列表，直接点击播放；③ 歌手：`getArtists()` → 点击进入该歌手专辑列表 → 点击专辑进入歌曲列表；④ 专辑：保留原有专辑→歌曲浏览流程；⑤ 歌单：展示 RDB 播放列表（含自动创建的 ❤️ 收藏），点击进入歌曲列表；⑥ 每个歌曲行新增心形收藏按钮（`ICON.HEART`/`ICON.HEART_FILL`），点击即添加/移除到收藏歌单；⑦ `MusicViewModel` 新增 `browseNovidromeAllSongs()`、`ensureFavoritePlaylist()`、`toggleFavoriteTrack()`、`isTrackFavorited()`、`getPlaylistTracks()`、`playNovidromeTrack()` 方法；⑧ Tab 切换懒加载——仅在切换到对应 Tab 时才拉取数据。
64. **笔记详情页导航动画横向位移修复** — 根因：`Navigation` 默认 Stack 模式的 push/pop 动画是 Slide（从左滑入/向左滑出），导致笔记列表在 push 时 header 和卡片一起左滑才消失。修复：所有 `pushPathByName()` 和 `pop()` 调用传入第三个参数 `false` 禁用默认 Slide 动画。涉及 `NotesPage.ets`、`NoteDetailPage.ets`、`MusicPage.ets`、`MusicPlayerPage.ets`、`Index.ets`。SDK 24 中第三参数类型为 `animated?: boolean`，不是对象。**（注：#66 在此基础之上添加了手动 Fade 动画来实现平滑淡入淡出过渡。）**

65. **音乐播放完全失效 — AVPlayer reset 竞态条件** — 根因：`MusicPlayerService.loadTrack()` 调用 `player.reset()` 后立即设置 `player.url`，但 `reset()` 的状态转换是异步的（需要等待 'idle' 状态到达）。在 player 还在旧状态时设置 URL，随后 reset 生效会清除该 URL，导致播放静默失败——用户点击播放按钮后无任何响应。修复：① 新增 `waitForState()` Promise 辅助方法，在 `reset()` 后等待 'idle' 状态（5 秒超时+error 状态处理）；② `play()` 补充处理 'stopped'/'error'/'playing' 等遗漏状态；③ 修复 `loadTrack()` 中硬编码字符串 `'novidrome'` → 使用 `MusicSource.NOVIDROME` 枚举；④ `MusicViewModel` 新增 `@Trace playbackError` 字段 + 播放错误回调透传，错误信息现在可见于 UI；⑤ 'error' 状态回调增强：触发 `onErrorCallback` 并记录 hilog。

66. **导航动画过于生硬 — 手动 Fade 方案 → 最终简化为直接无动画** — 四轮迭代：① #64 把全部 push/pop 动画参数设为 `false` 禁用 Slide → 页面瞬间切换无过渡，生硬。② 第一轮修复把 `false` 恢复到 `true` → 恢复了平滑过渡但也带回了 Slide 横向位移（老组件跟着一起运动）。③ 第二轮修复：保持 `pushPathByName`/`pop` 使用 `false`（禁用默认 Slide），在 NavDestination 页面手动实现 Fade 动画：`@Local pageOpacity` + `aboutToAppear()` 中 `animateTo` 驱动 0→1（入场）、`animatedPop()` 先设 1→0 再 `setTimeout` 260ms → `pop(false)`（退场）。外层 Stack 加 `.opacity(this.pageOpacity).animation({ duration: 250, curve: Curve.EaseInOut })`。④ **最终方案（本轮 #70）**：手动 Fade 方案中的 `.animation({})` 属性会动画化 Stack 的**所有**属性变化（包括 Navigation push 期间的布局/位置变化），导致旧页面组件仍出现横向位移。最终移除所有手动动画代码（`pageOpacity`/`animateTo`/`animatedPop`/`.opacity().animation()`），改为纯 `pushPathByName(..., false)` + `pop(false)` 实现无动画页面切换。SDK API 24 中 `pageTransition` 属性在 `NavDestinationAttribute` 上不存在，`transition` 属性不接受 `{duration:0}` 简化参数，故无法通过声明式属性禁用系统过渡。

67. **Navidrome 缓存 + 播放加载超时 + 错误可见性** — 三个改进：① NavidromeApiClient 新增 API 响应缓存（Map + TTL 5 分钟），`sendGetRequest()` 读取/写入缓存，`updateConfig()` 自动清缓存。`getStreamUrl()` 中 trackId 加上 `encodeURIComponent`。② MusicPlayerService 新增 `loadTimeoutId` + 30 秒加载超时→自动报错，防止 AVPlayer HTTP stream 加载挂死无反馈。③ MusicPage 新增播放错误 banner（底部红条显示 `playbackError` + 关闭按钮），FAB 图标根据 `displayState` 切换 PLAY/MUSIC_LIST。

68. **音乐播放完全失效（红色错误条）— AVPlayer 缺少 `prepare()` 调用** — 根因：HarmonyOS AVPlayer 状态机要求 `idle → (set url) → initialized → (call prepare()) → prepared → (call play()) → playing`。`MusicPlayerService.setupListeners()` 的 stateChange handler 在 `'initialized'` 状态时只设 `PlayerState.LOADING` 但**从未调用 `player.prepare()`**，导致播放器永远卡在 `initialized` 状态，30 秒超时后进入 error 状态 → MusicPage 底部错误 banner 变红。修复：① stateChange handler 中 `'initialized'` 分支新增 `this.avPlayer.prepare()` 调用；② `play()` 方法中 `'initialized'` 状态也追加 `prepare()` 以防 handler 与 play() 的竞态。

69. **点击歌曲不跳转全屏播放页** — 根因：`MusicPage.songRow` 的 `onClick` 只调用 `viewModel.playNovidromeTrack()` 开始播放，没有 push `music_player` NavDestination。修复：在 `onClick` 中 `playNovidromeTrack()` 后添加 `this.navStack.pushPathByName('music_player', {} as Record<string, Object>, false)`，点击歌曲即跳转全屏 Now Playing 页面。

70. **笔记详情页动画残留（横向位移）— 手动 Fade .animation() 副作用** — 根因：NoteDetailPage/MusicPlayerPage 外层 Stack 的 `.animation({ duration: 250, curve: Curve.EaseInOut })` 会动画化 Stack **所有**属性变化（不仅 opacity），Navigation push 期间的布局/位置变化也被捕获并平滑化 → 旧页面组件出现横向位移。修复：移除所有手动 Fade 代码（`@Local pageOpacity`/`animateTo`/`animatedPop`/`.opacity().animation()`），改为直接 `navStack.pop(false)`。同时尝试 `.pageTransition({ duration: 0 })` → 编译器报错 `Property 'pageTransition' does not exist on type 'NavDestinationAttribute'`（SDK API 24 不支持）；尝试 `.transition({ duration: 0 })` → 编译器报错 `'duration' does not exist in type 'TransitionOptions | TransitionEffect<...>'`。最终采用纯 `pushPathByName(..., false)` + `pop(false)` 无动画方案（#66 最终方案）。

71. **切歌后无法播放 — AVPlayer release()+createAVPlayer() 替代 reset()** — 根因：切歌时 `loadTrack()` 调用 `player.reset()` 回到 idle，但旧 HTTP stream 的内部状态（缓冲数据、pending 回调）会干扰新 URL 的加载。此外，`reset()` 的异步 'released' 事件可能在重建新播放器后才到达，导致误设 `autoPlayWhenReady=false`。修复：`loadTrack()` 改为完全释放旧播放器 → 创建新实例：① `off()` 解绑所有事件监听；② `release()` 释放旧实例；③ `media.createAVPlayer()` 创建全新播放器（天然 idle 状态）；④ 重新 `setupListeners()`。去掉不再需要的 `ensurePlayer()` 和 `waitForState()` 方法。

72. **流媒体 URL 缓存 — 切歌更流畅** — NavidromeApiClient 新增：① `streamUrlCache: Map<string, string>` 缓存 `getStreamUrl()` 结果（含含随机 salt 的 auth token，token 无状态可复用）；② `coverArtUrlCache: Map<string, string>` 缓存 `getCoverArtUrl()` 结果；③ `invalidateCache()` 同时清空两个 URL 缓存。切歌时免重新生成 salt+MD5，直接复用已缓存的完整 stream URL。

73. **统一毛玻璃设计 — 音乐页面** — ① `MusicPage.songRow` 缺少 `backdropBlur`+`backgroundColor`（歌曲行透明无深度），新增 REGULAR 级模糊+半透明背景，与专辑/歌手/歌单行一致；② `MusicPlayerPage` 专辑封面占位列从 `SURFACE` 级纯色背景升级为 REGULAR 级 backdropBlur 材质。

74. **播放时底栏显示红色 — playbackError 未及时清除** — 根因：一旦触发过播放错误（如 prepare() 失败），`playbackError` 被设置后只在手动关闭或下次 `playTrack()` 时清除。若后续播放成功但 `playbackError` 未重置，红色错误条持续显示。修复：① `MusicViewModel` stateChange 回调中 `state === PLAYING` 时自动清除 `playbackError`；② `MusicPage` 错误条条件从 `playbackError !== ''` 改为 `displayState === ERROR && playbackError !== ''`（双重保险 —— 仅在 ERROR 状态时显示，PLAYING 时不可能出现红条）。

75. **音乐页面动画优化与残影消除** — ① MusicPage 内容区层级切换由 `visibility` 瞬切改为 `opacity` + `.animation({duration:200})` 平滑交叉淡入淡出，同时加 `hitTestBehavior(None)` 防止隐藏层误触；② MusicPlayerPage 新增 `animateTo` 入场淡入（200ms EaseOut）+ 退场淡出（150ms EaseIn）+ `pop(false)`，在无 Slide 的前提下实现柔和过渡。

76. **播放器页面 UI 优化 + 收藏分类 + MiniPlayer 增强** — ① MusicPlayerPage 左侧后退按钮改为上一首（PREVIOUS）按钮；② 移除音量调节滑块（系统音量可直接调整）；③ MusicPage 新增「❤️ 收藏」第 5 个 Tab，显示所有收藏曲目，支持点击播放和取消收藏；④ MusicPage 错误底栏从红色 `#C62828` 改为毛玻璃半透明（backdropBlur + getOverlayColor），与整体设计统一；⑤ MiniPlayer 底栏新增上一首按钮（位于标题右侧、播放/暂停左侧）；⑥ MusicViewModel 新增 `@Trace favoriteTracks: Track[]` + `loadFavoriteTracks()` 方法。

61. **专辑打开后无歌曲 + 无法流式播放 + MusicPage 重构为纯 Navidrome 流媒体（6 轮修复）** — 六个根因：⓪ **URL 双 `?` bug（第三轮新发现）** — `sendGetRequest()` 始终用 `?` 连接认证参数，当 endpoint 自带 `?`（如 `getAlbumList2?type=newest&size=500`）时 URL 变成 `...?type=newest&size=500?u=...`，第二个 `?` 之后全部被服务器当作 `size` 值的一部分，认证参数丢失 → 服务器返回错误 / 空数据；① **`getAlbumList2` JSON key 错误** — Subsonic `getAlbumList2` 返回 key `"albumList2"` 而非 `"albumList"`，代码读错 key → 永远 undefined；② **`getSongs()` 缺少 status 检查**；③ **错误静默吞噬** — catch 块设 `=[]` 丢弃异常；④ **AVPlayer 播放竞态条件** — `play()` 先于 prepared 状态调用导致静默无操作；⑤ **MusicPage 架构错位 + 过渡残影** — 没有本地音乐却保留本地曲库标签；`if/else` 条件渲染导致旧视图销毁→新视图创建的布局动画，旧窗口随新窗口一起运动。修复：⓪ `sendGetRequest` 检测 endpoint 含 `?` 则用 `&` 连接认证参数；① `SubsonicAlbumListResponse` 新增 `albumList2?:`；② `getSongs()` 新增 status 检查 + `encodeURIComponent` + 单曲兼容；③ MusicViewModel 新增 `@Trace novidromeError`；④ `autoPlayWhenReady` + `reset()`；⑤ MusicPage 完全重写 — 移除本地标签/导入按钮；**用 Stack + Visibility 替代 if/else**，两个视图同时挂载瞬间切换无销毁重建 → 根除过渡残影；loading 遮罩在 browseLevel 变更之前先设 true。

## ArkTS Strict Rules
- No spread operator `...` → explicit property copy when creating new ThemeConfig
- No indexed access `obj['key']` → use static NavParams class
- No `any`, no `unknown`, no untyped object literals
- `@Builder` params are value snapshots → use `@ComponentV2` + `@Param` for reactive bindings
- @CustomDialog renders in overlay → pass themeConfig as param, not @Consumer
- Field initializers run before @Consumer resolves → use `aboutToAppear()` for dependent init
- GradientDirection only: Top, Bottom, Left, Right (no diagonals)

## V2 State Management Rules (enforced by compiler)
- All components use `@ComponentV2` (NOT `@Component`)
- `@Local` replaces `@State`; `@Param` replaces `@Prop`
- `@Link` is REMOVED → use `@Param` + `@Event` pattern (parent passes value + callback)
- `@Provider`/`@Consumer` replace `@Provide`/`@Consume` (@Consumer needs default value)
- `@ObservedV2` + `@Trace` replace `@Observed` (@Trace on tracked properties)
- `@Monitor('propName')` replaces `@Watch('methodName')` (decorates method, not property)
- **Callback properties set by parents MUST have `@Event`** or compiler rejects them
- `@Entry` and `@CustomDialog` stay as-is (not V1 state management)
- `@Builder` and `@BuilderParam` unchanged

## Icon System
- `import { ICON } from '../utils/IconGlyphs'`
- Key icons: BACK=‹, MENU=☰, PLUS=+, DELETE=✕, NOTES=☷, TODOS=☑, POMODORO=◷, VOICE=🎤, SETTINGS=⚙, EMPTY_NOTES=☷, CLOSE=✕, PIN=📌, EDIT=✎, VIEW_GRID=▦, VIEW_LIST=☰

## Version
- **Bundle name**: `com.lychee.memosflow`
- `AppScope/app.json5`: versionCode=1001001, versionName="2.1.0"
- `entry/oh-package.json5`: version="2.1.0"
- `constants/AppConstants.ets`: APP_VERSION='2.1.0'
- `pages/SettingsPage.ets`: displays "版本 2.1.0 · HarmonyOS NEXT"
- App icon: `111.png` in `AppScope/resources/base/media/` and `entry/src/main/resources/base/media/`
