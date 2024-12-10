#!/bin/bash
set -e

source /workspace/venv/bin/activate

# 安装 ComfyUI
cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir -r requirements.txt

# 创建软链接以共享模型
ln -s /workspace/data/models/checkpoints /workspace/ComfyUI/models/checkpoints
ln -s /workspace/data/models/loras /workspace/ComfyUI/models/loras
ln -s /workspace/data/models/controlnet /workspace/ComfyUI/models/controlnet
ln -s /workspace/data/models/vae /workspace/ComfyUI/models/vae

# 链接专用输出目录
ln -s /workspace/data/comfyui/output /workspace/ComfyUI/output