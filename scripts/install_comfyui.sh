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

# 处理所有模型目录
echo "配置模型目录..."
for DIR in checkpoints loras controlnet vae; do
    MODELS_DIR="models/$DIR"
    if [ -d "$MODELS_DIR" ] && [ ! -L "$MODELS_DIR" ]; then
        echo "发现已存在的模型目录 $DIR，正在复制到专用目录..."
        mkdir -p "/workspace/data/comfyui/models/$DIR"
        cp -r "$MODELS_DIR"/* "/workspace/data/comfyui/models/$DIR/" 2>/dev/null || true
        rm -rf "$MODELS_DIR"
    fi
    ln -sf "/workspace/data/models/$DIR" "/workspace/ComfyUI/models/$DIR"
done

# 处理输出目录
echo "配置输出目录..."
if [ -d "output" ] && [ ! -L "output" ]; then
    echo "发现已存在的输出目录，正在复制到专用目录..."
    cp -r output/* /workspace/data/comfyui/output/ 2>/dev/null || true
    rm -rf output
fi
ln -sf /workspace/data/comfyui/output /workspace/ComfyUI/output