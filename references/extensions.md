# 扩展 API 详细参考

当 SKILL.md 中的速查信息不够用时，加载此文件获取详细 API 文档。

## 转场效果详解（@remotion/transitions）

### TransitionSeries 完整用法

```typescript
import { TransitionSeries, linearTiming, springTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { wipe } from "@remotion/transitions/wipe";
import { flip } from "@remotion/transitions/flip";
import { clockWipe } from "@remotion/transitions/clock-wipe";
```

**所有转场类型**：
- `fade()` — 淡入淡出
- `slide({ direction })` — 滑动，direction: `"from-left"` | `"from-right"` | `"from-top"` | `"from-bottom"`
- `wipe({ direction })` — 擦除，同上方向
- `flip({ direction })` — 翻转，direction: `"from-left"` | `"from-right"` | `"from-top"` | `"from-bottom"`
- `clockWipe()` — 时钟式擦除

**时间控制**：
- `linearTiming({ durationInFrames: 20 })` — 匀速
- `springTiming({ config: { damping: 200 }, durationInFrames: 25 })` — 弹性

**Overlay（叠加效果）**：
```typescript
<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={60}><SceneA /></TransitionSeries.Sequence>
  <TransitionSeries.Overlay durationInFrames={20}>
    <CustomOverlayEffect />
  </TransitionSeries.Overlay>
  <TransitionSeries.Sequence durationInFrames={60}><SceneB /></TransitionSeries.Sequence>
</TransitionSeries>
```
- Overlay 不缩短总时长，Transition 会缩短
- Overlay 不能与 Transition 相邻

**时长计算**：
```typescript
const timing = linearTiming({ durationInFrames: 15 });
const transitionDuration = timing.getDurationInFrames({ fps: 30 });
// 总时长 = 所有场景时长之和 - 所有转场时长之和
```

## Google 字体详解（@remotion/google-fonts）

```typescript
// 基本用法
import { loadFont } from "@remotion/google-fonts/Lobster";
const { fontFamily } = loadFont();

// 指定字重和子集（减小文件大小）
import { loadFont } from "@remotion/google-fonts/Roboto";
const { fontFamily } = loadFont("normal", {
  weights: ["400", "700"],
  subsets: ["latin"],
});

// 等待字体加载完成
const { fontFamily, waitUntilDone } = loadFont();
await waitUntilDone();
```

**⚠️ 中文字体不要用 @remotion/google-fonts**——中文字体有 100+ 个 Unicode 子集，每次渲染需要从 Google CDN（fonts.gstatic.com）下载，在中国网络经常超时失败。

**中文字体推荐方案**——使用系统字体回退链（零网络依赖，跨平台）：
```typescript
// 覆盖 macOS (PingFang SC) + Windows (Microsoft YaHei) + Linux (Noto Sans CJK)
const fontFamily = '"PingFang SC", "Microsoft YaHei", "Hiragino Sans GB", "Noto Sans CJK SC", "WenQuanYi Micro Hei", sans-serif';
```

## 本地字体详解（@remotion/fonts）

```typescript
import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";

// 加载单个字体
await loadFont({
  family: "MyFont",
  url: staticFile("MyFont-Regular.woff2"),
  weight: "400",
  style: "normal",
  format: "woff2",    // 可选，自动检测
  display: "block",   // 可选
});

// 加载多个字重
await Promise.all([
  loadFont({ family: "Inter", url: staticFile("Inter-Regular.woff2"), weight: "400" }),
  loadFont({ family: "Inter", url: staticFile("Inter-Bold.woff2"), weight: "700" }),
]);
```

## 形状详解（@remotion/shapes）

