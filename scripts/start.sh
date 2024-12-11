#!/bin/bash
set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR/../config"

# 创建 supervisor 配置目录
mkdir -p /etc/supervisor/conf.d

# 复制 supervisor 配置文件
cp "$CONFIG_DIR/conf.d/"*.conf /etc/supervisor/conf.d/

# 创建日志目录
mkdir -p /var/log/supervisor

# 确保日志目录权限正确
chown -R root:root /var/log/supervisor
chmod -R 755 /var/log/supervisor

# 处理 supervisord
if command -v supervisord &> /dev/null; then
    echo "supervisord 已安装，正在重启..."
    if pgrep supervisord > /dev/null; then
        pkill supervisord
        sleep 2
    fi
    supervisord -c /etc/supervisor/supervisord.conf
else
    echo "错误: supervisord 未安装"
    exit 1
fi

# 等待几秒让服务启动
sleep 5

# 重新加载配置
supervisorctl update
supervisorctl start all

# 检查服务状态
supervisorctl status

# 处理 nginx
if command -v nginx &> /dev/null; then
    echo "nginx 已安装，正在重启..."
    
    # 创建必要的目录
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled

    # 复制配置文件
    cp "$CONFIG_DIR/nginx/nginx.conf" /etc/nginx/nginx.conf
    cp "$CONFIG_DIR/nginx/sites-available/"*.conf /etc/nginx/sites-available/

    # 创建软链接
    ln -sf /etc/nginx/sites-available/comfyui.conf /etc/nginx/sites-enabled/
    ln -sf /etc/nginx/sites-available/sd-webui.conf /etc/nginx/sites-enabled/

    # 重启 nginx
    if pgrep nginx > /dev/null; then
        nginx -s stop
        sleep 2
    fi
    nginx
else
    echo "错误: nginx 未安装"
    exit 1
fi

# 检查 Nginx 配置
nginx -t

# 重新加载 Nginx 配置
nginx -s reload