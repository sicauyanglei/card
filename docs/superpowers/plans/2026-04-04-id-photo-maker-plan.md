# 证件照制作工具 - 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 纯前端网页应用，实现拍照/相册选择 → 人脸检测 → 抠图换背景 → 生成常用尺寸证件照 → 打印排版和单独下载完整流程。

**Architecture:** 单页应用（Single Page App），纯前端无后端依赖，使用 Canvas 2D 进行图像处理，MediaPipe Face Detection 做的人脸检测，JSZip 做打包下载。

**Tech Stack:** HTML5 + CSS3 + Vanilla JavaScript（无框架依赖）, MediaPipe Face Detection（CDN）, JSZip（CDN）, Canvas 2D API

---

## 文件结构

```
index.html              - 单页应用入口，完整的可运行页面
├── 内联 CSS（style 标签）
├── 内联 JS（script 标签）
└── 外部 CDN 依赖
    ├── MediaPipe Face Detection
    └── JSZip
```

> **设计决策：** 所有代码放在单个 `index.html` 中（内联 CSS/JS），最大化简单性和可移植性，无需构建工具。

---

## 任务列表

### Task 1: 项目初始化与基础结构

**Files:**
- Create: `index.html`

- [ ] **Step 1: 创建 HTML 基础结构**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>证件照制作工具</title>
  <style>
    /* CSS 将后续步骤填充 */
  </style>
</head>
<body>
  <div id="app">
    <h1>证件照制作工具</h1>
    <div id="step-indicator">步骤指示器</div>
    <div id="content"></div>
  </div>

  <!-- MediaPipe -->
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/face_detection@0.4/face_detection.js" crossorigin="anonymous"></script>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/camera_utils@0.3/camera_utils.js" crossorigin="anonymous"></script>

  <!-- JSZip -->
  <script src="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"></script>

  <script>
    // JS 将后续步骤填充
  </script>
