#!/bin/bash

# 确保 PATH 包含 Drosera
export PATH=$PATH:/root/.drosera/bin

# 脚本保存路径
SCRIPT_PATH="$HOME/Drosera.sh"

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 权限运行此脚本 (sudo)"
    exit 1
fi

# 命令1：安装 Drosera 节点
function install_drosera_node() {
    # 更新系统包并安装依赖
    echo "正在更新系统包并安装依赖..."
    apt-get update && apt-get upgrade -y || { echo "系统包更新失败"; exit 1; }
    apt-get install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip || { echo "依赖安装失败"; exit 1; }
    echo "依赖安装完成"

    # 检查 jq 是否安装
    if ! command -v jq &> /dev/null; then
        echo "jq 未安装，正在安装..."
        apt-get install -y jq || { echo "jq 安装失败"; exit 1; }
        echo "jq 安装完成"
    else
        echo "jq 已安装，检查更新..."
        apt-get install -y jq
    fi

    # 检查 Docker 是否安装
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装..."
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io || { echo "Docker 安装失败"; exit 1; }
        echo "Docker 安装完成"
    else
        echo "Docker 已安装，检查更新..."
        apt-get install -y docker-ce docker-ce-cli containerd.io
    fi

    # 启动并启用 Docker 服务
    systemctl start docker || { echo "Docker 服务启动失败"; exit 1; }
    systemctl enable docker || { echo "Docker 服务启用失败"; exit 1; }

    # 检查 Docker Compose 是否安装
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose 未安装，正在安装最新版本..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        docker-compose --version || { echo "Docker Compose 安装失败"; exit 1; }
        echo "Docker Compose 安装完成"
    else
        echo "Docker Compose 已安装，检查更新..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    # 安装 Bun
    echo "正在安装 Bun..."
    echo "正在检查并安装 unzip..."
    if ! command -v unzip &> /dev/null; then
        apt-get install -y unzip || { echo "unzip 安装失败"; exit 1; }
        echo "unzip 安装完成"
    else
        echo "unzip 已安装"
    fi
    curl -fsSL https://bun.sh/install | bash || { echo "Bun 安装失败"; exit 1; }
    BUN_BIN="/root/.bun/bin/bun"
    if [ -f "$BUN_BIN" ]; then
        echo "Bun 安装完成"
        export PATH=$PATH:/root/.bun/bin
        echo 'export PATH=$PATH:/root/.bun/bin' >> /root/.bashrc
    else
        echo "Bun 安装失败，请检查网络或 https://bun.sh/install"
        exit 1
    fi

    # 安装 Foundry
    echo "正在安装 Foundry..."
    curl -L https://foundry.paradigm.xyz | bash || { echo "Foundry 安装失败"; exit 1; }
    if [ -f "/root/.foundry/bin/foundryup" ]; then
        /root/.foundry/bin/foundryup
        export PATH=$PATH:/root/.foundry/bin
        echo 'export PATH=$PATH:/root/.foundry/bin' >> /root/.bashrc
        forge --version || { echo "forge 未安装"; exit 1; }
        echo "Foundry 安装完成"
    else
        echo "Foundry 安装失败，请检查网络或 https://foundry.paradigm.xyz"
        exit 1
    fi

    # 安装 Drosera
    echo "正在安装 Drosera..."
    curl -L https://app.drosera.io/install | bash || { echo "Drosera 安装失败"; exit 1; }
    source /root/.bashrc
    export PATH=$PATH:/root/.drosera/bin
    echo 'export PATH=$PATH:/root/.drosera/bin' >> /root/.bashrc
    if command -v droseraup &> /dev/null; then
        droseraup || { echo "droseraup 执行失败"; exit 1; }
        echo "Drosera 安装完成"
    else
        echo "droseraup 命令未找到，Drosera 安装失败"
        exit 1
    fi

    # 检查 Drosera 二进制文件并验证版本
    DROsera_BIN="/root/.drosera/bin/drosera"
    if [ -f "$DROsera_BIN" ]; then
        echo "找到 Drosera，正在验证版本..."
        $DROsera_BIN --version || { echo "Drosera 版本检查失败"; exit 1; }
        echo "Drosera 版本检查成功"
    else
        echo "Drosera 未找到（$DROsera_BIN 不存在）"
        exit 1
    fi

    # 运行 droseraup（确保最新版本）
    if command -v droseraup &> /dev/null; then
        echo "正在运行 droseraup..."
        droseraup || { echo "droseraup 执行失败"; exit 1; }
    else
        echo "droseraup 命令未找到"
        exit 1
    fi

    # 创建 my-drosera-trap 目录并切换
    echo "创建 my-drosera-trap 目录并切换..."
    mkdir -p /root/my-drosera-trap && cd /root/my-drosera-trap || { echo "目录创建或切换失败"; exit 1; }

    # 配置 Git 用户信息
    echo "配置 Git 用户信息..."
    git config --global user.email "1" || { echo "Git 配置失败"; exit 1; }
    git config --global user.name "1" || { echo "Git 配置失败"; exit 1; }

    # 初始化 Foundry 模板
    echo "初始化 Foundry 模板..."
    forge init -t drosera-network/trap-foundry-template || { echo "Foundry 模板初始化失败"; exit 1; }
    echo "Foundry 模板初始化完成"

    # 执行 bun install
    echo "执行 bun install..."
    bun install || { echo "bun install 失败"; exit 1; }
    echo "bun install 完成"

    # 执行 forge build
    echo "执行 forge build..."
    forge build || { echo "forge build 失败"; exit 1; }
    echo "forge build 完成"

    # 提示用户确保 Holesky ETH 资金并输入 EVM 钱包私钥
    echo "请确保你的钱包地址在 Holesky 测试网上有足够的 ETH 用于交易。"
    echo "请输入 EVM 钱包私钥："
    read DROSERA_PRIVATE_KEY
    if [ -z "$DROSERA_PRIVATE_KEY" ]; then
        echo "错误：未提供私钥，drosera apply 将跳过"
    else
        echo "正在执行第一次 drosera apply..."
        DROSERA_PRIVATE_KEY="$DROSERA_PRIVATE_KEY" drosera apply || { echo "第一次 drosera apply 失败"; exit 1; }
        echo "第一次 drosera apply 完成"
    fi

    # 询问用户是否继续进行下一步
    echo "所有操作已完成，是否继续进行下一步（drosera dryrun、第二次 drosera apply、Drosera Operator 安装和注册、防火墙配置、检查并停止 drosera 服务、配置 Drosera-Network 仓库、启动 Docker Compose 服务）？（y/n）"
    read -r CONTINUE
    if [ "$CONTINUE" = "y" ] || [ "$CONTINUE" = "Y" ]; then
        echo "正在执行 drosera dryrun..."
        cd /root/my-drosera-trap || { echo "切换到 my-drosera-trap 失败"; exit 1; }
        drosera dryrun || { echo "drosera dryrun 失败"; exit 1; }
        echo "drosera dryrun 完成"

        # 提示用户输入 EVM 钱包地址并修改 drosera.toml
        echo "请输入 EVM 钱包地址（用于 drosera.toml 的 whitelist）："
        read WALLET_ADDRESS
        if [ -z "$WALLET_ADDRESS" ]; then
            echo "错误：未提供钱包地址"
            exit 1
        fi

        # 检查 drosera.toml 是否存在
        DROsera_TOML="/root/my-drosera-trap/drosera.toml"
        if [ -f "$DROsera_TOML" ]; then
            # 检查是否包含 whitelist 字段（宽松匹配）
            if grep -q "[[:space:]]*whitelist[[:space:]]*=[[:space:]]*\[\]" "$DROsera_TOML"; then
                sed -i "s/[[:space:]]*whitelist[[:space:]]*=[[:space:]]*\[\]/whitelist = [\"$WALLET_ADDRESS\"]/g" "$DROsera_TOML"
                echo "已更新 drosera.toml 的 whitelist 为 [\"$WALLET_ADDRESS\"]"
            else
                echo "未找到空的 whitelist = []，尝试追加..."
                echo "whitelist = [\"$WALLET_ADDRESS\"]" >> "$DROsera_TOML"
                echo "已添加 whitelist = [\"$WALLET_ADDRESS\"] 到 drosera.toml"
            fi
            # 添加 private_trap = true（避免重复添加）
            if ! grepiedad -q "private_trap = true" "$DROsera_TOML"; then
                echo "private_trap = true" >> "$DROsera_TOML"
                echo "已添加 private_trap = true 到 drosera.toml"
            fi
        else
            echo "错误：drosera.toml 未找到（$DROsera_TOML）"
            exit 1
        fi

        # 执行第二次 drosera apply
        if [ -z "$DROSERA_PRIVATE_KEY" ]; then
            echo "错误：未提供私钥，第二次 drosera apply 将跳过"
        else
            echo "第二次 drosera apply 将复用第一次输入的私钥：${DROSERA_PRIVATE_KEY:0:10}..."
            echo "正在执行第二次 drosera apply..."
            cd /root/my-drosera-trap || { echo "切换到 my-drosera-trap 失败"; exit 1; }
            # 尝试执行 drosera apply，最多重试 3 次，每次等待 300 秒
            MAX_RETRIES=3
            RETRY_COUNT=0
            until DROSERA_PRIVATE_KEY="$DROSERA_PRIVATE_KEY" drosera apply; do
                RETRY_COUNT=$((RETRY_COUNT + 1))
                if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
                    echo "第二次 drosera apply 失败，已达到最大重试次数 ($MAX_RETRIES)。请稍后手动运行 'DROSERA_PRIVATE_KEY=your_private_key drosera apply' 或检查冷却期。"
                    exit 1
                fi
                echo "第二次 drosera apply 失败，可能由于冷却期未结束。等待 300 秒后重试（第 $RETRY_COUNT 次）..."
                sleep 300
            done
            echo "第二次 drosera apply 完成"
        fi

        # 切换到主目录并安装 Drosera Operator
        echo "切换到主目录并安装 Drosera Operator..."
        cd ~ || { echo "切换到主目录失败"; exit 1; }
        curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
        tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz || { echo "Drosera Operator 解压失败"; exit 1; }
        rm -f drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz || { echo "删除 Drosera Operator 压缩包失败"; exit 1; }
        echo "Drosera Operator 安装完成，压缩包已删除"
        echo "Drosera Operator 安装完成"

        # 测试 Drosera Operator
        echo "测试 Drosera Operator 是否正常运行..."
        ./drosera-operator --version || { echo "Drosera Operator 版本检查失败"; exit 1; }
        echo "Drosera Operator 版本检查成功"

        # 复制 Drosera Operator 到 /usr/bin
        echo "复制 Drosera Operator 到 /usr/bin..."
        cp drosera-operator /usr/bin || { echo "复制 Drosera Operator 失败"; exit 1; }
        echo "Drosera Operator 已成功复制到 /usr/bin"

        # 拉取 Drosera Operator 的最新 Docker 镜像
        echo "正在拉取 Drosera Operator 的最新 Docker 镜像..."
        docker pull ghcr.io/drosera-network/drosera-operator:latest || { echo "Drosera Operator Docker 镜像拉取失败"; exit 1; }
        echo "Drosera Operator Docker 镜像拉取完成"

        # 运行 Drosera Operator 注册
        if [ -z "$DROSERA_PRIVATE_KEY" ]; then
            echo "错误：未提供私钥，drosera-operator register 将跳过"
        else
            echo "正在运行 Drosera Operator 注册..."
            drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key "$DROSERA_PRIVATE_KEY" || { echo "Drosera Operator 注册失败"; exit 1; }
            echo "Drosera Operator 注册完成"
        fi

        # 检查并停止 drosera 服务
        echo "正在检查 drosera 服务状态..."
        if systemctl is-active --quiet drosera; then
            echo "drosera 服务正在运行，正在停止并禁用..."
            systemctl stop drosera
            systemctl disable drosera
            echo "drosera 服务已停止并禁用"
        else
            echo "drosera 服务未运行，无需停止"
        fi

        # 拉取 Drosera-Network 仓库
        echo "正在拉取 Drosera-Network 仓库..."
        git clone https://github.com/sdohuajia/Drosera-Network.git || { echo "Drosera-Network 仓库拉取失败"; exit 1; }
        echo "Drosera-Network 仓库拉取完成"

        # 获取机器核心数
        AVAILABLE_CORES=$(nproc)
        echo "检测到机器有 $AVAILABLE_CORES 个 CPU 核心"

        # 输入 CPU 核心数
        echo "请输入要使用的 CPU 核心数（例如 4 表示使用核心 1-4，$AVAILABLE_CORES 表示核心 1-$AVAILABLE_CORES，输入 0 表示不限制）："
        read CPU_CORES

        # 验证输入
        if [[ ! "$CPU_CORES" =~ ^[0-9]+$ ]]; then
            echo "错误：请输入一个正整数或 0（0 表示不限制）"
            exit 1
        elif [ "$CPU_CORES" != "0" ] && [ "$CPU_CORES" -gt "$AVAILABLE_CORES" ]; then
            echo "错误：输入的核心数 ($CPU_CORES) 超过系统可用核心数 ($AVAILABLE_CORES)"
            exit 1
        elif [ "$CPU_CORES" != "0" ] && [ "$CPU_CORES" -lt 1 ]; then
            echo "错误：核心数必须为正整数或 0"
            exit 1
        fi

        # 切换到 Drosera-Network 目录并复制 .env 文件
        echo "切换到 Drosera-Network 目录并复制 .env 文件..."
        cd Drosera-Network || { echo "切换到 Drosera-Network 失败"; exit 1; }
        cp .env.example .env || { echo ".env 文件复制失败"; exit 1; }
        echo ".env 文件复制完成"

        # 自动获取服务器公网 IP 并写入 .env
        echo "正在自动获取服务器公网 IP 地址..."
        SERVER_IP=$(curl -s https://api.ipify.org)
        if [ -z "$SERVER_IP" ]; then
            echo "错误：无法获取服务器公网 IP，请检查网络连接"
            exit 1
        fi
        sed -i "s/VPS_IP=.*/VPS_IP=$SERVER_IP/" .env
        echo "已更新 .env 的 VPS_IP 为 $SERVER_IP"

        # 写入 ETH_PRIVATE_KEY 到 .env
        if [ -z "$DROSERA_PRIVATE_KEY" ]; then
            echo "错误：未提供私钥，ETH_PRIVATE_KEY 配置将跳过"
        else
            sed -i "s/ETH_PRIVATE_KEY=.*/ETH_PRIVATE_KEY=$DROSERA_PRIVATE_KEY/" .env
            echo "已更新 .env 的 ETH_PRIVATE_KEY"
        fi

        # 修改 docker-compose.yaml 以动态设置 CPU 核心绑定
        echo "正在配置 docker-compose.yaml 以绑定 CPU 核心..."
        if [ ! -f "docker-compose.yaml" ]; then
            echo "错误：未找到 docker-compose.yaml 文件，请确保 Drosera-Network 仓库包含该文件"
            exit 1
        fi
        if [ "$CPU_CORES" != "0" ]; then
            # 计算 cpuset 值（例如输入 4 -> cpuset: "1-4"）
            CPUSET="1-$CPU_CORES"
            # 检查是否已有 cpuset 配置，动态添加或修改
            if grep -A 10 "drosera:" docker-compose.yaml | grep -q "cpuset:"; then
                sed -i "/drosera:/,/^[^ ]/ s/cpuset: .*/cpuset: \"$CPUSET\"/" docker-compose.yaml
            else
                # 在 drosera 服务下添加 cpuset 配置（缩进 2 空格）
                sed -i "/drosera:/a\  cpuset: \"$CPUSET\"" docker-compose.yaml
            fi
            echo "已设置 drosera 服务绑定 CPU 核心 $CPUSET"
        else
            # 如果输入 0，移除 cpuset 配置（若存在）
            if grep -A 10 "drosera:" docker-compose.yaml | grep -q "cpuset:"; then
                sed -i "/drosera:/,/^[^ ]/ {/^  cpuset: .*/d}" docker-compose.yaml
                echo "已移除 drosera 服务的 CPU 核心绑定"
            else
                echo "未设置 CPU 核心绑定，将使用默认配置"
            fi
        fi

        # 启动 Docker Compose 服务
        echo "正在启动 Docker Compose 服务..."
        if command -v docker-compose &> /dev/null; then
            echo "使用 docker-compose 启动服务..."
            docker-compose -f docker-compose.yaml up -d || { echo "Docker Compose 服务启动失败"; exit 1; }
        elif docker compose version &> /dev/null; then
            echo "使用 docker compose 启动服务..."
            docker compose -f docker-compose.yaml up -d || { echo "Docker Compose 服务启动失败"; exit 1; }
        else
            echo "错误：未找到 docker-compose 或 docker compose 命令"
            exit 1
        fi
        echo "Docker Compose 服务启动完成"

        # 清理私钥变量
        unset DROSERA_PRIVATE_KEY
        echo "私钥变量已清理"
    else
        echo "用户选择退出，安装 Drosera 节点结束。"
        return
    fi

    echo "Drosera 节点安装和配置完成！"
    echo "按任意键返回主菜单..."
    read -r
}

# 命令2：查看日志
function view_logs() {
    echo "正在查看 drosera-node 日志..."
    docker logs -f drosera-node
    echo "日志查看结束，按任意键返回主菜单..."
    read -r
}

# 命令3：重启 Operators
function restart_operators() {
    echo "正在重启 Operators..."
    cd ~/Drosera-Network || { echo "切换到 Drosera-Network 目录失败"; exit 1; }
    if command -v docker-compose &> /dev/null; then
        echo "使用 docker-compose 停止服务..."
        docker-compose -f docker-compose.yaml down || { echo "Docker Compose 服务停止失败"; exit 1; }
        echo "使用 docker-compose 启动服务..."
        docker-compose -f docker-compose.yaml up -d || { echo "Docker Compose 服务启动失败"; exit 1; }
    elif docker compose version &> /dev/null; then
        echo "使用 docker compose 停止服务..."
        docker compose -f docker-compose.yaml down || { echo "Docker Compose 服务停止失败"; exit 1; }
        echo "使用 docker compose 启动服务..."
        docker compose -f docker-compose.yaml up -d || { echo "Docker Compose 服务启动失败"; exit 1; }
    else
        echo "错误：未找到 docker-compose 或 docker compose 命令"
        exit 1
    fi
    echo "Operators 重启完成"
    echo "按任意键返回主菜单..."
    read -r
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装 Drosera 节点"
        echo "2. 查看日志"
        echo "3. 重启 Operators"
        echo -n "请输入选项 (1-3): "
        read choice
        case $choice in
            1) install_drosera_node ;;
            2) view_logs ;;
            3) restart_operators ;;
            *) echo "无效选项，请输入 1、2 或 3" ; sleep 2 ;;
        esac
    done
}

# 启动主菜单
main_menu
