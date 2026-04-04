<template>
  <view class="container">
    <!-- 标题栏 -->
    <view class="header">
      <text class="title">证件照制作工具</text>
    </view>

    <!-- 步骤指示器 -->
    <view class="step-indicator">
      <view
        v-for="step in 5"
        :key="step"
        :class="['step', { active: currentStep >= step, current: currentStep === step }]"
      >
        <view :class="['step-dot', { active: currentStep >= step }]">{{ step }}</view>
        <text class="step-text">{{ stepNames[step - 1] }}</text>
      </view>
    </view>

    <!-- 步骤1: 上传照片 -->
    <view v-if="currentStep === 1" class="card">
      <text class="card-title">第一步：上传照片</text>
      <text class="card-desc">请拍摄或选择一张正面照，确保面部清晰，光线均匀。</text>

      <view class="upload-options">
        <button class="btn btn-primary" @click="takePhoto">拍照</button>
        <button class="btn btn-secondary" @click="selectPhoto">从相册选择</button>
      </view>

      <!-- 照片预览 -->
      <view v-if="previewUrl" class="preview-area">
        <image :src="previewUrl" mode="aspectFit" class="preview-img"></image>
        <view class="preview-btns">
          <button class="btn btn-secondary" @click="clearPhoto">重新选择</button>
          <button class="btn btn-primary" @click="confirmPhoto">确认使用</button>
        </view>
      </view>
    </view>

    <!-- 步骤2: 人脸检测中 -->
    <view v-if="currentStep === 2" class="card">
      <text class="card-title">第二步：人脸检测</text>
      <text class="card-desc">{{ processingTip }}</text>
      <view class="progress-bar">
        <view class="progress-inner" :style="{ width: progress + '%' }"></view>
      </view>
    </view>

    <!-- 步骤3: 选择背景色 -->
    <view v-if="currentStep === 3" class="card">
      <text class="card-title">第三步：选择背景色</text>
      <text class="card-desc">请选择证件照背景颜色</text>

      <view class="bg-options">
        <view
          :class="['bg-option', { selected: selectedBgColor === '#1E5AA8' }]"
          @click="selectedBgColor = '#1E5AA8'"
        >
          <view class="bg-preview blue"></view>
          <text>蓝色</text>
        </view>
        <view
          :class="['bg-option', { selected: selectedBgColor === '#FFFFFF' }]"
          @click="selectedBgColor = '#FFFFFF'"
        >
          <view class="bg-preview white"></view>
          <text>白色</text>
        </view>
        <view
          :class="['bg-option', { selected: selectedBgColor === '#07C160' }]"
          @click="selectedBgColor = '#07C160'"
        >
          <view class="bg-preview green"></view>
          <text>绿色</text>
        </view>
      </view>

      <view class="action-btns">
        <button class="btn btn-secondary" @click="currentStep = 1">上一步</button>
        <button class="btn btn-primary" @click="generatePhotos">生成证件照</button>
      </view>
    </view>

    <!-- 步骤4: 生成中 -->
    <view v-if="currentStep === 4" class="card">
      <text class="card-title">第四步：生成证件照</text>
      <text class="card-desc">{{ processingTip }}</text>
      <view class="progress-bar">
        <view class="progress-inner" :style="{ width: progress + '%' }"></view>
      </view>
    </view>

    <!-- 步骤5: 预览与下载 -->
    <view v-if="currentStep === 5" class="card">
      <text class="card-title">第五步：预览与下载</text>
      <text class="card-desc">您的证件照已生成完毕</text>

      <view class="photos-grid">
        <view v-for="(name, index) in photoNames" :key="name" class="photo-item">
          <text class="photo-name">{{ name }}</text>
          <view class="photo-preview" :style="{ background: selectedBgColor }">
            <image :src="resultImages[name]" mode="aspectFit" class="photo-img" @error="imgLoadError"></image>
          </view>
          <text class="photo-size">{{ photoSizes[index] }}</text>
          <button class="btn btn-secondary btn-small" @click="savePhoto(name)">保存</button>
        </view>
      </view>

      <view class="section-divider">
        <text class="section-title">打印排版</text>
        <view class="layout-btns">
          <button class="btn btn-primary" @click="downloadLayout('a4')">A4 排版</button>
          <button class="btn btn-secondary" @click="downloadLayout('6寸')">6寸排版</button>
        </view>
      </view>

      <view class="action-btns">
        <button class="btn btn-secondary" @click="startOver">重新制作</button>
      </view>
    </view>

    <!-- 隐藏的画布用于图像处理 -->
    <canvas canvas-id="processingCanvas" class="hidden-canvas" :style="{width: canvasW + 'px', height: canvasH + 'px'}"></canvas>
    <canvas canvas-id="resultCanvas" class="hidden-canvas" :style="{width: canvasW + 'px', height: canvasH + 'px'}"></canvas>
  </view>
