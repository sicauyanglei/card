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
      <text class="card-desc">正在检测人脸位置，请稍候...</text>
      <view class="spinner"></view>
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
      <text class="card-desc">正在处理照片，请稍候...</text>
      <view class="spinner"></view>
    </view>

    <!-- 步骤5: 预览与下载 -->
    <view v-if="currentStep === 5" class="card">
      <text class="card-title">第五步：预览与下载</text>
      <text class="card-desc">您的证件照已生成完毕</text>

      <view class="photos-grid">
        <view v-for="(name, index) in photoNames" :key="name" class="photo-item">
          <text class="photo-name">{{ name }}</text>
          <view class="photo-preview" :style="{ background: selectedBgColor }">
            <image :src="previewUrl" mode="aspectFit" class="photo-img"></image>
          </view>
          <text class="photo-size">{{ photoSizes[index] }}</text>
          <button class="btn btn-secondary btn-small" @click="savePhoto(name)">保存</button>
        </view>
      </view>

      <view class="section-divider">
        <text class="section-title">打印排版</text>
        <text class="card-desc">排版后可直接打印冲印</text>
        <view class="layout-btns">
          <button class="btn btn-primary" @click="downloadLayout('a4')">A4 排版</button>
          <button class="btn btn-secondary" @click="downloadLayout('6寸')">6寸排版</button>
        </view>
      </view>

      <view class="action-btns">
        <button class="btn btn-secondary" @click="startOver">重新制作</button>
      </view>
    </view>
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
      photoNames: ['一寸', '二寸', '小二寸'],
      photoSizes: ['25mm×35mm', '35mm×49mm', '33mm×48mm'],
      photoWidths: [295, 413, 390],
      photoHeights: [413, 579, 567]
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
      // 模拟检测延迟
      setTimeout(() => {
        this.currentStep = 3
      }, 1000)
    },

    // 生成证件照
    generatePhotos() {
      this.currentStep = 4
      // 模拟处理延迟
      setTimeout(() => {
        this.currentStep = 5
        uni.showToast({ title: '生成成功', icon: 'success' })
      }, 2000)
    },

    // 保存单张照片
    savePhoto(name) {
      if (!this.originalImage) {
        uni.showToast({ title: '请先选择照片', icon: 'none' })
        return
      }
      uni.saveImageToPhotosAlbum({
        filePath: this.originalImage,
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
      this.selectedBgColor = '#1E5AA8'
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
  background: #f0f0f0;
  color: #333;
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

.spinner {
  width: 60rpx;
  height: 60rpx;
  border: 4rpx solid #f0f0f0;
  border-top-color: #1E5AA8;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 40rpx auto;
}

@keyframes spin {
  to { transform: rotate(360deg); }
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
  margin-bottom: 10rpx;
}

.layout-btns {
  display: flex;
  gap: 20rpx;
  justify-content: center;
  margin: 20rpx 0;
}
</style>
