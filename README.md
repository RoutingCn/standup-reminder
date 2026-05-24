# 起身 StandUp — 久坐提醒 · 随机运动 · 视频陪练

## 项目结构

```
standup/
├── pubspec.yaml              # 依赖配置
├── lib/
│   ├── main.dart             # 入口，初始化通知 & 路由
│   ├── models/
│   │   ├── exercise.dart     # 运动动作模型
│   │   └── session_record.dart # 运动记录模型
│   ├── services/
│   │   ├── database_service.dart    # SQLite 数据库 (18个预置动作)
│   │   ├── exercise_service.dart    # 推荐算法 (加权随机+分类轮换)
│   │   └── notification_service.dart # 本地通知 (锁屏也能弹)
│   └── screens/
│       ├── home_screen.dart      # 首页：提醒状态、快捷入口
│       ├── exercise_screen.dart  # 运动页：视频播放、倒计时
│       ├── history_screen.dart   # 历史记录、周统计图
│       └── settings_screen.dart  # 提醒间隔、时长限制
└── assets/videos/            # 放你的 mp4 视频文件
```

## 快速开始

### 1. 安装 Flutter
https://docs.flutter.dev/get-started/install

### 2. 创建 Flutter 项目并覆盖代码
```bash
flutter create standup
cd standup
# 把本项目的 lib/ 和 assets/ 覆盖过去
# 用本项目的 pubspec.yaml 替换自动生成的
flutter pub get
```

### 3. 添加视频
把拍好的 mp4 文件放到 `assets/videos/`，文件名要和 `database_service.dart` 里 `_seedExercises` 中的 `video_filename` 对应：
- neck_stretch.mp4
- shoulder_rolls.mp4
- wrist_stretch.mp4
- ... 等

### 4. Android 通知权限配置
打开 `android/app/src/main/AndroidManifest.xml`，在 `<manifest>` 下添加：
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### 5. 运行
```bash
flutter run
```

## 核心设计

- **视频本地存储**：视频文件打包在 assets 中，首次使用即本地播放，零网络依赖
- **推荐算法**：最近做过的降低权重，越久没做的越优先，同时按拉伸→灵活→力量→放松轮换
- **后台提醒**：用系统级通知调度，App 被杀死也能准时弹提醒
- **无视频也能用**：如果视频文件缺失，自动降级为文字指导模式
