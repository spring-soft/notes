# MemoFlow

> 沉浸光感 · 专注于心 — HarmonyOS NEXT 备忘录应用

<p align="center">
  <img src="AppScope/resources/base/media/111.png" width="96" height="96" alt="MemoFlow icon" />
</p>

**MemoFlow** 是一款基于 **HarmonyOS NEXT** 的全功能备忘录应用，融合笔记、待办、番茄钟与深度主题定制，采用五级沉浸材质层级系统打造空间纵深感。

---

## ✨ 功能

### 📝 笔记
- 创建、编辑、删除笔记，支持颜色标签和分类
- 列表 / 网格双视图切换（平板）— 搜索、排序、过滤一站式
- Markdown 风格编辑器，200 字标题 + 50K 字正文
- 浮动毛玻璃标题栏 — 滚动时笔记穿透半透明 Header

### ✅ 待办
- 分组管理（工作 / 个人 / 购物 / 学习 / 健康 + 自定义）
- 完成状态切换，描述文字显示
- 底部分类筛选条 + 自定义品类创建
- 上拉添加面板，智能预设 Chip + 自定义输入

### 🍅 番茄钟
- 工作 / 短休息 / 长休息三模式，可配置时长
- 挂钟时间戳驱动 — 后台切 Tab 不漂移，毫秒级精度
- SVG Path 弧线进度环，单圆点旋转动画
- 模块级单例 ViewModel — 切 Tab 不重置

### 🎨 主题
- 8 套预设配色（海洋蓝 / 日落橙 / 森林绿 / 薰衣草 / 樱桃粉 / 深夜青 / 暖琥珀 / 石板灰）
- 深色模式一键切换
- 自定义背景图片 + 透明度滑块
- 圆角 / 字号自由调节

### 🌐 沉浸光感 (v2.1)
- 5 级材质深度层级：极薄(4px) → 薄(8px) → 常规(16px) → 厚(24px) → 极厚(30px)
- 模糊强度滑块 (0–60px) + 材质透明度滑块 (5%–100%)
- 沉浸光感总开关 — 开启毛玻璃 / 关闭平铺
- **真正的 GPU 物理光感材质**：HdsTabs 底部标签栏使用 `barFloatingStyle({ systemMaterialEffect })`
- 非 HDS 组件降级：`backdropBlur()` + 半透明背景覆盖

### 📱 平板适配
- 断点响应式（600/840 vp），侧边栏 + 内容区双栏布局
- 侧边栏沉浸材质表面 (24px blur)
- 笔记网格 / 列表模式自由切换

---

## 🛠 技术栈

| 类别 | 技术 |
|------|------|
| 平台 | HarmonyOS NEXT 6.1.1 (SDK API 24) |
| 语言 | ArkTS strict mode（无 `any`/`unknown`，无 spread，无 indexed-access） |
| 架构 | Stage 模型，per-tab Navigation + NavPathStack |
| UI 框架 | ArkUI V2 — `@ComponentV2`, `@ObservedV2`, `@Trace`, `@Provider`/`@Consumer` |
| 状态管理 | V2 全量迁移（`@Local`/`@Param`/`@Event` 替代 `@State`/`@Prop`/`@Link`） |
| 设计系统 | `@kit.UIDesignKit` (HdsTabs + hdsMaterial), `backdropBlur()` fallback |
| 数据库 | 关系型数据库 (RDB) + Preferences 键值对 |
| 图标 | HarmonyOS SymbolGlyph 系统原生图标（30+） |
| 构建 | DevEco Studio → `hvigorw assembleHap` |

---

## 📂 项目结构

