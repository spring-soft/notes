# MemoFlow

**MemoFlow** — HarmonyOS NEXT 备忘录应用，采用简洁实用的设计风格。

## 功能

- **笔记** — 创建、编辑、删除笔记，支持分类标签和颜色标记
- **待办** — 待办事项管理，支持分组、优先级和完成状态
- **番茄钟** — 番茄工作法计时器，可配置工作和休息时长
- **语音备忘录** — 录制和播放语音备忘
- **主题** — 8 种预设主题配色，支持深色模式切换
- **平板适配** — 响应式布局，平板侧边导航 + 网格视图

## 技术栈

| 类别 | 技术 |
|------|------|
| 平台 | HarmonyOS NEXT 6.1.1 (SDK API 24) |
| 语言 | ArkTS (strict mode) |
| 架构 | Stage 模型，Navigation + Tabs 导航 |
| 数据库 | 关系型数据库 (RDB) + Preferences |
| 构建 | hvigorw assembleHap |

## 版本

**1.0.1**

## 项目结构

```
entry/src/main/ets/
├── pages/              # 页面组件
│   ├── Index.ets       # 入口，导航和标签页
│   ├── NotesPage.ets   # 笔记列表
│   ├── NoteDetailPage.ets  # 笔记编辑
│   ├── TodosPage.ets   # 待办列表
│   ├── PomodoroPage.ets    # 番茄钟
│   ├── VoiceMemoPage.ets   # 语音备忘录
│   └── SettingsPage.ets    # 设置
├── components/
│   ├── business/       # 业务组件
│   └── common/         # 通用组件
├── viewmodel/          # 视图模型层
├── repository/         # 数据仓库层
├── model/              # 数据模型
├── utils/              # 工具函数
├── constants/          # 常量定义
└── service/            # 服务层
```

## 构建

```bash
hvigorw assembleHap
```

## 许可

仅限个人使用。
