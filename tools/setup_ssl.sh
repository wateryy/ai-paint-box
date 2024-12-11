#!/bin/bash
set -e

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -t, --type <type>     SSL 类型: letsencrypt, self-signed, mkcert (必需)"
    echo "  -d, --domain <domain>  域名 (letsencrypt 必需)"
    echo "  -e, --email <email>   邮箱 (letsencrypt 必需)"
    echo "  -h, --help            显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0 --type letsencrypt --domain example.com --email admin@example.com"
    echo "  $0 --type self-signed"
    echo "  $0 --type mkcert"
}

# 安装 Let's Encrypt 证书
setup_letsencrypt() {
    if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
        echo "错误: letsencrypt 需要域名和邮箱"
        exit 1
    fi

    # 移除旧的 certbot
    apt-get remove -y certbot python3-certbot-nginx || true

    # 安装依赖
    apt-get update
    apt-get install -y \
        python3-venv \
        python3-dev \
        gcc \
        libaugeas0 \
        augeas-lenses \
        libssl-dev \
        libffi-dev \
        ca-certificates

    # 创建虚拟环境并安装 certbot
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --no-cache-dir certbot certbot-nginx

    # 创建符号链接
    ln -sf /opt/certbot/bin/certbot /usr/local/bin/certbot

    # 申请证书
    certbot --nginx \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        -d "$DOMAIN" \
        --redirect

    # 添加自动续期的 cron 任务
    echo "0 0,12 * * * /usr/local/bin/certbot renew -q" | crontab -

    echo "Let's Encrypt 证书配置完成"
}

# 安装自签名证书
setup_self_signed() {
    # 生成自签名证书
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

    # 修改 nginx 配置
    sed -i 's/listen 10066/listen 10066 ssl/g' /etc/nginx/nginx.conf
    sed -i '/server_name/a \    ssl_certificate /etc/nginx/ssl/nginx.crt;\n    ssl_certificate_key /etc/nginx/ssl/nginx.key;' /etc/nginx/nginx.conf

    # 重启 nginx
    nginx -t && nginx -s reload

    echo "自签名证书配置完成"
}

# 安装 mkcert 证书
setup_mkcert() {
    # 安装 mkcert
    apt-get update
    apt-get install -y libnss3-tools
    curl -L https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64 -o /usr/local/bin/mkcert
    chmod +x /usr/local/bin/mkcert

    # 初始化 mkcert
    mkcert -install

    # 生成证书
    mkdir -p /etc/nginx/ssl
    mkcert -key-file /etc/nginx/ssl/nginx.key \
           -cert-file /etc/nginx/ssl/nginx.crt \
           localhost 127.0.0.1 ::1

    # 修改 nginx 配置
    sed -i 's/listen 10066/listen 10066 ssl/g' /etc/nginx/nginx.conf
    sed -i '/server_name/a \    ssl_certificate /etc/nginx/ssl/nginx.crt;\n    ssl_certificate_key /etc/nginx/ssl/nginx.key;' /etc/nginx/nginx.conf

    # 重启 nginx
    nginx -t && nginx -s reload

    echo "mkcert 证书配置完成"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查必需参数
if [ -z "$TYPE" ]; then
    echo "错误: 必须指定 SSL 类型"
    show_help
    exit 1
fi

# 根据类型执行相应的配置
case $TYPE in
    letsencrypt)
        setup_letsencrypt
        ;;
    self-signed)
        setup_self_signed
        ;;
    mkcert)
        setup_mkcert
        ;;
    *)
        echo "错误: 不支持的 SSL 类型: $TYPE"
        show_help
        exit 1
        ;;
esac 