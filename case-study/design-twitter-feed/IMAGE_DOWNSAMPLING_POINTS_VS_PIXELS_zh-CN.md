# 理解图片 Downsampling（降采样）：Points（点） vs Pixels（像素）

## 核心问题 🤔

**为什么图片 downsampling（降采样）时要乘 `UIScreen.main.scale`？**

答案：因为 **UIKit 用的是 POINTS（点）**，而 **图片和屏幕实际使用的是 PIXELS（像素）**，在 retina（视网膜）屏上：**1 point ≠ 1 pixel**！

---

## Points 与 Pixels 说明 📐

### iOS 到底在用什么

- **UIKit 使用 POINTS（点，逻辑单位，设备无关）**
- **屏幕显示的是 PIXELS（像素，物理单位）**
- **在 retina 屏上：1 point = 多个 pixels**

```swift
// 你在 UIKit 里写的是：
imageView.frame.size = CGSize(width: 190, height: 100)
//                                    ↑        ↑
//                                  POINTS   POINTS（不是 pixels）

// 但屏幕实际显示的是 PIXELS：
// iPhone 14 Pro (3x): 1 point = 3×3 pixels = 9 pixels
// iPhone 14 (2x):     1 point = 2×2 pixels = 4 pixels
// Old iPhone 3G:      1 point = 1×1 pixel  = 1 pixel
```

### Scale Factor（缩放因子）

```swift
// scale 表示：每个 point 对应多少个 pixel
UIScreen.main.scale

// 典型返回：
// 3.0: iPhone 14 Pro, iPhone 13 Pro, iPhone 12 Pro
// 2.0: iPhone 14, iPhone SE, 大多数 iPhone
// 1.0: 非常老的非 retina 设备
```

---

## 实际例子：你的图片 🖼️

### 你的场景
- **原图**：1920×1090 pixels（图片文件真实像素）
- **显示尺寸**：`(UIScreen.main.bounds.width - 32) × 190 points`
- **设备**：iPhone 14 Pro（3x）

### 开始计算

#### 显示尺寸（Points）
```swift
let width = UIScreen.main.bounds.width - 32  // ≈ 361 points
let height = 190  // points
```

#### 屏幕实际需要（Pixels）
```
设备：iPhone 14 Pro（scale = 3.0）

显示尺寸：     361×190 POINTS
                 ↓ 乘 scale
实际像素：     361×3 = 1083 pixels（宽）
              190×3 =  570 pixels（高）

屏幕最终需要：1083×570 PIXELS
```

---

## 不乘 Scale 会发生什么 ❌

### 如果你把 361×190 points 当成 pixels 去降采样：

```
步骤 1：降采样
原图：           1920×1090 pixels
降采样到：       361×190 PIXELS
                ↓
[得到一张较小的 361×190 图片]

步骤 2：在 iPhone 14 Pro 显示
屏幕需要：       1083×570 PIXELS
你提供：         361×190 PIXELS
iOS 被迫放大：   361×3 = 1083（3× 放大）
                190×3 = 570

结果：模糊（BLURRY）😞
```

**为什么会模糊？** 因为 iOS 把 361×190 的图拉伸到 1083×570，每个像素被扩成 3×3 像素块。

---

## 乘 Scale 后会发生什么 ✅

### 如果你降采样到 `(361×3)×(190×3) = 1083×570 pixels`：

```
步骤 1：降采样
原图：           1920×1090 pixels
降采样到：       1083×570 PIXELS（361 points × 3）
                ↓
[得到清晰的 1083×570 图片]

步骤 2：在 iPhone 14 Pro 显示
屏幕需要：       1083×570 PIXELS
你提供：         1083×570 PIXELS
完美匹配：       无需放大

结果：清晰（SHARP）✨
```

**为什么清晰？** 因为 downsample 后的像素数量和屏幕需求一致，image pixel 与 screen pixel 形成 1:1 映射。

---

## 可视化理解 🎨

### 原始图片
```
1920×1090 pixels
████████████████████████████████
████████████████████████████████
████████████████████████████████
```

### iPhone 14 Pro 显示（3x Retina）

