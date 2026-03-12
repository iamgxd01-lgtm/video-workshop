---
name: video-workshop
description: |
  视频工坊——用自然语言创作动画视频。
  用户描述想要的视频内容和效果，AI 自动生成并渲染为 MP4 文件。
  支持文字动画、图文轮播、数据可视化、Logo 动画、片头片尾等各种视频类型。
  触发场景：用户想做视频、制作动画、生成短视频时触发，
  包括但不限于："帮我做一个视频"、"生成一个动画"、"做一个片头"、
  "把这段文字变成视频"、"做一个数据动画"、"视频工坊"、
  "帮我做个短视频"、"制作一个动态海报"、"做一个文字动画"、
  "帮我做个视频号/抖音/小红书的视频"。
  即使用户没说"视频"，只要意图是把内容变成动态画面，就应该触发此 Skill。
compatibility: |
  Requires: Node.js 18+.
  Workspace: ~/.video-workshop/ (created by setup.sh).
license_deps: |
  remotion: Remotion License (installed locally via npm, not bundled)
  react: MIT
user-invocable: true
---

# 视频工坊

帮用户用自然语言创作动画视频。用户描述想要什么，你来生成代码并渲染为视频文件。

## 触发条件

用户想做视频、动画、动态内容时激活。包括：
- "帮我做一个视频/动画/片头/片尾"
- "把这段文字/数据变成视频"
- "做一个 XX 秒的短视频"
- "做一个动态海报/封面"
- 任何描述了想要"动态画面"的意图

## 前置检查

每次执行前检查：

```bash
ls ~/.video-workshop/node_modules/remotion 2>/dev/null && echo "READY" || echo "NOT_READY"
```

- **READY** → 直接开始创作
- **NOT_READY** → 告诉用户：「视频工坊还没有安装，请先运行安装命令。我来帮你执行。」然后运行：`bash <skill-directory>/setup.sh`

## 执行步骤

### Step 1: 理解用户需求

从用户的描述中提取：
- **内容**：要展示什么文字、数据、图片
- **时长**：多少秒（默认 10 秒，即 300 帧 @ 30fps）
- **尺寸**：竖屏 1080×1920（抖音/小红书）、横屏 1920×1080（B站/YouTube）、方形 1080×1080（默认）
- **风格**：颜色、字体大小、动画效果

如果用户没说清，用默认值直接开始，不要追问太多细节。做出来再迭代。

### Step 2: 创建项目

```bash
PROJECT_NAME="<用中文拼音或英文短名>"
PROJECT_DIR="$HOME/.video-workshop/projects/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR/src"
cp "$HOME/.video-workshop/remotion.config.ts" "$PROJECT_DIR/" 2>/dev/null
```

### Step 3: 编写视频组件

在 `$PROJECT_DIR/src/` 下创建三个文件：

**src/index.ts**（入口，每个项目都一样）：
```typescript
import { registerRoot } from "remotion";
import { RemotionRoot } from "./Root";
registerRoot(RemotionRoot);
```

**src/Root.tsx**（注册组件）：
```typescript
import React from "react";
import { Composition } from "remotion";
import { Main } from "./Main";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="Main"
      component={Main}
      durationInFrames={帧数}
      fps={30}
      width={宽度}
      height={高度}
    />
  );
};
```

**src/Main.tsx**（核心动画组件——这是你发挥创意的地方）：

根据用户需求编写动画。以下是全部可用的动画工具和能力：

#### 核心 API 速查

```typescript
// 从 "remotion" 导入——基础能力
import {
  useCurrentFrame,       // 当前帧号（0, 1, 2, ...）
  useVideoConfig,        // { width, height, fps, durationInFrames }
  interpolate,           // 值映射：interpolate(frame, [0, 30], [0, 1])
  spring,                // 弹性动画：spring({ frame, fps, config: { damping: 200 } })
  Sequence,              // 时间偏移容器：<Sequence from={30} premountFor={30}>...</Sequence>
  Series,                // 顺序播放容器：<Series><Series.Sequence>...</Series.Sequence></Series>
  Loop,                  // 循环播放：<Loop durationInFrames={60}>...</Loop>
  AbsoluteFill,          // 全屏定位容器
  Img,                   // 图片组件（替代 <img>）
  staticFile,            // 引用 public/ 下的静态文件
  Easing,                // 缓动函数：Easing.bezier(), Easing.out(), Easing.inOut()
  random,                // 确定性随机数：random("seed") 每次渲染结果一致
  delayRender,           // 等待异步操作：const handle = delayRender()
  continueRender,        // 完成异步操作：continueRender(handle)
} from "remotion";

// 从 "@remotion/media" 导入——音视频能力
import { Audio, Video, OffthreadVideo } from "@remotion/media";
// Audio: 音频组件（支持 volume、trimBefore/trimAfter、playbackRate、loop、toneFrequency）
// Video: 视频组件（支持同样的属性）
// OffthreadVideo: 高性能视频组件（在独立线程解码，推荐用于嵌入视频）
```

