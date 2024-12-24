#!/bin/bash
set -e  # 遇到错误立即退出

# 基础路径设置
DATA_ROOT="/workspace/data"
MODELS_ROOT="$DATA_ROOT/models"
SD_MODELS_DIR="$MODELS_ROOT/Stable-diffusion"
VAE_MODELS_DIR="$MODELS_ROOT/vae-models"
LORA_MODELS_DIR="$MODELS_ROOT/lora-xl"

# 确保目录存在
mkdir -p "$SD_MODELS_DIR"
mkdir -p "$VAE_MODELS_DIR"
mkdir -p "$LORA_MODELS_DIR"

# 检查文件是否存在且非空
check_file() {
    local filepath=$1
    if [ -f "$filepath" ]; then
        local size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null)
        if [ "$size" -gt 0 ]; then
            return 0  # 文件存在且非空
        fi
    fi
    return 1  # 文件不存在或为空
}

# 通用下载函数
download_model() {
    local url=$1      # 下载链接
    local filename=$2 # 保存的文件名
    local max_retries=3  # 最大重试次数
    
    # 检查当前目录
    if check_file "$filename"; then
        echo "$filename 已存在且非空，跳过下载"
        return 0
    fi
    
    # 检查共享目录中是否已存在
    local shared_file
    case "$filename" in
        *"xl_base"* | *"xl_refiner"* | *"v1-5"*)
            shared_file="$MODELS_ROOT/Stable-diffusion/$filename"
            ;;
        *"vae"*)
            shared_file="$MODELS_ROOT/vae-models/$filename"
            ;;
        *"lora"* | *"detail"* | *"noise"*)
            shared_file="$MODELS_ROOT/lora-xl/$filename"
            ;;
    esac
    
    if [ -n "$shared_file" ] && check_file "$shared_file"; then
        echo "在共享目录找到 $filename，创建符号链接..."
        ln -sf "$shared_file" "$filename"
        return 0
    fi
    
    echo "开始下载 $filename..."
    for ((i=1; i<=$max_retries; i++)); do
        echo "尝试 $i/$max_retries..."
        if wget -q --show-progress "$url" -O "$filename.tmp"; then
            mv "$filename.tmp" "$filename"
            echo "$filename 下载完成"
            return 0
        fi
        echo "下载失败，重试..."
        rm -f "$filename.tmp"
        sleep 2
    done
    
    echo "警告：$filename 在 $max_retries 次尝试后仍然下载失败，继续执行..."
    return 0  # 返回0以继续执行
}

# 进入 SD 模型目录
cd "$SD_MODELS_DIR"

echo "=== 开始下载基础模型 ==="
# SDXL 基础模型
# download_model "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
#     "sd_xl_base_1.0.safetensors"
# download_model "https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors" \
#     "sd_xl_refiner_1.0.safetensors"


echo "=== 开始下载 VAE 模型 ==="
cd "$VAE_MODELS_DIR"

# SDXL VAE
# download_model "https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors" \
#     "sdxl_vae.safetensors"

# # kl-f8-anime VAE
# download_model "https://huggingface.co/hakurei/waifu-diffusion-v1-4/resolve/main/vae/kl-f8-anime2.ckpt" \
#     "kl-f8-anime.vae.pt"

# 创建 Text Encoder 目录
mkdir -p "$MODELS_ROOT/text-encoder"
cd "$MODELS_ROOT/text-encoder"

echo "=== 开始下载 Text Encoder 模型 ==="

# CLIP Text Encoder
# download_model "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/pytorch_model.bin" \
#     "clip-vit-large-patch14.bin"

# CLIP Vision Encoder
# download_model "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/preprocessor_config.json" \
#     "clip-vit-large-patch14-preprocessor.json"

# T5 Text Encoder
# download_model "https://huggingface.co/DeepFloyd/t5-v1_1-xxl/resolve/main/config.json" \
#     "t5-v1_1-xxl-config.json"

# BERT Text Encoder
# download_model "https://huggingface.co/bert-base-uncased/resolve/main/pytorch_model.bin" \
#     "bert-base-uncased.bin"
# download_model "https://huggingface.co/bert-base-uncased/resolve/main/config.json" \
#     "bert-base-uncased-config.json"

echo "=== 开始下载常用 LoRA ==="
cd "$LORA_MODELS_DIR"

# Detail Tweaker
# download_model "https://civitai.com/api/download/models/87153" \
#     "detail_tweaker_xl.safetensors"

# # Add Detail
# download_model "https://civitai.com/api/download/models/135867" \
#     "add_detail.safetensors"

# # SDXL Offset Noise
# download_model "https://civitai.com/api/download/models/134485" \
#     "offset_noise.safetensors"

echo "所有模型下载完成"
echo "提示：可以通过 Civitai 等平台下载更多模型" 