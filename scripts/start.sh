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

# 直接启动 supervisord
supervisord -c /etc/supervisor/supervisord.conf

# 等待几秒让服务启动
sleep 5

# 重新加载配置
supervisorctl reread
supervisorctl update

# 启动所有服务
supervisorctl start all

# 检查服务状态
supervisorctl status

# 直接启动 nginx
nginx

# 检查 Nginx 配置
nginx -t

# 重新加载 Nginx 配置
nginx -s reload