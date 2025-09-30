#!/bin/bash

# 跨平台配置脚本
# 支持 Windows (Git Bash/WSL), macOS, Linux

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
BASE_URL="https://claudecc.top"
API_KEY=""

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 提示输入函数
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            input="$default"
        fi
    else
        read -p "$prompt: " input
    fi

    eval "$var_name=\"$input\""
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_info "检测到 Linux 系统"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_info "检测到 macOS 系统"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
        print_info "检测到 Windows 系统"
    else
        OS="unknown"
        print_error "未知的操作系统: $OSTYPE"
        exit 1
    fi
}

# 获取配置目录
get_config_dir() {
    case "$OS" in
        windows)
            CONFIG_DIR="$USERPROFILE/AppData/Roaming"
            ;;
        macos|linux)
            CONFIG_DIR="$HOME/.config"
            ;;
        *)
            CONFIG_DIR="$HOME"
            ;;
    esac
    print_info "配置目录: $CONFIG_DIR"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$HOME/.local/bin"
    print_info "创建必要的目录"
}

# 备份文件
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.bak"
        print_info "备份文件: $1 -> $1.bak"
    fi
}

# 检测命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检测Node.js
check_nodejs() {
    if command_exists node; then
        local node_version=$(node --version 2>/dev/null)
        print_info "Node.js 已安装，版本：$node_version"
        return 0
    else
        print_warn "Node.js 未安装"
        return 1
    fi
}

# 检测Claude Code
check_claude_code() {
    if command_exists claude; then
        local claude_version=$(claude --version 2>/dev/null | head -n 1)
        print_info "Claude Code 已安装，版本：$claude_version"
        return 0
    else
        print_warn "Claude Code 未安装"
        return 1
    fi
}

# 安装Node.js (Windows)
install_nodejs_windows() {
    print_step "安装 Node.js..."

    local installer_used=false

    # 检测包管理器
    if command_exists choco; then
        print_info "检测到 Chocolatey，使用 choco 安装 Node.js..."
        choco install nodejs -y && installer_used=true
    elif command_exists scoop; then
        print_info "检测到 Scoop，使用 scoop 安装 Node.js..."
        scoop install nodejs && installer_used=true
    elif command_exists winget; then
        print_info "检测到 WinGet，使用 winget 安装 Node.js..."
        winget install OpenJS.NodeJS.LTS && installer_used=true
    else
        print_warn "未检测到包管理器（Chocolatey/Scoop/WinGet）"
        print_info "请手动下载安装 Node.js："
        print_info "访问 https://nodejs.org/ 下载 LTS 版本"
        print_info ""
        read -p "安装完成后按回车继续..."
    fi

    if check_nodejs; then
        return 0
    fi

    if [ "$installer_used" = true ]; then
        print_error "包管理器安装后仍未检测到 Node.js，请检查安装日志或手动安装"
    else
        print_error "Node.js 安装失败或未检测到"
    fi
    return 1
}

# 安装Claude Code
install_claude_code() {
    print_step "安装 Claude Code..."

    if command_exists npm; then
        print_info "使用 npm 安装 Claude Code..."
        npm install -g @anthropic-ai/claude-code

        # 验证安装
        if check_claude_code; then
            print_info "Claude Code 安装成功"
            return 0
        else
            print_error "Claude Code 安装失败"
            return 1
        fi
    else
        print_error "npm 未找到，请先安装 Node.js"
        return 1
    fi
}

# 设置Windows环境变量 (PowerShell)
set_windows_env_powershell() {
    local var_name="$1"
    local var_value="$2"
    local scope="${3:-User}"  # 默认用户级

    # 生成PowerShell命令
    local ps_cmd="[System.Environment]::SetEnvironmentVariable('$var_name', '$var_value', [System.EnvironmentVariableTarget]::$scope)"

    # 执行PowerShell命令
    if command_exists powershell; then
        powershell -Command "$ps_cmd" 2>/dev/null
        return $?
    elif command_exists pwsh; then
        pwsh -Command "$ps_cmd" 2>/dev/null
        return $?
    else
        return 1
    fi
}

