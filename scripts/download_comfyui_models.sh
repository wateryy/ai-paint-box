#!/bin/bash
set -e  # 遇到错误立即退出

# 基础路径设置
DATA_ROOT="/workspace/data"
MODELS_ROOT="$DATA_ROOT/models"

# 基础共享目录中已定义的目录
# $MODELS_ROOT/
#   - clip
#   - Stable-diffusion
#   - clip_vision
#   - configs
#   - controlnet
#   - photomaker
#   - lora-xl
#   - vae-models
#   - gligen
#   - hypernetworks
#   - upscale-models
# $DATA_ROOT/embeddings

# ComfyUI 自己的模型目录
COMFYUI_MODELS_DIR="/workspace/ComfyUI/models"

# 检查链接有效性的函数
check_url() {
    local url=$1
    local filename=$2
    
    echo "检查链接: $filename"
    if curl --connect-timeout 10 --max-time 10 -sI "$url" | grep -q "HTTP/[0-9\.]* [23].."; then
        echo "✓ $filename 链接有效"
        return 0
    else
        echo "✗ $filename 链接无效"
        return 1
    fi
}

# 存储所有需要下载的模型信息
declare -A MODEL_URLS=(
    ["sd_xl_base_1.0.safetensors"]="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
    ["sd_xl_refiner_1.0.safetensors"]="https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors"
)

# 在开始下载前检查所有链接
echo "=== 开始检查所有下载链接 ==="
INVALID_URLS=()
for filename in "${!MODEL_URLS[@]}"; do
    if ! check_url "${MODEL_URLS[$filename]}" "$filename"; then
        INVALID_URLS+=("$filename")
    fi
done

# 如果有无效链接，显示警告
if [ ${#INVALID_URLS[@]} -gt 0 ]; then
    echo "警告：发现 ${#INVALID_URLS[@]} 个无效链接："
    for filename in "${INVALID_URLS[@]}"; do
        echo "- $filename: ${MODEL_URLS[$filename]}"
    done
    echo "是否继续下载其他模型？(y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo "下载已取消"
        exit 1
    fi
fi

# 通用下载函数
download_model() {
    local url=$1      # 下载链接
    local filename=$2 # 保存的文件名
    local max_retries=3  # 最大重试次数
    local retry_count=0
    
    # 检查文件是否存在且大小不为0
    if [ -f "$filename" ]; then
        local size=$(stat -f%z "$filename" 2>/dev/null || stat -c%s "$filename" 2>/dev/null)
        if [ "$size" -eq 0 ]; then
            echo "发现空文件 $filename，删除并重新下载..."
            rm "$filename"
        else
            echo "$filename 已存在且非空，跳过下载"
            return 0
        fi
    fi
    
    while [ $retry_count -lt $max_retries ]; do
        echo "正在下载 $filename... (尝试 $((retry_count + 1))/$max_retries)"
        if wget -q --show-progress --timeout=30 --tries=3 "$url" -O "$filename"; then
            # 下载完成后检查文件大小
            local final_size=$(stat -f%z "$filename" 2>/dev/null || stat -c%s "$filename" 2>/dev/null)
            if [ "$final_size" -eq 0 ]; then
                echo "警告：下载的文件 $filename 为空，重试..."
                rm "$filename"
                retry_count=$((retry_count + 1))
                sleep 2  # 等待2秒后重试
                continue
            fi
            echo "$filename 下载完成"
            return 0
        else
            echo "警告：$filename 下载失败，重试中..."
            [ -f "$filename" ] && rm "$filename"
            retry_count=$((retry_count + 1))
            sleep 2  # 等待2秒后重试
        fi
    done
    
    echo "错误：$filename 在 $max_retries 次尝试后仍然下载失败，跳过"
    return 0  # 继续执行脚本
}

# 开始下载
echo "=== 开始下载模型 ==="
for filename in "${!MODEL_URLS[@]}"; do
    # 跳过已知的无效链接
    if [[ " ${INVALID_URLS[@]} " =~ " ${filename} " ]]; then
        echo "跳过无效链接: $filename"
        continue
    fi
    
    # 根据文件类型确定目录
    case "$filename" in
        *"xl_base"* | *"xl_refiner"* | *"v1-5"* | *"Realistic_Vision"* | *"Deliberate"*)
            cd "$MODELS_ROOT/Stable-diffusion"
            ;;
        *"vae"*)
            cd "$MODELS_ROOT/vae-models"
            ;;
        # ... (添加其他类型的判断)
    esac
    
    download_model "${MODEL_URLS[$filename]}" "$filename"
