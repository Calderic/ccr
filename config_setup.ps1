# Windows PowerShell 配置脚本
# 支持 Claude Code, Gemini CLI, Codex 自动配置

param(
    [string]$BaseUrl = "https://claudecc.top",
    [string]$ApiKey = "",
    [switch]$Clean,
    [switch]$Help
)

# 颜色定义
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Gray = "Gray"
}

# 打印函数
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor $Colors.Blue
}

# 提示输入函数
function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    if ($Default) {
        $input = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($input)) {
            return $Default
        }
        return $input
    } else {
        return Read-Host $Prompt
    }
}

# 检查命令是否存在
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# 检查Node.js
function Test-NodeJS {
    if (Test-Command "node") {
        try {
            $version = node --version 2>$null
            Write-Info "Node.js 已安装，版本：$version"
            return $true
        } catch {
            Write-Warning "Node.js 命令存在但无法获取版本"
            return $false
        }
    } else {
        Write-Warning "Node.js 未安装"
        return $false
    }
}

# 检查Claude Code
function Test-ClaudeCode {
    if (Test-Command "claude") {
        try {
            $version = claude --version 2>$null | Select-Object -First 1
            Write-Info "Claude Code 已安装，版本：$version"
            return $true
        } catch {
            Write-Warning "Claude Code 命令存在但无法获取版本"
            return $false
        }
    } else {
        Write-Warning "Claude Code 未安装"
        return $false
    }
}

# 检查包管理器
function Get-PackageManager {
    if (Test-Command "choco") {
        return "chocolatey"
    } elseif (Test-Command "scoop") {
        return "scoop"
    } elseif (Test-Command "winget") {
        return "winget"
    } else {
        return "none"
    }
}

# 安装Node.js
function Install-NodeJS {
    Write-Step "安装 Node.js..."

    $packageManager = Get-PackageManager
    $installed = $false

    switch ($packageManager) {
        "chocolatey" {
            Write-Info "使用 Chocolatey 安装 Node.js..."
            try {
                choco install nodejs -y
                $installed = $true
            } catch {
                Write-Error "Chocolatey 安装失败: $_"
            }
        }
        "scoop" {
            Write-Info "使用 Scoop 安装 Node.js..."
            try {
                scoop install nodejs
                $installed = $true
            } catch {
                Write-Error "Scoop 安装失败: $_"
            }
        }
        "winget" {
            Write-Info "使用 WinGet 安装 Node.js..."
            try {
                winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
                $installed = $true
            } catch {
                Write-Error "WinGet 安装失败: $_"
            }
        }
        default {
            Write-Warning "未检测到包管理器（Chocolatey/Scoop/WinGet）"
            Write-Info "请手动下载安装 Node.js："
            Write-Info "访问 https://nodejs.org/ 下载 LTS 版本"
            Write-Info ""
            Read-Host "安装完成后按回车继续..."
        }
    }

    # 刷新环境变量
    if ($installed) {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }

    return (Test-NodeJS)
}

# 安装Claude Code
function Install-ClaudeCode {
    Write-Step "安装 Claude Code..."

    if (Test-Command "npm") {
        Write-Info "使用 npm 安装 Claude Code..."
        try {
            npm install -g @anthropic-ai/claude-code

            # 刷新环境变量
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            if (Test-ClaudeCode) {
                Write-Info "Claude Code 安装成功"
                return $true
            } else {
                Write-Error "Claude Code 安装失败"
                return $false
            }
        } catch {
            Write-Error "npm 安装失败: $_"
            return $false
        }
    } else {
        Write-Error "npm 未找到，请先安装 Node.js"
        return $false
    }
}

# 设置环境变量（用户级别）
function Set-UserEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value
    )

    try {
        [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)
        # 同时设置当前会话
        Set-Item -Path "env:$Name" -Value $Value -Force
        Write-Info "设置环境变量: $Name = $Value"
        return $true
    } catch {
        Write-Error "设置环境变量失败: $_"
        return $false
    }
}

# 删除环境变量（用户级别）
function Remove-UserEnvironmentVariable {
    param([string]$Name)

    try {
        [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::User)
        # 同时清除当前会话
        Remove-Item -Path "env:$Name" -ErrorAction SilentlyContinue
        Write-Info "删除环境变量: $Name"
        return $true
    } catch {
        Write-Error "删除环境变量失败: $_"
        return $false
    }
}

# 配置Claude Code环境变量
function Set-ClaudeCodeEnv {
    Write-Step "配置 Claude Code 环境变量..."

    # 获取API密钥
    if ([string]::IsNullOrWhiteSpace($script:ApiKey)) {
        Write-Warning "请输入你的 API 密钥（格式: cr_xxxxxxxxxx）"
        $script:ApiKey = Get-UserInput "API密钥" ""

        if ([string]::IsNullOrWhiteSpace($script:ApiKey)) {
            Write-Error "API密钥不能为空"
            return $false
        }
    }

    # 设置环境变量
    $success = $true
    $success = $success -and (Set-UserEnvironmentVariable "ANTHROPIC_BASE_URL" "$BaseUrl/api")
    $success = $success -and (Set-UserEnvironmentVariable "ANTHROPIC_AUTH_TOKEN" $script:ApiKey)

    if ($success) {
        Write-Info "Claude Code 环境变量配置完成"
    } else {
        Write-Error "Claude Code 环境变量配置失败"
    }

    return $success
}

