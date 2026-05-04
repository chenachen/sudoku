# Sudoku · Flutter

一个使用 Flutter 实现的、同时支持 iOS 与 Android 的数独游戏。具备多难度、笔记、计时、统计、暗夜模式、DIY 玩法以及"退出后继续上次游戏"等完整功能。

> 设计与验收标准请参阅 [DESIGN.md](DESIGN.md)。

---

## ✨ 功能

- 🎚 4 档内置难度：**简单 / 中级 / 高级 / 专家**，每档独立的提示次数 / 容错次数 / 挖空数。
- 🛠 **DIY 模式**：自定义挖空数、提示次数、容错次数与是否启用自动检查；可保存多个预设。
- ✏️ **笔记**：每格最多 9 个候选数，落子时自动清理同行/列/宫笔记。
- ⏱ **计时**：暂停 / 继续不计入用时；后台/锁屏自动落盘。
- 📈 **统计**：按难度展示总局数、胜利数、最快用时、平均用时；可清空。
- 🎨 **同值高亮 + 自动检查**：选中格联动行/列/宫高亮，冲突格红色描边；可在设置中开关。
- 🌙 **暗夜模式**：浅色 / 深色 / 跟随系统三档可切换。
- 💾 **退出后继续**：未完成的对局自动持久化，下次启动一键恢复。
- ✅ **唯一解保证**：生成器在挖空时实时验证唯一解（求解器在出现第二个解时立刻剪枝）。

---

## 🧱 技术选型

| 关注点 | 方案 | 备注 |
|--------|------|------|
| UI 框架 | Flutter (>=3.22) | Material 3 |
| 语言 | Dart 3.4+ | null-safe |
| 状态管理 | [Riverpod 2](https://riverpod.dev) | `Notifier` + 不可变 `GameState` |
| 本地存储 | [Hive 2](https://docs.hivedb.dev) | 轻量、快速；存储为 JSON-friendly Map，不依赖 `build_runner` |
| 计时 | `Stopwatch` + `Timer.periodic` | 1Hz 心跳 |
| 测试 | `flutter_test` | 引擎 / 存储 / 计时 |

理由：相较 Bloc，Riverpod 模板代码更少，且天然支持 Provider override 用于测试与启动期注入；相较 SharedPreferences，Hive 更适合存储 `GameState` 等复杂结构。

---

## 🗂 项目结构

```
sudoku/
├── DESIGN.md                  # 完整设计文档
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart              # 启动入口，注入 StorageService
│   ├── app.dart               # MaterialApp + 主题
│   ├── core/
│   │   ├── sudoku/            # 引擎：board / solver / generator / validator
│   │   ├── models/            # Difficulty / GameState / Stats
│   │   ├── storage/           # Hive 持久化封装
│   │   └── timer/             # GameTimer
│   ├── features/
│   │   ├── home/              # 首页
│   │   ├── game/              # 棋盘页 + 控制器 + 子组件
│   │   ├── stats/             # 统计页
│   │   ├── settings/          # 设置页 + Settings Notifier
│   │   ├── diy/               # DIY 模式
│   │   └── theme/             # 主题 Notifier + 颜色
│   └── shared/widgets/        # 通用组件
└── test/
    ├── engine_test.dart       # 数独引擎单测
    ├── storage_test.dart      # 存档 / 记录 / 预设
    └── timer_test.dart        # 计时暂停 / 恢复
```

---

## 🚀 开发与运行

### 1. 准备环境

- 安装 [Flutter SDK ≥ 3.22](https://docs.flutter.dev/get-started/install)
- iOS 构建需 macOS + Xcode 15+；Android 构建需 Android Studio / SDK 33+。

```bash
flutter --version
flutter doctor
```

### 2. 第一次拉取后

> 仓库只包含跨平台 Dart 源码与设计、文档、测试。各平台脚手架（`ios/`、`android/`、`macos/` 等）由 Flutter 工具按当前 SDK 版本生成，避免随 SDK 升级而 churn。

```bash
flutter create .          # 生成 ios/ android/ 等平台目录（首次执行）
flutter pub get
```

### 3. 运行

```bash
flutter run               # 自动选择已连接的设备/模拟器
flutter run -d ios
flutter run -d android
```

### 4. 测试

```bash
flutter test
```

预期会跑通 `test/engine_test.dart`、`test/storage_test.dart`、`test/timer_test.dart`。

### 5. 静态分析

```bash
flutter analyze
```

---

## 📦 构建与发布

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK / App Bundle（推荐 AAB 上 Play）
flutter build apk --release
flutter build appbundle --release
```

签名：在 `android/app/build.gradle` 中配置 `signingConfigs`，并将密钥放在 `android/key.properties`（参考 [官方文档](https://docs.flutter.dev/deployment/android)）。

### iOS

```bash
# 模拟器
flutter build ios --simulator

# 真机 (需开发者账号 + 在 Xcode 中配置 Signing)
flutter build ipa --release
open build/ios/archive/Runner.xcarchive
```

之后通过 Xcode Organizer 或 `xcrun altool`、Transporter 上传至 App Store Connect。详见 [官方文档](https://docs.flutter.dev/deployment/ios)。

---

## 🧪 验收清单

| ID | 验收项 | 状态 |
|----|--------|------|
| AC-1 | App 可在 iOS / Android 启动到首页 | ✅ |
| AC-2 | 棋盘 9×9，3×3 宫粗描边，固定数字与玩家输入区分 | ✅ |
| AC-3 | 4 档难度可选 | ✅ |
| AC-4 | 笔记开关 + 候选数显示 | ✅ |
| AC-5 | 计时正确、暂停可恢复 | ✅ |
| AC-6 | 统计页按难度聚合（局数/最快/平均） | ✅ |
| AC-7 | 同值高亮 | ✅ |
| AC-8 | 自动检查冲突高亮 | ✅ |
| AC-9 | 退出后再进入有"继续游戏" | ✅ |
| AC-10 | 新开覆盖前提示确认 | ✅ |
| AC-11 | 主题：浅色 / 深色 / 跟随系统 | ✅ |
| AC-12 | DIY 表单 + 预设保存 | ✅ |
| AC-13 | README 完整 | ✅ |
| AC-14 | `flutter test` 全部通过 | ✅ |

---

## 📝 许可

本项目仅作为示例工程使用。
