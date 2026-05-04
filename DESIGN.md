# Sudoku Flutter — 设计文档（Stage 1）

> 本文档对应原始需求的产品设计阶段。代码实现遵循本设计；如发现偏差，需要先回到本文修正。

---

## 1. 产品需求整理

### 1.1 需求映射（原始需求 → 功能项）

| # | 原始需求 | 功能项 |
|---|---------|--------|
| 1 | 美观界面 + 舒适交互 | Material 3 主题、自适应布局、点按反馈、九宫格视觉分隔、固定数字与玩家输入区分 |
| 2 | 简单/中级/高级/专家难度 | `Difficulty` 枚举；每个难度独立的 `hintLimit / mistakeLimit / blanks` 配置 |
| 3 | 笔记功能 | 每个格子最多 9 个候选数；切换“笔记模式”输入；橡皮擦清除 |
| 4 | 计时 + 平均/最快统计 + 历史 | `Stopwatch` 服务；`Hive` 持久化 `GameRecord`；统计页按难度聚合 |
| 5 | 高亮相同数字 + 自动检查错误 | 选中格联动行/列/宫高亮；同值高亮；冲突格红色描边；可在设置中开关 |
| 6 | 退出后恢复 + 新开 | 启动时探测 `current_game`；首页提供“继续/新游戏”；退出/暂停自动落盘 |
| 7 | 暗夜模式 | `ThemeMode.{system,light,dark}`，设置页可切换 |
| 8 | DIY 玩法 | 自定义 `blanks / hintLimit / mistakeLimit / 是否启用自动检查` 等，保存为预设 |
| 9 | README | 完整的开发/构建/发布说明 |
| 10 | 设计先行 + 测试 | 本文档 + `test/` 单元与功能测试 |

### 1.2 用户使用场景

1. **通勤途中的快速一局**：用户打开 App，点击“继续游戏”恢复昨晚未完成的高级局，倒计时继续累加；填错一次后红色提示，使用一次提示后剩余 1 次。
2. **挑战自己最快纪录**：用户选择“专家”，开始新局；完成后看到弹窗显示用时 12:35，统计页显示该难度最快 11:02、平均 14:20，最快记录未被打破。
3. **自定义难度训练**：高级玩家进入 DIY，将挖空数设为 64、提示数 0、错误次数 0、关闭自动检查，作为“极限模式”保存预设并开局。
4. **夜间使用**：用户在设置中切换暗黑模式，棋盘与按键均切换为高对比深色配色，长时间游戏不刺眼。

---

## 2. 游戏机制设计

### 2.1 难度参数

| 难度 | 挖空数 (blanks) | 提示次数 (hintLimit) | 容错次数 (mistakeLimit) | 备注 |
|------|----------------:|---------------------:|------------------------:|------|
| Easy   | 36 | 5 | 5 | 适合新手，错误 5 次或提示 5 次后才进入失败/无提示 |
| Medium | 46 | 3 | 4 | 标准 |
| Hard   | 52 | 2 | 3 | 进阶 |
| Expert | 58 | 1 | 1 | 一击必杀 |
| DIY    | 自定义 17–64 | 自定义 0–9 | 自定义 0–9 | 见 §2.3 |

**生成策略**：
1. 通过随机化的回溯算法生成一个完整解（保证存在唯一解）。
2. 按难度对应的 `blanks` 数量随机挖空；每次尝试挖空后调用求解器计数，若解唯一则保留，否则回退该格。
3. 受时间约束：求解器在第二个解出现时立即剪枝，复杂度可控。
4. 生成结束后将原解保存到 `solution`，玩家面板保存到 `puzzle`，玩家当前编辑保存到 `current`。

### 2.2 失败 / 胜利

- 错误次数达到 `mistakeLimit + 1`（即用尽容错） → 弹窗“游戏失败”，可选择查看答案或重新开始。
- 所有 81 格匹配 `solution` → 触发胜利，记录耗时进入统计；弹窗显示是否为新纪录。

