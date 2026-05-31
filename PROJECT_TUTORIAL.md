# 起身 App 项目教程：从需求到 iOS 上架

这份文档把 `起身` 这个 Flutter 项目整理成一份可复用教程。它不是只列命令，而是按“为什么要做、怎么拆、代码放在哪里、外部资源从哪里来、以后怎么继续迭代”的顺序复盘整个应用。

适合三类读者：

- 想理解这个项目架构的人。
- 想手动维护或发布这个 App 的人。
- 想照着这个项目做一个类似轻量工具 App 的人。

## 1. 项目目标

`起身` 是一个面向久坐人群的轻量运动提醒 App。它的核心目标不是做复杂健身课程，而是在工作间隙降低“开始活动身体”的心理门槛。

### 1.1 用户问题

目标用户通常有这些问题：

- 长时间坐在电脑前，容易忘记起身。
- 想活动一下，但不知道马上做什么动作。
- 不希望每次都打开复杂训练计划。
- 希望动作短、简单、适合办公室。
- 希望可以加入自己的动作和视频素材。

### 1.2 产品定位

这个 App 的定位是：

```text
久坐提醒 + 随机动作 + 轻量动作库 + 本地自定义视频
```

它刻意不做账号系统、云同步、社交、订阅课程等功能。这样可以让第一版更容易完成、测试和上架，也降低隐私合规压力。

## 2. 功能拆解

当前版本实现了以下功能：

| 模块 | 功能 |
| --- | --- |
| 首页 | 显示提醒状态、今日完成次数、随机抽取入口、分类入口 |
| 定时提醒 | 设置提醒开关，按间隔触发本地通知 |
| 随机推荐 | 从动作库中加权随机选择动作，减少近期重复 |
| 动作跟练 | 视频播放、倒计时、完成记录、跳过 |
| 动作库管理 | 查看、添加、编辑、删除自定义动作 |
| 分类管理 | 查看和维护动作分类 |
| 视频导入 | 从本地选择 MP4/MOV，并复制到 App 沙盒 |
| 历史记录 | 记录完成/跳过的 session |
| 设置 | 管理提醒间隔等偏好 |

## 3. 为什么选择 Flutter

这个项目选择 Flutter，主要是因为：

- 一套代码可以覆盖 Android 和 iOS。
- 适合快速构建自定义视觉风格。
- 本地数据库、通知、视频播放、文件选择等能力都有成熟插件。
- iOS 上架需要原生工程，但 Flutter 可以生成并维护大部分结构。

当前项目的 Flutter/Dart 版本要求来自 `pubspec.lock`：

```text
Dart: >=3.12.0 <4.0.0
Flutter: >=3.44.0
```

## 4. 技术栈总览

### 4.1 Flutter 侧依赖

依赖声明在 `pubspec.yaml`：

| 依赖 | 来源 | 用途 |
| --- | --- | --- |
| `flutter` | Flutter SDK | UI 框架 |
| `sqflite` | pub.dev | SQLite 本地数据库 |
| `path` | pub.dev | 拼接数据库路径 |
| `path_provider` | pub.dev | 获取 App 沙盒目录 |
| `flutter_local_notifications` | pub.dev | 本地定时通知 |
| `timezone` | pub.dev | 时区感知通知调度 |
| `video_player` | pub.dev | 播放动作视频 |
| `shared_preferences` | pub.dev | 保存提醒开关、提醒间隔等轻量配置 |
| `intl` | pub.dev | 日期/格式化预留 |
| `provider` | pub.dev | 状态管理预留 |
| `file_picker` | pub.dev | 从设备选择视频文件 |
| `flutter_lints` | pub.dev | Dart/Flutter 代码规范 |

注意：`intl` 和 `provider` 当前不是核心路径中强依赖的设计支点，更像是后续扩展预留。

### 4.2 iOS 原生依赖

iOS 依赖由 CocoaPods 管理，锁定在 `ios/Podfile.lock`。

直接来自 Flutter 插件的 Pod：