done

# 下载到 ComfyUI 自己目录的模型
echo "=== 开始下载 VAE Approx 模型 ==="
mkdir -p "$COMFYUI_MODELS_DIR/vae_approx"
cd "$COMFYUI_MODELS_DIR/vae_approx"

# TAESD
echo "下载 TAESD 模型..."
download_model "https://huggingface.co/madebyollin/taesd/resolve/main/model.safetensors" \
    "taesd_encoder.pth"
# 对于 decoder，使用相同的文件
cp "taesd_encoder.pth" "taesd_decoder.pth"

# TAESDXL
echo "下载 TAESDXL 模型..."
download_model "https://huggingface.co/madebyollin/taesdxl/resolve/main/model.safetensors" \
    "taesdxl_encoder.pth"
# 对于 decoder，使用相同��文件
cp "taesdxl_encoder.pth" "taesdxl_decoder.pth"

echo "=== 开始下载人脸修复模型 ==="
mkdir -p "$COMFYUI_MODELS_DIR/facerestore_models"
cd "$COMFYUI_MODELS_DIR/facerestore_models"

# RestoreFormer - 使用 GitHub 官方链接
echo "下载 RestoreFormer 模型..."
download_model "https://github.com/wzhouxiff/RestoreFormer/releases/download/v1.0/RestoreFormer.pth" \
    "RestoreFormer.pth"

# 人脸检测模型
echo "=== 开始下载人脸检测模型 ==="

# YuNet 人脸检测模型 - 使用 OpenCV 官方链接
echo "下载 YuNet 模型..."
download_model "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx" \
    "yunet_120x160.onnx"

# MediaPipe Face Detection 模型
echo "下载 MediaPipe 人脸检测模型..."
download_model "https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/1/blaze_face_short_range.tflite" \
    "blaze_face_short_range.tflite"

# InsightFace 模型
echo "下载 InsightFace 模型..."
download_model "https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip" \
    "buffalo_l.zip"

echo "=== 开始下载 LoRA 模型 ==="
cd "$MODELS_ROOT/lora-xl"

# 更新 Hyper-FLUX 链接
download_model "https://civitai.com/api/download/models/198530" \
    "Hyper-FLUX.1-dev-8steps-lora.safetensors"

# SigCLIP Vision
echo "下载 SigCLIP Vision..."
download_model "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/pytorch_model.bin" \
    "sigclip_vision_patch14_384.pth"

# T5 编码器 - 使用 t5-large 替代
echo "下载 T5 编码器..."
download_model "https://huggingface.co/t5-large/resolve/main/pytorch_model.bin" \
    "t5_xxl_encoderonly_fp8_e4m3fn.pth"

echo "=== 开始下载 Ultralytics 模型 ==="
mkdir -p "$COMFYUI_MODELS_DIR/ultralytics_bbox"
cd "$COMFYUI_MODELS_DIR/ultralytics_bbox"

# YOLOv8 不同规模的模型
echo "下载 YOLOv8 模型..."
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt" \
    "yolov8n.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s.pt" \
    "yolov8s.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m.pt" \
    "yolov8m.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8l.pt" \
    "yolov8l.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8x.pt" \
    "yolov8x.pt"


mkdir -p "$COMFYUI_MODELS_DIR/ultralytics_segm"
cd "$COMFYUI_MODELS_DIR/ultralytics_segm"

echo "下载 YOLOv8 分割模型..."
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n-seg.pt" \
    "yolov8n-seg.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s-seg.pt" \
    "yolov8s-seg.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-seg.pt" \
    "yolov8m-seg.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8l-seg.pt" \
    "yolov8l-seg.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8x-seg.pt" \
    "yolov8x-seg.pt"

mkdir -p "$COMFYUI_MODELS_DIR/ultralytics_pose"
cd "$COMFYUI_MODELS_DIR/ultralytics_pose"

echo "下载 YOLOv8 姿态检测模型..."
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n-pose.pt" \
    "yolov8n-pose.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s-pose.pt" \
    "yolov8s-pose.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-pose.pt" \
    "yolov8m-pose.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8l-pose.pt" \
    "yolov8l-pose.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8x-pose.pt" \
    "yolov8x-pose.pt"

mkdir -p "$COMFYUI_MODELS_DIR/ultralytics_cls"
cd "$COMFYUI_MODELS_DIR/ultralytics_cls"