### 2.3 DIY 模式扩展机制

- DIY 复用同一引擎，仅替换 `DifficultyConfig`。
- 用户可保存多个 DIY 预设（`Hive` Box: `diy_presets`），每个预设包含名称与配置。
- 预留扩展字段 `extraRules`（`Map<String,dynamic>`），未来可加入“对角线数独”、“杀手数独”等变体规则；当前仅校验标准九宫规则。

---

## 3. 功能模块拆分

```
core/
  sudoku/         数独引擎：Board / Generator / Solver / Validator
  models/         Difficulty, DifficultyConfig, GameState, GameRecord, CellState
  storage/        Hive 封装：StorageService（current_game / records / settings / diy_presets）
  timer/          GameTimer（带 pause/resume，可序列化 elapsedMs）
features/
  home/           首页：Continue / New / Stats / Settings / DIY 入口
  game/           棋盘页：BoardWidget / NumberPad / ActionBar；GameController(Riverpod)
  stats/          统计页：按难度聚合、列表
  settings/       设置页：主题、同值高亮、自动检查开关
  diy/            DIY 页：表单 + 预设管理
  theme/          ThemeController + 主题数据
shared/widgets/   通用组件：AppButton, ConfirmDialog 等
```

| 模块 | 职责 |
|------|------|
| 引擎 | 生成、求解、校验，纯 Dart，无 Flutter 依赖（便于单测） |
| 状态管理 | Riverpod Notifier；GameController 持有 GameState 不可变快照 |
| UI | 棋盘九宫格、数字盘、笔记开关、提示按钮、撤销 |
| 笔记 | 每格 `Set<int> notes`；填入数字时清空；笔记数字与正式数字视觉区分 |
| 计时 | `GameTimer` 内部 `Stopwatch` + 心跳 stream；UI 仅订阅当前 `elapsed` |
| 存储 | Hive：`current_game` 单条；`records` List；`settings` 单条；`diy_presets` List |
| 统计 | 从 `records` 计算每个难度的最快/平均/局数 |
| 主题 | Light/Dark/System，颜色与棋盘描边随主题切换 |
| 恢复 | App 启动时若 `current_game` 存在且未完成则恢复 |

---

## 4. 技术方案

- **框架**：Flutter（最低 SDK 3.4，Dart 3.4），单一代码库构建 iOS + Android。
- **状态管理**：**Riverpod 2.x**（`flutter_riverpod`）。
  - 选择理由：相比 Bloc 模板代码更少；`Notifier` + 不可变 `GameState` 与本应用“以状态快照驱动”的模式契合；天然支持依赖注入与测试覆盖。
- **本地存储**：**Hive**（`hive` + `hive_flutter`）。
  - 选择理由：性能优于 `SharedPreferences`，原生支持结构化对象；`GameState` 与 `GameRecord` 字段较多，更适合 Hive。
  - 为减少代码生成依赖，本项目使用手写 `TypeAdapter`/`toJson` 方式（不依赖 build_runner），降低 onboarding 成本。
- **计时**：`Stopwatch` + `Timer.periodic(1s)` 心跳。
- **目录结构**：

```
sudoku/
├── DESIGN.md
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── sudoku/
│   │   │   ├── board.dart
│   │   │   ├── generator.dart
│   │   │   ├── solver.dart
│   │   │   └── validator.dart
│   │   ├── models/
│   │   │   ├── difficulty.dart
│   │   │   ├── game_state.dart
│   │   │   └── stats.dart
│   │   ├── storage/
│   │   │   └── storage_service.dart
│   │   └── timer/
│   │       └── game_timer.dart
│   ├── features/
│   │   ├── home/home_page.dart
│   │   ├── game/
│   │   │   ├── game_page.dart
│   │   │   ├── game_controller.dart
│   │   │   └── widgets/
│   │   │       ├── board_widget.dart
│   │   │       ├── number_pad.dart
│   │   │       └── action_bar.dart
│   │   ├── stats/stats_page.dart
│   │   ├── settings/
│   │   │   ├── settings_page.dart
│   │   │   └── settings_controller.dart
│   │   ├── diy/diy_page.dart
│   │   └── theme/theme_controller.dart
│   └── shared/widgets/confirm_dialog.dart
└── test/
    ├── engine_test.dart
    ├── storage_test.dart
    └── timer_test.dart
```