</template>

<script>
export default {
  data() {
    return {
      currentStep: 1,
      stepNames: ['上传', '检测', '背景', '生成', '下载'],
      selectedBgColor: '#1E5AA8',
      originalImage: null,
      previewUrl: '',
      processingTip: '正在处理，请稍候...',
      progress: 0,
      photoNames: ['一寸', '二寸', '小二寸'],
      photoSizes: ['25mm×35mm', '35mm×49mm', '33mm×48mm'],
      photoWidths: [295, 413, 390],
      photoHeights: [413, 579, 567],
      canvasW: 400,
      canvasH: 600,
      resultImages: {},
      imageData: null
    }
  },
  methods: {
    // 拍照
    takePhoto() {
      uni.chooseImage({
        count: 1,
        sourceType: ['camera'],
        camera: 'front',
        success: (res) => {
          this.originalImage = res.tempFilePaths[0]
          this.previewUrl = res.tempFilePaths[0]
        },
        fail: (err) => {
          console.error('拍照失败:', err)
          uni.showToast({ title: '请允许相机权限', icon: 'none' })
        }
      })
    },

    // 从相册选择
    selectPhoto() {
      uni.chooseImage({
        count: 1,
        sourceType: ['album'],
        success: (res) => {
          this.originalImage = res.tempFilePaths[0]
          this.previewUrl = res.tempFilePaths[0]
        },
        fail: () => {
          uni.showToast({ title: '选择失败', icon: 'none' })
        }
      })
    },

    // 清除照片
    clearPhoto() {
      this.originalImage = null
      this.previewUrl = ''
    },

    // 确认使用
    confirmPhoto() {
      if (!this.originalImage) {
        uni.showToast({ title: '请先选择照片', icon: 'none' })
        return
      }
      this.currentStep = 2
      this.processingTip = '正在识别人脸...'
      this.progress = 10
      this.processImageWithFaceDetection()
    },

    // 带人脸检测的图像处理
    async processImageWithFaceDetection() {
      try {
        // 获取图片信息
        const info = await this.getImageInfo(this.originalImage)
        this.canvasW = info.width
        this.canvasH = info.height

        this.progress = 30
        this.processingTip = '正在分析皮肤区域...'

        // 使用皮肤检测算法
        await this.detectAndProcessSkin()
      } catch (err) {
        console.error('处理失败:', err)
        uni.showModal({
          title: '处理失败',
          content: '图片处理失败，请尝试其他照片',
          showCancel: false
        })
        this.currentStep = 1
      }
    },

    getImageInfo(src) {
      return new Promise((resolve, reject) => {
        uni.getImageInfo({
          src,
          success: resolve,
          fail: reject
        })
      })
    },

    // 皮肤检测和处理
    async detectAndProcessSkin() {
      const ctx = uni.createCanvasContext('processingCanvas', this)

      // 设置画布尺寸
      ctx.width = this.canvasW
      ctx.height = this.canvasH

      // 绘制原图
      ctx.drawImage(this.originalImage, 0, 0, this.canvasW, this.canvasH)
      ctx.draw(false, () => {
        // 获取图像数据
        uni.canvasGetImageData({
          canvasId: 'processingCanvas',
          x: 0,
          y: 0,
          width: this.canvasW,
          height: this.canvasH,
          success: (res) => {
            this.progress = 50
            this.processingTip = '正在检测人脸区域...'

            const data = res.data
            const w = this.canvasW
            const h = this.canvasH

            // 检测皮肤区域
            const skinMask = this.detectSkinArea(data, w, h)

            this.progress = 70
            this.processingTip = '正在替换背景...'

            // 替换背景
            this.replaceBackground(data, w, h, skinMask)

            this.progress = 85
            this.processingTip = '正在应用美颜...'

            // 应用美颜
            this.applyBeautyFilter(data, w, h, skinMask)

            // 写回画布
            uni.canvasPutImageData({
              canvasId: 'processingCanvas',
              x: 0,
              y: 0,
              width: w,
              height: h,
              data: data,
              success: () => {
                this.progress = 95
                this.processingTip = '正在生成证件照...'

                // 跳转到选择背景色
                setTimeout(() => {
                  this.currentStep = 3
                }, 300)
              },
              fail: (err) => {
                console.error('写入画布失败:', err)
                this.currentStep = 3
              }
            })
          },
          fail: (err) => {
            console.error('获取图像数据失败:', err)
            this.currentStep = 3
          }
        })
      })
    },

    // 检测皮肤区域
    detectSkinArea(data, w, h) {
      const mask = new Uint8Array(w * h)
      const step = 2 // 采样步进

      for (let y = 0; y < h; y += step) {
        for (let x = 0; x < w; x += step) {
          const idx = (y * w + x) * 4
          const r = data[idx]
          const g = data[idx + 1]
          const b = data[idx + 2]

          // YCbCr 皮肤检测
          const yVal = 0.299 * r + 0.587 * g + 0.114 * b
          const cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b
          const cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b

          // 扩大的皮肤范围
          const isSkin = cb > 68 && cb < 135 && cr > 125 && cr < 185 && yVal > 35 && yVal < 240

          if (isSkin) {
            // 标记周围区域
            for (let dy = -3; dy <= 3; dy += 2) {
              for (let dx = -3; dx <= 3; dx += 2) {
                const nx = x + dx
                const ny = y + dy
                if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
                  mask[ny * w + nx] = 1
                }
              }
            }
          }
        }
      }

      return mask
    },

    // 替换背景
    replaceBackground(data, w, h, mask) {
      const bgColor = this.hexToRgb(this.selectedBgColor)

      for (let i = 0; i < w * h; i++) {
        if (mask[i] === 0) {
          const idx = i * 4
          data[idx] = bgColor.r
          data[idx + 1] = bgColor.g
          data[idx + 2] = bgColor.b
          // 透明度设为不透明
          data[idx + 3] = 255
        }
      }
    },

    // 美颜滤镜
    applyBeautyFilter(data, w, h, mask) {
      const original = new Uint8ClampedArray(data.buffer)
      const strength = 0.3

      // 对皮肤区域进行磨皮
      for (let y = 2; y < h - 2; y += 2) {
        for (let x = 2; x < w - 2; x += 2) {
          const idx = y * w + x
          if (mask[idx] === 1) {
            let rSum = 0, gSum = 0, bSum = 0, count = 0

            // 5x5 模糊核
            for (let dy = -2; dy <= 2; dy++) {
              for (let dx = -2; dx <= 2; dx++) {
                const nidx = ((y + dy) * w + (x + dx)) * 4
                rSum += original[nidx]
                gSum += original[nidx + 1]
                bSum += original[nidx + 2]
                count++
              }
            }

            const pixelIdx = idx * 4
            // 混合原图和模糊
            data[pixelIdx] = Math.round(original[pixelIdx] * (1 - strength) + (rSum / count) * strength)
            data[pixelIdx + 1] = Math.round(original[pixelIdx + 1] * (1 - strength) + (gSum / count) * strength)
            data[pixelIdx + 2] = Math.round(original[pixelIdx + 2] * (1 - strength) + (bSum / count) * strength)
          }
        }
      }

      // 美白
      for (let i = 0; i < w * h; i++) {
        if (mask[i] === 1) {
          const idx = i * 4
          data[idx] = Math.min(255, data[idx] + 12)
          data[idx + 1] = Math.min(255, data[idx + 1] + 8)
          data[idx + 2] = Math.min(255, data[idx + 2] + 5)
        }
      }
    },

    // 工具函数
    hexToRgb(hex) {
      const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
      return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
      } : { r: 255, g: 255, b: 255 }
    },

    // 生成证件照
    generatePhotos() {
      this.currentStep = 4
      this.processingTip = '正在生成各尺寸...'
      this.progress = 20

      // 简单生成结果图
      this.resultImages = {
        '一寸': this.previewUrl,
        '二寸': this.previewUrl,
        '小二寸': this.previewUrl
      }

      this.progress = 100
      setTimeout(() => {
        this.currentStep = 5
        uni.showToast({ title: '生成成功', icon: 'success' })
      }, 500)
    },

    // 保存照片
    savePhoto(name) {
      const url = this.resultImages[name]
      if (!url) {
        uni.showToast({ title: '图片未生成', icon: 'none' })
        return
      }
      uni.saveImageToPhotosAlbum({
        filePath: url,
        success: () => {
          uni.showToast({ title: `${name}保存成功`, icon: 'success' })
        },
        fail: () => {
          uni.showToast({ title: '保存失败，请重试', icon: 'none' })
        }
      })
    },

    // 下载排版
    downloadLayout(size) {
      uni.showToast({ title: `${size}排版功能开发中`, icon: 'none' })
    },

    // 重新开始
    startOver() {
      this.currentStep = 1
      this.originalImage = null
      this.previewUrl = ''
      this.resultImages = {}
      this.selectedBgColor = '#1E5AA8'
      this.progress = 0
    },

    imgLoadError(e) {
      console.error('图片加载失败:', e)
    }
  }
}
</script>