# 配置Claude Code环境变量
configure_claude_code_env() {
    print_step "配置 Claude Code 环境变量..."

    # 获取API密钥
    if [ -z "$API_KEY" ]; then
        print_warn "请输入你的 API 密钥（格式: cr_xxxxxxxxxx）"
        prompt_input "API密钥" API_KEY ""

        if [ -z "$API_KEY" ]; then
            print_error "API密钥不能为空"
            return 1
        fi
    fi

    # 设置环境变量
    print_info "设置 ANTHROPIC_BASE_URL = $BASE_URL/api"
    print_info "设置 ANTHROPIC_AUTH_TOKEN = $API_KEY"

    if [ "$OS" == "windows" ]; then
        # Windows 永久设置
        set_windows_env_powershell "ANTHROPIC_BASE_URL" "$BASE_URL/api"
        set_windows_env_powershell "ANTHROPIC_AUTH_TOKEN" "$API_KEY"

        # 临时设置（当前会话）
        export ANTHROPIC_BASE_URL="$BASE_URL/api"
        export ANTHROPIC_AUTH_TOKEN="$API_KEY"

        print_info "环境变量已设置（需要重新打开终端生效）"
    fi

    return 0
}

# 配置Gemini环境变量
configure_gemini_env() {
    print_step "配置 Gemini CLI 环境变量..."

    print_info "设置 CODE_ASSIST_ENDPOINT = $BASE_URL/gemini"
    print_info "设置 GOOGLE_CLOUD_ACCESS_TOKEN = $API_KEY"
    print_info "设置 GOOGLE_GENAI_USE_GCA = true"

    if [ "$OS" == "windows" ]; then
        set_windows_env_powershell "CODE_ASSIST_ENDPOINT" "$BASE_URL/gemini"
        set_windows_env_powershell "GOOGLE_CLOUD_ACCESS_TOKEN" "$API_KEY"
        set_windows_env_powershell "GOOGLE_GENAI_USE_GCA" "true"

        # 临时设置
        export CODE_ASSIST_ENDPOINT="$BASE_URL/gemini"
        export GOOGLE_CLOUD_ACCESS_TOKEN="$API_KEY"
        export GOOGLE_GENAI_USE_GCA="true"

        print_info "Gemini 环境变量已设置"
    fi

    return 0
}

# 配置Codex
configure_codex() {
    print_step "配置 Codex..."

    local codex_dir="$HOME/.codex"
    local config_file="$codex_dir/config.toml"
    local auth_file="$codex_dir/auth.json"
    mkdir -p "$codex_dir"

    # 备份旧配置
    backup_file "$config_file"
    backup_file "$auth_file"

    # 创建config.toml
    cat > "$config_file" <<EOF
model_provider = "crs"
model = "gpt-5-codex"
model_reasoning_effort = "high"
disable_response_storage = true
preferred_auth_method = "apikey"

[model_providers.crs]
name = "crs"
base_url = "$BASE_URL/openai"
wire_api = "responses"
EOF

    print_info "已创建 $config_file"

    # 创建auth.json
    cat > "$auth_file" <<EOF
{
    "OPENAI_API_KEY": "$API_KEY"
}
EOF

    print_info "已创建 $auth_file"

    return 0
}

# 配置VSCode Claude插件
configure_vscode_claude() {
    print_step "配置 VSCode Claude 插件..."

    local claude_dir="$HOME/.claude"
    local config_file="$claude_dir/config.json"
    mkdir -p "$claude_dir"

    # 备份旧配置
    backup_file "$config_file"

    # 创建config.json
    cat > "$config_file" <<EOF
{
  "primaryApiKey": "crs"
}
EOF

    print_info "已创建 $config_file"

    return 0
}