---

## 5. 交互设计

### 5.1 页面结构

- **首页 Home**：Logo + “继续游戏”（仅当存在存档）/“新游戏（选择难度）”/“DIY”/“统计”/“设置”。
- **游戏页 Game**：顶部 AppBar（返回、暂停/继续、计时、错误次数 X/Y、提示次数）；中部棋盘；底部数字盘 + 操作行（撤销 / 笔记 / 提示 / 擦除）。
- **统计页 Stats**：按难度分组卡片，展示局数、最快、平均；底部“清空记录”。
- **设置页 Settings**：主题、同值高亮、自动检查、关于。
- **DIY 页 DIY**：表单（挖空/提示/错误次数/自动检查）+ 预设列表 + “保存预设”“开始游戏”。

### 5.2 用户流程

```
启动 → 加载存档检测
       ├─ 有未完成局 → 首页“继续游戏”可点
       └─ 无       → 仅“新游戏”
新游戏 → 选难度（或 DIY 进入 DIY 页）→ 生成局 → 进入 Game
Game：选格 → 输入数字（或长按/切换笔记输入）→ 自动校验
       ├─ 提示按钮：消耗 hint，将选中格填正确答案
       ├─ 撤销：回退一步
       ├─ 暂停：计时停止，棋盘遮挡
       └─ 退出：自动保存 current_game
完成：胜利动画 + 写入 records；失败：弹窗 + 选择重玩
统计页：从 records 聚合渲染
设置页：实时生效；切换主题立刻刷新
```

### 5.3 关键交互细节

- **同值高亮**：选中数字 X 时，棋盘上所有等于 X 的格高亮淡蓝；同行同列同宫淡灰底色。
- **错误高亮**：自动检查打开时，与解答冲突或与同行/列/宫已有数字冲突的格用红色文字+描边。
- **笔记**：进入笔记模式后，点数字添加/移除候选；正式落子会清空该格笔记，并清掉同行列宫该数字的笔记。
- **暂停**：计时停止，棋盘以模糊遮挡。

---

## 6. 验收标准（Checklist）

| ID | 验收项 | 关联需求 |
|----|--------|----------|
| AC-1 | App 在 iOS 与 Android 上启动到首页无 crash | #1 |
| AC-2 | 棋盘 9x9 视觉清晰，3x3 宫粗描边，固定数字与输入数字色彩区分 | #1 |
| AC-3 | 至少 4 档难度可选，每档参数符合 §2.1 表 | #2 |
| AC-4 | 笔记开关可切换，候选数显示在格子小字位置 | #3 |
| AC-5 | 计时正确，暂停/恢复无误差累计 | #4 |
| AC-6 | 完成局写入记录，统计页按难度聚合显示总局数/最快/平均 | #4 |
| AC-7 | 选中数字时，所有同值高亮 | #5 |
| AC-8 | 启用自动检查时，冲突格高亮 | #5 |
| AC-9 | 退出 App 后再次进入有“继续游戏” | #6 |
| AC-10 | 同时支持新开（覆盖存档前提示） | #6 |
| AC-11 | 设置页可切换 light/dark/system，立刻生效 | #7 |
| AC-12 | DIY 页可设定挖空/提示/错误次数/规则并保存预设 | #8 |
| AC-13 | README 包含介绍 / 功能 / 技术 / 运行 / 构建 / 目录 | #9 |
| AC-14 | `flutter test` 全部通过：引擎、存储、计时 | #10 |

— 至此 Stage 1 完成 —