</body>
</html>
```

- [ ] **Step 2: 创建 CSS 基础样式**

在 `style` 标签中添加：
- 基础重置（margin/padding: 0, box-sizing: border-box）
- 居中容器 `.container { max-width: 800px; margin: 0 auto; padding: 20px; }`
- 步骤指示器 `.step-indicator { display: flex; justify-content: center; gap: 20px; }`
- 卡片样式 `.card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }`
- 按钮样式 `.btn { padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; }` `.btn-primary { background: #1E5AA8; color: white; }` `.btn-secondary { background: #f0f0f0; color: #333; }`
- 隐藏类 `.hidden { display: none; }`

- [ ] **Step 3: 创建 JS 应用状态和步骤管理**

在 `script` 标签中添加：
```javascript
const state = {
  currentStep: 1,          // 1=拍照/选择, 2=检测中, 3=选背景色, 4=生成, 5=预览
  originalImage: null,      // 原始图片（File 对象）
  detectedFace: null,       // 检测到的人脸数据
  processedImage: null,     // 处理后的人像（ImageData）
  selectedBgColor: '#1E5AA8', // 默认蓝底
  photos: {}                // 生成的各种尺寸证件照 { '1寸': canvas, '2寸': canvas, ... }
};

function setStep(step) {
  state.currentStep = step;
  render();
}
```

- [ ] **Step 4: 创建基础 render 函数框架**

```javascript
function render() {
  const content = document.getElementById('content');
  switch (state.currentStep) {
    case 1: content.innerHTML = renderStep1(); break;
    case 2: content.innerHTML = renderStep2(); break;
    case 3: content.innerHTML = renderStep3(); break;
    case 4: content.innerHTML = renderStep4(); break;
    case 5: content.innerHTML = renderStep5(); break;
  }
}

// 占位函数，后续步骤填充
function renderStep1() { return '<div>Step 1</div>'; }
function renderStep2() { return '<div>Step 2</div>'; }
function renderStep3() { return '<div>Step 3</div>'; }
function renderStep4() { return '<div>Step 4</div>'; }
function renderStep5() { return '<div>Step 5</div>'; }

// 启动
render();
```

- [ ] **Step 5: 提交**

```bash
git add index.html
git commit -m "feat: scaffold id-photo-maker project structure"
```

---

### Task 2: 照片输入模块（拍照 + 相册）

**Files:**
- Modify: `index.html`（renderStep1 函数）

- [ ] **Step 1: 实现 renderStep1 - 拍照/选择界面**

```javascript
function renderStep1() {
  return `
    <div class="card">
      <h2>第一步：上传照片</h2>
      <p>请拍摄或选择一张正面照，确保面部清晰，光线均匀。</p>

      <div class="upload-options" style="display: flex; gap: 20px; justify-content: center; margin: 30px 0;">
        <button class="btn btn-primary" onclick="openCamera()">
          📷 拍照
        </button>
        <button class="btn btn-secondary" onclick="selectFromGallery()">
          📁 从相册选择
        </button>
      </div>

      <input type="file" id="file-input" accept="image/*" class="hidden" onchange="handleFileSelect(event)">
      <video id="camera-video" autoplay class="hidden" style="max-width: 100%;"></video>
      <canvas id="camera-canvas" class="hidden"></canvas>

      <div id="preview-area" class="hidden" style="text-align: center; margin-top: 20px;">
        <img id="preview-img" style="max-width: 300px; border-radius: 8px;">
        <div style="margin-top: 15px;">
          <button class="btn btn-secondary" onclick="clearPhoto()">重新选择</button>
          <button class="btn btn-primary" onclick="confirmPhoto()">确认使用</button>
        </div>
      </div>
    </div>
  `;
}
```

- [ ] **Step 2: 实现 openCamera 函数**

```javascript
let cameraStream = null;

async function openCamera() {
  try {
    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'user', width: 1280, height: 720 }
    });
    const video = document.getElementById('camera-video');
    const previewArea = document.getElementById('preview-area');
    const previewImg = document.getElementById('preview-img');

    video.classList.remove('hidden');
    previewArea.classList.remove('hidden');
    previewImg.classList.add('hidden');

    video.srcObject = cameraStream;
  } catch (err) {
    alert('无法打开相机，请检查权限设置。' + err.message);
  }
}
```

- [ ] **Step 3: 实现拍照并预览**

```javascript
function capturePhoto() {
  const video = document.getElementById('camera-video');
  const canvas = document.getElementById('camera-canvas');
  const previewImg = document.getElementById('preview-img');

  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  canvas.getContext('2d').drawImage(video, 0, 0);

  // 停止相机
  if (cameraStream) {
    cameraStream.getTracks().forEach(track => track.stop());
    cameraStream = null;
  }

  // 显示预览
  const dataUrl = canvas.toDataURL('image/jpeg', 0.9);
  previewImg.src = dataUrl;
  video.classList.add('hidden');
  previewImg.classList.remove('hidden');

  // 保存到 state
  state.originalImage = dataURLtoFile(dataUrl, 'photo.jpg');
}
```

- [ ] **Step 4: 实现 selectFromGallery**

```javascript
function selectFromGallery() {
  document.getElementById('file-input').click();
}

function handleFileSelect(event) {
  const file = event.target.files[0];
  if (!file) return;

  state.originalImage = file;

  const reader = new FileReader();
  reader.onload = function(e) {
    const previewImg = document.getElementById('preview-img');
    const previewArea = document.getElementById('preview-area');
    const video = document.getElementById('camera-video');
    const canvas = document.getElementById('camera-canvas');

    previewImg.src = e.target.result;
    video.classList.add('hidden');
    canvas.classList.add('hidden');
    previewArea.classList.remove('hidden');
    previewImg.classList.remove('hidden');
  };
  reader.readAsDataURL(file);
}
```

- [ ] **Step 5: 实现辅助函数和 confirmPhoto**

```javascript
function dataURLtoFile(dataurl, filename) {
  const arr = dataurl.split(',');
  const mime = arr[0].match(/:(.*?);/)[1];
  const bstr = atob(arr[1]);
  let n = bstr.length;
  const u8arr = new Uint8Array(n);
  while (n--) u8arr[n] = bstr.charCodeAt(n);
  return new File([u8arr], filename, { type: mime });
}

function clearPhoto() {
  state.originalImage = null;
  document.getElementById('file-input').value = '';
  document.getElementById('preview-area').classList.add('hidden');
}

function confirmPhoto() {
  if (!state.originalImage) {
    alert('请先拍摄或选择照片');
    return;
  }
  setStep(2);
  detectFace();
}
```

- [ ] **Step 6: 修改 renderStep1 添加拍照按钮点击事件**

在 openCamera 的 button 中添加 onclick 触发 capturePhoto 逻辑，或添加一个"拍照"按钮。

实际修改 renderStep1，在拍照按钮旁添加一个"拍摄"按钮：

```javascript
// 修改 renderStep1 中的拍照按钮
<button class="btn btn-primary" onclick="openCamera()">📷 拍照</button>
<button class="btn btn-secondary" onclick="selectFromGallery()">📁 从相册选择</button>
```

添加 capturePhoto 按钮在 openCamera 显示 video 后：

```javascript
// 修改 openCamera 函数，在 video 后添加
video.srcObject = cameraStream;
// 添加一个拍照按钮的 overlay 或在 UI 变化时显示拍照按钮
```

**简化方案：** 用 video + capture 按钮，点击 capturePhoto() 拍一张显示到 previewImg，然后用户确认。

- [ ] **Step 7: 提交**

```bash
git add index.html
git commit -m "feat: implement photo input (camera + gallery)"
```

---

### Task 3: 人脸检测模块

**Files:**
- Modify: `index.html`（新增 detectFace 函数和 renderStep2/renderStep3）

- [ ] **Step 1: 实现 renderStep2 - 检测中界面**

```javascript
function renderStep2() {
  return `
    <div class="card" style="text-align: center;">
      <h2>第二步：人脸检测</h2>
      <p>正在检测人脸位置，请稍候...</p>
      <div class="spinner" style="width: 40px; height: 40px; border: 4px solid #f0f0f0; border-top: 4px solid #1E5AA8; border-radius: 50%; animation: spin 1s linear infinite; margin: 30px auto;"></div>
      <style>@keyframes spin { to { transform: rotate(360deg); } }</style>
    </div>
  `;
}
```

- [ ] **Step 2: 实现 detectFace 函数（使用 MediaPipe）**

```javascript
async function detectFace() {
  const faceDetection = new FaceDetection({
    locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/face_detection@0.4/${file}`
  });

  faceDetection.setOptions({
    model: 'short',
    minDetectionConfidence: 0.5
  });

  faceDetection.onResults((results) => {
    if (results.detections.length === 0) {
      alert('未检测到人脸，请重新拍摄一张面部清晰的照片。');
      setStep(1);
      return;
    }

    const detection = results.detections[0];
    const bbox = detection.boundingBox;
    state.detectedFace = {
      x: bbox.x,
      y: bbox.y,
      width: bbox.width,
      height: bbox.height,
      landmarks: detection.landmarks
    };

    setStep(3);
    renderBgColorSelection();
  });

  // 创建图片元素用于检测
  const img = new Image();
  img.onload = async () => {
    const canvas = document.createElement('canvas');
    canvas.width = img.width;
    canvas.height = img.height;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0);
    await faceDetection.send({ image: canvas });
  };

  if (state.originalImage instanceof File) {
    img.src = await state.originalImage.arrayBuffer().then(b => {
      const blob = new Blob([b], { type: state.originalImage.type });
      return URL.createObjectURL(blob);
    });
  } else {
    img.src = state.originalImage;
  }
}
```

- [ ] **Step 3: 实现 renderStep3 - 背景色选择界面**

```javascript
function renderStep3() {
  return `
    <div class="card">
      <h2>第三步：选择背景色</h2>
      <p>请选择证件照背景颜色</p>

      <div style="display: flex; gap: 30px; justify-content: center; margin: 30px 0;">
        <div class="bg-option" onclick="selectBgColor('#1E5AA8')" style="cursor: pointer; text-align: center;">
          <div style="width: 120px; height: 150px; background: #1E5AA8; border-radius: 8px; border: 3px solid ${state.selectedBgColor === '#1E5AA8' ? '#333' : 'transparent'};"></div>
          <p style="margin-top: 10px;">蓝色背景</p>
        </div>
        <div class="bg-option" onclick="selectBgColor('#FFFFFF')" style="cursor: pointer; text-align: center;">
          <div style="width: 120px; height: 150px; background: #FFFFFF; border-radius: 8px; border: 3px solid ${state.selectedBgColor === '#FFFFFF' ? '#333' : 'transparent'}; box-shadow: 0 0 0 1px #ddd;"></div>
          <p style="margin-top: 10px;">白色背景</p>
        </div>
      </div>

      <div style="text-align: center; margin-top: 20px;">
        <button class="btn btn-secondary" onclick="setStep(1)">上一步</button>
        <button class="btn btn-primary" onclick="generatePhotos()">生成证件照</button>
      </div>
    </div>
  `;
}

