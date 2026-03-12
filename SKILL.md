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

根据用户需求编写动画。以下是可用的动画工具：

#### 核心 API 速查

```typescript
// 从 "remotion" 导入
import {
  useCurrentFrame,       // 当前帧号（0, 1, 2, ...）
  useVideoConfig,        // { width, height, fps, durationInFrames }
  interpolate,           // 值映射：interpolate(frame, [0, 30], [0, 1])
  spring,                // 弹性动画：spring({ frame, fps, config: { damping: 200 } })
  Sequence,              // 时间偏移容器：<Sequence from={30}>...</Sequence>
  AbsoluteFill,          // 全屏定位容器
  Img,                   // 图片组件（替代 <img>）
  Audio,                 // 音频组件
  Video,                 // 视频组件
  staticFile,            // 引用 public/ 下的静态文件
} from "remotion";
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
      <Sequence key={i} from={i * 30}>
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

#### 布局技巧

- 用 `AbsoluteFill` 做全屏背景
- 用 `flexbox` 居中内容
- 文字用 `fontFamily: "sans-serif"` 或 `"PingFang SC", "Microsoft YaHei", sans-serif`（中文）
- 颜色用 CSS 标准写法
- 所有样式用 React 的 `style={{}}` 内联写法

#### 编写原则

1. **组件自包含**：所有动画逻辑写在一个 Main.tsx 里（简单视频），或拆成子组件用 Sequence 编排
2. **帧驱动**：所有动画基于 `useCurrentFrame()` 计算，不用 CSS animation
3. **中文友好**：文字内容直接写中文，字体用系统自带中文字体
4. **性能优先**：避免在渲染函数中做复杂计算，能缓存的用 `useMemo`

### Step 4: 渲染视频

```bash
bash <skill-directory>/scripts/render.sh "$PROJECT_DIR" Main "$PROJECT_DIR/output.mp4"
```

渲染完成后，脚本会输出 `RENDER_SUCCESS: <文件路径>`。

### Step 5: 交付结果

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
