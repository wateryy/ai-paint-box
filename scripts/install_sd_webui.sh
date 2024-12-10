#!/bin/bash
set -e

source /workspace/venv/bin/activate

# 安装 Stable Diffusion WebUI
cd /workspace
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui
pip install --no-cache-dir -r requirements.txt
pip install --no-cache-dir xformers

# 创建软链接以共享模型
ln -s /workspace/data/models/checkpoints /workspace/stable-diffusion-webui/models/Stable-diffusion
ln -s /workspace/data/models/loras /workspace/stable-diffusion-webui/models/Lora
ln -s /workspace/data/models/controlnet /workspace/stable-diffusion-webui/models/ControlNet
ln -s /workspace/data/models/vae /workspace/stable-diffusion-webui/models/VAE

# 链接专用输出目录
ln -s /workspace/data/sd/output /workspace/stable-diffusion-webui/outputs