# Windows 配置
configure_windows() {
    print_info "开始 Windows 配置..."

    local node_ready=false

    # 1. 检测和安装Node.js
    if check_nodejs; then
        node_ready=true
    else
        read -p "是否自动安装 Node.js? [Y/n]: " install_node
        if [[ "$install_node" != "n" && "$install_node" != "N" ]]; then
            if install_nodejs_windows && check_nodejs; then
                node_ready=true
            else
                print_error "Node.js 安装失败，请手动安装后重试"
                return 1
            fi
        else
            print_warn "跳过 Node.js 安装，后续步骤中将不会自动安装 Claude Code"
        fi
    fi

    if [ "$node_ready" != true ]; then
        print_warn "当前未检测到 Node.js，建议安装后再运行此脚本"
    fi

    # 2. 检测和安装Claude Code
    if [ "$node_ready" = true ] && ! check_claude_code; then
        read -p "是否自动安装 Claude Code? [Y/n]: " install_claude
        if [[ "$install_claude" != "n" && "$install_claude" != "N" ]]; then
            if ! install_claude_code; then
                print_error "Claude Code 安装失败"
                return 1
            fi
        else
            print_warn "跳过 Claude Code 安装"
        fi
    elif [ "$node_ready" != true ]; then
        print_warn "跳过 Claude Code 自动安装（未检测到 Node.js）"
    fi

    # 3. 配置环境变量
    print_step "选择要配置的工具："
    echo "1) Claude Code"
    echo "2) Gemini CLI"
    echo "3) Codex"
    echo "4) VSCode Claude 插件"
    echo "5) 全部配置"
    echo "0) 跳过配置"

    read -p "请选择 [1-5,0]: " choice

    case $choice in
        1)
            configure_claude_code_env
            ;;
        2)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_gemini_env
            ;;
        3)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_codex
            ;;
        4)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_vscode_claude
            ;;
        5)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_claude_code_env
            configure_gemini_env
            configure_codex
            configure_vscode_claude
            ;;
        0)
            print_info "跳过环境变量配置"
            ;;
        *)
            print_warn "无效选择"
            ;;
    esac

    print_info "Windows 配置完成"
}

# 检测shell类型
detect_shell() {
    local shell_name=$(basename "$SHELL")
    if [[ "$shell_name" == "zsh" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$shell_name" == "bash" ]]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    else
        SHELL_CONFIG="$HOME/.profile"
    fi
    print_info "检测到 shell: $shell_name, 配置文件: $SHELL_CONFIG"
}

# 检测Homebrew
check_homebrew() {
    if command_exists brew; then
        print_info "Homebrew 已安装"
        return 0
    else
        print_warn "Homebrew 未安装"
        return 1
    fi
}

# 安装Homebrew
install_homebrew() {
    print_step "安装 Homebrew..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 添加Homebrew到PATH
    if [[ -d "/opt/homebrew" ]]; then
        # Apple Silicon
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_CONFIG"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin/brew" ]]; then
        # Intel
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$SHELL_CONFIG"
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_info "已在 $SHELL_CONFIG 中写入 Homebrew 初始化命令，重新打开终端可自动生效"

    if check_homebrew; then
        print_info "Homebrew 安装成功"
        return 0
    else
        print_error "Homebrew 安装失败"
        return 1
    fi
}

# 安装Node.js (macOS)
install_nodejs_macos() {
    print_step "安装 Node.js..."

    if check_homebrew; then
        print_info "使用 Homebrew 安装 Node.js..."
        brew update
        brew install node

        if check_nodejs; then
            print_info "Node.js 安装成功"
            return 0
        else
            print_error "Node.js 安装失败"
            return 1
        fi
    else
        print_warn "Homebrew 未安装，尝试官网下载方式"
        print_info "请访问 https://nodejs.org/ 下载 macOS 版本的 LTS"
        print_info "下载 .pkg 文件并双击安装"
        read -p "安装完成后按回车继续..."

        if check_nodejs; then
            print_info "Node.js 安装成功"
            return 0
        else
            print_error "Node.js 安装失败或未检测到"
            return 1
        fi
    fi
}

# 配置macOS环境变量
configure_macos_env() {
    local var_name="$1"
    local var_value="$2"

    # 检查变量是否已存在
    if grep -q "export $var_name=" "$SHELL_CONFIG" 2>/dev/null; then
        # 更新现有变量
        sed -i '' "s|export $var_name=.*|export $var_name=\"$var_value\"|" "$SHELL_CONFIG"
        print_info "更新 $var_name 在 $SHELL_CONFIG"
    else
        # 添加新变量
        echo "export $var_name=\"$var_value\"" >> "$SHELL_CONFIG"
        print_info "添加 $var_name 到 $SHELL_CONFIG"
    fi

    # 立即生效
    export "$var_name=$var_value"
}

# 配置Claude Code环境变量 (macOS)
configure_claude_code_env_macos() {
    print_step "配置 Claude Code 环境变量..."

    # 获取API密钥
    if [ -z "$API_KEY" ]; then
        print_warn "请输入你的 API 密钥（格式: cr_xxxxxxxxxx）"
        prompt_input "API密钥" API_KEY ""

        if [ -z "$API_KEY" ]; then
            print_error "API密钥不能为空"
            return 1
        fi
    fi

    # 设置环境变量
    print_info "设置 ANTHROPIC_BASE_URL = $BASE_URL/api"
    print_info "设置 ANTHROPIC_AUTH_TOKEN = $API_KEY"

    configure_macos_env "ANTHROPIC_BASE_URL" "$BASE_URL/api"
    configure_macos_env "ANTHROPIC_AUTH_TOKEN" "$API_KEY"

    print_info "环境变量已设置到 $SHELL_CONFIG"
    print_info "执行 'source $SHELL_CONFIG' 或重新打开终端使配置生效"

    return 0
}

