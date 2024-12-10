#!/bin/bash
set -e

# 安装系统依赖
apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    git \
    wget \
    curl \
    libgl1-mesa-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    ffmpeg \
    supervisor \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# 设置 Python 3.10 为默认版本
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
update-alternatives --set python3 /usr/bin/python3.10

# 安装最新版本的 pip
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# 创建工作目录
mkdir -p /workspace
cd /workspace

# 创建虚拟环境
python3 -m venv /workspace/venv
source /workspace/venv/bin/activate

# 更新虚拟环境中的基础包
pip install --no-cache-dir -U pip setuptools wheel

# 安装其他常用基础包
pip install --no-cache-dir \
    numpy \
    pandas \
    pillow \
    requests \
    tqdm

# 创建模型目录结构
mkdir -p /workspace/data/models/{checkpoints,loras,controlnet,vae}  # 共享模型
mkdir -p /workspace/data/comfyui/{models,output}  # ComfyUI 专用
mkdir -p /workspace/data/sd/{models,output}  # SD WebUI 专用

# 安装 Nginx
apt-get update && apt-get install -y nginx

# 备份原始配置
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# 复制新的配置文件
cp /workspace/config/nginx/nginx.conf /etc/nginx/nginx.conf

# 创建日志目录
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx
chmod -R 755 /var/log/nginx