| Pod | 来源 | 对应 Flutter 插件 |
| --- | --- | --- |
| `file_picker` | `.symlinks/plugins/file_picker/ios` | `file_picker` |
| `flutter_local_notifications` | `.symlinks/plugins/flutter_local_notifications/ios` | `flutter_local_notifications` |
| `shared_preferences_foundation` | `.symlinks/plugins/shared_preferences_foundation/darwin` | `shared_preferences` |
| `sqflite_darwin` | `.symlinks/plugins/sqflite_darwin/darwin` | `sqflite` |
| `video_player_avfoundation` | `.symlinks/plugins/video_player_avfoundation/darwin` | `video_player` |

间接引入的第三方 iOS 原生库：

| Pod | 版本 | 为什么会出现 |
| --- | --- | --- |
| `DKImagePickerController` | 4.3.9 | `file_picker` 在 iOS 上选择媒体文件需要 |
| `DKPhotoGallery` | 0.0.19 | `DKImagePickerController` 的图片/媒体预览依赖 |
| `SDWebImage` | 5.21.7 | `DKPhotoGallery` 的图片加载依赖 |
| `SwiftyGif` | 5.4.5 | `DKPhotoGallery` 的 GIF 支持依赖 |

### 4.3 本地工具链

这个项目 iOS 发布实际用到：

| 工具 | 用途 |
| --- | --- |
| Flutter SDK | 构建 Flutter App |
| Dart SDK | 编译 Dart 代码 |
| Xcode | iOS 真机调试、归档、上传 App Store Connect |
| CocoaPods 1.16.2 | 安装 iOS 插件依赖 |
| Git/GitHub | 版本管理和远端同步 |
| App Store Connect | 元数据、隐私、价格、构建选择、提交审核 |

## 5. 项目结构

核心代码都在 `lib/`：

```text
lib/
├── main.dart
├── models/
│   ├── exercise.dart
│   ├── exercise_category.dart
│   └── session_record.dart
├── screens/
│   ├── home_screen.dart
│   ├── exercise_screen.dart
│   ├── exercise_manager_screen.dart
│   ├── exercise_form_screen.dart
│   ├── category_manager_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
└── services/
    ├── database_service.dart
    ├── exercise_service.dart
    ├── notification_service.dart
    └── video_service.dart
```

其他关键文件：

| 文件 | 作用 |
| --- | --- |
| `pubspec.yaml` | Flutter 项目信息、依赖、资源声明 |
| `ios/Podfile` | iOS CocoaPods 配置和兼容性补丁 |
| `ios/Runner/Info.plist` | iOS 权限、Bundle 配置、出口合规声明 |
| `APP_STORE_PRIVACY.md` | App Store 隐私说明 |
| `APP_STORE_SUBMISSION_GUIDE.md` | 手动提交审核流程 |

## 6. 架构设计

这个项目采用轻量分层：

```text
Screens -> Services -> Models -> Local Storage / Native Plugins
```

### 6.1 Screens 层

Screens 是 UI 和用户交互入口。它们直接调用 service，不再额外加复杂状态管理层。

当前项目规模不大，这样做的好处是：

- 文件少。
- 调试直观。
- 适合单人快速迭代。

代价是：

- 当页面继续增加时，状态逻辑会分散。
- 后续如果加入账号、云同步、订阅，需要再引入更清晰的状态层。

### 6.2 Services 层

Services 封装平台能力和业务逻辑：

| Service | 责任 |
| --- | --- |
| `DatabaseService` | SQLite 建表、迁移、预置数据、CRUD、统计 |
| `ExerciseService` | 随机推荐和分类轮转 |
| `NotificationService` | 本地通知初始化、调度、取消、权限 |
| `VideoService` | 文件选择、视频校验、复制到沙盒 |

### 6.3 Models 层

Models 是数据库记录和业务对象的桥：

| Model | 对应数据 |
| --- | --- |
| `Exercise` | 一个动作 |
| `ExerciseCategory` | 一个动作分类 |
| `SessionRecord` | 一次运动尝试或完成记录 |

每个 model 都提供 `toMap()` 和 `fromMap()`，用于和 SQLite 表互相转换。

## 7. 启动流程详解

入口在 `lib/main.dart`。

启动流程：