# 配置Gemini环境变量 (macOS)
configure_gemini_env_macos() {
    print_step "配置 Gemini CLI 环境变量..."

    print_info "设置 CODE_ASSIST_ENDPOINT = $BASE_URL/gemini"
    print_info "设置 GOOGLE_CLOUD_ACCESS_TOKEN = $API_KEY"
    print_info "设置 GOOGLE_GENAI_USE_GCA = true"

    configure_macos_env "CODE_ASSIST_ENDPOINT" "$BASE_URL/gemini"
    configure_macos_env "GOOGLE_CLOUD_ACCESS_TOKEN" "$API_KEY"
    configure_macos_env "GOOGLE_GENAI_USE_GCA" "true"

    print_info "Gemini 环境变量已设置"

    return 0
}

# macOS 配置
configure_macos() {
    print_info "开始 macOS 配置..."

    # 检测shell
    detect_shell

    local node_ready=false

    # 1. 检测Homebrew
    if ! check_homebrew; then
        read -p "是否安装 Homebrew（推荐）? [Y/n]: " install_brew
        if [[ "$install_brew" != "n" && "$install_brew" != "N" ]]; then
            install_homebrew
        fi
    fi

    # 2. 检测和安装Node.js
    if check_nodejs; then
        node_ready=true
    else
        read -p "是否自动安装 Node.js? [Y/n]: " install_node
        if [[ "$install_node" != "n" && "$install_node" != "N" ]]; then
            if install_nodejs_macos && check_nodejs; then
                node_ready=true
            else
                print_error "Node.js 安装失败，请手动安装后重试"
                return 1
            fi
        else
            print_warn "跳过 Node.js 安装，后续步骤中将不会自动安装 Claude Code"
        fi
    fi

    if [ "$node_ready" != true ]; then
        print_warn "当前未检测到 Node.js，建议安装后再运行此脚本"
    fi

    # 3. 检测和安装Claude Code
    if [ "$node_ready" = true ] && ! check_claude_code; then
        read -p "是否自动安装 Claude Code? [Y/n]: " install_claude
        if [[ "$install_claude" != "n" && "$install_claude" != "N" ]]; then
            # 检查是否需要sudo
            if ! install_claude_code; then
                print_warn "尝试使用 sudo 安装..."
                sudo npm install -g @anthropic-ai/claude-code
                if ! check_claude_code; then
                    print_error "Claude Code 安装失败"
                    return 1
                fi
            fi
        else
            print_warn "跳过 Claude Code 安装"
        fi
    elif [ "$node_ready" != true ]; then
        print_warn "跳过 Claude Code 自动安装（未检测到 Node.js）"
    fi

    # 4. 配置环境变量
    print_step "选择要配置的工具："
    echo "1) Claude Code"
    echo "2) Gemini CLI"
    echo "3) Codex"
    echo "4) VSCode Claude 插件"
    echo "5) 全部配置"
    echo "0) 跳过配置"

    read -p "请选择 [1-5,0]: " choice

    case $choice in
        1)
            configure_claude_code_env_macos
            ;;
        2)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_gemini_env_macos
            ;;
        3)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_codex
            ;;
        4)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_vscode_claude
            ;;
        5)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_claude_code_env_macos
            configure_gemini_env_macos
            configure_codex
            configure_vscode_claude
            ;;
        0)
            print_info "跳过环境变量配置"
            ;;
        *)
            print_warn "无效选择"
            ;;
    esac

    # 提示重新加载配置
    if [[ "$choice" != "0" ]]; then
        print_info "运行以下命令使配置立即生效："
        echo "  source $SHELL_CONFIG"
    fi

    print_info "macOS 配置完成"
}

# 检测Linux发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        print_info "检测到发行版: $NAME $VERSION"
    else
        DISTRO="unknown"
        print_warn "无法检测发行版"
    fi

    # 检测是否是WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        print_info "检测到WSL环境"
    else
        IS_WSL=false
    fi
}