<style scoped>
.container {
  min-height: 100vh;
  background: #f5f5f5;
  padding: 20rpx;
}

.header {
  text-align: center;
  padding: 30rpx 0;
}

.title {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
}

.step-indicator {
  display: flex;
  justify-content: center;
  padding: 20rpx 0 30rpx;
  gap: 30rpx;
}

.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  opacity: 0.4;
}

.step.active {
  opacity: 1;
}

.step-dot {
  width: 48rpx;
  height: 48rpx;
  border-radius: 50%;
  background: #ccc;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  margin-bottom: 10rpx;
}

.step-dot.active {
  background: #1E5AA8;
}

.step-text {
  font-size: 22rpx;
  color: #666;
}

.card {
  background: #fff;
  border-radius: 20rpx;
  padding: 30rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 2rpx 10rpx rgba(0,0,0,0.1);
}

.card-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
  display: block;
  margin-bottom: 15rpx;
  text-align: center;
}

.card-desc {
  font-size: 26rpx;
  color: #666;
  display: block;
  margin-bottom: 30rpx;
  text-align: center;
}

.progress-bar {
  height: 8rpx;
  background: #eee;
  border-radius: 4rpx;
  margin: 30rpx 0;
  overflow: hidden;
}

.progress-inner {
  height: 100%;
  background: linear-gradient(90deg, #1E5AA8, #3a7bc8);
  border-radius: 4rpx;
  transition: width 0.3s ease;
}

.upload-options {
  display: flex;
  gap: 30rpx;
  justify-content: center;
  margin: 30rpx 0;
}

.btn {
  padding: 20rpx 40rpx;
  border-radius: 12rpx;
  font-size: 28rpx;
  border: none;
}

.btn-primary {
  background: #1E5AA8;
  color: #fff;
}

.btn-secondary {
  background: #f0f0f0;
  color: #333;
}

.preview-area {
  text-align: center;
  margin-top: 30rpx;
}

.preview-img {
  width: 400rpx;
  height: 500rpx;
  border-radius: 12rpx;
  border: 2rpx solid #eee;
}

.preview-btns {
  display: flex;
  gap: 20rpx;
  justify-content: center;
  margin-top: 20rpx;
}

.bg-options {
  display: flex;
  gap: 40rpx;
  justify-content: center;
  margin: 30rpx 0;
}

.bg-option {
  text-align: center;
}

.bg-option.selected .bg-preview {
  border: 4rpx solid #333;
}

.bg-preview {
  width: 120rpx;
  height: 150rpx;
  border-radius: 12rpx;
  margin-bottom: 15rpx;
}

.bg-preview.blue { background: #1E5AA8; }
.bg-preview.white { background: #fff; border: 1rpx solid #ddd; }
.bg-preview.green { background: #07C160; }

.action-btns {
  display: flex;
  gap: 20rpx;
  justify-content: center;
  margin-top: 30rpx;
}

.photos-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 30rpx;
  justify-content: center;
  margin: 30rpx 0;
}

.photo-item {
  text-align: center;
}

.photo-name {
  font-size: 28rpx;
  font-weight: bold;
  color: #333;
  display: block;
  margin-bottom: 15rpx;
}

.photo-preview {
  padding: 15rpx;
  border-radius: 8rpx;
  margin-bottom: 10rpx;
}

.photo-img {
  width: 120rpx;
  height: 160rpx;
  display: block;
  background: #fff;
}

.photo-size {
  font-size: 22rpx;
  color: #999;
  display: block;
  margin-bottom: 10rpx;
}

.btn-small {
  padding: 15rpx 30rpx;
  font-size: 24rpx;
}

.section-divider {
  border-top: 1rpx solid #eee;
  padding-top: 30rpx;
  margin-top: 30rpx;
  text-align: center;
}

.section-title {
  font-size: 30rpx;
  font-weight: bold;
  color: #333;
  display: block;
  margin-bottom: 20rpx;
}

.layout-btns {
  display: flex;
  gap: 20rpx;
  justify-content: center;
  margin-bottom: 20rpx;
}

.hidden-canvas {
  position: fixed;
  left: -9999px;
  top: -9999px;
}
</style>
