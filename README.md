# 起身 StandUp — 久坐提醒 · 随机运动 · 视频陪练

一个简单直接的 Flutter 久坐提醒 App。精选 18 个动作 + 随机抽取 + 视频陪练 + 全屏跟练，支持手动添加自己的运动视频和分类。

## 功能

- ⏰ **定时提醒**：每 30/60/90 分钟提醒起身活动，Android 锁屏也能弹
- 🎲 **随机推荐**：加权轮转算法，最近做过的降权，跨分类轮换
- 🎬 **视频跟练**：全屏播放 + 倒计时，自动循环
- ✏️ **自定义动作**：添加自己的运动（名称、描述、时长、视频）
- 📂 **自定义分类**：创建自己的分类（图标、颜色可自定义）
- 📊 **运动记录**：完成记录 + 历史统计
- 🎯 **无需视频**：视频缺失时自动降级为文字指导模式

## 快速开始

```bash
flutter pub get
flutter run
```

## 构建 APK

```bash
flutter build apk --release --no-tree-shake-icons
```

APK 生成在 `build/app/outputs/flutter-apk/app-release.apk`

## 项目结构

```
lib/
├── main.dart                          # 入口
├── models/
│   ├── exercise.dart                  # 运动动作模型
│   ├── exercise_category.dart         # 分类模型（图标池+颜色池）
│   └── session_record.dart            # 运动记录模型
├── screens/
│   ├── home_screen.dart               # 首页：提醒状态、随机入口、分类快速开始
│   ├── exercise_screen.dart           # 运动页：视频全屏 + 倒计时
│   ├── exercise_manager_screen.dart   # 运动库管理
│   ├── exercise_form_screen.dart      # 新增/编辑动作表单
│   ├── category_manager_screen.dart   # 分类管理
│   ├── history_screen.dart            # 运动历史记录
│   └── settings_screen.dart           # 提醒间隔、运动偏好
└── services/
    ├── database_service.dart          # SQLite 数据库（18 个预置动作）
    ├── exercise_service.dart          # 加权轮转推荐算法
    ├── notification_service.dart      # 本地通知（时区感知）
    └── video_service.dart             # 视频选取 + 校验
```

## 技术栈

- Flutter 3.44+ / Dart 3.x
- sqflite（本地数据库，v5 迁移）
- flutter_local_notifications（时区感知的定时通知）
- file_picker（从设备选取视频文件）
- video_player（视频播放）
- shared_preferences（配置持久化）
- provider（状态管理）

## 数据库版本

| 版本 | 变更 |
|------|------|
| v1 | 初始数据库：exercises + session_records |
| v2 | 添加 video_source, is_builtin 列 |
| v3 | 添加 categories 表 + category_id 列 |
| v4 | 逐列 PRAGMA 安全迁移 |
| v5 | 删除旧 `category` 残留列 |

## 许可

MIT