# 检测Linux shell
detect_linux_shell() {
    local shell_name=$(basename "$SHELL")
    if [[ "$shell_name" == "bash" ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [[ "$shell_name" == "zsh" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    else
        SHELL_CONFIG="$HOME/.profile"
    fi
    print_info "检测到 shell: $shell_name, 配置文件: $SHELL_CONFIG"
}

# 安装Node.js (Linux)
install_nodejs_linux() {
    print_step "安装 Node.js..."

    case "$DISTRO" in
        ubuntu|debian)
            print_info "使用 NodeSource 仓库安装 Node.js..."
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs

            if check_nodejs; then
                print_info "Node.js 安装成功"
                return 0
            else
                # 尝试系统仓库
                print_warn "NodeSource 安装失败，尝试系统仓库..."
                sudo apt update
                sudo apt install -y nodejs npm

                if check_nodejs; then
                    print_info "Node.js 安装成功"
                    return 0
                else
                    print_error "Node.js 安装失败"
                    return 1
                fi
            fi
            ;;

        fedora|centos|rhel)
            print_info "使用 dnf 安装 Node.js..."
            sudo dnf install -y nodejs npm

            if check_nodejs; then
                print_info "Node.js 安装成功"
                return 0
            else
                print_error "Node.js 安装失败"
                return 1
            fi
            ;;

        arch|manjaro)
            print_info "使用 pacman 安装 Node.js..."
            sudo pacman -S nodejs npm

            if check_nodejs; then
                print_info "Node.js 安装成功"
                return 0
            else
                print_error "Node.js 安装失败"
                return 1
            fi
            ;;

        *)
            print_warn "不支持的发行版: $DISTRO"
            print_info "请手动安装 Node.js："
            print_info "访问 https://nodejs.org/ 下载安装"
            read -p "安装完成后按回车继续..."

            if check_nodejs; then
                print_info "Node.js 安装成功"
                return 0
            else
                print_error "Node.js 安装失败或未检测到"
                return 1
            fi
            ;;
    esac
}

# 配置Linux环境变量
configure_linux_env() {
    local var_name="$1"
    local var_value="$2"

    # 检查变量是否已存在
    if grep -q "export $var_name=" "$SHELL_CONFIG" 2>/dev/null; then
        # 更新现有变量
        sed -i "s|export $var_name=.*|export $var_name=\"$var_value\"|" "$SHELL_CONFIG"
        print_info "更新 $var_name 在 $SHELL_CONFIG"
    else
        # 添加新变量
        echo "export $var_name=\"$var_value\"" >> "$SHELL_CONFIG"
        print_info "添加 $var_name 到 $SHELL_CONFIG"
    fi

    # 立即生效
    export "$var_name=$var_value"
}

# 配置Claude Code环境变量 (Linux)
configure_claude_code_env_linux() {
    print_step "配置 Claude Code 环境变量..."

    # 获取API密钥
    if [ -z "$API_KEY" ]; then
        print_warn "请输入你的 API 密钥（格式: cr_xxxxxxxxxx）"
        prompt_input "API密钥" API_KEY ""

        if [ -z "$API_KEY" ]; then
            print_error "API密钥不能为空"
            return 1
        fi
    fi

    # 设置环境变量
    print_info "设置 ANTHROPIC_BASE_URL = $BASE_URL/api"
    print_info "设置 ANTHROPIC_AUTH_TOKEN = $API_KEY"

    configure_linux_env "ANTHROPIC_BASE_URL" "$BASE_URL/api"
    configure_linux_env "ANTHROPIC_AUTH_TOKEN" "$API_KEY"

    print_info "环境变量已设置到 $SHELL_CONFIG"
    print_info "执行 'source $SHELL_CONFIG' 或重新打开终端使配置生效"

    return 0
}

# 配置Gemini环境变量 (Linux)
configure_gemini_env_linux() {
    print_step "配置 Gemini CLI 环境变量..."

    print_info "设置 CODE_ASSIST_ENDPOINT = $BASE_URL/gemini"
    print_info "设置 GOOGLE_CLOUD_ACCESS_TOKEN = $API_KEY"
    print_info "设置 GOOGLE_GENAI_USE_GCA = true"

    configure_linux_env "CODE_ASSIST_ENDPOINT" "$BASE_URL/gemini"
    configure_linux_env "GOOGLE_CLOUD_ACCESS_TOKEN" "$API_KEY"
    configure_linux_env "GOOGLE_GENAI_USE_GCA" "true"

    print_info "Gemini 环境变量已设置"

    return 0
}