#### 常用动画模式

**淡入**：
```typescript
const frame = useCurrentFrame();
const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: "clamp" });
return <div style={{ opacity }}>内容</div>;
```

**从下方飘入**：
```typescript
const frame = useCurrentFrame();
const { fps } = useVideoConfig();
const translateY = spring({ frame, fps, config: { damping: 200 } });
return <div style={{ transform: `translateY(${(1 - translateY) * 100}px)` }}>内容</div>;
```

**逐个出现（列表项）**：
```typescript
const items = ["第一点", "第二点", "第三点"];
return (
  <div>
    {items.map((item, i) => (
      <Sequence key={i} from={i * 30} premountFor={30}>
        <FadeIn>{item}</FadeIn>
      </Sequence>
    ))}
  </div>
);
```

**缩放弹入**：
```typescript
const scale = spring({ frame, fps, config: { damping: 100, stiffness: 200 } });
return <div style={{ transform: `scale(${scale})` }}>内容</div>;
```

**打字机效果**：
```typescript
const text = "这是一段文字";
const charsShown = Math.floor(interpolate(frame, [0, 60], [0, text.length], { extrapolateRight: "clamp" }));
return <span>{text.slice(0, charsShown)}</span>;
```

**颜色渐变背景**：
```typescript
const hue = interpolate(frame, [0, durationInFrames], [200, 260]);
return <AbsoluteFill style={{ background: `linear-gradient(135deg, hsl(${hue}, 80%, 20%), hsl(${hue + 40}, 80%, 40%))` }} />;
```

**顺序播放多个场景（Series）**：
```typescript
import { Series } from "remotion";
<Series>
  <Series.Sequence durationInFrames={90}><Intro /></Series.Sequence>
  <Series.Sequence durationInFrames={120}><MainContent /></Series.Sequence>
  <Series.Sequence durationInFrames={60}><Outro /></Series.Sequence>
</Series>
```

#### 全部能力目录

以下是所有已安装的扩展能力。用户描述需求时，根据关键词选用对应能力：

##### 1. 转场效果（@remotion/transitions）
**用户说**："加个转场"、"场景切换要有过渡"、"淡入淡出切换"
```typescript
import { TransitionSeries, linearTiming, springTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { wipe } from "@remotion/transitions/wipe";
import { flip } from "@remotion/transitions/flip";
import { clockWipe } from "@remotion/transitions/clock-wipe";

<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={60}><SceneA /></TransitionSeries.Sequence>
  <TransitionSeries.Transition
    presentation={fade()}
    timing={linearTiming({ durationInFrames: 15 })}
  />
  <TransitionSeries.Sequence durationInFrames={60}><SceneB /></TransitionSeries.Sequence>
</TransitionSeries>
// slide() 支持 direction: "from-left" | "from-right" | "from-top" | "from-bottom"
// 注意：转场会缩短总时长，两个 60 帧场景 + 15 帧转场 = 105 帧（不是 120）
```

##### 2. 字体使用（重要）

**中文字体——必须用系统字体回退链**，禁止用 @remotion/google-fonts 加载中文字体（Google CDN 在中国网络不可靠，会导致渲染超时）：
```typescript
// ✅ 正确：跨平台系统字体回退链（macOS / Windows / Linux 全覆盖）
const fontFamily = '"PingFang SC", "Microsoft YaHei", "Hiragino Sans GB", "Noto Sans CJK SC", "WenQuanYi Micro Hei", sans-serif';

// ❌ 错误：不要用 @remotion/google-fonts 加载中文字体
// import { loadFont } from "@remotion/google-fonts/NotoSansSC";
// 原因：中文字体有 100+ 个子集，每次渲染需要从 Google CDN 下载，中国网络经常失败
```

