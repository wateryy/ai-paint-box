#!/bin/bash
set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 添加脚本执行权限
chmod +x "$SCRIPT_DIR/scripts/"*.sh
echo "已添加脚本执行权限"

# 首先运行环境检查
"$SCRIPT_DIR/scripts/check_environment.sh" || {
    echo "环境检查失败，安装终止"
    exit 1
}

# 执行安装脚本
"$SCRIPT_DIR/scripts/install_base.sh"
"$SCRIPT_DIR/scripts/install_sd_webui.sh"
"$SCRIPT_DIR/scripts/install_comfyui.sh"
"$SCRIPT_DIR/scripts/install_comfyui_custom_nodes.sh"
"$SCRIPT_DIR/scripts/start.sh"

echo "安装完成！" 