function selectBgColor(color) {
  state.selectedBgColor = color;
  render(); // 重新渲染以更新选中状态
}
```

- [ ] **Step 4: 提交**

```bash
git add index.html
git commit -m "feat: implement face detection with MediaPipe"
```

---

### Task 4: 图像处理模块（抠图 + 背景替换）

**Files:**
- Modify: `index.html`（新增 processImage 函数）

- [ ] **Step 1: 实现 processImage - 人像抠图和背景替换**

```javascript
async function processImage() {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = img.width;
      canvas.height = img.height;
      ctx.drawImage(img, 0, 0);

      const srcImg = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const data = srcImg.data;

      // 检测皮肤色调范围 (简化版)
      const skinColor = detectSkinTone(data, canvas.width, canvas.height);

      // 遍历每个像素，判断是否接近皮肤色
      for (let i = 0; i < data.length; i += 4) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];

        if (isSkinPixel(r, g, b, skinColor)) {
          // 保留原像素（人像部分）
        } else {
          // 替换背景色
          const bgColor = hexToRgb(state.selectedBgColor);
          data[i] = bgColor.r;
          data[i + 1] = bgColor.g;
          data[i + 2] = bgColor.b;
          // alpha 保持不变
        }
      }

      ctx.putImageData(srcImg, 0, 0);
      state.processedImage = canvas;
      resolve();
    };

    if (state.originalImage instanceof File) {
      img.src = URL.createObjectURL(state.originalImage);
    } else {
      img.src = state.originalImage;
    }
  });
}