**英文字体**——可以用 @remotion/google-fonts（英文字体子集少，下载快）：
```typescript
import { loadFont } from "@remotion/google-fonts/Lobster";
const { fontFamily } = loadFont();
// 建议指定字重和子集以减少请求：
const { fontFamily } = loadFont("normal", { weights: ["400", "700"], subsets: ["latin"] });
```

**自定义字体**——用 @remotion/fonts 加载本地文件：
```typescript
import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";
await loadFont({ family: "MyFont", url: staticFile("MyFont.woff2") });
```

##### 4. 形状生成（@remotion/shapes）
**用户说**："画个圆/三角/星星"、"加个图形"
```typescript
import { Circle, Rect, Triangle, Star, Ellipse, Pie } from "@remotion/shapes";
<Circle radius={100} fill="blue" />
<Triangle length={200} direction="up" fill="red" />
<Star innerRadius={50} outerRadius={100} points={5} fill="gold" />
<Pie radius={100} progress={0.75} fill="green" closePath />
```

##### 5. SVG 路径动画（@remotion/paths）
**用户说**："画一条线慢慢出现"、"路径动画"、"折线图动画"
```typescript
import { evolvePath, getLength, getPointAtLength, getTangentAtLength } from "@remotion/paths";
const progress = interpolate(frame, [0, 60], [0, 1], { extrapolateRight: "clamp" });
const { strokeDasharray, strokeDashoffset } = evolvePath(progress, svgPathString);
// 可用于：折线图动画、手写签名效果、路径跟踪动画
```

##### 6. 噪声/粒子效果（@remotion/noise）
**用户说**："加点动态纹理"、"粒子效果"、"有机感的背景"
```typescript
import { noise2D, noise3D, noise4D } from "@remotion/noise";
// 生成平滑随机值，用于粒子运动、波浪效果、有机动画
const value = noise2D("seed", x * 0.01, frame * 0.02); // 返回 -1 到 1
```

##### 7. 运动模糊（@remotion/motion-blur）
**用户说**："加运动模糊"、"快速运动的模糊效果"
```typescript
import { CameraMotionBlur } from "@remotion/motion-blur";
<CameraMotionBlur samples={10} shutterAngle={180}>
  <YourAnimatedContent />
</CameraMotionBlur>
```

##### 8. 文字测量（@remotion/layout-utils）
**用户说**："文字自动适配大小"、"不要超出边框"
```typescript
import { measureText, fillTextBox, fitText } from "@remotion/layout-utils";
const { width } = measureText({ text: "Hello", fontFamily: "Arial", fontSize: 48 });
const fitted = fitText({ text: "长文本", withinWidth: 800, fontFamily: "Arial" });
// fitted.fontSize 是自动计算的最佳字号
```

##### 9. GIF 动画（@remotion/gif）
**用户说**："放个GIF"、"嵌入动图"
```typescript
import { Gif } from "@remotion/gif";
<Gif src={staticFile("animation.gif")} width={300} height={300} fit="cover" />
// GIF 自动与视频时间轴同步
```

##### 10. 音视频工具（@remotion/media-utils）
**用户说**："获取音频时长"、"根据音乐节奏做动画"
```typescript
import { getAudioDurationInSeconds, getVideoMetadata, getAudioData, useAudioData, visualizeAudio } from "@remotion/media-utils";
// 获取音频时长（用于动态计算视频长度）
const duration = await getAudioDurationInSeconds(staticFile("audio.mp3"));
// 音频可视化（频谱柱状图）
const audioData = useAudioData(staticFile("audio.mp3"));
const visualization = visualizeAudio({ fps, frame, audioData, numberOfSamples: 256 });
```

##### 11. 数据图表（纯代码实现，无需额外包）
**用户说**："做个数据动画"、"柱状图/饼图/折线图"
- 柱状图：用 div + spring 动画控制高度
- 饼图：用 SVG circle + stroke-dashoffset 动画
- 折线图：用 @remotion/paths 的 evolvePath 动画
- 所有图表必须用 useCurrentFrame() 驱动，禁用第三方图表库的内置动画