```typescript
import { Circle, Rect, Triangle, Star, Ellipse, Pie } from "@remotion/shapes";

// 圆形
<Circle radius={100} fill="blue" stroke="white" strokeWidth={2} />

// 矩形
<Rect width={200} height={100} fill="red" cornerRadius={10} />

// 三角形
<Triangle length={200} direction="up" fill="green" cornerRadius={5} />
// direction: "up" | "down" | "left" | "right"

// 星形
<Star innerRadius={50} outerRadius={100} points={5} fill="gold" cornerRadius={3} />

// 椭圆
<Ellipse rx={150} ry={100} fill="purple" />

// 饼图/扇形
<Pie radius={100} progress={0.75} fill="orange" closePath rotation={-Math.PI / 2} />
// progress: 0-1，rotation 用于设置起始角度（-PI/2 = 12 点钟方向）
```

**获取形状的 SVG 路径**（用于路径动画）：
```typescript
import { makeCircle, makeRect, makeStar, makeTriangle, makePie } from "@remotion/shapes";
const circlePath = makeCircle({ radius: 100 });
// 返回 { path, width, height, transformOrigin, instructions }
```

## SVG 路径动画详解（@remotion/paths）

```typescript
import {
  evolvePath,           // 路径绘制动画
  getLength,            // 获取路径总长度
  getPointAtLength,     // 获取路径上某点坐标
  getTangentAtLength,   // 获取路径上某点切线方向
  getSubpaths,          // 分割复合路径
  interpolatePath,      // 两个路径之间插值变形
  reversePath,          // 反转路径方向
  scalePath,            // 缩放路径
  translatePath,        // 平移路径
  warpPath,             // 变形路径
  resetPath,            // 将路径移到原点
  getBoundingBox,       // 获取路径边界框
  normalizePath,        // 标准化路径
} from "@remotion/paths";

// 路径绘制动画（折线图、签名效果）
const progress = interpolate(frame, [0, 60], [0, 1], { extrapolateRight: "clamp" });
const { strokeDasharray, strokeDashoffset } = evolvePath(progress, pathString);
<path d={pathString} strokeDasharray={strokeDasharray} strokeDashoffset={strokeDashoffset} />

// 沿路径移动物体
const pathLength = getLength(pathString);
const point = getPointAtLength(pathString, progress * pathLength);
const tangent = getTangentAtLength(pathString, progress * pathLength);
const angle = Math.atan2(tangent.y, tangent.x);

// 路径变形动画（两个形状之间平滑过渡）
const morphed = interpolatePath(progress, path1, path2);
```

## 噪声详解（@remotion/noise）

```typescript
import { noise2D, noise3D, noise4D } from "@remotion/noise";

// 2D 噪声（用于平面纹理、波浪）
const value = noise2D("seed", x * 0.01, y * 0.01); // 返回 -1 到 1

// 3D 噪声（用于随时间变化的 2D 纹理）
const value = noise3D("seed", x * 0.01, y * 0.01, frame * 0.02);

// 4D 噪声（用于随时间变化的 3D 效果）
const value = noise4D("seed", x, y, z, frame * 0.02);

// 常见用法：粒子系统
const particles = Array.from({ length: 100 }, (_, i) => {
  const x = noise2D("x" + i, i * 0.1, frame * 0.02) * width;
  const y = noise2D("y" + i, i * 0.1, frame * 0.02) * height;
  return { x, y };
});
```

## 运动模糊详解（@remotion/motion-blur）

```typescript
import { CameraMotionBlur } from "@remotion/motion-blur";

// 包裹需要模糊的内容
<CameraMotionBlur samples={10} shutterAngle={180}>
  <YourFastMovingContent />
</CameraMotionBlur>

// samples: 采样数（越多越平滑，性能越差），建议 8-15
// shutterAngle: 快门角度（0-360），180 是电影标准
```

## 文字测量详解（@remotion/layout-utils）

```typescript
import { measureText, fillTextBox, fitText } from "@remotion/layout-utils";

// 测量文字尺寸
const { width, height } = measureText({
  text: "Hello World",
  fontFamily: "Arial",
  fontSize: 48,
  fontWeight: "bold",
});

// 自动缩放文字以适配容器宽度
const { fontSize } = fitText({
  text: "很长的标题文字需要自动缩小",
  withinWidth: 800,
  fontFamily: "Arial",
});

// 填充文本框（自动换行计算）
const lines = fillTextBox({
  maxWidth: 600,
  maxLines: 3,
  fontSize: 32,
  fontFamily: "Arial",
  text: "需要自动换行的长文本...",
});
```

