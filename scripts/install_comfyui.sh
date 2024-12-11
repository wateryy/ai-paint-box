#!/bin/bash
set -e

source /workspace/venv/bin/activate

# 安装 ComfyUI
cd /workspace

# 如果目录已存在，先删除
if [ -d "ComfyUI" ]; then
    echo "ComfyUI 目录已存在，正在删除..."
    rm -rf ComfyUI
fi

git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir -r requirements.txt

# 处理需要共享的模型目录
echo "配置共享模型目录..."

# 定义需要共享的目录映射关系
declare -A SHARED_DIRS=(
    ["clip"]="clip"
    ["checkpoints"]="Stable-diffusion"
    ["clip_vision"]="clip_vision"
    ["configs"]="configs"
    ["controlnet"]="controlnet"
    ["loras"]="lora-xl"
    ["vae"]="vae-models"
    ["gligen"]="gligen"
    ["hypernetworks"]="hypernetworks"
    ["upscale_models"]="upscale-models"
)

# 处理每个需要共享的目录
for COMFY_DIR in "${!SHARED_DIRS[@]}"; do
    SD_DIR="${SHARED_DIRS[$COMFY_DIR]}"
    MODELS_DIR="models/$COMFY_DIR"
    
    # 如果目录存在且不��软链接，复制内容到共享目录
    if [ -d "$MODELS_DIR" ] && [ ! -L "$MODELS_DIR" ]; then
        echo "发现模型目录 $COMFY_DIR，正在复制到共享目录..."
        cp -r "$MODELS_DIR"/* "/workspace/data/models/$SD_DIR/" 2>/dev/null || true
        rm -rf "$MODELS_DIR"
    fi
    
    # 创建父目录（如果需要）
    mkdir -p "$(dirname "$MODELS_DIR")"
    
    # 创建软链接到共享目录
    ln -sf "/workspace/data/models/$SD_DIR" "/workspace/ComfyUI/$MODELS_DIR"
done

# 处理 embeddings 目录（在 models 目录外）
if [ -d "models/embeddings" ] && [ ! -L "models/embeddings" ]; then
    echo "发现 embeddings 目录，正在复制到共享目录..."
    cp -r models/embeddings/* /workspace/data/embeddings/ 2>/dev/null || true
    rm -rf models/embeddings
fi
ln -sf "/workspace/data/embeddings" "/workspace/ComfyUI/models/embeddings"

# 处理输出目录
echo "配置输出目录..."
if [ -d "output" ] && [ ! -L "output" ]; then
    echo "发现输出目录，正在复制到专用目录..."
    cp -r output/* /workspace/data/comfyui/output/ 2>/dev/null || true
    rm -rf output
fi
ln -sf /workspace/data/comfyui/output /workspace/ComfyUI/output