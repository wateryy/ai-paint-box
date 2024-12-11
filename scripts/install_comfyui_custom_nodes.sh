#!/bin/bash
set -e

cd /workspace/ComfyUI/custom_nodes/

echo "开始安装 ComfyUI 扩展..."

# 函数：安装扩展
install_extension() {
    local repo_url=$1
    local dir_name=$(basename $repo_url .git)
    echo "正在安装 $dir_name..."
    if [ -d "$dir_name" ]; then
        echo "目录已存在，正在更新..."
        cd "$dir_name"
        git pull
        cd ..
    else
        git clone "$repo_url"
    fi
}

echo "=== 安装核心扩展 ==="
# ComfyUI Manager - 扩展管理器
install_extension "https://github.com/ltdrdata/ComfyUI-Manager.git"

# Impact Pack - 核心功能增强
install_extension "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"

# ComfyUI-Inspire-Pack - 功能扩展包
install_extension "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git"

# AIGODLIKE-COMFYUI-TRANSLATION - 中文汉化
install_extension "https://github.com/AIGODLIKE/AIGODLIKE-COMFYUI-TRANSLATION.git"

echo "=== 安装工作流工具 ==="
# Workflow Manager - 工作流管理
install_extension "https://github.com/ltdrdata/ComfyUI-Workflow-Component.git"

# Custom Scripts - 高级工作流工具
install_extension "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"

# RGB Three - 工作流增强
install_extension "https://github.com/rgthree/rgthree-comfy.git"

echo "=== 安装图像处理工具 ==="
# ControlNet 辅助工具
install_extension "https://github.com/Fannovel16/comfyui_controlnet_aux.git"

# Ultimate Upscale - 终极放大工具
install_extension "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"

# Images Grid - 图像网格工具
install_extension "https://github.com/LEv145/images-grid-comfy-plugin.git"

# ReActor - 人脸替换工具
install_extension "https://github.com/Gourieff/comfyui-reactor-node.git"

# 图像后处理工具
install_extension "https://github.com/BlenderNeko/ComfyUI_Cutoff.git"

echo "=== 安装动画相关工具 ==="
# Video Helper Suite - 视频处理工具
install_extension "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# AnimateDiff - 动画生成工具
install_extension "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git"

echo "=== 安装提示词工具 ==="
# WD14 Tagger - 标签生成器
install_extension "https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git"

# Use Everywhere - 提示词工具
install_extension "https://github.com/chrisgoringe/cg-use-everywhere.git"

# 高级文本编码
install_extension "https://github.com/BlenderNeko/ComfyUI_ADV_CLIP_emb.git"

echo "=== 安装效率工具 ==="
# Efficiency Nodes - 批处理工具
install_extension "https://github.com/LucianoCirino/efficiency-nodes-comfyui.git"

# 工作区管理
install_extension "https://github.com/11cafe/comfyui-workspace-manager.git"

echo "所有扩展安装完成"

# 重启 ComfyUI 服务
echo "重启 ComfyUI 服务..."
supervisorctl restart comfyui

echo "ComfyUI 扩展安装完成并已重启服务"