##### 12. 3D 场景（@remotion/three）— 可选
**用户说**："做个3D效果"、"立体动画"
```typescript
import { ThreeCanvas } from "@remotion/three";
import { useCurrentFrame } from "remotion";
// 需要 three、@react-three/fiber、@react-three/drei
<ThreeCanvas><mesh rotation={[0, frame * 0.02, 0]}>...</mesh></ThreeCanvas>
```

##### 13. Lottie 动画（@remotion/lottie）— 可选
**用户说**："嵌入一个Lottie动画"、"用AE导出的动画"
```typescript
import { Lottie } from "@remotion/lottie";
import animationData from "./animation.json";
<Lottie animationData={animationData} />
// 自动与视频时间轴同步
```

##### 14. 地图动画（需 mapbox-gl）— 可选
**用户说**："做个地图动画"、"展示地理位置"
需要用户提供 Mapbox API Key，使用 mapbox-gl + @turf/turf 实现

##### 15. 参数化视频（zod schema）
**用户说**："做个模板可以换内容"、"批量生成不同内容的视频"
```typescript
import { z } from "zod";
const schema = z.object({ title: z.string(), color: z.string() });
// 在 Composition 中使用 schema 属性，渲染时通过 --props 传入不同数据
```

##### 16. 透明视频渲染
**用户说**："导出透明背景的视频"
渲染时使用 `--codec vp8 --image-format png` 输出 WebM 格式透明视频

#### 音视频操作速查

```typescript
// 音频：导入、裁剪、音量、变速、循环、变调
import { Audio } from "@remotion/media";
<Audio src={staticFile("bgm.mp3")} volume={0.5} trimBefore={2 * fps} trimAfter={10 * fps} loop playbackRate={1.5} toneFrequency={1.2} />

// 视频：导入、裁剪、音量、变速、循环
import { Video, OffthreadVideo } from "@remotion/media";
<OffthreadVideo src={staticFile("clip.mp4")} volume={0.8} muted={false} style={{ width: 500 }} />
// OffthreadVideo 比 Video 性能更好，推荐使用
```

#### 创作质量标准（必须遵守）

每个视频必须达到**商业级信息可视化视频**的水准。以下不是"可选优化"，而是底线要求：

##### 一、叙事结构（有头有尾）

每个视频必须包含三段式结构：
1. **片头**（1-2 秒）：标题 + 副标题，带入场动画（scale+fade 组合）
2. **主体**（视频主要内容）：按逻辑分段，每段有主题词/小标题
3. **片尾**（1-2 秒）：总结语/金句/品牌标识，带退场动画

```typescript
// 三段式结构模板
<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={60}><Intro /></TransitionSeries.Sequence>
  <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />
  <TransitionSeries.Sequence durationInFrames={主体帧数}><MainContent /></TransitionSeries.Sequence>
  <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />
  <TransitionSeries.Sequence durationInFrames={60}><Outro /></TransitionSeries.Sequence>
</TransitionSeries>
```

##### 二、视觉设计（专业感）

**背景层次**——禁止使用纯色背景，必须有层次感：
```typescript
// 标准背景模板：渐变 + 网格/点阵 + 微光
const Background = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const hue = interpolate(frame, [0, durationInFrames], [220, 260]);
  return (
    <AbsoluteFill>
      {/* 层1: 渐变底色 */}
      <div style={{
        position: "absolute", inset: 0,
        background: `radial-gradient(ellipse at 30% 20%, hsl(${hue}, 40%, 15%) 0%, hsl(${hue + 20}, 30%, 6%) 100%)`
      }} />
      {/* 层2: 网格纹理 */}
      <div style={{
        position: "absolute", inset: 0, opacity: 0.06,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
        backgroundSize: "60px 60px"
      }} />
      {/* 层3: 扫光效果（可选） */}
      <div style={{
        position: "absolute", inset: 0, opacity: 0.03,
        background: `radial-gradient(circle at ${30 + frame * 0.3}% ${40 + Math.sin(frame * 0.02) * 10}%, rgba(255,255,255,0.8), transparent 50%)`
      }} />
    </AbsoluteFill>
  );
};
```

