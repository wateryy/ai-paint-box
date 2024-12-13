#!/bin/bash
set -e

source /workspace/venv/bin/activate

# 安装 Stable Diffusion WebUI Forge
cd /workspace

# 如果目录已存在，先删除
if [ -d "stable-diffusion-webui" ]; then
    echo "stable-diffusion-webui 目录已存在，正在删除..."
    rm -rf stable-diffusion-webui
fi

# 克隆 Forge 仓库
git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git stable-diffusion-webui
cd stable-diffusion-webui

# 安装依赖
pip install --no-cache-dir -r requirements_versions.txt
pip install --no-cache-dir xformers

# 定义需要共享的目录映射关系
declare -A SHARED_DIRS=(
    ["models/clip"]="/workspace/data/models/clip"
    ["models/Stable-diffusion"]="/workspace/data/models/Stable-diffusion"
    ["models/clip_vision"]="/workspace/data/models/clip_vision"
    ["models/configs"]="/workspace/data/models/configs"
    ["models/controlnet"]="/workspace/data/models/controlnet"
    ["models/photomaker"]="/workspace/data/models/photomaker"
    ["models/Lora"]="/workspace/data/models/lora-xl"
    ["models/VAE"]="/workspace/data/models/vae-models"
    ["models/animediff-models"]="/workspace/data/models/animediff-models"
    ["models/animediff-models-lora"]="/workspace/data/models/animediff-models-lora"
    ["embeddings"]="/workspace/data/embeddings"
)

# 创建并链接目录
echo "配置模型目录..."
for SD_DIR in "${!SHARED_DIRS[@]}"; do
    SHARED_DIR="${SHARED_DIRS[$SD_DIR]}"
    
    # 如果目录存在且不是软链接，复制内容到共享目录
    if [ -d "$SD_DIR" ] && [ ! -L "$SD_DIR" ]; then
        echo "发现目录 $SD_DIR，正在复制到共享目录..."
        cp -r "$SD_DIR"/* "$SHARED_DIR/" 2>/dev/null || true
        rm -rf "$SD_DIR"
    fi
    
    # 创建父目录（如果需要）
    mkdir -p "$(dirname "$SD_DIR")"
    
    # 创建软链接到共享目录
    ln -sf "$SHARED_DIR" "$SD_DIR"
done

# 处理输出目录
echo "配置输出目录..."
if [ -d "outputs" ] && [ ! -L "outputs" ]; then
    echo "发现输出目录，正在复制到专用目录..."
    cp -r outputs/* /workspace/data/sd/output/ 2>/dev/null || true
    rm -rf outputs
fi
ln -sf /workspace/data/sd/output /workspace/stable-diffusion-webui/outputs