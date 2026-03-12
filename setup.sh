#!/bin/bash
# ============================================
# 视频工坊 — 一键安装
# 用法：bash setup.sh
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

ok() { echo -e "  ${GREEN}✅ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "  ${RED}❌ $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }

echo ""
echo -e "${BOLD}🎬 视频工坊 — 安装开始${NC}"
echo "=========================================="
echo ""

FAILED=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$HOME/.video-workshop"

# ---- 操作系统检测 ----
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  OS="windows"
fi

# ---- Step 1: 检查 Node.js ----
echo -e "${BOLD}🔍 检查基础环境...${NC}"

if ! command -v node &>/dev/null; then
  fail "需要 Node.js 18+，请先安装"
  if [ "$OS" = "macos" ]; then
    echo "    安装方法：brew install node"
  elif [ "$OS" = "linux" ]; then
    echo "    安装方法：sudo apt install nodejs npm"
  fi
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  fail "Node.js 版本太低（需要 18+，当前 v$(node -v)）"
  echo "    升级方法：brew upgrade node"
  exit 1
fi
ok "Node.js $(node -v)"

if ! command -v npm &>/dev/null; then
  fail "需要 npm，请安装 Node.js（自带 npm）"
  exit 1
fi
ok "npm $(npm -v)"

echo ""

# ---- Step 2: 创建工作空间 ----
echo -e "${BOLD}📁 准备工作空间...${NC}"

mkdir -p "$WORKSPACE/projects"

# 复制项目骨架（如果还没有 package.json）
if [ ! -f "$WORKSPACE/package.json" ]; then
  cp "$SCRIPT_DIR/templates/package.json" "$WORKSPACE/package.json"
  cp "$SCRIPT_DIR/templates/tsconfig.json" "$WORKSPACE/tsconfig.json"
  cp "$SCRIPT_DIR/templates/remotion.config.ts" "$WORKSPACE/remotion.config.ts"
  ok "工作空间已创建"
else
  ok "工作空间已存在"
fi

echo ""

# ---- Step 3: 安装依赖 ----
echo -e "${BOLD}📦 安装视频引擎（首次安装约 1-2 分钟）...${NC}"

cd "$WORKSPACE"

if [ -d "$WORKSPACE/node_modules/remotion" ]; then
  ok "视频引擎已安装"
else
  npm install --silent 2>&1 | tail -1
  if [ -d "$WORKSPACE/node_modules/remotion" ]; then
    ok "视频引擎安装完成"
  else
    fail "视频引擎安装失败"
    FAILED+=("视频引擎")
  fi
fi

echo ""

# ---- Step 4: 检查中文字体 ----
echo -e "${BOLD}🔤 检查中文字体...${NC}"

CJK_FONT_FOUND=false
if [ "$OS" = "macos" ]; then
  # macOS 自带 PingFang SC
  if system_profiler SPFontsDataType 2>/dev/null | grep -q "PingFang SC" || [ -f "/System/Library/Fonts/PingFang.ttc" ]; then
    CJK_FONT_FOUND=true
    ok "PingFang SC（macOS 内置）"
  fi
elif [ "$OS" = "windows" ]; then
  # Windows 自带 Microsoft YaHei
  if [ -f "/c/Windows/Fonts/msyh.ttc" ] || [ -f "$WINDIR/Fonts/msyh.ttc" ] 2>/dev/null; then
    CJK_FONT_FOUND=true
    ok "Microsoft YaHei（Windows 内置）"
  fi
else
  # Linux：检查常见中文字体
  if fc-list 2>/dev/null | grep -qi "noto sans cjk\|wenquanyi\|wqy\|droid sans fallback"; then
    CJK_FONT_FOUND=true
    ok "中文字体已安装"
  fi
fi

if [ "$CJK_FONT_FOUND" = "false" ]; then
  warn "未检测到中文字体，中文文字可能显示为方块"
  if [ "$OS" = "linux" ]; then
    info "建议安装：sudo apt install fonts-noto-cjk（Debian/Ubuntu）"
    info "         sudo yum install google-noto-sans-cjk-fonts（CentOS/RHEL）"
  else
    info "建议安装 Noto Sans CJK 字体"
  fi
  FAILED+=("中文字体（可选）")
fi

echo ""

# ---- Step 5: 确保浏览器渲染器可用 ----
echo -e "${BOLD}🌐 检查渲染环境...${NC}"

npx remotion browser ensure 2>/dev/null
if [ $? -eq 0 ]; then
  ok "渲染环境就绪"
else
  warn "渲染环境下载失败，首次渲染时会自动重试"
fi

echo ""

# ---- 安装摘要 ----
echo "=========================================="
if [ ${#FAILED[@]} -eq 0 ]; then
  echo -e "${GREEN}${BOLD}🎉 安装成功！${NC}"
  echo ""
  echo "  现在你可以在 AI 编辑器中说："
  echo "  「帮我做一个视频，内容是……」"
  echo ""
  echo -e "  ${BLUE}视频项目保存在：$WORKSPACE/projects/${NC}"
  echo ""
  info "提示：本工具使用的视频引擎对 4 人以上公司有商业许可要求，"
  info "个人使用和小团队（3人以下）免费。"
else
  echo ""
  warn "以下组件安装失败："
  for f in "${FAILED[@]}"; do
    fail "  $f"
  done
  echo ""
  echo "  建议：检查网络连接后重新运行 bash setup.sh"
fi
echo ""