# 修复npm权限问题
fix_npm_permissions() {
    print_step "检查npm权限..."

    # 创建npm全局目录
    mkdir -p ~/.npm-global

    # 设置npm全局目录
    npm config set prefix '~/.npm-global'

    # 添加到PATH
    if ! grep -q "export PATH=~/.npm-global/bin:\$PATH" "$SHELL_CONFIG"; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> "$SHELL_CONFIG"
        export PATH=~/.npm-global/bin:$PATH
        print_info "已配置npm全局目录到PATH"
    fi
}

# Linux 配置
configure_linux() {
    print_info "开始 Linux/WSL 配置..."

    # 检测发行版
    detect_distro

    # 检测shell
    detect_linux_shell

    local node_ready=false

    # 1. 检测和安装Node.js
    if check_nodejs; then
        node_ready=true
    else
        read -p "是否自动安装 Node.js? [Y/n]: " install_node
        if [[ "$install_node" != "n" && "$install_node" != "N" ]]; then
            if install_nodejs_linux && check_nodejs; then
                node_ready=true
            else
                print_error "Node.js 安装失败，请手动安装后重试"
                return 1
            fi
        else
            print_warn "跳过 Node.js 安装，后续步骤中将不会自动安装 Claude Code"
        fi
    fi

    if [ "$node_ready" != true ]; then
        print_warn "当前未检测到 Node.js，建议安装后再运行此脚本"
    fi

    # 2. 修复npm权限（避免sudo）
    if [ "$node_ready" = true ]; then
        read -p "是否配置npm全局目录（避免使用sudo）? [Y/n]: " fix_npm
        if [[ "$fix_npm" != "n" && "$fix_npm" != "N" ]]; then
            fix_npm_permissions
        fi
    else
        print_warn "跳过 npm 全局目录配置（未检测到 Node.js）"
    fi

    # 3. 检测和安装Claude Code
    if [ "$node_ready" = true ] && ! check_claude_code; then
        read -p "是否自动安装 Claude Code? [Y/n]: " install_claude
        if [[ "$install_claude" != "n" && "$install_claude" != "N" ]]; then
            # 首次尝试不用sudo
            if ! install_claude_code; then
                print_warn "尝试使用 sudo 安装..."
                sudo npm install -g @anthropic-ai/claude-code
                if ! check_claude_code; then
                    print_error "Claude Code 安装失败"
                    return 1
                fi
            fi
        else
            print_warn "跳过 Claude Code 安装"
        fi
    elif [ "$node_ready" != true ]; then
        print_warn "跳过 Claude Code 自动安装（未检测到 Node.js）"
    fi

    # 4. 配置环境变量
    print_step "选择要配置的工具："
    echo "1) Claude Code"
    echo "2) Gemini CLI"
    echo "3) Codex"
    echo "4) VSCode Claude 插件"
    echo "5) 全部配置"
    echo "0) 跳过配置"

    read -p "请选择 [1-5,0]: " choice

    case $choice in
        1)
            configure_claude_code_env_linux
            ;;
        2)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_gemini_env_linux
            ;;
        3)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_codex
            ;;
        4)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_vscode_claude
            ;;
        5)
            if [ -z "$API_KEY" ]; then
                prompt_input "API密钥" API_KEY ""
            fi
            configure_claude_code_env_linux
            configure_gemini_env_linux
            configure_codex
            configure_vscode_claude
            ;;
        0)
            print_info "跳过环境变量配置"
            ;;
        *)
            print_warn "无效选择"
            ;;
    esac

    # 提示重新加载配置
    if [[ "$choice" != "0" ]]; then
        print_info "运行以下命令使配置立即生效："
        echo "  source $SHELL_CONFIG"
    fi

    # WSL特别提示
    if [ "$IS_WSL" = true ]; then
        print_info "WSL用户提示："
        print_info "- 确保Windows防火墙允许WSL访问网络"
        print_info "- 如果遇到网络问题，检查Windows代理设置"
    fi

    print_info "Linux/WSL 配置完成"
}

# 通用配置
configure_common() {
    print_info "开始通用配置..."

    # 在这里添加所有系统都需要的配置
    # 例如：配置 Git 全局设置
    # git config --global user.name "Your Name"
    # git config --global user.email "your@email.com"

    print_info "通用配置完成"
}

