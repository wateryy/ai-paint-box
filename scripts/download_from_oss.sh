#!/bin/bash

# 配置变量
OSSUTIL_VERSION="1.7.16"  # ossutil 版本
INSTALL_DIR="/usr/local/bin"  # ossutil 安装目录
OSSUTIL_CONFIG_FILE="${HOME}/.ossutilconfig"  # 修改为用户目录下的默认配置文件位置

# 安装 ossutil 的函数
install_ossutil() {
    echo "=== 开始安装 ossutil ==="
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    # 下载 ossutil
    echo "下载 ossutil..."
    wget "https://gosspublic.alicdn.com/ossutil/${OSSUTIL_VERSION}/ossutil64" -O ossutil
    
    if [ $? -ne 0 ]; then
        echo "错误：ossutil 下载失败"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    # 添加执行权限
    chmod +x ossutil
    
    # 移动到安装目录
    echo "安装 ossutil 到 $INSTALL_DIR..."
    mv ossutil "$INSTALL_DIR/ossutil"
    
    # 清理临时目录
    cd - > /dev/null
    rm -rf "$tmp_dir"
    
    echo "ossutil 安装完成"
}

# 从 OSS 下载文件的函数
download_from_oss() {
    local oss_path=$1
    local local_dir=$2
    
    echo "=== 开始从 OSS 下载文件 ==="
    echo "OSS 路径: $oss_path"
    echo "本地目录: $local_dir"
    
    # 确保目标目录存在
    mkdir -p "$local_dir"
    
    # 构建下载参数
    local cp_params=(
        "-r"
        "--update"
        "--parallel=${OSS_PARALLEL:-3}"
        "--part-size=${OSS_PART_SIZE:-1048576}"
        "--config-file" "$OSSUTIL_CONFIG_FILE"  # 添加配置文件参数
    )
    
    # 如果配置了内网访问
    if [ "${OSS_INTERNAL,,}" = "true" ]; then
        cp_params+=("--internal")
    fi
    
    # 下载文件
    ossutil cp "${cp_params[@]}" "$oss_path" "$local_dir"
    
    if [ $? -ne 0 ]; then
        echo "错误：文件下载失败"
        return 1
    fi
    
    echo "文件下载完成"
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] <OSS路径> <本地目录>"
    echo
    echo "选项:"
    echo "  -e, --endpoint <endpoint>       指定 OSS endpoint"
    echo "  -i, --access-key <key>         指定 Access Key ID"
    echo "  -k, --access-secret <secret>   指定 Access Key Secret"
    echo "  -h, --help                     显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0 -e oss-cn-beijing.aliyuncs.com -i YOUR_KEY -k YOUR_SECRET oss://bucket/path /workspace/data"
}

# 配置 ossutil 的函数
configure_ossutil() {
    local endpoint=$1
    local access_key=$2
    local access_secret=$3
    
    echo "=== 配置 ossutil ==="
    
    # 检查配置文件是否存在
    if [ -f "$OSSUTIL_CONFIG_FILE" ]; then
        echo "发现已存在的配置文件，将使用现有配置"
        return 0
    fi
    
    # 创建配置文件目录
    mkdir -p "$(dirname "$OSSUTIL_CONFIG_FILE")"
    
    # 创建默认配置文件
    cat > "$OSSUTIL_CONFIG_FILE" << EOF
[Credentials]
language=CH
endpoint=${endpoint}
accessKeyID=${access_key}
accessKeySecret=${access_secret}
EOF
    
    if [ $? -ne 0 ]; then
        echo "错误：创建配置文件失败"
        return 1
    fi
    
    # 设置配置文件权限
    chmod 600 "$OSSUTIL_CONFIG_FILE"
    
    echo "ossutil 配置完成"
}

# 主函数
main() {
    local endpoint=""
    local access_key=""
    local access_secret=""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--endpoint)
                endpoint="$2"
                shift 2
                ;;
            -i|--access-key)
                access_key="$2"
                shift 2
                ;;
            -k|--access-secret)
                access_secret="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # 检查参数
    if [ $# -lt 2 ]; then
        show_help
        exit 1
    fi
    
    local oss_path=$1
    local local_dir=$2
    
    # 检查 ossutil 是否已安装
    if ! command -v ossutil &> /dev/null; then
        install_ossutil
    fi
    
    # 如果提供了凭证参数，则配置 ossutil
    if [ -n "$endpoint" ] && [ -n "$access_key" ] && [ -n "$access_secret" ]; then
        configure_ossutil "$endpoint" "$access_key" "$access_secret"
        if [ $? -ne 0 ]; then
            echo "错误：ossutil 配置失败"
            exit 1
        fi
    elif [ ! -f "$OSSUTIL_CONFIG_FILE" ]; then
        echo "错误：未找到配置文件，请提供 endpoint、access-key 和 access-secret 参数"
        show_help
        exit 1
    fi
    
    # 下载文件
    download_from_oss "$oss_path" "$local_dir"
}

# 执行主函数
main "$@" 