```
┌────────────────────────────────────────────┐
│ UIImageView: 361×190 POINTS                │
│                                            │
│ 但屏幕实际显示：                           │
│ 1083×570 PIXELS（361×3, 190×3）            │
│                                            │
│ point 到 pixel 的映射：                    │
│                                            │
│  3x 设备上的 1 POINT：                     │
│  ┌─┬─┬─┐                                   │
│  │█│█│█│ ← 9 个屏幕像素                    │
│  ├─┼─┼─┤                                   │
│  │█│█│█│                                   │
│  ├─┼─┼─┤                                   │
│  │█│█│█│                                   │
│  └─┴─┴─┘                                   │
│                                            │
│ 如果图片只给这个 point 1 个像素：         │
│  ┌─────┐                                   │
│  │  █  │ ← 1 个图片像素被拉伸填满          │
│  │     │   9 个屏幕像素 = 模糊             │
│  └─────┘                                   │
│                                            │
│ 如果图片给这个 point 9 个像素：           │
│  ┌─┬─┬─┐                                   │
│  │█│█│█│ ← 9 个图片像素映射到             │
│  ├─┼─┼─┤   9 个屏幕像素 = 清晰             │
│  │█│█│█│                                   │
│  ├─┼─┼─┤                                   │
│  │█│█│█│                                   │
│  └─┴─┴─┘                                   │
└────────────────────────────────────────────┘
```

---

## 历史背景：为什么会有这个机制 📱

### iPhone 屏幕演进

#### iPhone 2G/3G（2007-2009）
```
屏幕：       320×480 pixels
Scale：      1.0（1 point = 1 pixel）
PPI：        163
显示尺寸：   320×480 points
```

#### iPhone 4（2010，第一代 Retina）
```
屏幕：       640×960 pixels  ← 像素变 2×
Scale：      2.0（1 point = 4 pixels）
PPI：        326  ← 密度翻倍
显示尺寸：   320×480 points  ← 逻辑尺寸不变

Apple 的关键设计：App 布局代码不用改，画面更清晰。
```

#### iPhone 14 Pro（2022）
```
屏幕：       1179×2556 pixels  ← 每 point 有 3× 像素
Scale：      3.0（1 point = 9 pixels）
PPI：        460
显示尺寸：   ~393×852 points

同样布局代码可继续使用，但图片想清晰就要提供更多像素。
```

### 为什么要有 Points

**如果 App 直接用 pixels 会怎样？**

- iPhone 3G 上按钮宽 100 pixels
- 到 iPhone 4，像素变密，按钮会看起来变小
- 大量旧 App 视觉会错乱

**用 points 解决：**

- 按钮宽 100 **points**
- iPhone 3G：100 points = 100 pixels
- iPhone 4：100 points = 200 pixels（2x）
- iPhone 14 Pro：100 points = 300 pixels（3x）
- 物理尺寸一致，只是更清晰

---

## 代码对比：正确与错误 ⚖️

### ❌ 错误：把 Points 当 Pixels

```swift
let targetSize = CGSize(
    width: UIScreen.main.bounds.width - 32,  // 361 POINTS
    height: 192                               // 192 POINTS
)

// 问题：DownsamplingImageProcessor 期望的是 PIXELS，不是 points
.processor(DownsamplingImageProcessor(size: targetSize))

// iPhone 14 Pro（3x）上：
// 实际降采样：361×192 PIXELS
// 显示需要：1083×576 PIXELS（361×3, 192×3）
// iOS 必须 3× 放大 → 模糊
```

### ✅ 正确：先 Points 转 Pixels

```swift
let displaySizeInPoints = CGSize(
    width: UIScreen.main.bounds.width - 32,  // 361 POINTS
    height: 192                               // 192 POINTS
)

// points -> pixels
let targetSizeInPixels = CGSize(
    width: displaySizeInPoints.width * UIScreen.main.scale,   // 361×3 = 1083
    height: displaySizeInPoints.height * UIScreen.main.scale  // 192×3 = 576
)

.processor(DownsamplingImageProcessor(size: targetSizeInPixels))

// iPhone 14 Pro（3x）上：
// 实际降采样：1083×576 PIXELS
// 显示需要：1083×576 PIXELS
// 1:1 映射 → 清晰
```

### 我们的实现

```swift
private static func calculateDownsampleSize(targetSize: CGSize?) -> CGSize {
    let screenScale = UIScreen.main.scale  // 2.0 or 3.0

    if let targetSize {
        // points -> pixels
        return CGSize(
            width: targetSize.width * screenScale,
            height: targetSize.height * screenScale
        )
    } else {
        // 默认缩略图：150×100 points
        return CGSize(
            width: 150 * screenScale,   // 2x: 300px, 3x: 450px
            height: 100 * screenScale   // 2x: 200px, 3x: 300px
        )
    }
}
```