## GIF 详解（@remotion/gif）

```typescript
import { Gif } from "@remotion/gif";
import { staticFile } from "remotion";

<Gif
  src={staticFile("animation.gif")}
  width={300}
  height={300}
  fit="cover"        // "cover" | "contain" | "fill"
  playbackRate={1}   // 播放速度
/>
// GIF 帧自动与视频时间轴同步
// 可用远程 URL：<Gif src="https://example.com/animation.gif" />
```

## 音频可视化详解（@remotion/media-utils）

```typescript
import { useAudioData, visualizeAudio, getAudioDurationInSeconds } from "@remotion/media-utils";
import { staticFile, useCurrentFrame, useVideoConfig } from "remotion";

// 获取音频时长（用于动态设置视频长度）
const durationInSeconds = await getAudioDurationInSeconds(staticFile("audio.mp3"));

// 音频频谱可视化
const MyVisualization = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const audioData = useAudioData(staticFile("audio.mp3"));
  if (!audioData) return null;

  const visualization = visualizeAudio({
    fps,
    frame,
    audioData,
    numberOfSamples: 256,  // FFT 采样数（2 的幂次）
  });

  // visualization 是一个数组，每个值 0-1 代表该频段的强度
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 2 }}>
      {visualization.map((v, i) => (
        <div key={i} style={{ width: 4, height: v * 200, background: "white" }} />
      ))}
    </div>
  );
};
```

## 音视频操作详解（@remotion/media）

### Audio 完整属性
```typescript
import { Audio } from "@remotion/media";

<Audio
  src={staticFile("audio.mp3")}     // 音频源（本地或远程 URL）
  volume={0.5}                       // 静态音量 0-1，或函数 (f) => number
  muted={false}                      // 是否静音（可动态）
  trimBefore={2 * fps}               // 跳过开头（帧数）
  trimAfter={10 * fps}               // 截断结尾（帧数）
  playbackRate={1.5}                 // 播放速度
  loop                               // 是否循环
  loopVolumeCurveBehavior="repeat"   // "repeat" | "extend"
  toneFrequency={1.2}               // 变调 0.01-2（仅渲染时生效）
/>
```

### Video / OffthreadVideo 完整属性
```typescript
import { Video, OffthreadVideo } from "@remotion/media";

// OffthreadVideo 推荐用于嵌入视频（在独立线程解码，不阻塞渲染）
<OffthreadVideo
  src={staticFile("clip.mp4")}
  volume={0.8}
  muted={false}
  trimBefore={2 * fps}
  trimAfter={10 * fps}
  playbackRate={2}
  loop
  toneFrequency={1.0}
  style={{ width: 500, objectFit: "cover" }}
/>
```

## Sequence 和 Series 详解

### Sequence（自由定位）
```typescript
<Sequence
  from={30}                    // 从第 30 帧开始
  durationInFrames={60}        // 持续 60 帧
  premountFor={30}             // 提前 30 帧预加载（始终使用！）
  layout="none"                // 不包裹 AbsoluteFill（用于 inline 布局）
  width={500}                  // 指定宽度（嵌套 Composition 时用）
  height={300}                 // 指定高度
>
  <Content />
</Sequence>
// Sequence 内部的 useCurrentFrame() 返回局部帧号（从 0 开始）
```

### Series（顺序排列）
```typescript
<Series>
  <Series.Sequence durationInFrames={45}><Intro /></Series.Sequence>
  <Series.Sequence durationInFrames={60}><MainContent /></Series.Sequence>
  <Series.Sequence offset={-15} durationInFrames={60}>
    {/* offset 负值 = 与上一个场景重叠 15 帧 */}
    <Outro />
  </Series.Sequence>
</Series>
```

## 参数化视频（Zod Schema）

