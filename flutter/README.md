# 证件照制作工具 - Flutter 版

基于 Flutter 开发的证件照制作 App，支持 Android 和 iOS。

## 功能

- 拍照或从相册选择照片
- 自动皮肤检测
- 多种背景色切换（蓝、白、绿）
- 美颜处理（提亮美白）
- 生成多种尺寸证件照（一寸、二寸、小二寸）
- 打印排版
- 分享/保存照片

## 环境要求

- Flutter SDK >= 3.0.0
- Android Studio / VS Code + Flutter 插件
- Android SDK (用于 Android 打包)
- Xcode (用于 iOS 打包，仅 macOS)

## 安装依赖

```bash
cd flutter
flutter pub get
```

## 运行调试

```bash
# Android 调试
flutter run

# iOS 调试 (macOS)
flutter run -d ios
```

## 打包

### Android

```bash
# APK
flutter build apk --release

# 生成文件在 build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
# 需要 macOS 和 Xcode
flutter build ios --release
```

## 项目结构

```
flutter/
├── lib/
│   ├── main.dart          # 入口
│   └── pages/
│       └── home_page.dart # 主页面
├── android/               # Android 配置
├── ios/                   # iOS 配置
└── pubspec.yaml          # 依赖配置
```

## 使用的包

- `image_picker`: 图片选择（相机/相册）
- `image`: Dart 图像处理库
- `path_provider`: 文件路径获取
- `share_plus`: 分享功能
- `permission_handler`: 权限处理

## 注意事项

1. Android 11+ 需要在 AndroidManifest.xml 中配置相应权限
2. iOS 需要在 Info.plist 中配置相机和相册访问权限
3. 图像处理在主线程执行，大图片可能需要等待