---

## 真机验证 🧪

### 调试代码

```swift
print("=== Screen Information ===")
print("Scale factor: \(UIScreen.main.scale)x")
print("Screen bounds: \(UIScreen.main.bounds.size) points")
print("Screen pixels: \(UIScreen.main.bounds.width * UIScreen.main.scale) × \(UIScreen.main.bounds.height * UIScreen.main.scale)")
print("")

let displaySize = CGSize(width: UIScreen.main.bounds.width - 32, height: 192)
print("=== Your Image View ===")
print("Display size: \(displaySize) points")
print("Pixels needed: \(displaySize.width * UIScreen.main.scale) × \(displaySize.height * UIScreen.main.scale)")
print("")

print("=== Without Scale (WRONG) ===")
print("Downsampled to: \(displaySize.width) × \(displaySize.height) pixels")
print("But screen needs: \(displaySize.width * UIScreen.main.scale) × \(displaySize.height * UIScreen.main.scale) pixels")
print("Upscaling factor: \(UIScreen.main.scale)x → BLURRY!")
print("")

print("=== With Scale (CORRECT) ===")
let correctSize = CGSize(
    width: displaySize.width * UIScreen.main.scale,
    height: displaySize.height * UIScreen.main.scale
)
print("Downsampled to: \(correctSize.width) × \(correctSize.height) pixels")
print("Screen needs: \(correctSize.width) × \(correctSize.height) pixels")
print("Perfect match → SHARP!")
```

### iPhone 14 Pro（3x）输出

```
=== Screen Information ===
Scale factor: 3.0x
Screen bounds: (393.0, 852.0) points
Screen pixels: 1179.0 × 2556.0

=== Your Image View ===
Display size: (361.0, 192.0) points
Pixels needed: 1083.0 × 576.0

=== Without Scale (WRONG) ===
Downsampled to: 361.0 × 192.0 pixels
But screen needs: 1083.0 × 576.0 pixels
Upscaling factor: 3.0x → BLURRY!

=== With Scale (CORRECT) ===
Downsampled to: 1083.0 × 576.0 pixels
Screen needs: 1083.0 × 576.0 pixels
Perfect match → SHARP!
```

### iPhone SE（2x）输出

```
=== Screen Information ===
Scale factor: 2.0x
Screen bounds: (375.0, 667.0) points
Screen pixels: 750.0 × 1334.0

=== Your Image View ===
Display size: (343.0, 192.0) points
Pixels needed: 686.0 × 384.0

=== Without Scale (WRONG) ===
Downsampled to: 343.0 × 192.0 pixels
But screen needs: 686.0 × 384.0 pixels
Upscaling factor: 2.0x → BLURRY!

=== With Scale (CORRECT) ===
Downsampled to: 686.0 × 384.0 pixels
Screen needs: 686.0 × 384.0 pixels
Perfect match → SHARP!
```

---

## 常见场景 📊

### 场景 1：Feed 缩略图

```swift
// ImageView: 150×100 points

// ❌ 不乘 scale
Downsample 到: 150×100 pixels
3x 设备需要: 450×300 pixels
放大: 3× → 模糊

// ✅ 乘 scale（3x）
Downsample 到: 450×300 pixels
3x 设备需要: 450×300 pixels
无需放大 → 清晰
```

### 场景 2：全宽图片

```swift
// ImageView: (screen.width - 32) × 200 points
// iPhone 14 Pro 上约 361×200 points

// ❌ 不乘 scale
Downsample 到: 361×200 pixels
3x 设备需要: 1083×600 pixels
放大: 3× → 模糊

// ✅ 乘 scale（3x）
Downsample 到: 1083×600 pixels
3x 设备需要: 1083×600 pixels
无需放大 → 清晰
```

### 场景 3：小图标

```swift
// ImageView: 32×32 points

// ❌ 不乘 scale
Downsample 到: 32×32 pixels
3x 设备需要: 96×96 pixels
放大: 3× → 图标发糊

// ✅ 乘 scale（3x）
Downsample 到: 96×96 pixels
3x 设备需要: 96×96 pixels
无需放大 → 清晰
```

---

## 内存影响 💾

### 以 1920×1090 原图为例

