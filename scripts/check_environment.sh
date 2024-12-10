#!/bin/bash
set -e

# 检查是否是 Ubuntu 22.04
check_ubuntu() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "22.04" ]; then
            echo "✓ 系统检查通过：Ubuntu 22.04"
            return 0
        fi
    fi
    echo "✗ 错误：需要 Ubuntu 22.04，但当前系统是 $PRETTY_NAME"
    return 1
}

# 检查 CUDA 版本
check_cuda() {
    if ! command -v nvcc &> /dev/null; then
        echo "✗ 错误：未安装 CUDA"
        return 1
    fi

    CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
    REQUIRED_VERSION="12.2"

    if [ "$CUDA_VERSION" = "$REQUIRED_VERSION" ]; then
        echo "✓ CUDA 版本检查通过：$CUDA_VERSION"
        return 0
    else
        echo "✗ 错误：需要 CUDA $REQUIRED_VERSION，但当前版本是 $CUDA_VERSION"
        return 1
    fi
}

# 检查 GPU 是否可用
check_gpu() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo "✗ 错误：未找到 NVIDIA 显卡或驱动"
        return 1
    fi

    GPU_COUNT=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l)
    if [ "$GPU_COUNT" -gt 0 ]; then
        echo "✓ GPU 检查通过：找到 $GPU_COUNT 个 NVIDIA GPU"
        nvidia-smi --query-gpu=gpu_name --format=csv,noheader | sed 's/^/  - /'
        return 0
    else
        echo "✗ 错误：未检测到可用的 NVIDIA GPU"
        return 1
    fi
}

# 主函数
main() {
    echo "开始环境检查..."
    echo "-------------------"
    
    local has_error=0

    # 运行所有检查
    check_ubuntu || has_error=1
    check_cuda || has_error=1
    check_gpu || has_error=1

    echo "-------------------"
    if [ $has_error -eq 0 ]; then
        echo "✓ 所有检查通过！"
        return 0
    else
        echo "✗ 环境检查失败！"
        return 1
    fi
}

# 运行主函数
main 