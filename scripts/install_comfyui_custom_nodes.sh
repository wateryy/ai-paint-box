#!/bin/bash

CUSTOM_NODES_PATH="/workspace/ComfyUI/custom_nodes"
mkdir -p "$CUSTOM_NODES_PATH"
cd "$CUSTOM_NODES_PATH"

# 安装扩展和依赖的函数
install_extension() {
    local repo_url=$1
    local dir_name=$(basename $repo_url .git)
    echo "正在安装 $dir_name..."
    
    if [ -d "$dir_name" ]; then
        echo "$dir_name 已存在，正在更新..."
        cd "$dir_name"
        git pull
    else
        git clone "$repo_url"
        cd "$dir_name"
    fi

    # 检查并安装依赖
    if [ -f "requirements.txt" ]; then
        echo "安装 $dir_name 的依赖..."
        pip install -r requirements.txt
    fi
    
    # 检查并运行安装脚本
    if [ -f "install.py" ]; then
        echo "运行 $dir_name 的安装脚本..."
        python install.py
    fi
    
    cd ..
}

echo "=== 开始安装自定义节点 ==="

# 基础功能扩展
install_extension "https://github.com/ltdrdata/ComfyUI-Manager"
install_extension "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
install_extension "https://github.com/WASasquatch/was-node-suite-comfyui"
install_extension "https://github.com/rgthree/rgthree-comfy"
install_extension "https://github.com/cubiq/ComfyUI_essentials"

# 图像处理和增强
install_extension "https://github.com/kijai/ComfyUI-SUPIR.git"
install_extension "https://github.com/ssitu/ComfyUI_UltimateSDUpscale"
install_extension "https://github.com/ZHO-ZHO-ZHO/ComfyUI-APISR"
install_extension "https://github.com/GreenLandisaLie/AuraSR-ComfyUI"

# ControlNet 相关
install_extension "https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet"
install_extension "https://github.com/Fannovel16/comfyui_controlnet_aux.git"

# 动画和视频
install_extension "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved"
install_extension "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# 人像和面部处理
install_extension "https://github.com/ZHO-ZHO-ZHO/ComfyUI-InstantID"
install_extension "https://github.com/cubiq/ComfyUI_InstantID"
install_extension "https://github.com/cubiq/ComfyUI_FaceAnalysis.git"
install_extension "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait"
install_extension "https://github.com/kijai/ComfyUI-LivePortraitKJ"
install_extension "https://github.com/florestefano1975/comfyui-portrait-master.git"

# IPAdapter 相关
install_extension "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
install_extension "https://github.com/Shakker-Labs/ComfyUI-IPAdapter-Flux"

# 提示词和标签
install_extension "https://github.com/pythongosssss/ComfyUI-WD14-Tagger"
install_extension "https://github.com/adieyal/comfyui-dynamicprompts.git"
install_extension "https://github.com/meap158/ComfyUI-Prompt-Expansion.git"
install_extension "https://github.com/AIrjen/OneButtonPrompt.git"

# 工作流和界面增强
install_extension "https://github.com/11cafe/comfyui-workspace-manager"
install_extension "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
install_extension "https://github.com/crystian/ComfyUI-Crystools"

# 风格和效果
install_extension "https://github.com/yichengup/Comfyui_Flux_Style_Adjust.git"
install_extension "https://github.com/KoreTeknology/ComfyUI-Universal-Styler.git"
install_extension "https://github.com/chflame163/ComfyUI_LayerStyle.git"

# AI 和模型集成
install_extension "https://github.com/city96/ComfyUI-GGUF"
install_extension "https://github.com/leoleelxh/ComfyUI-LLMs.git"
install_extension "https://github.com/storyicon/comfyui_segment_anything.git"

# 其他实用工具
install_extension "https://github.com/jags111/efficiency-nodes-comfyui"
install_extension "https://github.com/erosDiffusion/ComfyUI-enricos-nodes"
install_extension "https://github.com/kijai/ComfyUI-KJNodes"
install_extension "https://github.com/SeargeDP/SeargeSDXL.git"

echo "=== 所有自定义节点安装完成 ==="
echo "提示：某些节点可能需要下载额外的模型才能使用"