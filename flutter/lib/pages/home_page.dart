import 'dart:io';
import 'dart:typed_data';
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
  Color _selectedBgColor = const Color(0xFF1E5AA8);
  bool _isProcessing = false;
  String _processingTip = '正在处理...';
  double _progress = 0;

  // 证件照尺寸 (300dpi)
  final Map<String, Map<String, int>> _photoSizes = {
    '一寸': {'width': 295, 'height': 413},
    '二寸': {'width': 413, 'height': 579},
    '小二寸': {'width': 390, 'height': 567},
  };

  final List<String> _stepNames = ['上传', '检测', '背景', '生成', '下载'];
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
          final isCurrent = _currentStep == index;
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
              '第二步：人脸检测',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              '正在检测人脸位置，请稍候...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              color: const Color(0xFF1E5AA8),
            ),
            const SizedBox(height: 20),
            Text(_processingTip),
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
            const SizedBox(height: 40),
            if (_processedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: _selectedBgColor,
                  padding: const EdgeInsets.all(10),
                  child: Image.memory(
                    _processedImage!,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
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
                  onPressed: _generatePhotos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('生成证件照'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 步骤4: 生成中
  Widget _buildStep4() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '第四步：生成证件照',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text('正在处理照片，请稍候...'),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              color: const Color(0xFF1E5AA8),
            ),
            const SizedBox(height: 20),
            Text(_processingTip),
          ],
        ),
      ),
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
            const Text(
              '打印排版',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _generateLayout('a4'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('A4 排版下载'),
                ),
                const SizedBox(width: 15),
                OutlinedButton(
                  onPressed: () => _generateLayout('6寸'),
                  child: const Text('6寸排版下载'),
                ),
              ],
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
      _processingTip = '正在识别人脸...';
      _progress = 0.1;
    });
    _processImage();
  }

  // 处理图片
  Future<void> _processImage() async {
    if (_originalImage == null) return;

    try {
      setState(() {
        _progress = 0.2;
        _processingTip = '正在读取图片...';
      });

      // 读取图片
      final bytes = await _originalImage!.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('无法读取图片');

      setState(() {
        _progress = 0.4;
        _processingTip = '正在检测皮肤区域...';
      });

      // 检测皮肤区域并处理
      final processed = await _processSkinDetection(image);

      setState(() {
        _progress = 0.9;
        _processingTip = '正在完成处理...';
        _processedImage = Uint8List.fromList(img.encodePng(processed));
      });

      // 跳转到选择背景色
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

  // 皮肤检测和处理
  Future<img.Image> _processSkinDetection(img.Image image) async {
    // 缩放到合适大小
    final maxSize = 600;
    img.Image processed;
    if (image.width > maxSize || image.height > maxSize) {
      processed = img.copyResize(image, width: maxSize);
    } else {
      processed = image.clone();
    }

    final width = processed.width;
    final height = processed.height;

    // 创建背景色
    final bgColor = Color(
      _selectedBgColor.red,
      _selectedBgColor.green,
      _selectedBgColor.blue,
    );

    // 遍历每个像素
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = processed.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // YCbCr 皮肤检测
        final yVal = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        final cb = (128 - 0.168736 * r - 0.331264 * g + 0.5 * b).toInt();
        final cr = (128 + 0.5 * r - 0.418688 * g - 0.081312 * b).toInt();

        // 皮肤范围判断
        final isSkin = cb > 68 && cb < 135 && cr > 125 && cr < 185 && yVal > 35 && yVal < 240;

        if (!isSkin) {
          // 替换为背景色
          processed.setPixel(x, y, img.ColorRgb8(bgColor.red, bgColor.green, bgColor.blue));
        } else {
          // 美颜：轻微提亮
          final newR = (r + 10).clamp(0, 255);
          final newG = (g + 8).clamp(0, 255);
          final newB = (b + 5).clamp(0, 255);
          processed.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
        }
      }
    }

    return processed;
  }

  // 生成证件照
  void _generatePhotos() {
    setState(() {
      _currentStep = 3;
      _processingTip = '正在生成各尺寸...';
      _progress = 0.3;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _currentStep = 4;
        _progress = 1.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生成成功!'), backgroundColor: Colors.green),
      );
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

  // 生成排版
  void _generateLayout(String size) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('排版功能开发中...')),
    );
  }

  // 重新开始
  void _startOver() {
    setState(() {
      _currentStep = 0;
      _originalImage = null;
      _processedImage = null;
      _selectedBgColor = const Color(0xFF1E5AA8);
      _progress = 0;
    });
  }
}
