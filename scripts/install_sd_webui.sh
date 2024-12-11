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

# 处理所有模型目录
echo "配置模型目录..."
declare -A MODEL_DIRS=(
    ["Stable-diffusion"]="checkpoints"
    ["Lora"]="loras"
    ["ControlNet"]="controlnet"
    ["VAE"]="vae"
)

for SD_DIR in "${!MODEL_DIRS[@]}"; do
    DATA_DIR="${MODEL_DIRS[$SD_DIR]}"
    MODELS_DIR="models/$SD_DIR"
    if [ -d "$MODELS_DIR" ] && [ ! -L "$MODELS_DIR" ]; then
        echo "发现已存在的模型目录 $SD_DIR，正在复制到专用目录..."
        mkdir -p "/workspace/data/sd/models/$DATA_DIR"
        cp -r "$MODELS_DIR"/* "/workspace/data/sd/models/$DATA_DIR/" 2>/dev/null || true
        rm -rf "$MODELS_DIR"
    fi
    ln -sf "/workspace/data/models/$DATA_DIR" "/workspace/stable-diffusion-webui/models/$SD_DIR"
done

# 处理输出目录
echo "配置输出目录..."
if [ -d "outputs" ] && [ ! -L "outputs" ]; then
    echo "发现已存在的输出目录，正在复制到专用目录..."
    cp -r outputs/* /workspace/data/sd/output/ 2>/dev/null || true
    rm -rf outputs
fi
ln -sf /workspace/data/sd/output /workspace/stable-diffusion-webui/outputs