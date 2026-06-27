#!/bin/bash
# Maps English git commit messages to Chinese equivalents
msg=$(cat)
case "$msg" in
  "refactor: rewrite NotesPage tablet UI, simplify card layout")
    echo "重构：重写笔记主页平板UI，简化卡片布局"
    ;;
  "fix: GlassDialog height stretches full screen on tablet — add maxHeight constraint")
    echo "修复：GlassDialog在平板上高度撑满全屏 — 添加maxHeight约束"
    ;;
  "fix: GlassDialog compact sizing — reduce height/width, center buttons, tighten spacing")
    echo "修复：GlassDialog紧凑尺寸 — 减小高度宽度，按钮居中，收紧间距"
    ;;
  "fix: GlassDialog use customStyle to remove system container white edges, add self-contained borderRadius+clip")
    echo "修复：GlassDialog使用customStyle去除系统容器白边，添加自备圆角和裁剪"
    ;;
  "fix: GlassDialog remove Stack+height100% — use single Column with combined linearGradient background")
    echo "修复：GlassDialog移除Stack和height100% — 使用单Column合并渐变背景"
    ;;
  "refactor: remove all liquid glass effects — backdropBlur, createGlassColor, specular highlight overlays, glass sliders")
    echo "重构：删除所有液态玻璃效果 — backdropBlur、createGlassColor、高光叠加层、玻璃滑块"
    ;;
  *)
    echo "$msg"
    ;;
esac