1. `WidgetsFlutterBinding.ensureInitialized()` 确保 Flutter 插件可用。
2. 设置系统状态栏、导航栏颜色。
3. 初始化 `NotificationService`。
4. 注册通知点击回调。
5. 运行 `StandUpApp`。

通知点击后的流程：

```text
用户点击提醒通知
-> payload == reminder
-> ExerciseService.recommendWithRotation()
-> 找到一个推荐动作
-> navigatorKey 打开 ExerciseScreen
```

这里使用了全局 `navigatorKey`，因为通知回调发生时不一定有页面上下文。这个做法适合本项目这种简单跳转。

## 8. 数据模型详解

### 8.1 Exercise

`Exercise` 表示一个运动动作。

关键字段：

| 字段 | 含义 |
| --- | --- |
| `id` | SQLite 自增 ID |
| `name` | 动作名称 |
| `description` | 动作说明 |
| `categoryId` | 分类 ID |
| `durationSeconds` | 建议运动时长 |
| `videoPath` | 视频路径或资源名 |
| `videoSource` | `asset` 或 `file` |
| `difficulty` | `easy`、`medium`、`hard` |
| `tags` | 标签数组，数据库里用逗号字符串存 |
| `equipment` | 器材，例如 `none`、`chair`、`mat` |
| `isBuiltin` | 是否内置动作 |

设计要点：

- 内置动作不允许随便删除。
- 自定义动作可以携带用户本地视频。
- `videoSource` 让同一个页面同时支持内置资源和用户文件。

### 8.2 ExerciseCategory

`ExerciseCategory` 表示分类。

它除了数据库字段，还内置两个静态资源池：

- `iconPool`：分类可选 Material 图标。
- `colorPool`：分类可选主题色。

这些不是外部图片资源，而是 Flutter Material Icons 和颜色值。

### 8.3 SessionRecord

`SessionRecord` 表示一次运动记录。

它既可以记录完成，也可以记录跳过：

| 字段 | 含义 |
| --- | --- |
| `scheduledAt` | 计划或进入动作的时间 |
| `startedAt` | 开始时间 |
| `completed` | 是否完成 |
| `completedAt` | 完成时间 |
| `skipped` | 是否跳过 |

## 9. 数据库设计

数据库服务在 `lib/services/database_service.dart`。

数据库名：

```text
standup.db
```

当前版本：

```text
5
```

### 9.1 表结构

#### categories

```text
id
name
icon_name
color_value
sort_order
is_builtin
```

#### exercises

```text
id
name
description
category_id
duration_seconds
video_path
video_source
difficulty
tags
equipment
is_builtin
```

#### session_records

```text
id
exercise_id
scheduled_at
started_at
completed
completed_at
skipped
```

### 9.2 内置分类

首次创建数据库时，会插入 4 个分类：

| 分类 | 图标 | 颜色 |
| --- | --- | --- |
| 拉伸 | `self_improvement` | 蓝色 |
| 力量 | `fitness_center` | 红色 |
| 灵活度 | `directions_run` | 绿色 |
| 放松 | `spa` | 紫色 |

### 9.3 内置动作

首次创建数据库时，会插入 18 个动作：

| 动作 | 分类 | 时长 | 难度 |
| --- | --- | --- | --- |
| 颈部侧拉伸 | 拉伸 | 30 秒 | easy |
| 肩部环绕 | 拉伸 | 40 秒 | easy |
| 手腕拉伸 | 拉伸 | 30 秒 | easy |
| 坐姿脊柱扭转 | 拉伸 | 30 秒 | easy |
| 胸部伸展 | 拉伸 | 30 秒 | easy |
| 站立前屈 | 拉伸 | 30 秒 | easy |
| 髋屈肌拉伸 | 拉伸 | 45 秒 | medium |
| 靠墙静蹲 | 力量 | 45 秒 | medium |
| 椅式深蹲 | 力量 | 45 秒 | easy |
| 桌面俯卧撑 | 力量 | 40 秒 | easy |
| 提踵运动 | 力量 | 35 秒 | easy |
| 坐姿抬腿 | 力量 | 50 秒 | easy |
| 手臂大回环 | 灵活度 | 35 秒 | easy |
| 髋部画圈 | 灵活度 | 40 秒 | medium |
| 猫牛式 | 灵活度 | 40 秒 | easy |
| 踝关节环绕 | 灵活度 | 35 秒 | easy |
| 腹式深呼吸 | 放松 | 60 秒 | easy |
| 20-20-20护眼 | 放松 | 30 秒 | easy |

