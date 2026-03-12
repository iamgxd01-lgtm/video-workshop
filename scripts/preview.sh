#!/bin/bash
# ============================================
# 视频预览脚本（启动本地预览服务器）
# 用法：bash preview.sh <项目目录>
# ============================================

set -e

PROJECT_DIR="$1"
WORKSPACE="$HOME/.video-workshop"

if [ -z "$PROJECT_DIR" ]; then
  echo "ERROR: 需要指定项目目录" >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/src/index.ts" ]; then
  echo "ERROR: 项目目录中没有找到 src/index.ts" >&2
  exit 1
fi

# 使用工作空间的 node_modules
cd "$WORKSPACE"

# 将绝对路径转为相对路径
REL_ENTRY=$(python3 -c "import os; print(os.path.relpath('$PROJECT_DIR/src/index.ts', '$WORKSPACE'))")

echo ""
echo "正在启动预览服务器..."
echo "启动后可在浏览器中实时查看视频效果"
echo ""

# 启动 remotion studio（预览服务器）
npx remotion studio "$REL_ENTRY"