```
entry/src/main/ets/
├── pages/                     # 页面
│   ├── Index.ets              # 入口 — @Provider 源 + HdsTabs + 平板侧边栏
│   ├── NotesPage.ets          # 笔记列表（浮动 Header + Scroll+ForEach）
│   ├── NoteDetailPage.ets     # 笔记编辑/创建
│   ├── TodosPage.ets          # 待办分组列表
│   ├── PomodoroPage.ets       # 番茄钟计时
│   └── SettingsPage.ets       # 主题 / 毛玻璃 / 沉浸光感 / 番茄钟设置
│
├── components/
│   ├── business/              # 业务组件
│   │   ├── NoteCard.ets       # 笔记卡片（色条 accent border-left）
│   │   ├── NoteEditor.ets     # 笔记编辑器（@Monitor 同步 + isUserEditing 守卫）
│   │   ├── ColorPicker.ets    # 颜色选择网格
│   │   ├── ImagePickerButton.ets  # 背景图片选择
│   │   ├── TodoItem.ets       # 待办项
│   │   ├── TodoAddSheet.ets   # 待办添加面板
│   │   ├── TodoCategoryHeader.ets # 分类头
│   │   ├── PomodoroCircle.ets # 番茄钟 SVG Path 弧线进度环
│   │   ├── PomodoroControls.ets   # 番茄钟控制按钮
│   │   ├── PomodoroSessionStats.ets # 番茄钟统计
│   │   └── ReminderPicker.ets # 提醒时间拾取器
│   │
│   └── common/                # 通用组件
│       ├── GlassDialog.ets    # 自定义对话框（ULTRA_THICK 30px blur）
│       ├── GlassContainer.ets # 沉浸容器（elevation 映射 blur 级别）
│       ├── GlassCard.ets      # 沉浸卡片（内嵌 accent 色条）
│       ├── GlassButton.ets    # 沉浸按钮（backdropBlur 交互反馈）
│       ├── GlassTextField.ets # 沉浸输入框
│       ├── SearchBar.ets      # 搜索栏（THIN 8px blur）
│       ├── ThemeBackground.ets    # 全屏渐变背景 + 光球 + 自定义图片
│       ├── EmptyState.ets     # 空状态提示
│       └── LoadingSpinner.ets # 加载动画
│
├── viewmodel/                 # 视图模型层
│   ├── ThemeViewModel.ets     # 主题状态管理（cloneConfig / commitConfig 去重）
│   ├── NotesViewModel.ets     # 笔记 CRUD + 搜索 / 排序 / 过滤
│   ├── TodosViewModel.ets     # 待办 + 分类管理
│   └── PomodoroViewModel.ets  # 番茄钟逻辑（模块单例）
│
├── repository/                # 数据仓库层
│   ├── DatabaseHelper.ets     # RDB 单例（initPromise 去重）
│   ├── NoteRepository.ets     # 笔记 SQL CRUD
│   ├── TodoRepository.ets     # 待办 SQL CRUD
│   └── SettingsRepository.ets # Preferences 读写
│
├── model/                     # 数据模型
│   ├── ThemeConfigModel.ets   # ThemeConfig 接口 + 预设枚举
│   ├── NoteModel.ets          # 笔记实体
│   ├── PomodoroSessionModel.ets # 番茄钟类型 / 状态枚举
│   └── AppConstantsModel.ets  # 基础类型别名 (ColorHex, Seconds)
│
├── constants/                 # 常量
│   ├── AppConstants.ets       # 应用名 / 版本号 / DB 名 / 限制
│   ├── MaterialConstants.ets  # 5 级深度层级 + getBlur() / getOverlayColor()
│   ├── ThemeConstants.ets     # 8 套预设配色 + 深色覆写
│   ├── PomodoroConstants.ets  # 番茄钟默认值 / 范围
│   └── ColorConstants.ets     # 颜色盘
│
├── utils/                     # 工具
│   ├── IconGlyphs.ets         # 30+ SymbolGlyph 资源常量
│   ├── ColorUtils.ets         # hexToRgba / lightenColor / darkenColor / isDarkColor
│   ├── NavParams.ets          # 页面参数传递（noteId + triggerNotesRefresh 回调）
│   ├── MaterialCapability.ets # 设备材质能力检测（hdsMaterial API）
│   └── DateUtils.ets          # 日期格式化
│
└── service/                   # 服务层
    ├── PomodoroTimerService.ets # 挂钟时间戳计时器
    └── WindowService.ets       # 状态栏样式同步
```

---

## 🔨 构建 & 运行

### 前置条件
- DevEco Studio (API 24+)
- HarmonyOS NEXT 设备或模拟器

### 构建

```bash
hvigorw assembleHap
```

产物位于 `entry/build/default/outputs/default/entry-default-signed.hap`。

### 安装到设备

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

---

## 📐 架构要点

### 数据流
```
Index (root)
├── @Provider → themeConfig, themeVM, navStack, isTablet
├── HdsTabs 容器
│   ├── Navigation(navStack[0]) → NavDestination('notes_list') → NotesPage
│   ├── Navigation(navStack[1]) → NavDestination('todos_list') → TodosPage
│   ├── Navigation(navStack[2]) → NavDestination('pomodoro') → PomodoroPage
│   └── Navigation(navStack[3]) → NavDestination('settings') → SettingsPage
└── 平板: Row(240vp sidebar + NavDestination content)
```

### 状态管理 (V2)
- `@ComponentV2` 替代 `@Component`，所有组件
- `@Local` / `@Param` / `@Event` 替代 `@State` / `@Prop` / `@Link`
- `@Provider` / `@Consumer` 替代 `@Provide` / `@Consume`
- `@ObservedV2` + `@Trace` 替代 `@Observed`
- `@Monitor('propName')` 替代 `@Watch('methodName')`
- 回调属性必须加 `@Event`

### 材质系统
```
Layer 5 (极厚 30px):   GlassDialog, 底部面板      — 最高隐私
Layer 4 (厚 24px):     FAB 按钮, 平板侧边栏
Layer 3 (常规 16px):   卡片, 容器
Layer 2 (薄 8px):      搜索栏, Chip, 页面 Headers
Layer 1 (极薄 4px):    页面背景 NavDestination
Layer 0 (无 blur):     ThemeBackground 渐变画布
```

---

## 📄 许可证

仅限个人使用。

---

<p align="center">
  <b>MemoFlow</b> v2.1.0 · HarmonyOS NEXT · Made with ❤️
</p>