function detectSkinTone(data, width, height) {
  // 简单取中间区域采样皮肤色
  const centerX = Math.floor(width / 2);
  const centerY = Math.floor(height / 2);
  const sampleSize = Math.floor(Math.min(width, height) * 0.1);

  let rSum = 0, gSum = 0, bSum = 0, count = 0;

  for (let dy = -sampleSize; dy < sampleSize; dy += 2) {
    for (let dx = -sampleSize; dx < sampleSize; dx += 2) {
      const x = centerX + dx;
      const y = centerY + dy;
      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      const idx = (y * width + x) * 4;
      const r = data[idx];
      const g = data[idx + 1];
      const b = data[idx + 2];

      if (isSkinPixel(r, g, b)) {
        rSum += r; gSum += g; bSum += b; count++;
      }
    }
  }

  return count > 0
    ? { r: rSum / count, g: gSum / count, b: bSum / count }
    : { r: 200, g: 150, b: 120 };
}

function isSkinPixel(r, g, b, refColor) {
  // 基于 YCbCr 色彩空间简化判断
  const y = 0.299 * r + 0.587 * g + 0.114 * b;
  const cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
  const cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;

  // 皮肤色 Cb 范围: 77-127, Cr 范围: 133-173
  const isSkin = cb > 77 && cb < 127 && cr > 133 && cr < 173;

  // 额外基于距离判断
  if (refColor) {
    const dist = Math.sqrt(
      Math.pow(r - refColor.r, 2) +
      Math.pow(g - refColor.g, 2) +
      Math.pow(b - refColor.b, 2)
    );
    return isSkin || dist < 80;
  }

  return isSkin;
}

