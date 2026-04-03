const { test, expect } = require('@playwright/test');
const path = require('path');

test.describe('证件照制作工具 E2E 测试', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);
  });

  test('页面加载成功，显示第一步上传照片', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('第一步：上传照片');
    await expect(page.locator('button', { hasText: '拍照' })).toBeVisible();
    await expect(page.locator('button', { hasText: '从相册选择' })).toBeVisible();
  });

  test('从相册选择按钮可点击', async ({ page }) => {
    const selectBtn = page.locator('button', { hasText: '从相册选择' });
    await expect(selectBtn).toBeVisible();
    await selectBtn.click();
  });

  test('选择照片后预览区域显示', async ({ page }) => {
    const fileInput = page.locator('#file-input');
    await fileInput.setInputFiles({
      name: 'test-photo.jpg',
      mimeType: 'image/jpeg',
      buffer: Buffer.from('fake-image-data')
    });

    await expect(page.locator('#preview-area')).toBeVisible();
  });

  test('重新选择按钮存在', async ({ page }) => {
    const fileInput = page.locator('#file-input');
    await fileInput.setInputFiles({
      name: 'test-photo.jpg',
      mimeType: 'image/jpeg',
      buffer: Buffer.from('fake-image-data')
    });

    const clearBtn = page.locator('button', { hasText: '重新选择' });
    await expect(clearBtn).toBeVisible();
  });

  test('预览区域无照片时隐藏', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    // 预览区域默认隐藏（通过父容器隐藏）
    await expect(page.locator('#preview-area')).toHaveClass(/hidden/);
  });

  test('标题正确显示', async ({ page }) => {
    await expect(page.locator('h1')).toContainText('证件照制作工具');
  });
});

test.describe('UI 元素完整性', () => {
  test('所有按钮存在', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    await expect(page.locator('button', { hasText: '拍照' })).toBeVisible();
    await expect(page.locator('button', { hasText: '从相册选择' })).toBeVisible();
  });

  test('隐藏元素存在但不可见', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    // 这些元素存在但默认隐藏
    await expect(page.locator('#file-input')).toBeAttached();
    await expect(page.locator('#camera-video')).toBeAttached();
    await expect(page.locator('#camera-canvas')).toBeAttached();
    await expect(page.locator('#capture-btn')).toBeAttached();
  });

  test('预览区域初始状态隐藏', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    await expect(page.locator('#preview-area')).toHaveClass(/hidden/);
  });
});

test.describe('CSS 样式检查', () => {
  test('页面有正确的样式定义', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    // 检查 card 样式
    const card = page.locator('.card').first();
    await expect(card).toBeVisible();
  });

  test('按钮有正确样式', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    const primaryBtn = page.locator('.btn-primary').first();
    await expect(primaryBtn).toBeVisible();
    await expect(primaryBtn).toHaveCSS('background-color', 'rgb(30, 90, 168)');
  });
});

test.describe('JavaScript 功能检查', () => {
  test('必要函数存在且可调用', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    // 函数通过 onclick 属性绑定，所以检查按钮的 onclick 属性
    const confirmBtn = page.locator('#preview-area .btn-primary');
    await expect(confirmBtn).toHaveAttribute('onclick', 'confirmPhoto()');

    const clearBtn = page.locator('#preview-area .btn-secondary').first();
    await expect(clearBtn).toHaveAttribute('onclick', 'clearPhoto()');
  });

  test('拍照和选择按钮有正确的事件处理', async ({ page }) => {
    await page.goto(`file://${path.resolve(__dirname, '../../index.html')}`);

    const cameraBtn = page.locator('button').filter({ hasText: '拍照' });
    await expect(cameraBtn).toHaveAttribute('onclick', 'openCamera()');

    const galleryBtn = page.locator('button').filter({ hasText: '从相册选择' });
    await expect(galleryBtn).toHaveAttribute('onclick', 'selectFromGallery()');
  });
});
