import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '证件照制作',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentStep = 0;
  File? _originalImage;
  Uint8List? _processedImage;
  Uint8List? _originalWithBg;
  Color _selectedBgColor = const Color(0xFF1E5AA8);
  bool _isProcessing = false;
  String _processingTip = '正在处理...';
  double _progress = 0;

  // 美颜设置
  double _smoothLevel = 0.3; // 磨皮级别 0-1
  double _brightLevel = 0.15; // 美白级别 0-1
  bool _enableBeauty = true;

  // 证件照尺寸 (300dpi)
  final Map<String, Map<String, int>> _photoSizes = {
    '一寸': {'width': 295, 'height': 413},
    '二寸': {'width': 413, 'height': 579},
    '小二寸': {'width': 390, 'height': 567},
  };

  final List<String> _stepNames = ['上传', '检测', '背景', '美颜', '生成'];
  final List<Color> _bgColors = [
    const Color(0xFF1E5AA8), // 蓝
    const Color(0xFFFFFFFF), // 白
    const Color(0xFF07C160), // 绿
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('证件照制作工具'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E5AA8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isActive = _currentStep >= index;
          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? const Color(0xFF1E5AA8) : Colors.grey[300],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stepNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? const Color(0xFF1E5AA8) : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (index < 4)
                Container(
                  width: 40,
                  height: 2,
                  color: _currentStep > index ? const Color(0xFF1E5AA8) : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return _buildStep1();
    }
  }

  // 步骤1: 上传照片
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '第一步：上传照片',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '请拍摄或选择一张正面照，确保面部清晰，光线均匀。',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _selectFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('相册选择'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
            if (_originalImage != null) ...[
              const SizedBox(height: 30),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _originalImage!,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _originalImage = null),
                    child: const Text('重新选择'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _confirmPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5AA8),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认使用'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 步骤2: 人脸检测中
  Widget _buildStep2() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '第二步：人脸检测与背景替换',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(_processingTip, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            if (_progress > 0)
              LinearProgressIndicator(
              value: _progress,
              color: const Color(0xFF1E5AA8),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 20),
            if (_originalWithBg != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _originalWithBg!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 步骤3: 选择背景色
  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '第三步：选择背景色',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '请选择证件照背景颜色',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _bgColors.map((color) {
                final isSelected = _selectedBgColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBgColor = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: color == Colors.white
                                ? [BoxShadow(color: Colors.grey[300]!)]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          color == const Color(0xFF1E5AA8)
                              ? '蓝色'
                              : color == Colors.white
                                  ? '白色'
                                  : '绿色',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF1E5AA8) : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            if (_processedImage != null)
              Container(
                decoration: BoxDecoration(
                  color: _selectedBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(15),
                child: Image.memory(
                  _processedImage!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('上一步'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _applyBgAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('应用背景色'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 步骤4: 美颜设置
  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '第四步：美颜设置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '调整美颜效果（可选）',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // 开关
            SwitchListTile(
              title: const Text('启用美颜'),
              subtitle: const Text('磨皮+美白'),
              value: _enableBeauty,
              activeColor: const Color(0xFF1E5AA8),
              onChanged: (v) => setState(() => _enableBeauty = v),
            ),

            if (_enableBeauty) ...[
              const SizedBox(height: 20),

              // 磨皮级别
              _buildSlider(
                '磨皮强度',
                _smoothLevel,
                (v) => setState(() => _smoothLevel = v),
              ),

              const SizedBox(height: 16),

              // 美白级别
              _buildSlider(
                '美白强度',
                _brightLevel,
                (v) => setState(() => _brightLevel = v),
              ),
            ],

            const SizedBox(height: 30),

            // 预览
            if (_processedImage != null)
              Container(
                decoration: BoxDecoration(
                  color: _selectedBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(15),
                child: Image.memory(
                  _processedImage!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text('上一步'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _applyBeautyAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('应用并继续'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1E5AA8),
          inactiveColor: Colors.grey[300],
          min: 0,
          max: 1,
        ),
      ],
    );
  }

  // 步骤5: 预览与下载
  Widget _buildStep5() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '第五步：预览与下载',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '您的证件照已生成完毕',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // 照片展示
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: _photoSizes.entries.map((entry) {
                return _buildPhotoCard(entry.key, entry.value);
              }).toList(),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // 打印排版
            const Text(
              '打印排版',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _generateLayout('a4'),
                  icon: const Icon(Icons.description),
                  label: const Text('A4 排版'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 15),
                OutlinedButton.icon(
                  onPressed: () => _generateLayout('6寸'),
                  icon: const Icon(Icons.photo_size_select_large),
                  label: const Text('6寸排版'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _saveAllPhotos,
              icon: const Icon(Icons.save_alt),
              label: const Text('保存所有尺寸'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),
            OutlinedButton(
              onPressed: _startOver,
              child: const Text('重新制作'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String name, Map<String, int> size) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (_processedImage != null)
            Image.memory(
              _processedImage!,
              width: 100,
              height: 130,
              fit: BoxFit.contain,
            ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${size['width']}×${size['height']}px',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _savePhoto(name),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E5AA8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 拍照
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _originalImage = File(image.path));
    }
  }

  // 从相册选择
  Future<void> _selectFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _originalImage = File(image.path));
    }
  }

  // 确认使用照片
  void _confirmPhoto() {
    if (_originalImage == null) return;
    setState(() {
      _currentStep = 1;
      _processingTip = '正在处理...';
      _progress = 0;
    });
    _processImage();
  }

  // 处理图片
  Future<void> _processImage() async {
    if (_originalImage == null) return;

    try {
      setState(() {
        _progress = 0.1;
        _processingTip = '正在读取图片...';
      });

      final bytes = await _originalImage!.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('无法读取图片');

      setState(() {
        _progress = 0.3;
        _processingTip = '正在检测人脸区域...';
      });

      // 检测皮肤并替换背景
      final processed = await _processWithSkinDetection(image);

      setState(() {
        _progress = 0.9;
        _processingTip = '处理完成';
        _processedImage = Uint8List.fromList(img.encodePng(processed));
        _originalWithBg = Uint8List.fromList(img.encodePng(processed));
      });

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _currentStep = 2;
        _progress = 1.0;
      });
    } catch (e) {
      setState(() => _currentStep = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e')),
        );
      }
    }
  }

  // 应用背景色
  void _applyBgAndContinue() {
    setState(() => _currentStep = 3);
  }

  // 应用美颜
  Future<void> _applyBeautyAndContinue() async {
    if (!_enableBeauty) {
      setState(() => _currentStep = 4);
      return;
    }

    setState(() {
      _progress = 0.1;
      _processingTip = '正在应用美颜...';
      _currentStep = 4; // 留在当前页面，但显示进度
    });

    try {
      final bytes = _processedImage!;
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('无法解码图片');

      setState(() {
        _progress = 0.3;
        _processingTip = '正在磨皮...';
      });

      // 应用美颜
      final smoothed = _applyBeauty(image);

      setState(() {
        _progress = 0.9;
        _processingTip = '完成';
        _processedImage = Uint8List.fromList(img.encodePng(smoothed));
      });

      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _currentStep = 4);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('美颜处理失败: $e')),
        );
      }
    }
  }

  // 皮肤检测和处理
  Future<img.Image> _processWithSkinDetection(img.Image image) async {
    // 缩放
    final maxSize = 800;
    img.Image processed;
    if (image.width > maxSize || image.height > maxSize) {
      processed = img.copyResize(image, width: maxSize);
    } else {
      processed = image.clone();
    }

    final width = processed.width;
    final height = processed.height;

    // 检测皮肤区域
    final skinMask = _detectSkinMask(processed);

    // 边缘羽化
    _featherEdges(skinMask, width, height);

    // 替换背景
    _replaceBackground(processed, skinMask, width, height);

    return processed;
  }

  // 检测皮肤区域
  Uint8List _detectSkinMask(img.Image image) {
    final width = image.width;
    final height = image.height;
    final mask = Uint8List(width * height);
    final step = 2;

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // YCbCr 皮肤检测
        final yVal = 0.299 * r + 0.587 * g + 0.114 * b;
        final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
        final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;

        // 扩大的皮肤范围
        final isSkin = cb > 65 && cb < 140 && cr > 120 && cr > 125 && cr < 190 && yVal > 30 && yVal < 245;

        if (isSkin) {
          // 标记皮肤区域
          for (int dy = -4; dy <= 4; dy += 2) {
            for (int dx = -4; dx <= 4; dx += 2) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                mask[ny * width + nx] = 1;
              }
            }
          }
        }
      }
    }

    return mask;
  }

  // 边缘羽化
  void _featherEdges(Uint8List mask, int width, int height) {
    // 简单的边缘膨胀后收缩，让边缘更平滑
    for (int iter = 0; iter < 3; iter++) {
      final newMask = Uint8List.fromList(mask);

      for (int y = 2; y < height - 2; y++) {
        for (int x = 2; x < width - 2; x++) {
          final idx = y * width + x;
          if (mask[idx] == 1) {
            // 如果是皮肤，附近也标记为皮肤
            for (int dy = -2; dy <= 2; dy++) {
              for (int dx = -2; dx <= 2; dx++) {
                newMask[(y + dy) * width + (x + dx)] = 1;
              }
            }
          }
        }
      }

      // 收缩
      for (int y = 2; y < height - 2; y++) {
        for (int x = 2; x < width - 2; x++) {
          final idx = y * width + x;
          if (mask[idx] == 1) {
            int count = 0;
            for (int dy = -2; dy <= 2; dy++) {
              for (int dx = -2; dx <= 2; dx++) {
                if (mask[(y + dy) * width + (x + dx)] == 1) count++;
              }
            }
            if (count < 15) newMask[idx] = 0;
          }
        }
      }

      mask.setAll(0, newMask);
    }
  }

  // 替换背景
  void _replaceBackground(img.Image image, Uint8List mask, int width, int height) {
    final bgRed = _selectedBgColor.red;
    final bgGreen = _selectedBgColor.green;
    final bgBlue = _selectedBgColor.blue;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (mask[idx] == 0) {
          image.setPixel(x, y, img.ColorRgb8(bgRed, bgGreen, bgBlue));
        }
      }
    }
  }

  // 应用美颜（磨皮+美白）
  img.Image _applyBeauty(img.Image image) {
    if (!_enableBeauty) return image;

    final width = image.width;
    final height = image.height;
    final smoothed = image.clone();

    // 磨皮：简单的均值滤波（保留边缘）
    if (_smoothLevel > 0) {
      for (int y = 3; y < height - 3; y++) {
        for (int x = 3; x < width - 3; x++) {
          double rSum = 0, gSum = 0, bSum = 0;
          int count = 0;

          // 5x5 滤波
          for (int dy = -2; dy <= 2; dy++) {
            for (int dx = -2; dx <= 2; dx++) {
              final pixel = image.getPixel(x + dx, y + dy);
              rSum += pixel.r;
              gSum += pixel.g;
              bSum += pixel.b;
              count++;
            }
          }

          final blended = _smoothLevel;
          final pixel = image.getPixel(x, y);
          final newR = (pixel.r * (1 - blended) + (rSum / count) * blended).toInt();
          final newG = (pixel.g * (1 - blended) + (gSum / count) * blended).toInt();
          final newB = (pixel.b * (1 - blended) + (bSum / count) * blended).toInt();

          smoothed.setPixel(x, y, img.ColorRgb8(newR.clamp(0, 255), newG.clamp(0, 255), newB.clamp(0, 255)));
        }
      }
    }

    // 美白
    if (_brightLevel > 0) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = smoothed.getPixel(x, y);
          final yVal = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

          // 只对较暗的区域美白
          if (yVal < 200) {
            final boost = _brightLevel * 15;
            final newR = (pixel.r + boost).clamp(0, 255).toInt();
            final newG = (pixel.g + boost * 0.8).clamp(0, 255).toInt();
            final newB = (pixel.b + boost * 0.6).clamp(0, 255).toInt();
            smoothed.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
          }
        }
      }
    }

    return smoothed;
  }

  // 生成证件照
  void _generatePhotos() {
    setState(() {
      _currentStep = 4;
    });
  }

  // 保存照片
  Future<void> _savePhoto(String name) async {
    if (_processedImage == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/证件照_$name.png');
      await file.writeAsBytes(_processedImage!);

      await Share.shareXFiles([XFile(file.path)], text: '证件照_$name');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  // 保存所有尺寸
  Future<void> _saveAllPhotos() async {
    if (_processedImage == null) return;

    try {
      final bytes = _processedImage!;
      final tempDir = await getTemporaryDirectory();
      final files = <XFile>[];

      for (final name in _photoSizes.keys) {
        final file = File('${tempDir.path}/证件照_$name.png');
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path));
      }

      await Share.shareXFiles(files, text: '证件照全套');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  // 生成排版
  Future<void> _generateLayout(String size) async {
    if (_processedImage == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final layoutFile = File('${tempDir.path}/证件照_${size}_排版.png');

      // A4: 2480 x 3508 @300dpi
      // 6寸: 1800 x 1200 @300dpi
      final layoutSizes = {
        'a4': {'width': 2480, 'height': 3508},
        '6寸': {'width': 1800, 'height': 1200},
      };

      final sizeInfo = layoutSizes[size]!;
      final layout = img.Image(width: sizeInfo['width']!, height: sizeInfo['height']!);

      // 白色背景
      img.fill(layout, color: img.ColorRgb8(255, 255, 255));

      // 排版参数
      final margin = 150; // 边距
      final gap = 60; // 间距

      int x = margin;
      int y = margin;

      for (final entry in _photoSizes.entries) {
        final photoBytes = _processedImage!;
        final photo = img.decodeImage(photoBytes);
        if (photo == null) continue;

        final w = entry.value['width']!;
        final h = entry.value['height']!;

        // 缩放照片到目标尺寸
        final scaled = img.copyResize(photo, width: w, height: h);

        // 绘制
        for (int i = 0; i < 4; i++) { // 每种尺寸4张
          if (x + w > sizeInfo['width']! - margin) {
            x = margin;
            y += h + gap;
          }
          img.compositeImage(layout, scaled, dstX: x, dstY: y);
          x += w + gap;
        }
      }

      await layoutFile.writeAsBytes(img.encodePng(layout));

      await Share.shareXFiles([XFile(layoutFile.path)], text: '证件照_${size}_排版');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${size}排版已生成'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('排版生成失败: $e')),
        );
      }
    }
  }

  // 重新开始
  void _startOver() {
    setState(() {
      _currentStep = 0;
      _originalImage = null;
      _processedImage = null;
      _originalWithBg = null;
      _selectedBgColor = const Color(0xFF1E5AA8);
      _progress = 0;
      _smoothLevel = 0.3;
      _brightLevel = 0.15;
      _enableBeauty = true;
    });
  }
}