```typescript
import { z } from "zod";
import { Composition } from "remotion";

// 定义参数 schema
const videoSchema = z.object({
  title: z.string(),
  subtitle: z.string().optional(),
  backgroundColor: z.string().default("#1a1a2e"),
  items: z.array(z.string()),
});

// 在 Root.tsx 中使用
<Composition
  id="Main"
  component={Main}
  schema={videoSchema}
  defaultProps={{
    title: "默认标题",
    backgroundColor: "#1a1a2e",
    items: ["第一项", "第二项"],
  }}
  durationInFrames={300}
  fps={30}
  width={1080}
  height={1080}
/>

// 渲染时传入不同参数
// npx remotion render src/index.ts Main output.mp4 --props='{"title":"自定义标题"}'
```

## 透明视频渲染

在 render.sh 中使用以下参数：
```bash
npx remotion render src/index.ts Main output.webm \
  --codec vp8 \
  --image-format png
```
- 输出格式必须是 WebM
- 背景不要设置颜色（保持透明）

## 3D 场景详解（@remotion/three）

需要安装：three、@react-three/fiber、@react-three/drei（已在 optionalDependencies）

```typescript
import { ThreeCanvas } from "@remotion/three";
import { useCurrentFrame } from "remotion";

const My3DScene = () => {
  const frame = useCurrentFrame();
  return (
    <ThreeCanvas width={1080} height={1080}>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <mesh rotation={[0, frame * 0.02, 0]}>
        <boxGeometry args={[2, 2, 2]} />
        <meshStandardMaterial color="orange" />
      </mesh>
    </ThreeCanvas>
  );
};

// 注意：ThreeCanvas 代替普通的 <Canvas>，确保与 Remotion 时间轴同步
```

## Lottie 动画详解（@remotion/lottie）

需要安装：lottie-web（已在 optionalDependencies）

```typescript
import { Lottie, getLottieMetadata } from "@remotion/lottie";
import animationData from "./animation.json";

// 获取 Lottie 元数据（用于计算时长）
const metadata = getLottieMetadata(animationData);
// metadata.durationInSeconds, metadata.fps

const MyLottie = () => {
  return (
    <Lottie
      animationData={animationData}
      style={{ width: 500, height: 500 }}
      playbackRate={1}
      direction="forward"  // "forward" | "backward"
    />
  );
};
// Lottie 自动与视频时间轴同步
```

## Tailwind CSS 配置（@remotion/tailwind）

在 remotion.config.ts 中启用：
```typescript
import { Config } from "@remotion/cli/config";
import { enableTailwind } from "@remotion/tailwind";

Config.overrideWebpackConfig((config) => {
  return enableTailwind(config);
});
```

然后创建 tailwind.config.js：
```javascript
module.exports = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: { extend: {} },
  plugins: [],
};
```

在组件中使用：
```typescript
// 在入口文件顶部引入
import "./style.css"; // 内容：@tailwind base; @tailwind components; @tailwind utilities;

const MyComponent = () => (
  <div className="flex items-center justify-center bg-gradient-to-r from-blue-500 to-purple-600">
    <h1 className="text-6xl font-bold text-white">Hello</h1>
  </div>
);
```

## delayRender / continueRender（异步资源加载）

```typescript
import { delayRender, continueRender, staticFile } from "remotion";
import { useEffect, useState } from "react";

const MyComponent = () => {
  const [data, setData] = useState(null);
  const [handle] = useState(() => delayRender("Loading data..."));

  useEffect(() => {
    fetch(staticFile("data.json"))
      .then((res) => res.json())
      .then((json) => {
        setData(json);
        continueRender(handle);
      })
      .catch((err) => {
        console.error(err);
        continueRender(handle); // 必须调用，否则渲染会超时
      });
  }, [handle]);

  if (!data) return null;
  return <div>{JSON.stringify(data)}</div>;
};
// 注意：delayRender 有 30 秒超时，必须在超时前调用 continueRender
```

## Light Leaks 效果（@remotion/light-leaks）

WebGL 光泄漏效果，常用于转场叠加。在持续时间的前半段展开，后半段收回。