**节点发光效果**——重要元素必须有辉光（glow）：
```typescript
// 发光圆形节点
<div style={{
  width: 80, height: 80, borderRadius: "50%",
  background: `radial-gradient(circle, ${color}, ${darkerColor})`,
  boxShadow: `0 0 20px ${color}66, 0 0 40px ${color}33, 0 0 60px ${color}1a`,
  display: "flex", alignItems: "center", justifyContent: "center",
}} />

// 发光文字
<h1 style={{
  fontSize: 64, fontWeight: 900, color: "white",
  textShadow: "0 0 30px rgba(255,255,255,0.3), 0 2px 10px rgba(0,0,0,0.5)",
}} />
```

**配色体系**——使用有意义的分类配色，不随机选颜色：
```typescript
// 按语义分配颜色
const CATEGORY_COLORS = {
  primary: "#FFD700",    // 金色：核心/标题
  accent1: "#4ECDC4",    // 青色：第一类
  accent2: "#FF6B6B",    // 珊瑚：第二类
  accent3: "#A78BFA",    // 紫色：第三类
  accent4: "#34D399",    // 绿色：第四类
  subtle: "rgba(255,255,255,0.6)",  // 次要文字
  muted: "rgba(255,255,255,0.3)",   // 辅助线条
};
```

##### 三、镜头语言（动感）

**禁止全程固定画面**。必须使用至少一种镜头运动：

```typescript
// 镜头推拉（Zoom）：整个画布缓慢放大
const zoom = interpolate(frame, [0, durationInFrames], [1, 1.15], {
  easing: Easing.inOut(Easing.quad),
});
<div style={{ transform: `scale(${zoom})`, transformOrigin: "center" }}>
  {/* 所有内容 */}
</div>

// 镜头位移（Pan）：跟随焦点移动
const panX = interpolate(frame, [0, 90, 180, durationInFrames], [0, -100, -200, -300], {
  extrapolateRight: "clamp",
  easing: Easing.inOut(Easing.quad),
});
<div style={{ transform: `translateX(${panX}px)` }}>
  {/* 宽幅画布内容 */}
</div>

// 焦点跟随：新内容出现时画面微调
const focusX = spring({ frame: frame - 60, fps, config: { damping: 200 } });
const offsetX = interpolate(focusX, [0, 1], [0, -150]);
```

##### 四、动画品质（流畅感）

**弹性配置选择**（不要总用同一种 spring）：
```typescript
const smooth = { damping: 200 };                    // 丝滑入场（标题、背景元素）
const snappy = { damping: 20, stiffness: 200 };     // 干脆弹入（按钮、标签）
const bouncy = { damping: 8 };                       // 弹跳入场（活泼元素）
const heavy = { damping: 15, stiffness: 80, mass: 2 }; // 沉重落地（大块内容）
```

**入场+退场成对出现**：
```typescript
const inAnimation = spring({ frame, fps, config: { damping: 200 } });
const outAnimation = spring({ frame, fps, delay: durationInFrames - fps, durationInFrames: fps });
const progress = inAnimation - outAnimation; // 自动入场+退场
```

**交错出现（Stagger）**：多个元素不要同时出现，错开 5-10 帧：
```typescript
items.map((item, i) => {
  const delay = i * 8; // 每个元素错开 8 帧
  const progress = spring({ frame, fps, delay, config: { damping: 200 } });
  return <div style={{ opacity: progress, transform: `translateY(${(1-progress) * 30}px)` }}>{item}</div>;
})
```

##### 五、信息层次（可读性）

- **标题**：fontSize 56-72，fontWeight 900，白色 + textShadow
- **副标题/分类**：fontSize 24-32，fontWeight 600，主题色
- **正文/标签**：fontSize 16-20，fontWeight 400，rgba(255,255,255,0.7)
- **辅助信息**：fontSize 12-14，rgba(255,255,255,0.4)
- **关系线/连线**：strokeWidth 2-3，带透明度，使用贝塞尔曲线

#### 布局技巧

- 用 `AbsoluteFill` 做全屏背景
- 用 `flexbox` 居中内容
- 中文字体用系统回退链（见上方"字体使用"），英文字体可用 `@remotion/google-fonts`
- 颜色用 CSS 标准写法
- 所有样式用 React 的 `style={{}}` 内联写法，或用 Tailwind CSS（已安装 @remotion/tailwind）
- 始终给 `<Sequence>` 加 `premountFor` 预加载

#### 编写原则

