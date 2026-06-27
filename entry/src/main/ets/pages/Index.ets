import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { ThemeConfig, ThemePreset } from '../model/ThemeConfigModel';
import { BreakpointType, WindowSize, calculateBreakpoint, isTablet } from '../model/BreakpointModel';
import { SettingsRepository } from '../repository/SettingsRepository';
import { DatabaseHelper } from '../repository/DatabaseHelper';
import { TabItemConfig, getTabItems, NavDestinationNames } from '../constants/AppConstants';
import { ThemeBackground } from '../components/common/ThemeBackground';
import { MaterialConstants } from '../constants/MaterialConstants';
import { ICON } from '../utils/IconGlyphs';
import { common } from '@kit.AbilityKit';
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { NotesPage } from './NotesPage';
import { NoteDetailPage } from './NoteDetailPage';
import { TodosPage } from './TodosPage';
import { PomodoroPage } from './PomodoroPage';
import { SettingsPage } from './SettingsPage';
import { initPomodoroViewModel, PomodoroViewModel } from '../viewmodel/PomodoroViewModel';
import { PomodoroRepository } from '../repository/PomodoroRepository';

/**
 * Root navigation shell for the app.
 * - Provides ThemeConfig and ThemeViewModel to all child components via @Provide/@Consume.
 * - Detects screen breakpoints for responsive phone/tablet layout.
 * - Phone: Tabs with per-tab Navigation (each tab has its own NavPathStack + navDestination builder)
 * - Tablet: Side navigation panel with per-section Navigation
 */
@Entry
@Component
struct Index {
  @Provide('themeConfig') themeConfig: ThemeConfig = {
    primaryColor: '#4A90D9',
    backgroundColor: '#E8F0FE',
    surfaceColor: '#FFFFFF',
    textColor: '#1A2530',
    textSecondaryColor: '#5F6B7A',
    glassOpacity: 0.2,
    glassBlurRadius: 20,
    backgroundImageUri: '',
    isDarkMode: false,
    accentColor: '#4A90D9',
    fontScale: 1.0,
    borderRadius: 16,
    materialLevel: 0,
    immersiveEnabled: true,
  };
  @Provide('themeVM') themeVM: ThemeViewModel = new ThemeViewModel(
    new SettingsRepository(this.getAppContext()),
    this.getAppContext()
  );
  @Provide('navStack') currentNavStack: NavPathStack = new NavPathStack();
  @Provide('isTablet') isTablet: boolean = false;

  @State currentTabIndex: number = 0;
  @State windowSize: WindowSize = { width: 0, height: 0, breakpoint: BreakpointType.SM };
  @State isInitialized: boolean = false;
  @State themeUpdateSignal: number = 0;

  private tabsController: HdsTabsController = new HdsTabsController();
  private tabItems: TabItemConfig[] = getTabItems();
  // Per-tab NavPathStacks (shared by phone + tablet layouts)
  private tabNavStacks: NavPathStack[] = [
    new NavPathStack(),  // [0] Notes
    new NavPathStack(),  // [1] Todos
    new NavPathStack(),  // [2] Pomodoro
    new NavPathStack(),  // [3] Settings
  ];

  aboutToAppear(): void {
    this.currentNavStack = this.tabNavStacks[0];
    this.initializeApp();
  }

  private async initializeApp(): Promise<void> {
    const appContext: common.Context = this.getAppContext();
    await DatabaseHelper.getInstance().initialize(appContext);
    await this.themeVM.loadTheme();
    this.themeConfig = this.themeVM.themeConfig;

    // Initialize the module-level PomodoroViewModel singleton so the timer
    // survives tab switches (Tabs destroys non-visible TabContent).
    const pomodoroRepo: PomodoroRepository = new PomodoroRepository(DatabaseHelper.getInstance().getStore());
    const settingsRepo: SettingsRepository = new SettingsRepository(appContext);
    const pomodoroVM: PomodoroViewModel =
      initPomodoroViewModel(pomodoroRepo, settingsRepo);
    await pomodoroVM.initialize();

    // Sync @Provide('themeConfig') whenever themeVM changes
    // themeUpdateSignal forces Index + all children to re-render via @State
    this.themeVM.setThemeChangeListener((config: ThemeConfig) => {
      this.themeConfig = config;
      this.themeUpdateSignal++;
    });
    this.isInitialized = true;
  }

  private getAppContext(): common.Context {
    const ctx: common.Context = this.getUIContext().getHostContext() as common.Context;
    return ctx.getApplicationContext();
  }

