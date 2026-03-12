#!/bin/bash
# ============================================
# 视频渲染脚本（AI 调用，用户不直接使用）
# 用法：bash render.sh <项目目录> [composition-id] [输出文件路径]
# ============================================

set -e

PROJECT_DIR="$1"
COMP_ID="${2:-Main}"
OUTPUT="${3:-$PROJECT_DIR/output.mp4}"
WORKSPACE="$HOME/.video-workshop"

if [ -z "$PROJECT_DIR" ]; then
  echo "ERROR: 需要指定项目目录" >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/src/index.ts" ]; then
  echo "ERROR: 项目目录中没有找到 src/index.ts" >&2
  exit 1
fi

# 确保输出目录存在
mkdir -p "$(dirname "$OUTPUT")"

# 使用工作空间的 node_modules
cd "$WORKSPACE"

# 将绝对路径转为相对于工作空间的路径（remotion 需要相对路径）
REL_ENTRY=$(python3 -c "import os; print(os.path.relpath('$PROJECT_DIR/src/index.ts', '$WORKSPACE'))")
REL_OUTPUT=$(python3 -c "import os; print(os.path.relpath('$OUTPUT', '$WORKSPACE'))")

# 渲染视频
npx remotion render \
  "$REL_ENTRY" \
  "$COMP_ID" \
  "$REL_OUTPUT" \
  --codec h264 \
  --overwrite

echo ""
echo "RENDER_SUCCESS: $OUTPUT"
