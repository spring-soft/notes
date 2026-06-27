# MemoFlow Project Context

## Project
- **Name**: MemoFlow — HarmonyOS NEXT memo app with liquid glass UI
- **Path**: `E:\program\notes`
- **Version**: 1.1.0
- **Platform**: HarmonyOS NEXT 6.1.1 (SDK API 24), Stage model
- **Language**: ArkTS strict mode (no `any`, no spread `...`, no indexed access `obj['key']`)
- **Target**: phone + tablet (responsive breakpoints at 600/840 vp)
- **Build**: DevEco Studio → `hvigorw assembleHap`

## Architecture

### Navigation (per-tab Navigation pattern)
```
Index.ets (@Entry, @Provide source)
├── Tabs (5 tabs, barPosition: End)
│   ├── TabContent[0] → Navigation(navStack[0]) → NotesPage
│   ├── TabContent[1] → Navigation(navStack[1]) → TodosPage
│   ├── TabContent[2] → Navigation(navStack[2]) → PomodoroPage
│   ├── TabContent[3] → Navigation(navStack[3]) → VoiceMemoPage
│   └── TabContent[4] → Navigation(navStack[4]) → SettingsPage
└── Tablet: Row(sideNav 240vp + content area with per-section Navigation)
```

### Page routing
- Only `Index.ets` is `@Entry` (in main_pages.json)
- All sub-pages are `@Component struct` wrapped in `NavDestination(){}`
- Navigation uses `navDestination(builder)` — builder checks `name` param
- `NavParams` static class for parameter passing (no indexed access)
- `navStack.pushPathByName('note_detail', {})` — requires 2 args
- `navStack.pop()` to go back

### State management (@Provide/@Consume)
```
Index provides:
  @Provide('themeConfig') themeConfig: ThemeConfig
  @Provide('themeVM') themeVM: ThemeViewModel
  @Provide('navStack') currentNavStack: NavPathStack
  @State themeUpdateSignal: number  ← forces re-render when theme changes
```
- 29 components consume `@Consume('themeConfig')`
- `@BuilderParam` does NOT pass `@Provide` down (renders in caller's context)
- `@Provide` alone may not trigger re-render across Navigation boundaries → `themeUpdateSignal++` guarantees it
- Theme change chain: slider → themeVM.update*() → saveTheme() → notifyThemeChange() → Index listener → @Provide update + themeUpdateSignal++

### Settings page sliders (instant preview)
- Glass containers use **local @State** (`blurRadius`, `borderRadiusValue`, `glassOpacity`) for instant visual feedback
- `SettingSliderComponent` uses `@Component` + `@Link` (NOT @Builder — parameters are snapshots)
- themeVM.update*() called simultaneously for persistence + other pages
- Added `createGlassBg(opacity, isDark)` helper for dynamic glass background color

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
| `pages/Index.ets` | Root, @Provide source, tab+nav layout, theme sync listener |
| `pages/NotesPage.ets` | Notes list with search, sort filter, FAB, LazyForEach |
| `pages/NoteDetailPage.ets` | Note create/edit NavDestination, save via navStack.pop() |
| `pages/SettingsPage.ets` | Theme presets, glass sliders (local @State), pomodoro config |
| `viewmodel/ThemeViewModel.ets` | @Observed, listener pattern, all update methods create new ThemeConfig |
| `viewmodel/NotesViewModel.ets` | @Observed, CRUD, search, sort, filter |
| `repository/DatabaseHelper.ets` | RDB singleton, getStore() throws if not initialized |
| `repository/NoteRepository.ets` | Notes SQL CRUD |
| `repository/SettingsRepository.ets` | Preferences read/write for theme + pomodoro |
| `utils/IconGlyphs.ets` | ICON static class — 25+ Unicode icon chars |
| `utils/NavParams.ets` | Static noteId + needsNotesRefresh + triggerNotesRefresh callback |
| `components/business/NoteEditor.ets` | TextArea with @Watch sync, borderRadius(0), isUserEditing guard |
| `components/business/NoteCard.ets` | Liquid-glass note card with color tag border + specular highlight |
| `components/business/TodoAddSheet.ets` | Bottom sheet: custom category TextInput + preset chips + filtered user chips |
| `components/business/TodoItem.ets` | Todo list item with description display |
| `components/common/GlassDialog.ets` | CustomDialog — themeConfig via param (not @Consume) |
| `constants/AppConstants.ets` | Version 1.1.0, route names, limits |
| `model/NoteModel.ets` | Note interface + NOTE_CATEGORIES presets + NoteSortOrder enum |
| `model/TodoModel.ets` | TodoItem, TodoCategory, PRESET_TODO_CATEGORIES, TodoPriority, TodoFilterType |

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

## ArkTS Strict Rules
- No spread operator `...` → explicit property copy when creating new ThemeConfig
- No indexed access `obj['key']` → use static NavParams class
- No `any`, no untyped object literals
- `@Builder` params are value snapshots → use `@Component` + `@Link` for reactive bindings
- @CustomDialog renders in overlay → pass themeConfig as param, not @Consume
- Field initializers run before @Consume resolves → use `aboutToAppear()` for dependent init
- GradientDirection only: Top, Bottom, Left, Right (no diagonals)

## Icon System
- `import { ICON } from '../utils/IconGlyphs'`
- Key icons: BACK=‹, MENU=☰, PLUS=+, DELETE=✕, NOTES=☷, TODOS=☑, POMODORO=◷, VOICE=🎤, SETTINGS=⚙, PAUSE_BARS=❚❚, EMPTY_NOTES=📝, CLOSE=✕, PIN=📌

## Version
- `AppScope/app.json5`: versionCode=1000001, versionName="1.1.0"
- `entry/oh-package.json5`: version="1.1.0"
- `constants/AppConstants.ets`: APP_VERSION='1.1.0'
- `pages/SettingsPage.ets`: displays "版本 1.1.0 · HarmonyOS NEXT"
- App icon: `111.png` in `AppScope/resources/base/media/` and `entry/src/main/resources/base/media/`