```typescript
import { LightLeak } from "@remotion/light-leaks";
import { TransitionSeries } from "@remotion/transitions";

// 配合 TransitionSeries.Overlay 使用（最常见用法）
<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={2 * fps}><SceneA /></TransitionSeries.Sequence>
  <TransitionSeries.Overlay durationInFrames={1 * fps}>
    <LightLeak />
  </TransitionSeries.Overlay>
  <TransitionSeries.Sequence durationInFrames={2 * fps}><SceneB /></TransitionSeries.Sequence>
</TransitionSeries>

// 自定义外观
<LightLeak
  seed={5}         // 改变光泄漏的形状图案（不同 seed = 不同图案）
  hueShift={240}   // 色相旋转（0=橙黄, 120=绿, 240=蓝）
/>

// 独立使用（作为装饰叠加层）
<AbsoluteFill>
  <MyContent />
  <LightLeak durationInFrames={2 * fps} seed={3} hueShift={120} />
</AbsoluteFill>
```

## calculateMetadata 动态元数据

动态计算 Composition 的时长、尺寸、props——在渲染前执行一次。

```typescript
import { Composition, CalculateMetadataFunction } from "remotion";

// 定义计算函数
const calculateMetadata: CalculateMetadataFunction<MyProps> = async ({ props, abortSignal }) => {
  // 典型用法：根据音频时长动态设置视频时长
  const response = await fetch(props.dataUrl, { signal: abortSignal });
  const data = await response.json();

  return {
    durationInFrames: Math.ceil(data.audioDuration * 30), // 动态时长
    width: 1080,          // 可选：动态宽度
    height: 1080,         // 可选：动态高度
    fps: 30,              // 可选：动态帧率
    props: {              // 可选：转换 props
      ...props,
      fetchedData: data,
    },
  };
};

// 在 Root.tsx 中使用
<Composition
  id="Main"
  component={Main}
  durationInFrames={300}       // 占位值，会被 calculateMetadata 覆盖
  fps={30}
  width={1080}
  height={1080}
  defaultProps={{ dataUrl: "https://api.example.com/video-config" }}
  calculateMetadata={calculateMetadata}
/>
```

**配合音频时长的典型用法**：
```typescript
import { getAudioDurationInSeconds } from "@remotion/media-utils";
import { staticFile } from "remotion";

const calculateMetadata: CalculateMetadataFunction<Props> = async ({ props }) => {
  const duration = await getAudioDurationInSeconds(staticFile("narration.mp3"));
  return {
    durationInFrames: Math.ceil(duration * 30) + 60, // 音频时长 + 2秒片尾
  };
};
```

## Easing 缓动函数完整参考

除了 `spring()` 之外，`interpolate()` 支持丰富的缓动曲线：

```typescript
import { interpolate, Easing } from "remotion";

// 基本用法：给 interpolate 加 easing
const value = interpolate(frame, [0, 2 * fps], [0, 1], {
  easing: Easing.inOut(Easing.quad),
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
});
```

**凹凸性（Convexity）**——控制加速/减速：
- `Easing.in(curve)` — 慢启快停
- `Easing.out(curve)` — 快启慢停
- `Easing.inOut(curve)` — 慢启慢停

**曲线（Curve）**——控制弯曲程度（从平缓到剧烈）：
- `Easing.quad` — 二次（轻柔）
- `Easing.sin` — 正弦（自然）
- `Easing.exp` — 指数（强烈）
- `Easing.circle` — 圆弧（最剧烈）

**组合使用**：
```typescript
Easing.inOut(Easing.quad)    // 最常用：平滑的慢启慢停
Easing.out(Easing.exp)       // 快速弹出然后缓慢停下
Easing.in(Easing.circle)     // 缓慢启动然后急速加速
```

**贝塞尔曲线**——精确控制运动曲线：
```typescript
// 自定义贝塞尔曲线（与 CSS cubic-bezier 相同参数）
Easing.bezier(0.8, 0.22, 0.96, 0.65)  // 自定义运动曲线
Easing.bezier(0.25, 0.1, 0.25, 1.0)   // 类似 CSS ease
```