# 配置Gemini环境变量
function Set-GeminiEnv {
    Write-Step "配置 Gemini CLI 环境变量..."

    $success = $true
    $success = $success -and (Set-UserEnvironmentVariable "CODE_ASSIST_ENDPOINT" "$BaseUrl/gemini")
    $success = $success -and (Set-UserEnvironmentVariable "GOOGLE_CLOUD_ACCESS_TOKEN" $script:ApiKey)
    $success = $success -and (Set-UserEnvironmentVariable "GOOGLE_GENAI_USE_GCA" "true")

    if ($success) {
        Write-Info "Gemini 环境变量配置完成"
    } else {
        Write-Error "Gemini 环境变量配置失败"
    }

    return $success
}

# 配置Codex
function Set-CodexConfig {
    Write-Step "配置 Codex..."

    $codexDir = Join-Path $env:USERPROFILE ".codex"
    $configFile = Join-Path $codexDir "config.toml"
    $authFile = Join-Path $codexDir "auth.json"

    try {
        # 创建目录
        if (-not (Test-Path $codexDir)) {
            New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
        }

        # 备份旧文件
        if (Test-Path $configFile) {
            Copy-Item $configFile "$configFile.bak" -Force
            Write-Info "备份文件: $configFile -> $configFile.bak"
        }
        if (Test-Path $authFile) {
            Copy-Item $authFile "$authFile.bak" -Force
            Write-Info "备份文件: $authFile -> $authFile.bak"
        }

        # 创建config.toml
        $configContent = @"
model_provider = "crs"
model = "gpt-5-codex"
model_reasoning_effort = "high"
disable_response_storage = true
preferred_auth_method = "apikey"

[model_providers.crs]
name = "crs"
base_url = "$BaseUrl/openai"
wire_api = "responses"
"@
        Set-Content -Path $configFile -Value $configContent -Encoding UTF8
        Write-Info "已创建 $configFile"

        # 创建auth.json
        $authContent = @"
{
    "OPENAI_API_KEY": "$script:ApiKey"
}
"@
        Set-Content -Path $authFile -Value $authContent -Encoding UTF8
        Write-Info "已创建 $authFile"

        return $true
    } catch {
        Write-Error "配置 Codex 失败: $_"
        return $false
    }
}

# 清除Claude Code配置
function Clear-ClaudeCodeEnv {
    Write-Step "清除 Claude Code 环境变量..."

    $success = $true
    $success = $success -and (Remove-UserEnvironmentVariable "ANTHROPIC_BASE_URL")
    $success = $success -and (Remove-UserEnvironmentVariable "ANTHROPIC_AUTH_TOKEN")

    return $success
}

# 清除Gemini配置
function Clear-GeminiEnv {
    Write-Step "清除 Gemini CLI 环境变量..."

    $success = $true
    $success = $success -and (Remove-UserEnvironmentVariable "CODE_ASSIST_ENDPOINT")
    $success = $success -and (Remove-UserEnvironmentVariable "GOOGLE_CLOUD_ACCESS_TOKEN")
    $success = $success -and (Remove-UserEnvironmentVariable "GOOGLE_GENAI_USE_GCA")

    return $success
}

# 清除Codex配置
function Clear-CodexConfig {
    Write-Step "清除 Codex 配置..."

    $codexDir = Join-Path $env:USERPROFILE ".codex"

    try {
        if (Test-Path $codexDir) {
            Remove-Item $codexDir -Recurse -Force
            Write-Info "已删除 Codex 配置目录"
        }
        return $true
    } catch {
        Write-Error "清除 Codex 配置失败: $_"
        return $false
    }
}

# 清除所有配置
function Clear-AllConfigs {
    Write-Warning "============================================"
    Write-Warning "              警告！"
    Write-Warning "============================================"
    Write-Warning "您即将清除脚本所配置的所有环境变量和配置文件"
    Write-Warning "这将删除："
    Write-Warning "- Claude Code 环境变量 (ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN)"
    Write-Warning "- Gemini CLI 环境变量 (CODE_ASSIST_ENDPOINT, GOOGLE_CLOUD_ACCESS_TOKEN, GOOGLE_GENAI_USE_GCA)"
    Write-Warning "- Codex 配置目录 (~/.codex)"
    Write-Warning ""
    Write-Warning "注意：这不会卸载已安装的软件（Node.js, Claude Code等）"
    Write-Warning "============================================"

    $confirm = Read-Host "确定要继续吗？请输入 'yes' 确认"

    if ($confirm -ne "yes") {
        Write-Info "已取消清除操作"
        return
    }

    Write-Info "开始清除配置..."

    $success = $true
    $success = $success -and (Clear-ClaudeCodeEnv)
    $success = $success -and (Clear-GeminiEnv)
    $success = $success -and (Clear-CodexConfig)

    Write-Info "============================================"
    if ($success) {
        Write-Info "配置清除完成！"
    } else {
        Write-Warning "配置清除过程中出现了一些问题"
    }
    Write-Info "如需重新配置，请再次运行此脚本"
    Write-Info "============================================"
}

