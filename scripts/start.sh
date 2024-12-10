#!/bin/bash
set -e

# 创建 supervisor 配置目录
mkdir -p /etc/supervisor/conf.d

# 复制 supervisor 配置文件
cp /workspace/config/supervisord.conf /etc/supervisor/supervisord.conf
cp /workspace/config/conf.d/*.conf /etc/supervisor/conf.d/

# 创建日志目录
mkdir -p /var/log/supervisor

# 确保日志目录权限正确
chown -R root:root /var/log/supervisor
chmod -R 755 /var/log/supervisor

# 启动 supervisor 服务
service supervisor start || systemctl start supervisor

# 等待几秒让服务启动
sleep 5

# 重新加载配置
supervisorctl reread
supervisorctl update

# 启动所有服务
supervisorctl start all

# 检查服务状态
supervisorctl status

# 启动 Nginx 服务
service nginx start || systemctl start nginx

# 检查 Nginx 配置
nginx -t

# 重新加载 Nginx 配置
nginx -s reload