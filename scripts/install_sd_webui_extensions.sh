#!/bin/bash
set -e

cd /workspace/stable-diffusion-webui/extensions/

echo "开始安装 SD WebUI 扩展..."

# 函数：安装扩展
install_extension() {
    local repo_url=$1
    local dir_name=$(basename $repo_url .git)
    echo "正在安装 $dir_name..."
    if [ -d "$dir_name" ]; then
        echo "目录已存在，正在更新..."
        cd "$dir_name"
        git pull
        cd ..
    else
        git clone "$repo_url"
    fi
}

echo "=== 安装图像增强工具 ==="
# ControlNet - 图像控制
# install_extension "https://github.com/Mikubill/sd-webui-controlnet.git"

# Ultimate SD Upscale - 图像放大
# install_extension "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111.git"

# After Detailer - 面部优化
# install_extension "https://github.com/Bing-su/adetailer.git"

# Dynamic Thresholding - 动态阈值
# install_extension "https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git"

echo "=== 安装界面优化工具 ==="
# Image Browser - 图片浏览器
install_extension "https://github.com/AlUlkesh/stable-diffusion-webui-images-browser.git"

# Civitai Helper - 模型下载助手
install_extension "https://github.com/butaixianran/Stable-Diffusion-Webui-Civitai-Helper.git"

# Additional Networks - 模型管理
install_extension "https://github.com/kohya-ss/sd-webui-additional-networks.git"

echo "=== 安装提示词工具 ==="
# Tag Complete - 标签补全
# install_extension "https://github.com/DominikDoom/a1111-sd-webui-tagcomplete.git"

# Wildcards - 随机提示词
# install_extension "https://github.com/AUTOMATIC1111/stable-diffusion-webui-wildcards.git"

echo "=== 安装工作流工具 ==="
# Regional Prompter - 区域提示词
# install_extension "https://github.com/hako-mikan/sd-webui-regional-prompter.git"

echo "=== 安装本地化工具 ==="
# SD WebUI 中文本地化
install_extension "https://github.com/VinsonLaro/stable-diffusion-webui-chinese.git"

echo "所有扩展安装完成"

# 重启 SD WebUI 服务
echo "重启 SD WebUI 服务..."
supervisorctl restart sd-webui

echo "SD WebUI 扩展安装完成并已重启服务"

echo "提示：更多扩展可以通过 WebUI 的 Extensions 页面安装" 