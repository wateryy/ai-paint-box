# AI 绘图服务安装脚本

这是一个用于在 CUDA 12.6.x 环境下安装和配置 ComfyUI 和 Stable Diffusion WebUI 的脚本集合。

## 系统要求

- Ubuntu 22.04
- NVIDIA GPU
- CUDA 12.6.x

## 目录结构

```
.
├── init.sh                 # 主初始化脚本
├── scripts/               # 脚本目录
│   ├── check_environment.sh           # 环境检查脚本
│   ├── install_base.sh               # 基础环境安装脚本
│   ├── install_comfyui.sh           # ComfyUI 安装脚本
│   ├── install_comfyui_custom_nodes.sh # ComfyUI 自定义节点安装脚本
│   ├── install_sd_webui.sh          # SD WebUI 安装脚本
│   └── start.sh                     # 服务启动配置脚本
├── config/                # 配置文件目录
│   ├── supervisord.conf             # Supervisor 主配置
│   └── conf.d/                      # Supervisor 服务配置
│       ├── comfyui.conf            # ComfyUI 服务配置
│       └── sd-webui.conf           # SD WebUI 服务配置
└── data/                  # 数据目录
    ├── models/            # 共享模型目录
    │   ├── checkpoints/  # 模型检查点
    │   ├── loras/       # LoRA 模型
    │   ├── controlnet/  # ControlNet 模型
    │   └── vae/         # VAE 模型
    ├── comfyui/          # ComfyUI 专用目录
    │   ├── models/      # 专用模型
    │   └── output/      # 输出目录
    └── sd/               # SD WebUI 专用目录
        ├── models/      # 专用模型
        └── output/      # 输出目录
```

## 脚本说明

### init.sh
主初始化脚本，按顺序执行所有安装和配置步骤。

### check_environment.sh
检查系统环境是否满足要求：
- Ubuntu 22.04
- CUDA 12.6.x
- NVIDIA GPU 可用性

### install_base.sh
安装基础环境：
- Python 3.10 及依赖
- 系统工具和库
- vim 编辑器
- git, wget, curl 等工具
- 创建虚拟环境
- 创建数据目录结构

### install_comfyui.sh
安装和配置 ComfyUI：
- 克隆代码库
- 安装依赖
- 配置模型软链接

### install_sd_webui.sh
安装和配置 Stable Diffusion WebUI：
- 克隆代码库
- 安装依赖
- 配置模型软链接

### start.sh
配置服务启动：
- 复制 supervisor 配置文件
- 设置日志目录
- 配置服务自动启动

## 使用方法

1. 确保系统满足要求：
```bash
# 检查 CUDA 版本
nvcc --version
# 检查 GPU 状态
nvidia-smi
```

2. 克隆仓库：
```bash
git clone <repository_url>
cd <repository_name>
```

3. 运行安装脚本：
```bash
chmod +x init.sh
./init.sh
```

4. 检查服务状态：
```bash
supervisorctl status
```

## 服务管理

使用 supervisor 管理服务：
```bash
# 查看所有服务状态
supervisorctl status

# 启动所有服务
supervisorctl start all

# 停止所有服务
supervisorctl stop all

# 重启特定服务
supervisorctl restart comfyui
supervisorctl restart sd-webui
```

## 访问服务

服务通过 Nginx 代理，只允许白名单 IP 访问：

- ComfyUI: `http://<your-server>:10066`
- Stable Diffusion WebUI Forge: `http://<your-server>:10067`

### IP 白名单配置

编辑 `config/nginx/nginx.conf` 文件中的 geo 块来配置允许访问的 IP：

```nginx
geo $whitelist {
    default 0;        # 默认拒绝所有 IP
    127.0.0.1    1;  # 允许本地访问
    192.168.55.0/24 1;  # 允许特定网段
    # 在这里添加其他允许的 IP 或网段
}
```

### 安全特性

1. IP 白名单控制
   - 默认拒绝所有 IP 访问
   - 只允许白名单中的 IP 或网段访问
   - 未授权访问将返回 403 错误

2. 访问限制
   - 禁止直��访问根目录
   - 只允许访问 /comfyui/ 和 /sd/ 路径
   - 其他所有请求将返回 404 错误

3. 代理保护
   - 支持 WebSocket 连接
   - 设置了真实 IP 获取
   - 添加了必要的安全头部

修改配置后重新加载 Nginx：
```bash
nginx -t          # 检查配置
nginx -s reload   # 重新加载配置
```

## 注意事项

1. 所有脚本需要 root 权限运行
2. 确保有足够的磁盘空间用于模型存储
3. 建议使用 SSD 存储以提高性能
4. 定期备份重要的模型和配置文件

## 故障排除

1. 如果环境检查失败：
   - 确认 Ubuntu 版本是否为 22.04
   - 检查 CUDA 版本是否为 12.6.x
   - 验证 NVIDIA 驱动是否正确安装

2. 如果服务启动失败：
   - 检查日志文件：\`/var/log/supervisor/\`
   - 确认 Python 虚拟环境是否正确激活
   - 验证模型目录权限是否正确

3. 如果模型加载失败：
   - 检查模型文件是否存在
   - 确认软链接是否正确创建
   - 验证模型文件格式是否正确 