### 9.4 数据库迁移

数据库迁移逻辑写在 `_onUpgrade()`。

历史迁移意图：

| 版本 | 变更 |
| --- | --- |
| v1 | 初始动作和记录 |
| v2 | 添加 `video_source`、`is_builtin` |
| v3 | 添加分类表和 `category_id` |
| v4/v5 | 用 `PRAGMA table_info` 逐列检查，兼容旧安装 |

这里的设计重点是“安全补列”。`_ensureColumn()` 会先检查列是否存在，再决定是否 `ALTER TABLE`。这样可以应对旧版本用户升级时数据库状态不完全一致的问题。

## 10. 随机推荐算法

推荐逻辑在 `lib/services/exercise_service.dart`。

入口有两个：

```dart
recommend()
recommendWithRotation()
```

### 10.1 recommend()

`recommend()` 支持：

- 指定分类：`preferredCategoryId`
- 限制最长时长：`maxDurationSeconds`
- 避免最近 10 次完成过的动作
- 根据距离上次完成的时间加权随机

大致流程：

```text
读取所有动作
读取最近完成记录
过滤近期做过的动作
按分类/时长进一步过滤
计算权重
随机抽取
```

### 10.2 加权规则

如果某个动作从未完成过，权重较高：

```text
10.0
```

如果做过，则权重随距离上次完成的天数增加：

```text
1.0 + 距离上次完成的小时数 / 24
```

最高增加到 7 天左右。

这让推荐既有随机感，又不会一直抽到同一个动作。

### 10.3 recommendWithRotation()

`recommendWithRotation()` 会记住上次推荐的分类，并尝试推荐下一个分类的动作。

目的：

- 避免连续多次都是拉伸。
- 让拉伸、力量、灵活度、放松更均匀出现。

注意：`_lastCategoryId` 当前只存在内存中，App 重启后会重置。如果后续想做到跨启动记忆，可以把它存入 `SharedPreferences`。

## 11. 本地通知设计

通知逻辑在 `lib/services/notification_service.dart`。

### 11.1 使用的外部依赖

- `flutter_local_notifications`
- `timezone`
- `shared_preferences`

### 11.2 初始化

初始化时做三件事：

1. 初始化 timezone 数据。
2. 初始化 Android/iOS 通知设置。
3. Android 创建通知 channel。

iOS 初始化使用：

```dart
DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,
)
```

这会请求提醒权限。

### 11.3 调度下一次提醒

`scheduleNextReminder(intervalMinutes)` 会：

1. 取消旧提醒。
2. 计算下一次提醒时间。
3. 把时间写入 `SharedPreferences` 的 `next_reminder_at`。
4. 调用 `zonedSchedule()` 创建定时通知。
5. payload 设置为 `reminder`，用于点击后打开运动页。

提醒文案会从几个提示词里取一个：

```text
颈部拉伸
肩部放松
深蹲几个
深呼吸
活动手腕
站起来走走
```

## 12. 视频资源设计

视频相关逻辑在 `lib/services/video_service.dart` 和 `lib/screens/exercise_screen.dart`。

### 12.1 内置视频资源

`pubspec.yaml` 声明了：

```yaml
assets:
  - assets/videos/
```

但当前仓库中只有：

```text
assets/videos/.gitkeep
```

也就是说，项目预留了内置视频目录，但没有提交真实视频素材。

这很重要：App 里内置动作的 `video_path` 指向如 `neck_stretch.mp4`、`shoulder_rolls.mp4` 等资源名，但文件当前并不存在。因此运动页会自动降级到“文字指导模式”。

对应代码在 `ExerciseScreen._initVideo()`：

```text
尝试加载 assets/videos/{videoPath}
如果失败，_videoOk = false
页面显示视频占位和文字指导
```

### 12.2 用户自定义视频

