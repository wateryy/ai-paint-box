#!/bin/bash

# OSS配置信息
OSSUTIL_CONFIG_FILE="${HOME}/.ossutilconfig"
BUCKET_NAME="dl-does-matter"  # 直接在脚本中定义 bucket 名称

# 从配置文件读取OSS配置
if [ -f "$OSSUTIL_CONFIG_FILE" ]; then
    # 解析配置文件
    ENDPOINT=$(grep "endpoint=" "$OSSUTIL_CONFIG_FILE" | cut -d'=' -f2)
    ACCESS_KEY_ID=$(grep "accessKeyID=" "$OSSUTIL_CONFIG_FILE" | cut -d'=' -f2)
    ACCESS_KEY_SECRET=$(grep "accessKeySecret=" "$OSSUTIL_CONFIG_FILE" | cut -d'=' -f2)
    
    # 移除可能存在的引号和空格
    ENDPOINT=$(echo "$ENDPOINT" | tr -d '"' | tr -d ' ')
    ACCESS_KEY_ID=$(echo "$ACCESS_KEY_ID" | tr -d '"' | tr -d ' ')
    ACCESS_KEY_SECRET=$(echo "$ACCESS_KEY_SECRET" | tr -d '"' | tr -d ' ')
else
    log_message "${RED}错误：未找到OSS配置文件 $OSSUTIL_CONFIG_FILE${NC}"
    exit 1
fi

MOUNT_POINT="/mnt/oss"
LOG_FILE="/var/log/ossfs_mount.log"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 日志函数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
    echo -e "$1"
}

# 清理函数
cleanup() {
    log_message "${RED}正在清理...${NC}"
    fusermount -u $MOUNT_POINT 2>/dev/null
    exit 1
}

# 信号处理
trap 'cleanup' INT TERM

# 检查root权限
if [ "$EUID" -ne 0 ]; then 
    log_message "${RED}请使用root权限运行此脚本${NC}"
    exit 1
fi

# 检查参数
if [ -z "$BUCKET_NAME" ] || [ -z "$ACCESS_KEY_ID" ] || [ -z "$ACCESS_KEY_SECRET" ] || [ -z "$ENDPOINT" ]; then
    log_message "${RED}错误：请设置所有必要的OSS配置参数${NC}"
    exit 1
fi

# 检查并安装 ping 命令
if ! command -v ping &> /dev/null; then
    log_message "${GREEN}正在安装 ping 命令...${NC}"
    apt-get update && apt-get install -y iputils-ping
    if [ $? -ne 0 ]; then
        log_message "${RED}错误：安装 ping 命令失败${NC}"
        exit 1
    fi
fi

# 检查网络连接
ping -c 1 aliyun.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_message "${RED}错误：无法连接到阿里云，请检查网络${NC}"
    exit 1
fi

# 检查磁盘空间
MIN_SPACE_MB=500
AVAILABLE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
if [ $AVAILABLE_SPACE -lt $MIN_SPACE_MB ]; then
    log_message "${RED}错误：可用磁盘空间不足${NC}"
    exit 1
fi

# 备份现有配置
backup_config() {
    if [ -f /etc/passwd-ossfs ]; then
        cp /etc/passwd-ossfs /etc/passwd-ossfs.backup
    fi
}

log_message "${GREEN}开始安装OSSFS...${NC}"

# 检查是否已安装 ossfs 并验证版本
if command -v ossfs &> /dev/null && ossfs --version | grep -q "V1.91"; then
    log_message "${GREEN}检测到已安装 OSSFS $(ossfs --version | head -n1)，跳过安装步骤${NC}"
else
    # 安装必要的包
    apt-get update
    apt-get install -y gdebi-core

    # 下载并安装OSSFS
    wget https://gosspublic.alicdn.com/ossfs/ossfs_1.91.4_ubuntu22.04_amd64.deb
    if [ $? -ne 0 ]; then
        log_message "${RED}下载OSSFS失败${NC}"
        exit 1
    fi

    # 安装OSSFS
    gdebi ossfs_1.91.4_ubuntu22.04_amd64.deb
    if [ $? -ne 0 ]; then
        log_message "${RED}安装OSSFS失败${NC}"
        exit 1
    fi

    # 清理安装包
    rm ossfs_1.91.4_ubuntu22.04_amd64.deb