  build() {
    if (!this.isInitialized) {
      Column() {
        LoadingProgress()
          .width(48)
          .height(48)
          .color('#4A90D9');
        Text('加载中...')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .margin({ top: 16 });
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#1A2530');
    } else {
      Stack() {
        ThemeBackground();
        if (isTablet(this.windowSize.breakpoint)) {
          this.tabletLayout();
        } else {
          this.phoneLayout();
        }
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onAreaChange((_oldArea: Area, newArea: Area) => {
        const widthVp: number = newArea.width as number;
        if (widthVp > 0) {
          const bp: BreakpointType = calculateBreakpoint(widthVp);
          this.windowSize = {
            width: widthVp,
            height: newArea.height as number,
            breakpoint: bp,
          };
          this.isTablet = isTablet(bp);
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Phone layout — Tabs + per-tab Navigation with navDestination builders
  // ═══════════════════════════════════════════════════════════════════

  @Builder
  phoneLayout() {
    HdsTabs({ controller: this.tabsController, index: this.currentTabIndex }) {
      // Tab 0 — Notes
      TabContent() {
        Navigation(this.tabNavStacks[0]) {
          NotesPage();
        }
        .mode(NavigationMode.Stack)
        .hideTitleBar(true)
        .hideToolBar(true)
        .navDestination(this.notesDetailBuilder)
      }
      .tabBar(this.tabBarBuilder(this.tabItems[0], 0));

      // Tab 1 — Todos
      TabContent() {
        Navigation(this.tabNavStacks[1]) {
          TodosPage();
        }
        .mode(NavigationMode.Stack)
        .hideTitleBar(true)
        .hideToolBar(true)
      }
      .tabBar(this.tabBarBuilder(this.tabItems[1], 1));

      // Tab 2 — Pomodoro
      TabContent() {
        Navigation(this.tabNavStacks[2]) {
          PomodoroPage();
        }
        .mode(NavigationMode.Stack)
        .hideTitleBar(true)
        .hideToolBar(true)
      }
      .tabBar(this.tabBarBuilder(this.tabItems[2], 2));

      // Tab 3 — Settings
      TabContent() {
        Navigation(this.tabNavStacks[3]) {
          SettingsPage();
        }
        .mode(NavigationMode.Stack)
        .hideTitleBar(true)
        .hideToolBar(true)
      }
      .tabBar(this.tabBarBuilder(this.tabItems[3], 3));
    }
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .barHeight(64)
    .barBackgroundBlurStyle(BlurStyle.Thick)
    .scrollable(false)
    .onChange((index: number) => {
      this.tabNavStacks[this.currentTabIndex].clear();
      this.currentTabIndex = index;
      this.currentNavStack = this.tabNavStacks[index];
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // Tablet layout — side panel + per-section Navigation
  // ═══════════════════════════════════════════════════════════════════

  @Builder
  tabletLayout() {
    Row() {
      // Left side navigation panel — immersive material surface
      Column() {
        Text('MemoFlow')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.textColor)
          .padding({ left: 20, top: 20, bottom: 28 });

        ForEach(this.tabItems, (tab: TabItemConfig, index: number) => {
          this.sideNavItem(tab, index);
        }, (tab: TabItemConfig) => tab.id);
      }
      .width(240)
      .height('100%')
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.THICK))
      .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.THICK, this.themeConfig.isDarkMode))
      .border({
        width: { right: 1 },
        color: this.themeConfig.isDarkMode
          ? 'rgba(255, 255, 255, 0.08)'
          : 'rgba(0, 0, 0, 0.06)',
        style: BorderStyle.Solid,
      });

      // Right side content — per-section Navigation
      Column() {
        this.tabletSectionContent();
      }
      .layoutWeight(1)
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  tabletSectionContent() {
    if (this.currentTabIndex === 0) {
      Navigation(this.tabNavStacks[0]) {
        NotesPage();
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideToolBar(true)
      .width('100%')
      .height('100%')
      .navDestination(this.notesDetailBuilder);
    } else if (this.currentTabIndex === 1) {
      Navigation(this.tabNavStacks[1]) {
        TodosPage();
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideToolBar(true)
      .width('100%')
      .height('100%');
    } else if (this.currentTabIndex === 2) {
      Navigation(this.tabNavStacks[2]) {
        PomodoroPage();
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideToolBar(true)
      .width('100%')
      .height('100%');
    } else if (this.currentTabIndex === 3) {
      Navigation(this.tabNavStacks[3]) {
        SettingsPage();
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideToolBar(true)
      .width('100%')
      .height('100%');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NavDestination builders (used by Navigation.navDestination)
  // These create NavDestinations on demand when NavPathStack.pushPathByName is called
  // ═══════════════════════════════════════════════════════════════════

  @Builder
  notesDetailBuilder(name: string, param: Object) {
    if (name === 'note_detail') {
      NoteDetailPage();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Tab bar / side nav builders
  // ═══════════════════════════════════════════════════════════════════

  @Builder
  tabBarBuilder(tab: TabItemConfig, index: number) {
    Column() {
      SymbolGlyph(this.getTabIcon(tab.id))
        .fontSize(24)
        .fontColor([
          this.currentTabIndex === index
            ? this.themeConfig.primaryColor
            : this.themeConfig.textSecondaryColor
        ]);
      Text(tab.title)
        .fontSize(11)
        .fontColor(
          this.currentTabIndex === index
            ? this.themeConfig.primaryColor
            : this.themeConfig.textSecondaryColor
        )
        .margin({ top: 4 });
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8 });
  }

  @Builder
  sideNavItem(tab: TabItemConfig, index: number) {
    Row() {
      SymbolGlyph(this.getTabIcon(tab.id))
        .fontSize(22)
        .fontColor([
          this.currentTabIndex === index
            ? this.themeConfig.primaryColor
            : this.themeConfig.textSecondaryColor
        ])
        .margin({ right: 12 });

      Text(tab.title)
        .fontSize(16)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(
          this.currentTabIndex === index
            ? this.themeConfig.primaryColor
            : this.themeConfig.textColor
        );
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 4 })
    .backgroundColor(
      this.currentTabIndex === index
        ? (this.themeConfig.isDarkMode
          ? this.themeConfig.primaryColor + '25'
          : this.themeConfig.primaryColor + '15')
        : Color.Transparent
    )
    .onClick(() => {
      this.tabNavStacks[this.currentTabIndex].clear();
      this.currentTabIndex = index;
      this.currentNavStack = this.tabNavStacks[index];
    })
    .animation({ duration: 200, curve: Curve.EaseInOut });
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  private getTabIcon(tabId: string): Resource {
    if (tabId === 'notes') {
      return ICON.NOTES;
    } else if (tabId === 'todos') {
      return ICON.TODOS;
    } else if (tabId === 'pomodoro') {
      return ICON.POMODORO;
    } else if (tabId === 'settings') {
      return ICON.SETTINGS;
    }
    return ICON.EMPTY_GENERAL;
  }
}