1. **组件自包含**：所有动画逻辑写在一个 Main.tsx 里（简单视频），或拆成子组件用 Sequence/Series/TransitionSeries 编排
2. **帧驱动**：所有动画基于 `useCurrentFrame()` 计算，不用 CSS animation，不用第三方动画库
3. **中文友好**：文字内容直接写中文，中文字体用系统回退链（`"PingFang SC", "Microsoft YaHei", ...`），不要用 @remotion/google-fonts 加载中文字体
4. **性能优先**：避免在渲染函数中做复杂计算，能缓存的用 `useMemo`；嵌入视频用 `OffthreadVideo` 而非 `Video`
5. **预加载**：始终给 Sequence 加 `premountFor`；异步资源用 `delayRender`/`continueRender`
6. **确定性**：需要随机效果时用 `random("seed")` 而非 `Math.random()`，保证每帧渲染结果一致
7. **时间单位**：用 `秒 * fps` 表达时间，不要用裸帧数。如 `2 * fps`（2秒），不要写 `60`。让代码可读且适配不同帧率
8. **禁止 CSS 动画**：所有动画必须由 `useCurrentFrame()` 驱动。禁止 CSS transitions、CSS animations、Tailwind 动画类名（`animate-*`）——它们在逐帧渲染时不生效

#### 详细 API 参考

当以上速查信息不够用时（如需要转场时长计算、路径变形、音频可视化、3D 场景、Lottie 动画、Tailwind 配置等高级用法），加载详细参考文档：

```
读取 <skill-directory>/references/extensions.md
```

### Step 4: 预览视频

编写完代码后，启动预览服务器让用户在浏览器中实时查看效果：

```bash
bash <skill-directory>/scripts/preview.sh "$PROJECT_DIR"
```

预览服务器启动后，自动在浏览器中打开预览页面：

```bash
open "http://localhost:3000/Main"
```

告诉用户预览地址（如 `http://localhost:3000/Main`），可以拖动时间轴、逐帧查看动画效果。**等待用户确认效果满意后**，再进入下一步渲染。

> 只有用户明确说"不用预览"或"直接渲染"时才跳过此步骤。

### Step 5: 渲染视频

```bash
bash <skill-directory>/scripts/render.sh "$PROJECT_DIR" Main "$PROJECT_DIR/output.mp4"
```

渲染完成后，脚本会输出 `RENDER_SUCCESS: <文件路径>`。

### Step 6: 交付结果

告诉用户视频保存在哪里，并询问是否需要调整。

常见调整：
- "字再大一点" → 修改 fontSize
- "动画慢一点" → 调整 interpolate 的帧范围或 spring 的 damping
- "换个颜色" → 修改颜色值
- "加长到 20 秒" → 修改 durationInFrames
- "改成竖屏" → 修改 width/height

修改后重新执行 Step 4 渲染即可。

## 输出

- 视频文件：`~/.video-workshop/projects/<项目名>/output.mp4`
- 如果用户要求保存到桌面，渲染后 `cp` 过去

## 错误处理

| 场景 | 用户看到的提示 |
|------|--------------|
| Node.js 未安装 | "需要先安装基础环境，我来帮你。" |
| 工作空间未初始化 | "视频工坊还没安装，我来帮你运行安装。" |
| 渲染失败（代码错误） | "视频生成遇到问题，我来修复。" → 读取错误日志，修改代码后重新渲染 |
| 渲染失败（资源不足） | "视频太复杂了，我来简化一下再试。" |
| 用户要求的效果做不到 | 诚实说明限制，建议替代方案 |

## 规则

### 对话规则（严格遵守）

- 所有回复用**中文**
- **禁止**在对话中出现以下技术词汇：remotion、React、JSX、TSX、TypeScript、npm、node_modules、组件、渲染引擎、Composition、spring()、interpolate()、useCurrentFrame
- 用「视频」「动画」「效果」「画面」等用户能理解的词替代
- 不向用户展示代码——你在后台写代码，用户只看到"正在制作中..."和最终结果
- 出错时不甩技术日志，用中文说明问题和解决方案
- 渲染过程中可以说"正在生成视频，大约需要 X 秒..."

### 创作规则

- 默认尺寸：1080×1080（方形，适合大多数社交平台）
- 默认时长：10 秒（300 帧 @ 30fps）
- 默认风格：深色背景 + 白色文字 + 简洁动画
- 用户没指定时用默认值，做出来再迭代，不要追问过多细节
- 每次修改后自动重新渲染，不需要用户说"重新渲染"