用户新增动作时，可以选本地视频。

流程：

```text
file_picker 选择 MP4/MOV
-> VideoService.validateVideo()
-> 最大 80MB 校验
-> 保存时 copyToAppStorage()
-> 存入 App Documents/videos/
-> Exercise.videoSource = file
```

支持格式：

```text
mp4
mov
```

大小限制：

```text
80MB
```

### 12.3 iOS 视频选择的外部库链路

Flutter 层只写了 `file_picker`，但 iOS 下会经 CocoaPods 拉取：

```text
file_picker
-> DKImagePickerController
-> DKPhotoGallery
-> SDWebImage
-> SwiftyGif
```

这就是为什么 iOS 构建时会看到这些 Pod。

## 13. 页面代码详解

### 13.1 HomeScreen

文件：

```text
lib/screens/home_screen.dart
```

职责：

- 读取今日完成数。
- 读取下一次提醒时间。
- 开关提醒。
- 随机开始动作。
- 按分类开始动作。
- 进入运动库、分类、历史和设置。

关键状态：

```dart
int _todayCount
DateTime? _nextReminder
bool _reminderEnabled
List<ExerciseCategory> _categories
```

首页每 30 秒刷新一次：

```dart
Timer.periodic(const Duration(seconds: 30), (_) => _loadData())
```

提醒开关逻辑：

```text
用户打开开关
-> 请求通知权限
-> 保存 reminder_enabled
-> 读取 reminder_interval
-> scheduleNextReminder()
```

### 13.2 ExerciseScreen

文件：

```text
lib/screens/exercise_screen.dart
```

职责：

- 加载动作视频。
- 显示动作描述和标签。
- 倒计时。
- 全屏播放。
- 完成后写入记录。
- 完成后重新安排下一次提醒。

关键修复：

这个页面创建了多个 `AnimationController`：

```dart
_pulse
_complete
```

因此必须使用：

```dart
TickerProviderStateMixin
```

不能使用：

```dart
SingleTickerProviderStateMixin
```

否则真机点击“随机抽一个”时会报：

```text
SingleTickerProviderStateMixin but multiple tickers were created
```

### 13.3 ExerciseFormScreen

文件：

```text
lib/screens/exercise_form_screen.dart
```

职责：

- 新增/编辑动作。
- 输入名称、描述、时长。
- 选择分类、难度、器材。
- 输入标签。
- 选择和校验视频。
- 保存到 SQLite。

保存视频时，如果是用户选的视频，会复制到 App 沙盒长期目录：

```text
ApplicationDocumentsDirectory/videos/
```

这样即使原始文件位置不可访问，App 仍能播放自己的副本。

### 13.4 管理页和历史页

其他页面职责：

| 页面 | 作用 |
| --- | --- |
| `exercise_manager_screen.dart` | 展示动作列表，入口到新增/编辑 |
| `category_manager_screen.dart` | 展示和维护分类 |
| `history_screen.dart` | 展示历史运动记录 |
| `settings_screen.dart` | 修改提醒间隔等设置 |

## 14. iOS 工程适配

iOS 工程位于：

```text
ios/
```

### 14.1 最低系统版本

`ios/Podfile` 设置：

```ruby
platform :ios, '13.0'
```

### 14.2 CocoaPods 兼容补丁

`ios/Podfile` 里有一段 `post_install` 补丁，用于处理 `DKPhotoGalleryResource.swift`。

背景：

构建时曾遇到错误：

```text
Cannot find 'DKPhotoGalleryResource' in scope
```

原因是 `DKPhotoGallery` 的资源 Swift 文件在某些 Pod 安装结构下没有正确进入编译源。

补丁做了两件事：

1. 如果 `Resource 2/DKPhotoGalleryResource.swift` 存在而 `Resource/DKPhotoGalleryResource.swift` 不存在，就复制过去。
2. 把这个 Swift 文件加入 `DKPhotoGallery` target 的 source build phase。

这是一个针对第三方 Pod 的兼容性修复。

### 14.3 App Store 出口合规

`ios/Runner/Info.plist` 中添加：

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

表示 App 不使用需要额外出口合规证明的加密能力。