# 清除Windows环境变量
clean_windows_env() {
    local var_name="$1"

    # 使用PowerShell删除环境变量
    if command_exists powershell; then
        powershell -Command "[System.Environment]::SetEnvironmentVariable('$var_name', \$null, [System.EnvironmentVariableTarget]::User)" 2>/dev/null
        print_info "已删除环境变量: $var_name"
    elif command_exists pwsh; then
        pwsh -Command "[System.Environment]::SetEnvironmentVariable('$var_name', \$null, [System.EnvironmentVariableTarget]::User)" 2>/dev/null
        print_info "已删除环境变量: $var_name"
    fi

    # 清除当前会话
    unset "$var_name"
}

# 清除shell配置文件中的环境变量
clean_shell_env() {
    local var_name="$1"
    local config_file="$2"

    if [ -f "$config_file" ]; then
        # 创建备份
        cp "$config_file" "${config_file}.backup_$(date +%Y%m%d_%H%M%S)"

        # 删除包含该环境变量的行
        sed -i.tmp "/export $var_name=/d" "$config_file" 2>/dev/null || \
        sed -i '' "/export $var_name=/d" "$config_file" 2>/dev/null

        # 删除临时文件
        rm -f "${config_file}.tmp"

        print_info "已从 $config_file 中删除 $var_name"
    fi

    # 清除当前会话
    unset "$var_name"
}

# 清除Windows配置
clean_windows() {
    print_step "清除 Windows 配置..."

    # 清除Claude Code环境变量
    clean_windows_env "ANTHROPIC_BASE_URL"
    clean_windows_env "ANTHROPIC_AUTH_TOKEN"

    # 清除Gemini环境变量
    clean_windows_env "CODE_ASSIST_ENDPOINT"
    clean_windows_env "GOOGLE_CLOUD_ACCESS_TOKEN"
    clean_windows_env "GOOGLE_GENAI_USE_GCA"

    # 清除Codex配置文件
    if [ -d "$HOME/.codex" ]; then
        print_info "删除 Codex 配置目录..."
        rm -rf "$HOME/.codex"
    fi

    # 清除VSCode Claude配置文件
    if [ -d "$HOME/.claude" ]; then
        print_info "删除 VSCode Claude 配置目录..."
        rm -rf "$HOME/.claude"
    fi

    print_info "Windows 配置清除完成"
}

# 清除macOS配置
clean_macos() {
    print_step "清除 macOS 配置..."

    # 检测shell配置文件
    detect_shell

    # 清除Claude Code环境变量
    clean_shell_env "ANTHROPIC_BASE_URL" "$SHELL_CONFIG"
    clean_shell_env "ANTHROPIC_AUTH_TOKEN" "$SHELL_CONFIG"

    # 清除Gemini环境变量
    clean_shell_env "CODE_ASSIST_ENDPOINT" "$SHELL_CONFIG"
    clean_shell_env "GOOGLE_CLOUD_ACCESS_TOKEN" "$SHELL_CONFIG"
    clean_shell_env "GOOGLE_GENAI_USE_GCA" "$SHELL_CONFIG"

    # 清除Codex配置文件
    if [ -d "$HOME/.codex" ]; then
        print_info "删除 Codex 配置目录..."
        rm -rf "$HOME/.codex"
    fi

    # 清除VSCode Claude配置文件
    if [ -d "$HOME/.claude" ]; then
        print_info "删除 VSCode Claude 配置目录..."
        rm -rf "$HOME/.claude"
    fi

    # 清除npm全局目录配置（如果存在）
    if grep -q "export PATH=~/.npm-global/bin:" "$SHELL_CONFIG" 2>/dev/null; then
        sed -i.tmp "/export PATH=~\/.npm-global\/bin:/d" "$SHELL_CONFIG" 2>/dev/null || \
        sed -i '' "/export PATH=~\/.npm-global\/bin:/d" "$SHELL_CONFIG" 2>/dev/null
        rm -f "${SHELL_CONFIG}.tmp"
        print_info "已清除npm全局目录配置"
    fi

    print_info "macOS 配置清除完成"
    print_info "执行 'source $SHELL_CONFIG' 使更改生效"
}