fi

# 配置密钥信息
backup_config
echo "$BUCKET_NAME:$ACCESS_KEY_ID:$ACCESS_KEY_SECRET" > /etc/passwd-ossfs
chmod 640 /etc/passwd-ossfs

# 创建挂载点目录
mkdir -p $MOUNT_POINT

# 卸载已存在的挂载
fusermount -u $MOUNT_POINT 2>/dev/null || true

# 设置挂载选项
OSSFS_OPTS="-o url=https://$ENDPOINT \
    -o allow_other \
    -o umask=0666 \
    -o max_stat_cache_size=500000 \
    -o connect_timeout=10 \
    -o use_path_request_style \
    -o retries=3 \
    -o max_background=100 \
    -o bucket_cache=true \
    -o bucket_cache_size=1000000 \
    -o kernel_cache \
    -o auto_cache \
    -o no_check_certificate"

# 安装和配置 FUSE
install_fuse() {
    log_message "${GREEN}正在安装和配置 FUSE...${NC}"
    
    # 安装必要的包
    apt-get update
    apt-get install -y \
        libfuse2 \
        fuse \
        psmisc

    # 确保挂载点目录存在且权限正确
    mkdir -p $MOUNT_POINT
    chmod 755 $MOUNT_POINT

    # 确保没有进程在使用挂载点
    if command -v fuser >/dev/null 2>&1; then
        fuser -km $MOUNT_POINT >/dev/null 2>&1 || true
    fi

    # 卸载已存在的挂载
    if mount | grep -q "$MOUNT_POINT"; then
        fusermount -u $MOUNT_POINT >/dev/null 2>&1 || true
        umount -f $MOUNT_POINT >/dev/null 2>&1 || true
    fi

    # 确保 /dev/fuse 存在且权限正确
    if [ ! -c /dev/fuse ]; then
        mknod /dev/fuse c 10 229
    fi
    chmod 666 /dev/fuse

    # 确保当前用户在 fuse 组中
    if ! getent group fuse >/dev/null; then
        groupadd fuse
    fi
    usermod -aG fuse root

    # 重新加载 FUSE 模块
    modprobe -r fuse || true
    sleep 1
    modprobe fuse

    # 验证 FUSE 是否正确加载
    if ! lsmod | grep -q fuse; then
        log_message "${RED}错误：FUSE 模块加载失败${NC}"
        log_message "已加载模块："
        lsmod
        exit 1
    fi

    # 验证 /dev/fuse 权限
    ls -l /dev/fuse
    
    log_message "${GREEN}FUSE 安装和配置完成${NC}"
}

# 在挂载OSS之前调用此函数
install_fuse

# 挂载OSS
log_message "${GREEN}开始挂载OSS...${NC}"
ossfs $BUCKET_NAME $MOUNT_POINT \
    -o dbglevel=debug \
    -o curldbg \
    -o dev \
    -o allow_other \
    $OSSFS_OPTS

# 检查挂载
if mount | grep ossfs > /dev/null; then
    log_message "${GREEN}OSS挂载成功！${NC}"
    log_message "${GREEN}挂载点: $MOUNT_POINT${NC}"
else
    log_message "${RED}OSS挂载失败${NC}"
    # 显示详细的错误信息
    log_message "挂载点权限："
    ls -ld $MOUNT_POINT
    log_message "FUSE 设备权限："
    ls -l /dev/fuse
    log_message "当前用户和组："
    id
    exit 1
fi

# 显示挂载信息
df -h | grep ossfs

# 测试写入
echo "OSS mount test" > $MOUNT_POINT/test.txt
if [ $? -eq 0 ]; then
    log_message "${GREEN}写入测试文件成功${NC}"
    rm $MOUNT_POINT/test.txt
else
    log_message "${RED}写入测试失败，请检查权限${NC}"
fi

# 显示OSSFS版本信息
check_ossfs_version

log_message "${GREEN}脚本执行完成${NC}"

# 挂载OSS
# sudo ./mount_oss.sh

# 卸载挂载
# sudo fusermount -u /mnt/oss

# 开机启动
# 如果需要开机自动挂载，可以将以下内容添加到 /etc/fstab：
#ossfs#bucket_name mount_point fuse _netdev,allow_other,url=endpoint 0 0