```
原图：
- 尺寸：1920×1090 pixels
- 内存：约 8.2 MB（解压后）

不乘 scale（361×192）：
- 内存：约 270 KB
- 质量：3x 设备上模糊 ❌
- 节省：约 97%，但画质差

2x 设备乘 scale（686×384）：
- 内存：约 1.0 MB
- 质量：清晰 ✅
- 节省：约 88%，画质好

3x 设备乘 scale（1083×576）：
- 内存：约 2.4 MB
- 质量：清晰 ✅
- 节省：约 71%，画质好
```

**关键结论**：乘 scale 会增加一些内存，但相比原图仍小得多，且画质提升显著，这是正确 trade-off（取舍）。

---

## 为什么“文件大小小”，但“解码后内存大” 🧠

很多同学会困惑：  
同一张图，磁盘里可能只有几百 KB，但一显示就吃掉几 MB 内存。  
根因是：**比较的是两种完全不同的数据形态**。

### 1) 文件大小 = 压缩后的编码数据（用于存储/传输）

- JPEG/HEIF/WebP/PNG 文件在磁盘上通常是压缩格式
- 这个大小主要受压缩率、画面复杂度、编码质量影响
- 所以“文件 KB/MB”不能直接代表显示时内存

### 2) 解码后内存 = 未压缩像素缓冲区（用于渲染）

- 图片显示前，系统会把压缩数据解码成像素（bitmap）
- 常见情况下按 RGBA 计算：约 `4 bytes/pixel`
- 内存更接近：`width × height × bytesPerPixel`
- 实际上通常是：`bytesPerRow × height`（有行对齐，可能略大于简单乘法）

### 3) 你的例子（1920×1090）为什么会到约 8 MB

```text
1920 × 1090 × 4 bytes
= 8,371,200 bytes
≈ 7.98 MiB（约 8 MB）
```

即使文件本身只有 300 KB（例如高压缩 JPEG），解码后仍可能接近 8 MB。  
因为显示阶段需要的是“每个像素的颜色值”，不是压缩码流。

### 4) 还可能比 8 MB 更高的原因

- 同时存在多份数据：压缩数据 + 解码后的 bitmap + 渲染临时缓冲
- 不同像素格式/色彩空间（如更高位深）会提高每像素字节数
- 图像处理链路（resize/filter）可能产生中间副本

### 面试一句话回答

**文件大小看的是“压缩后体积”，内存大小看的是“解码后像素数量 × 每像素字节数”，两者不是同一维度，所以差距很大。**

---

## 黄金规则 🏆

### 规则 1：UIKit 用 Points
```swift
// 这些都是 POINTS：
imageView.frame.size
UIScreen.main.bounds
view.bounds
CGSize(width: 100, height: 100)
```

### 规则 2：图片处理用 Pixels
```swift
// 这些是 PIXELS：
image.size
CGImageGetWidth(image.cgImage)
DownsamplingImageProcessor 期望像素尺寸
```

### 规则 3：Points 转 Pixels
```swift
let pointsSize: CGSize = imageView.bounds.size
let pixelsSize = CGSize(
    width: pointsSize.width * UIScreen.main.scale,
    height: pointsSize.height * UIScreen.main.scale
)
```

### 规则 4：按“显示像素尺寸”做降采样
```swift
// ✅ 正确
let displaySizeInPoints = imageView.bounds.size
let downsampleSizeInPixels = CGSize(
    width: displaySizeInPoints.width * UIScreen.main.scale,
    height: displaySizeInPoints.height * UIScreen.main.scale
)

// ❌ 错误
let downsampleSize = imageView.bounds.size  // 把 points 误当 pixels
```

---

## 速查表 🎯

| 设备 | Scale | 示例 | Points → Pixels |
|---|---|---|---|
| iPhone 14 Pro Max | 3.0 | 100 pt | 300 px |
| iPhone 14 Pro | 3.0 | 100 pt | 300 px |
| iPhone 14 | 2.0 | 100 pt | 200 px |
| iPhone SE | 2.0 | 100 pt | 200 px |
| iPhone 13 Pro | 3.0 | 100 pt | 300 px |
| iPhone 12 | 2.0 | 100 pt | 200 px |
| iPad Pro 12.9" | 2.0 | 100 pt | 200 px |

**公式**：`pixels = points × scale`

---

## 常见错误 ⚠️

### 错误 1：把 Points 当 Pixels
```swift
// ❌ 错误
let size = CGSize(width: 190, height: 100)  // points
DownsamplingImageProcessor(size: size)      // 当成 pixels 了
```

