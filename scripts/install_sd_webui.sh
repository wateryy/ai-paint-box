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

# 处理模型目录
echo "配置模型目录..."
MODELS_DIR="models/Stable-diffusion"
if [ -d "$MODELS_DIR" ] && [ ! -L "$MODELS_DIR" ]; then
    echo "发现已存在的模型目录，正在备份..."
    mv "$MODELS_DIR" "${MODELS_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

# 创建软链接
ln -sf /workspace/data/models/checkpoints /workspace/stable-diffusion-webui/models/Stable-diffusion
ln -sf /workspace/data/models/loras /workspace/stable-diffusion-webui/models/Lora
ln -sf /workspace/data/models/controlnet /workspace/stable-diffusion-webui/models/ControlNet
ln -sf /workspace/data/models/vae /workspace/stable-diffusion-webui/models/VAE

# 链接专用输出目录
ln -sf /workspace/data/sd/output /workspace/stable-diffusion-webui/outputs