## AI 配音集成（ElevenLabs TTS）

用 ElevenLabs API 生成语音，配合 `calculateMetadata` 动态调整视频时长。

**前提**：需要 `ELEVENLABS_API_KEY` 环境变量。必须询问用户是否有 API Key。

**流程**：
1. 创建语音生成脚本（generate-voiceover.ts）
2. 调用 ElevenLabs API 生成 MP3
3. 用 `calculateMetadata` 读取音频时长，动态设置视频时长
4. 在组件中用 `<Audio>` 播放

```typescript
// generate-voiceover.ts —— 生成语音文件
const response = await fetch(
  `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
  {
    method: "POST",
    headers: {
      "xi-api-key": process.env.ELEVENLABS_API_KEY!,
      "Content-Type": "application/json",
      Accept: "audio/mpeg",
    },
    body: JSON.stringify({
      text: "欢迎来到今天的分享",
      model_id: "eleven_multilingual_v2",
      voice_settings: { stability: 0.5, similarity_boost: 0.75, style: 0.3 },
    }),
  },
);
const audioBuffer = Buffer.from(await response.arrayBuffer());
writeFileSync("public/voiceover/scene-01.mp3", audioBuffer);

// 运行：node --strip-types generate-voiceover.ts
```

## 音频可视化进阶（useWindowedAudioData）

性能更好的音频数据加载方式，适合长音频：

```typescript
import { useWindowedAudioData, visualizeAudio, visualizeAudioWaveform, createSmoothSvgPath } from "@remotion/media-utils";

// 窗口式加载（只加载当前帧附近的音频数据，比 useAudioData 更省内存）
const { audioData, dataOffsetInSeconds } = useWindowedAudioData({
  src: staticFile("music.mp3"),
  frame,
  fps,
  windowInSeconds: 30,   // 加载 30 秒窗口
});

// 频谱可视化（传入 dataOffsetInSeconds）
const frequencies = visualizeAudio({
  fps, frame, audioData,
  numberOfSamples: 256,
  optimizeFor: "speed",
  dataOffsetInSeconds,    // 重要：窗口偏移量
});

// 波形可视化（示波器风格）
const waveform = visualizeAudioWaveform({
  fps, frame, audioData,
  numberOfSamples: 256,
  windowInSeconds: 0.5,
  dataOffsetInSeconds,
});
const path = createSmoothSvgPath({
  points: waveform.map((y, i) => ({
    x: (i / (waveform.length - 1)) * width,
    y: HEIGHT / 2 + (y * HEIGHT) / 2,
  })),
});

// 低频提取（bass-reactive 效果：跟着节拍跳动）
const lowFreqs = frequencies.slice(0, 32);
const bassIntensity = lowFreqs.reduce((sum, v) => sum + v, 0) / lowFreqs.length;
const scale = 1 + bassIntensity * 0.5;  // 低音越强，放大越多
```

## 字幕系统（@remotion/captions）

使用 JSON 格式的字幕数据，支持转录和显示。高级用法请加载 `/remotion` Skill 的 rules/subtitles.md。

```typescript
import type { Caption } from "@remotion/captions";

// 字幕数据结构
const caption: Caption = {
  text: "你好世界",
  startMs: 0,
  endMs: 2000,
  timestampMs: null,
  confidence: null,
};
```

## FFmpeg 操作

Remotion 内置 FFmpeg，无需单独安装：

```bash
# 用 Remotion 内置的 ffmpeg（无需全局安装）
npx remotion ffmpeg -i input.mp4 output.mp3
npx remotion ffprobe input.mp4

# 裁剪视频（必须重编码以避免开头冻帧）
npx remotion ffmpeg -ss 00:00:05 -i public/input.mp4 -to 00:00:10 -c:v libx264 -c:a aac public/output.mp4
```

也可以在组件中用 `trimBefore`/`trimAfter` 非破坏性裁剪（见上方 Audio/Video 章节）。
