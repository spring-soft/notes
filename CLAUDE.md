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
├── HdsTabs (4 tabs, barPosition: End, barOverlap)
│   ├── TabContent[0] → Navigation(navStack[0]) → NotesPage
│   ├── TabContent[1] → Navigation(navStack[1]) → TodosPage
│   ├── TabContent[2] → Navigation(navStack[2]) → PomodoroPage
│   └── TabContent[3] → Navigation(navStack[3]) → SettingsPage
└── Tablet: Row(sideNav 240vp + content area with per-section Navigation)
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
- 5 tables: notes, todo_categories, todos, pomodoro_sessions, voice_memos
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