# 显示帮助
function Show-Help {
    Write-Host @"
Windows PowerShell 配置脚本

用法:
    .\config_setup.ps1 [参数]

参数:
    -BaseUrl <url>     指定基础URL (默认: https://claudecc.top)
    -ApiKey <key>      指定API密钥
    -Clean             清除所有配置
    -Help              显示此帮助信息

示例:
    .\config_setup.ps1                                    # 交互式配置
    .\config_setup.ps1 -ApiKey "cr_xxxxxxxxxx"           # 使用指定API密钥配置
    .\config_setup.ps1 -Clean                            # 清除所有配置
    .\config_setup.ps1 -BaseUrl "https://custom.url"     # 使用自定义URL

支持的工具:
    1. Claude Code     - Anthropic 官方CLI工具
    2. Gemini CLI      - Google Gemini 代码助手
    3. Codex           - OpenAI Codex 工具

注意:
    - 需要管理员权限安装某些软件
    - 某些包管理器可能需要单独安装
"@ -ForegroundColor $Colors.Gray
}

# 主配置流程
function Start-Configuration {
    Write-Host "========================================"
    Write-Host "         Windows 配置脚本"
    Write-Host "========================================"

    $nodeReady = $false

    # 1. 检查和安装Node.js
    if (Test-NodeJS) {
        $nodeReady = $true
    } else {
        $installNode = Get-UserInput "是否自动安装 Node.js?" "Y"
        if ($installNode -match "^[Yy]") {
            if (Install-NodeJS) {
                $nodeReady = $true
            } else {
                Write-Error "Node.js 安装失败，请手动安装后重试"
                return $false
            }
        } else {
            Write-Warning "跳过 Node.js 安装，后续步骤中将不会自动安装 Claude Code"
        }
    }

    if (-not $nodeReady) {
        Write-Warning "当前未检测到 Node.js，建议安装后再运行此脚本"
    }

    # 2. 检查和安装Claude Code
    if ($nodeReady -and -not (Test-ClaudeCode)) {
        $installClaude = Get-UserInput "是否自动安装 Claude Code?" "Y"
        if ($installClaude -match "^[Yy]") {
            if (-not (Install-ClaudeCode)) {
                Write-Error "Claude Code 安装失败"
                return $false
            }
        } else {
            Write-Warning "跳过 Claude Code 安装"
        }
    } elseif (-not $nodeReady) {
        Write-Warning "跳过 Claude Code 自动安装（未检测到 Node.js）"
    }

    # 3. 配置环境变量
    Write-Step "选择要配置的工具："
    Write-Host "1) Claude Code"
    Write-Host "2) Gemini CLI"
    Write-Host "3) Codex"
    Write-Host "4) 全部配置"
    Write-Host "0) 跳过配置"

    $choice = Get-UserInput "请选择 [1-4,0]" "1"

    switch ($choice) {
        "1" {
            Set-ClaudeCodeEnv
        }
        "2" {
            if ([string]::IsNullOrWhiteSpace($script:ApiKey)) {
                $script:ApiKey = Get-UserInput "API密钥" ""
            }
            Set-GeminiEnv
        }
        "3" {
            if ([string]::IsNullOrWhiteSpace($script:ApiKey)) {
                $script:ApiKey = Get-UserInput "API密钥" ""
            }
            Set-CodexConfig
        }
        "4" {
            if ([string]::IsNullOrWhiteSpace($script:ApiKey)) {
                $script:ApiKey = Get-UserInput "API密钥" ""
            }
            Set-ClaudeCodeEnv
            Set-GeminiEnv
            Set-CodexConfig
        }
        "0" {
            Write-Info "跳过环境变量配置"
        }
        default {
            Write-Warning "无效选择"
        }
    }

    Write-Info "Windows 配置完成"
    Write-Info "重新打开 PowerShell 或命令提示符使环境变量生效"
    return $true
}

# 主函数
function Main {
    # 检查执行策略
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-Warning "PowerShell 执行策略被限制，可能无法正常运行脚本"
        Write-Info "可以运行以下命令解决：Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    }

    # 处理参数
    if ($Help) {
        Show-Help
        return
    }

    if ($Clean) {
        Clear-AllConfigs
        return
    }

    # 设置全局变量
    $script:ApiKey = $ApiKey

    # 开始配置
    $result = Start-Configuration

    if ($result) {
        Write-Host "========================================"
        Write-Info "所有配置完成！"
        Write-Host "========================================"
    } else {
        Write-Host "========================================"
        Write-Error "配置过程中出现错误"
        Write-Host "========================================"
    }
}

# 运行主函数
Main