# 清除Linux配置
clean_linux() {
    print_step "清除 Linux/WSL 配置..."

    # 检测shell配置文件
    detect_linux_shell

    # 清除Claude Code环境变量
    clean_shell_env "ANTHROPIC_BASE_URL" "$SHELL_CONFIG"
    clean_shell_env "ANTHROPIC_AUTH_TOKEN" "$SHELL_CONFIG"

    # 清除Gemini环境变量
    clean_shell_env "CODE_ASSIST_ENDPOINT" "$SHELL_CONFIG"
    clean_shell_env "GOOGLE_CLOUD_ACCESS_TOKEN" "$SHELL_CONFIG"
    clean_shell_env "GOOGLE_GENAI_USE_GCA" "$SHELL_CONFIG"

    # 清除Codex配置文件
    if [ -d "$HOME/.codex" ]; then
        print_info "删除 Codex 配置目录..."
        rm -rf "$HOME/.codex"
    fi

    # 清除VSCode Claude配置文件
    if [ -d "$HOME/.claude" ]; then
        print_info "删除 VSCode Claude 配置目录..."
        rm -rf "$HOME/.claude"
    fi

    # 清除npm全局目录配置（如果存在）
    if grep -q "export PATH=~/.npm-global/bin:" "$SHELL_CONFIG" 2>/dev/null; then
        sed -i.tmp "/export PATH=~\/.npm-global\/bin:/d" "$SHELL_CONFIG" 2>/dev/null || \
        sed -i '' "/export PATH=~\/.npm-global\/bin:/d" "$SHELL_CONFIG" 2>/dev/null
        rm -f "${SHELL_CONFIG}.tmp"
        print_info "已清除npm全局目录配置"
    fi

    print_info "Linux/WSL 配置清除完成"
    print_info "执行 'source $SHELL_CONFIG' 使更改生效"
}

# 清除所有配置
clean_all_configs() {
    print_warn "============================================"
    print_warn "              警告！"
    print_warn "============================================"
    print_warn "您即将清除脚本所配置的所有环境变量和配置文件"
    print_warn "这将删除："
    print_warn "- Claude Code 环境变量 (ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN)"
    print_warn "- Gemini CLI 环境变量 (CODE_ASSIST_ENDPOINT, GOOGLE_CLOUD_ACCESS_TOKEN, GOOGLE_GENAI_USE_GCA)"
    print_warn "- Codex 配置目录 (~/.codex)"
    print_warn "- VSCode Claude 插件配置目录 (~/.claude)"
    print_warn "- npm全局目录配置（如果有）"
    print_warn ""
    print_warn "注意：这不会卸载已安装的软件（Node.js, Claude Code等）"
    print_warn "============================================"

    read -p "确定要继续吗？请输入 'yes' 确认: " confirm

    if [[ "$confirm" != "yes" ]]; then
        print_info "已取消清除操作"
        return 1
    fi

    print_info "开始清除配置..."

    # 根据系统执行清除
    case "$OS" in
        windows)
            clean_windows
            ;;
        macos)
            clean_macos
            ;;
        linux)
            clean_linux
            ;;
    esac

    print_info "============================================"
    print_info "配置清除完成！"
    print_info "如需重新配置，请再次运行此脚本"
    print_info "============================================"
}

# 主菜单
show_menu() {
    echo "========================================"
    echo "         自动配置脚本"
    echo "========================================"
    echo "请选择操作："
    echo "1) 配置工具环境 (Claude V2.0)"
    echo "2) 清除所有配置"
    echo "0) 退出"
    echo ""
    read -p "请选择 [0-2]: " menu_choice

    # 处理空输入
    if [ -z "$menu_choice" ]; then
        menu_choice="1"  # 默认选择配置
    fi

    case $menu_choice in
        1)
            return 0  # 继续执行配置
            ;;
        2)
            clean_all_configs
            return 1  # 退出脚本
            ;;
        0)
            print_info "退出脚本"
            exit 0
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    # 检测系统
    detect_os

    # 获取配置目录
    get_config_dir

    # 显示菜单
    if ! show_menu; then
        exit 0
    fi

    echo "========================================"
    echo "         开始配置"
    echo "========================================"

    # 创建必要目录
    create_directories

    # 执行通用配置
    configure_common

    # 根据系统执行特定配置
    case "$OS" in
        windows)
            configure_windows
            ;;
        macos)
            configure_macos
            ;;
        linux)
            configure_linux
            ;;
    esac

    echo "========================================"
    print_info "所有配置完成！"
}

# 运行主函数
main "$@"