如果不加，App Store Connect 可能显示：

```text
缺少出口合规证明
```

### 14.4 iOS 权限说明

当前 `Info.plist` 中有照片库相关说明：

```text
NSPhotoLibraryUsageDescription
用于选择你自己的运动视频，保存为自定义动作的跟练素材。

NSPhotoLibraryAddUsageDescription
用于在你选择保存或导入运动视频时访问照片库。
```

这些文案会显示在 iOS 权限弹窗里，需要和实际用途一致。

## 15. App Store 资源与元数据

### 15.1 截图

iPhone 截图使用：

```text
1242 × 2688px
```

生成目录：

```text
/Users/cnrouting/Downloads/appstore-screenshots-1242x2688
```

iPad 因为 App 支持 iPad，App Store Connect 要求上传 13 英寸 iPad 截图。本次用已有截图生成了：

```text
2064 × 2752px
```

临时文件：

```text
/private/tmp/appstore-ipad-screenshots/IMG_8741_ipad_2064x2752.PNG
```

建议正式视觉优化时，用 iPad 模拟器重新截图。

### 15.2 App Store 文案

推广文本：

```text
起身是一款为久坐人群设计的轻量运动提醒 App，帮你在工作间隙随机抽取简单动作，定时活动身体，慢慢养成不久坐的习惯。
```

关键词：

```text
久坐,提醒,运动,拉伸,健康,办公,番茄钟,习惯,锻炼,站立
```

版权：

```text
© 2026 cn routing. All rights reserved.
```

### 15.3 隐私

当前隐私策略：

- 不收集用户数据。
- 不需要账号登录。
- 动作、分类、记录和视频保存在本机。

对应文档：

```text
APP_STORE_PRIVACY.md
```

注意：App Store Connect 要求隐私政策 URL 是公网可访问页面。如果 GitHub 仓库私有，需要准备单独公开页面。

## 16. 从零构建教程

### 16.1 准备环境

需要：

- macOS
- Xcode
- Flutter SDK
- CocoaPods
- Apple Developer 账号

检查：

```bash
flutter doctor
pod --version
xcodebuild -version
```

### 16.2 获取依赖

```bash
cd ~/Developer/standup-reminder-git
flutter pub get
cd ios
pod install
cd ..
```

### 16.3 模拟器运行

```bash
flutter run
```

如果要指定模拟器：

```bash
flutter devices
flutter run -d <device-id>
```

### 16.4 真机运行

1. iPhone 开启开发者模式。
2. 用数据线连接 Mac。
3. iPhone 信任此电脑。
4. Xcode 中选择开发团队。
5. 运行：

```bash
flutter run -d <iphone-device-id>
```

### 16.5 发布构建

每次上传前递增 `pubspec.yaml` 的构建号：

```yaml
version: 1.1.0+4
```

然后：

```bash
flutter build ipa --release --no-tree-shake-icons
open build/ios/archive/Runner.xcarchive
```

在 Xcode Organizer 里上传。

## 17. 常见问题复盘

### 17.1 Homebrew 无法安装

现象：

```text
curl: (56) Recv failure: Operation timed out
zsh: command not found: brew
```

解决思路：

- 使用国内镜像安装 Homebrew。
- 或者先解决网络代理/DNS。

### 17.2 系统 Ruby 版本太旧导致 CocoaPods 安装失败

现象：

```text
ffi requires Ruby version >= 3.0
The current ruby version is 2.6.10
```

原因：

macOS 自带 Ruby 版本可能偏旧，即使 macOS 已升级到新版。

解决思路：

- 优先用 Homebrew 安装新版 Ruby。
- 再安装 CocoaPods。
- 不建议长期依赖系统 Ruby。

### 17.3 iOS Pod 编译 DKPhotoGallery 报错

现象：

```text
Cannot find 'DKPhotoGalleryResource' in scope
```

解决：

- 在 `ios/Podfile` 中加入 post_install 补丁。
- 重新执行 `pod install`。

### 17.4 真机运行要求钥匙串密码

原因：

Xcode 需要访问证书和签名私钥。

解决：

- 输入 Mac 登录密码。
- 允许 Xcode 或 codesign 访问钥匙串。