### 错误 2：硬编码 scale
```swift
// ❌ 错误：假设所有设备都是 2x
let pixels = points * 2.0

// ✅ 正确：使用当前设备真实 scale
let pixels = points * UIScreen.main.scale
```

### 错误 3：只在模拟器验证
```swift
// 模拟器 scale 与真机可能不一致
// 图片清晰度问题请务必在真机验证
```

### 错误 4：降采样过小
```swift
// 如果显示需要 300×200 pixels
// 你却只 downsample 到 150×100
// iOS 必须放大 2× -> 模糊
// 建议至少匹配显示像素，或略高一点
```

---

## 总结 📝

### 核心概念
- **UIKit = Points（逻辑单位）**
- **Screen/Image = Pixels（物理单位）**
- **Scale = 每 point 对应的 pixel 数（2x 或 3x）**

### 问题本质
- `imageView` 尺寸通常是 points
- downsampling 目标尺寸需要的是 pixels
- 不转换就容易模糊

### 解决方案
```swift
pixelsNeeded = pointsSize * UIScreen.main.scale
```

### 你的场景
```swift
// 原图：1920×1090 pixels
// 显示：361×192 points（iPhone 14 Pro）

// 不乘 scale：361×192 pixels -> 模糊
// 乘 scale：1083×576 pixels（361×3, 192×3）-> 清晰
```

### 最重要结论
**当从 UIKit 的 points 转到图片处理尺寸时，一定要乘 `UIScreen.main.scale`。**

---

## 延伸阅读 📚

- [Apple: Points vs Pixels](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html)
- [Apple: Reducing Image Memory Footprint](https://developer.apple.com/documentation/uikit/images_and_pdf/reducing_the_memory_footprint_of_your_image_views)
- [UIScreen Scale Documentation](https://developer.apple.com/documentation/uikit/uiscreen/1617836-scale)
- [Human Interface Guidelines: Image Size and Resolution](https://developer.apple.com/design/human-interface-guidelines/images)

---

*本指南说明了：在 iOS retina 屏设备上做图片 downsampling（降采样）时，为什么必须考虑 screen scale（屏幕缩放因子）。*

---

## 面试口述精简版

### 30 秒版本（超短）

在 iOS 里，`UIKit` 的尺寸是 `points（点）`，但图片解码和屏幕显示是 `pixels（像素）`。  
`DownsamplingImageProcessor` 需要像素尺寸，所以必须把 `point × UIScreen.main.scale` 转成像素。  
不乘 scale 会导致系统放大图片（2x/3x），结果变糊；乘完后像素和屏幕需求 1:1 匹配，画质清晰且内存仍显著低于原图。

### 1 分钟版本（标准）

这个问题的关键是单位不一致：布局用 points，渲染用 pixels。  
例如 iPhone 14 Pro 是 3x，`361×192 points` 实际需要 `1083×576 pixels`。  
如果我直接按 `361×192` 去 downsample，显示时会被 3x 放大，出现模糊。  
正确做法是先把目标显示尺寸从 points 转成 pixels：`targetPixels = targetPoints × screenScale`，再做 downsampling。  
这样既避免了不必要的大图解码，也能保证清晰度，是性能和画质的平衡点。

### 3 分钟版本（面试可用）

我会先讲结论：**downsampling 的目标尺寸必须是 pixels，不是 points**。  
原因是 iOS 有逻辑坐标和物理坐标两套系统：UIKit 布局在 points，屏幕输出在 pixels。  

然后我会举一个设备例子：
- 在 3x 设备上，1 point = 3×3 pixels。  
- 一个 `361×192 points` 的 `UIImageView`，屏幕实际需要 `1083×576 pixels`。  

如果错误地按 points 去 downsample（`361×192 pixels`），iOS 只能再放大到 `1083×576`，就会模糊。  
如果先乘 scale，再 downsample 到 `1083×576 pixels`，显示就是 1:1 映射，画质稳定。  

我在工程上会固定这条规则：
1. 先拿 UI 显示尺寸（points）  
2. 乘 `UIScreen.main.scale` 得到像素目标  
3. 用该像素尺寸做 `DownsamplingImageProcessor`  
4. 真机验证（2x 与 3x）是否清晰

最后补一句 trade-off：乘 scale 会比“不乘”多用一点内存，但相对原图仍然节省很多，同时能显著提升清晰度，这是正确取舍。