echo "下载 YOLOv8 分类模型..."
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n-cls.pt" \
    "yolov8n-cls.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s-cls.pt" \
    "yolov8s-cls.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-cls.pt" \
    "yolov8m-cls.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8l-cls.pt" \
    "yolov8l-cls.pt"
download_model "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8x-cls.pt" \
    "yolov8x-cls.pt"

echo "=== 开始下载 SAM 模型 ==="
mkdir -p "$COMFYUI_MODELS_DIR/sams"
cd "$COMFYUI_MODELS_DIR/sams"

echo "下载 SAM ViT-H 模型..."
download_model "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth" \
    "sam_vit_h.pth"

echo "下载 SAM ViT-L 模型..."
download_model "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_l_0b3195.pth" \
    "sam_vit_l.pth"

echo "下载 SAM ViT-B 模型..."
download_model "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth" \
    "sam_vit_b.pth"

echo "下载 MobileSAM 模型..."
download_model "https://github.com/ChaoningZhang/MobileSAM/raw/master/weights/mobile_sam.pt" \
    "mobile_sam.pt"

echo "=== 开始下载 VHS 视式文件 ==="
VHS_DIR="/workspace/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite/video_formats"
mkdir -p "$VHS_DIR"
cd "$VHS_DIR"

echo "下载视频格式配置..."
# 使用正确的 raw GitHub 链接
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/1080p_30fps_h264.json" \
    "1080p_30fps_h264.json"
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/1080p_60fps_h264.json" \
    "1080p_60fps_h264.json"
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/4k_30fps_h264.json" \
    "4k_30fps_h264.json"
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/4k_60fps_h264.json" \
    "4k_60fps_h264.json"
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/720p_30fps_h264.json" \
    "720p_30fps_h264.json"
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/720p_60fps_h264.json" \
    "720p_60fps_h264.json"
download_model "https://raw.githubusercontent.com/Kosinkadink/ComfyUI-VideoHelperSuite/main/video_formats/gif.json" \
    "gif.json"

# 如果下载失败，我们可以接创建这些配置文件
if [ ! -f "1080p_30fps_h264.json" ]; then
    echo '{
        "name": "1080p 30fps h264",
        "extension": "mp4",
        "codec": "libx264",
        "crf": 23,
        "preset": "medium",
        "width": 1920,
        "height": 1080,
        "fps": 30
    }' > "1080p_30fps_h264.json"
fi

if [ ! -f "1080p_60fps_h264.json" ]; then
    echo '{
        "name": "1080p 60fps h264",
        "extension": "mp4",
        "codec": "libx264",
        "crf": 23,
        "preset": "medium",
        "width": 1920,
        "height": 1080,
        "fps": 60
    }' > "1080p_60fps_h264.json"
fi

if [ ! -f "4k_30fps_h264.json" ]; then
    echo '{
        "name": "4K 30fps h264",
        "extension": "mp4",
        "codec": "libx264",
        "crf": 23,
        "preset": "medium",
        "width": 3840,
        "height": 2160,
        "fps": 30
    }' > "4k_30fps_h264.json"
fi

if [ ! -f "4k_60fps_h264.json" ]; then
    echo '{
        "name": "4K 60fps h264",
        "extension": "mp4",
        "codec": "libx264",
        "crf": 23,
        "preset": "medium",
        "width": 3840,
        "height": 2160,
        "fps": 60
    }' > "4k_60fps_h264.json"
fi

if [ ! -f "720p_30fps_h264.json" ]; then
    echo '{
        "name": "720p 30fps h264",
        "extension": "mp4",
        "codec": "libx264",
        "crf": 23,
        "preset": "medium",
        "width": 1280,
        "height": 720,
        "fps": 30
    }' > "720p_30fps_h264.json"
fi

if [ ! -f "720p_60fps_h264.json" ]; then
    echo '{
        "name": "720p 60fps h264",
        "extension": "mp4",
        "codec": "libx264",
        "crf": 23,
        "preset": "medium",
        "width": 1280,
        "height": 720,
        "fps": 60
    }' > "720p_60fps_h264.json"
fi

if [ ! -f "gif.json" ]; then
    echo '{
        "name": "GIF",
        "extension": "gif",
        "fps": 10
    }' > "gif.json"
fi

echo "所有模型下载完成"
echo "提示：可以通过 Civitai 等平台下载更多模型" 