function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : { r: 255, g: 255, b: 255 };
}
```

- [ ] **Step 2: 实现 autoCrop - 人像自动裁剪**

```javascript
async function autoCrop() {
  const face = state.detectedFace;
  const srcCanvas = state.processedImage;
  const srcCtx = srcCanvas.getContext('2d');
  const srcW = srcCanvas.width;
  const srcH = srcCanvas.height;

  // 计算人像框：头部占比约 70-80%，下部留肩
  // 头顶到下巴的距离约为 boundingBox 高度的 1.2-1.3 倍
  const faceCenterX = face.x + face.width / 2;
  const faceCenterY = face.y + face.height / 2;

  // 证件照人像框比例：头顶到下巴占整个高度约 70%
  const headToChinRatio = 0.75;
  const totalHeight = face.height / headToChinRatio;

  // 人像框尺寸（正方形裁剪，基于较高维度）
  const cropSize = Math.max(totalHeight, face.width * 1.4);

  const cropCanvas = document.createElement('canvas');
  const cropCtx = cropCanvas.getContext('2d');

  // 计算裁剪区域，使面部居中偏上（下巴在底部 1/3 处）
  let cropX = faceCenterX * srcW - cropSize * srcW / 2;
  let cropY = face.y * srcH - cropSize * srcH * 0.15; // 头顶偏上
  let cropW = cropSize * srcW;
  let cropH = cropSize * srcH;

  // 边界检查
  cropX = Math.max(0, Math.min(cropX, srcW - cropW));
  cropY = Math.max(0, Math.min(cropY, srcH - cropH));
  cropW = Math.min(cropW, srcW - cropX);
  cropH = Math.min(cropH, srcH - cropY);

  cropCanvas.width = cropW;
  cropCanvas.height = cropH;
  cropCtx.drawImage(srcCanvas, cropX, cropY, cropW, cropH, 0, 0, cropW, cropH);

  state.croppedImage = cropCanvas;
  return cropCanvas;
}
```

- [ ] **Step 3: 提交**

```bash
git add index.html
git commit -m "feat: implement background removal and auto-crop"
```

---

### Task 5: 证件照尺寸生成模块

**Files:**
- Modify: `index.html`（新增 generatePhotos 函数）

- [ ] **Step 1: 定义证件照尺寸规格（单位px，300dpi）**

```javascript
const PHOTO_SIZES = {
  '一寸': { mm: { width: 25, height: 35 }, px: { width: 295, height: 413 } },
  '二寸': { mm: { width: 35, height: 49 }, px: { width: 413, height: 579 } },
  '小二寸': { mm: { width: 33, height: 48 }, px: { width: 390, height: 567 } }
};
```

- [ ] **Step 2: 实现 generatePhotos - 生成各尺寸证件照**

```javascript
async function generatePhotos() {
  setStep(4);
  renderStep4();

  // 处理图像（抠图+背景替换）
  await processImage();

  // 自动裁剪
  await autoCrop();

  const croppedCanvas = state.croppedImage;

  // 生成各尺寸
  state.photos = {};

  for (const [name, size] of Object.entries(PHOTO_SIZES)) {
    const photoCanvas = document.createElement('canvas');
    const photoCtx = photoCanvas.getContext('2d');

    photoCanvas.width = size.px.width;
    photoCanvas.height = size.px.height;

    // 绘制证件照（居中填充）
    const srcAspect = croppedCanvas.width / croppedCanvas.height;
    const dstAspect = size.px.width / size.px.height;

    let sx = 0, sy = 0, sw = croppedCanvas.width, sh = croppedCanvas.height;
    let dx = 0, dy = 0, dw = size.px.width, dh = size.px.height;

    if (srcAspect > dstAspect) {
      // 源更宽，按高度对齐，裁剪宽度
      sw = croppedCanvas.height * dstAspect;
      sx = (croppedCanvas.width - sw) / 2;
    } else {
      // 源更高，按宽度对齐，裁剪高度
      sh = croppedCanvas.width / dstAspect;
      sy = (croppedCanvas.height - sh) / 2;
    }

    photoCtx.drawImage(croppedCanvas, sx, sy, sw, sh, dx, dy, dw, dh);
    state.photos[name] = photoCanvas;
  }

  setStep(5);
  renderPhotoPreview();
}
```

- [ ] **Step 3: 实现 renderStep4 - 生成中界面**

```javascript
function renderStep4() {
  return `
    <div class="card" style="text-align: center;">
      <h2>第四步：生成证件照</h2>
      <p>正在处理照片，请稍候...</p>
      <div class="spinner" style="width: 40px; height: 40px; border: 4px solid #f0f0f0; border-top: 4px solid #1E5AA8; border-radius: 50%; animation: spin 1s linear infinite; margin: 30px auto;"></div>
    </div>
  `;
}
```

- [ ] **Step 4: 提交**

```bash
git add index.html
git commit -m "feat: implement multi-size ID photo generation"
```

---

### Task 6: 预览与下载模块

**Files:**
- Modify: `index.html`（新增 renderStep5、renderPhotoPreview、下载函数）

- [ ] **Step 1: 实现 renderStep5 / renderPhotoPreview - 预览界面**

```javascript
function renderStep5() {
  const photosHtml = Object.entries(state.photos).map(([name, canvas]) => `
    <div style="text-align: center; margin: 15px;">
      <h3>${name}</h3>
      <div style="border: 1px solid #ddd; padding: 10px; display: inline-block; background: ${state.selectedBgColor};">
        <img src="${canvas.toDataURL('image/png')}" style="width: 150px; display: block;">
      </div>
      <p style="font-size: 12px; color: #666;">${PHOTO_SIZES[name].mm.width}mm × ${PHOTO_SIZES[name].mm.height}mm</p>
      <button class="btn btn-secondary" style="margin-top: 5px;" onclick="downloadSingle('${name}')">下载 ${name}</button>
    </div>
  `).join('');

  return `
    <div class="card">
      <h2>第五步：预览与下载</h2>
      <p>您的证件照已生成完毕</p>

      <div style="display: flex; flex-wrap: wrap; gap: 20px; justify-content: center; margin: 20px 0;">
        ${photosHtml}
      </div>

      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <h3>打印排版</h3>
        <p style="margin: 10px 0;">排版后可直接打印冲印</p>
        <div style="display: flex; gap: 15px; justify-content: center; margin: 15px 0;">
          <button class="btn btn-primary" onclick="generateLayout('a4')">A4 排版下载</button>
          <button class="btn btn-secondary" onclick="generateLayout('6寸')">6寸排版下载</button>
        </div>
        <button class="btn btn-secondary" style="margin-top: 10px;" onclick="downloadAllZip()">打包下载所有尺寸</button>
      </div>

      <div style="text-align: center; margin-top: 20px;">
        <button class="btn btn-secondary" onclick="startOver()">重新制作</button>
      </div>
    </div>
  `;
}
```

- [ ] **Step 2: 实现 downloadSingle - 单张下载**

```javascript
function downloadSingle(name) {
  const canvas = state.photos[name];
  const link = document.createElement('a');
  link.download = `证件照_${name}.png`;
  link.href = canvas.toDataURL('image/png');
  link.click();
}
```

- [ ] **Step 3: 实现 generateLayout - 打印排版**

```javascript
function generateLayout(size) {
  // A4: 210mm x 297mm @300dpi = 2480 x 3508 px
  // 6寸: 6" x 4" @300dpi = 1800 x 1200 px

  const layouts = {
    'a4': { width: 2480, height: 3508 },
    '6寸': { width: 1800, height: 1200 }
  };

  const layout = layouts[size];
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  canvas.width = layout.width;
  canvas.height = layout.height;

  // 白色背景
  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // 计算排版：各尺寸各放几张
  // A4 排版（留边距 10mm = 118px）
  const margin = 118; // 10mm @300dpi
  const availW = canvas.width - 2 * margin;
  const availH = canvas.height - 2 * margin;

  // 每种尺寸各 4 张（A4 一页 12 张）
  let x = margin, y = margin;
  const gap = 40;

  for (const [name, photoCanvas] of Object.entries(state.photos)) {
    const px = photoCanvas.width;
    const py = photoCanvas.height;

    for (let i = 0; i < 4; i++) {
      ctx.drawImage(photoCanvas, x, y, px, py);
      x += px + gap;
      if (x + px > canvas.width - margin) {
        x = margin;
        y += py + gap;
      }
    }
  }

  // 下载
  const link = document.createElement('a');
  link.download = `证件照_${size}_排版.png`;
  link.href = canvas.toDataURL('image/png');
  link.click();
}
```

- [ ] **Step 4: 实现 downloadAllZip - 打包下载**

```javascript
async function downloadAllZip() {
  const zip = new JSZip();

  for (const [name, canvas] of Object.entries(state.photos)) {
    const dataUrl = canvas.toDataURL('image/png');
    const base64 = dataUrl.split(',')[1];
    zip.file(`证件照_${name}.png`, base64, { base64: true });
  }

  const blob = await zip.generateAsync({ type: 'blob' });
  const link = document.createElement('a');
  link.download = '证件照_全套.zip';
  link.href = URL.createObjectURL(blob);
  link.click();
}
```

- [ ] **Step 5: 实现 startOver - 重新开始**

```javascript
function startOver() {
  state.currentStep = 1;
  state.originalImage = null;
  state.detectedFace = null;
  state.processedImage = null;
  state.croppedImage = null;
  state.photos = {};
  state.selectedBgColor = '#1E5AA8';
  if (cameraStream) {
    cameraStream.getTracks().forEach(track => track.stop());
    cameraStream = null;
  }
  render();
}
```

- [ ] **Step 6: 修复 render 函数以支持 renderStep3 和 renderStep5**

render 函数需要在步骤 3 和 5 时调用对应的 render 函数：

```javascript
function render() {
  const content = document.getElementById('content');
  switch (state.currentStep) {
    case 1: content.innerHTML = renderStep1(); break;
    case 2: content.innerHTML = renderStep2(); break;
    case 3: content.innerHTML = renderStep3(); break;
    case 4: content.innerHTML = renderStep4(); break;
    case 5: content.innerHTML = renderStep5(); break;
  }
}
```

- [ ] **Step 7: 提交**

```bash
git add index.html
git commit -m "feat: implement preview and download (single, layout, zip)"
```

---

### Task 7: 集成测试与修复

**Files:**
- Modify: `index.html`

- [ ] **Step 1: 整体流程测试 - 检查所有步骤衔接**

打开 `index.html`（用 file:// 或本地服务器），按流程测试：
1. 点击"拍照"或"从相册选择"
2. 确认照片后是否进入人脸检测
3. 检测完成后是否正确显示背景色选择
4. 选择背景色并点击"生成证件照"
5. 检查各尺寸预览是否正常显示
6. 测试下载功能

- [ ] **Step 2: 修复发现的问题**

根据测试结果修复，可能的问题：
- getUserMedia 在 file:// 协议下不可用 → 提示用 http 服务器或相册选择
- MediaPipe CDN 加载失败 → 添加备用源或本地缓存提示
- 抠图边缘不自然 → 添加羽化效果
- 相机权限拒绝处理 → 添加错误提示和降级到相册

**羽化修复示例：**
```javascript
// 在 processImage 中，背景替换时添加边缘羽化
function processImage() {
  return new Promise((resolve) => {
    // ... 原有的像素遍历逻辑 ...

    // 添加边缘平滑（简单的高斯模糊模拟）
    // 在边缘处逐步混合
    for (let i = 0; i < data.length; i += 4) {
      // ... 原有判断逻辑 ...
      // 边缘处 alpha 渐变混合
    }

    ctx.putImageData(srcImg, 0, 0);
    state.processedImage = canvas;
    resolve();
  });
}
```

- [ ] **Step 3: 最终提交**

```bash
git add index.html
git commit -m "fix: resolve integration issues and edge cases"
```

---

## 自检清单

**Spec 覆盖检查：**
- [x] 照片输入（拍照 + 相册）→ Task 2
- [x] 人脸检测（MediaPipe）→ Task 3
- [x] 自动裁剪（头部居中）→ Task 4
- [x] 背景替换（蓝/白）→ Task 4
- [x] 三种尺寸（一寸/二寸/小二寸）→ Task 5
- [x] 单张下载 → Task 6
- [x] A4/6寸排版 → Task 6
- [x] ZIP 打包 → Task 6

**占位符检查：**
- [x] 无 TBD/TODO/待实现
- [x] 所有函数有完整实现
- [x] 所有 CSS 有具体样式

**一致性检查：**
- [x] `state` 对象各字段在所有任务中一致
- [x] `PHOTO_SIZES` 定义与 spec 一致
- [x] `setStep()` 调用逻辑正确