### 17.5 真机要求开启 Developer Mode

现象：

```text
enable Developer Mode in Settings -> Privacy & Security
```

解决：

- iPhone 设置 -> 隐私与安全性 -> 开发者模式。
- 开启后重启手机。

### 17.6 点击随机抽取时报 SingleTickerProviderStateMixin

现象：

```text
SingleTickerProviderStateMixin but multiple tickers were created
```

原因：

`ExerciseScreen` 有两个 `AnimationController`。

解决：

```dart
with TickerProviderStateMixin
```

### 17.7 App Store Connect 要求登录用户名密码

这里填的是“App 内测试账号”，不是：

- Apple ID
- GitHub 账号
- App Store Connect 账号
- 开发者私人账号

当前 App 不需要登录，所以不勾选“需要登录”。

### 17.8 App Store 要求 iPad 截图

原因：

App 支持 iPad。

解决：

- 上传 13 英寸 iPad 截图。
- 可用规格包括 `2064 × 2752px`。

### 17.9 GitHub 推送失败

现象：

```text
Could not resolve host: github.com
Failed to connect to github.com port 443
```

解决：

- 检查代理和 DNS。
- 必要时在可联网终端重新执行 `git push`。

## 18. 外部资源清单

### 18.1 已引入的外部代码资源

| 来源 | 资源 | 用途 |
| --- | --- | --- |
| Flutter SDK | Flutter framework | App UI 和运行时 |
| pub.dev | `sqflite` | 本地数据库 |
| pub.dev | `flutter_local_notifications` | 本地通知 |
| pub.dev | `timezone` | 通知调度时区 |
| pub.dev | `video_player` | 视频播放 |
| pub.dev | `file_picker` | 文件选择 |
| pub.dev | `path_provider` | 沙盒目录 |
| pub.dev | `shared_preferences` | 轻量配置 |
| CocoaPods trunk | `DKImagePickerController` | iOS 媒体选择 |
| CocoaPods trunk | `DKPhotoGallery` | iOS 媒体预览 |
| CocoaPods trunk | `SDWebImage` | 图片加载 |
| CocoaPods trunk | `SwiftyGif` | GIF 支持 |

### 18.2 已引入的素材资源

当前仓库没有真实运动视频素材，只有：

```text
assets/videos/.gitkeep
```

iOS App 图标和启动图仍是 Flutter/Xcode 工程生成的默认资源或占位资源，位于：

```text
ios/Runner/Assets.xcassets/
```

### 18.3 用户运行时产生的资源

用户选择的视频会被复制到 App 沙盒：

```text
ApplicationDocumentsDirectory/videos/
```

这些文件不会进入 Git 仓库，也不会上传云端。

## 19. 继续迭代建议

### 19.1 产品层

- 增加真正的 iPad 截图。
- 替换默认 App 图标和启动图。
- 增加首次使用引导。
- 增加更准确的连续天数统计。
- 增加提醒时间段，例如只在工作日 9:00-18:00 提醒。

### 19.2 技术层

- 给 `DatabaseService` 增加更完整的迁移测试。
- 把首页状态从页面内部迁出，使用 `provider` 或更轻量的 controller。
- 给视频导入增加更可靠的 iOS/Android 权限处理。
- 对用户视频做缩略图和时长读取。
- 把推荐算法的 `_lastCategoryId` 持久化。

### 19.3 发布层

- 准备公开技术支持页和隐私政策页。
- 维护 `APP_STORE_SUBMISSION_GUIDE.md`。
- 每次发布前打 tag，例如：

  ```bash
  git tag ios-v1.1.0-build3
  git push origin ios-v1.1.0-build3
  ```

## 20. 本项目当前状态

截至本教程编写时：

- GitHub 分支：`codex-ios-port`
- App Store 版本：`1.1.0`
- 构建号：`3`
- Bundle Identifier：`com.routingcn.standupreminder`
- App Store 状态：已提交审核
- 最新教程提交：`62e12f3 Add App Store submission guide`

这意味着代码、发布配置、隐私文档和提交审核指引已经形成一套可复用基线。后续版本可以在这条线之上继续迭代。
