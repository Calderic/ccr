@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul

set "BASE_URL=https://claudecc.top"
set "API_KEY="

if not defined HOME set "HOME=%USERPROFILE%"

call :main
exit /b %ERRORLEVEL%

:main
call :print_info "检测到 Windows 系统"
echo ========================================
echo          自动配置脚本
echo ========================================

call :show_menu

if /I "%SELECTED_ACTION%"=="EXIT" (
    call :print_info "退出脚本"
    exit /b 0
) else if /I "%SELECTED_ACTION%"=="CLEAN" (
    call :clean_all_configs
    exit /b %ERRORLEVEL%
)

call :configure_windows
if errorlevel 1 (
    echo ========================================
    call :print_error "配置过程中出现错误"
    echo ========================================
    exit /b 1
)

echo ========================================
call :print_info "所有配置完成！"
echo ========================================
exit /b 0

:show_menu
set "MENU_CHOICE="
:menu_loop
call :print_step "请选择操作："
echo 1) 配置工具环境 (Claude V2.0)
echo 2) 清除所有配置
echo 0) 退出
set /p "MENU_CHOICE=请选择 [0-2] (默认1): "
if "%MENU_CHOICE%"=="" set "MENU_CHOICE=1"

if "%MENU_CHOICE%"=="1" (
    set "SELECTED_ACTION=CONFIG"
    exit /b 0
) else if "%MENU_CHOICE%"=="2" (
    set "SELECTED_ACTION=CLEAN"
    exit /b 0
) else if "%MENU_CHOICE%"=="0" (
    set "SELECTED_ACTION=EXIT"
    exit /b 0
)

call :print_error "无效选择"
goto :menu_loop

:configure_windows
call :print_info "开始 Windows 配置..."
set "NODE_READY=0"

call :check_nodejs
if errorlevel 1 (
    set "install_node="
    set /p "install_node=是否自动安装 Node.js? [Y/n]: "
    if "!install_node!"=="" set "install_node=Y"
    if /I "!install_node!"=="N" (
        call :print_warn "跳过 Node.js 安装，后续步骤中将不会自动安装 Claude Code"
    ) else (
        call :install_nodejs_windows
        if errorlevel 1 exit /b 1
        call :check_nodejs
        if errorlevel 1 exit /b 1
        set "NODE_READY=1"
    )
) else (
    set "NODE_READY=1"
)

if not "!NODE_READY!"=="1" (
    call :print_warn "当前未检测到 Node.js，建议安装后再运行此脚本"
)

if "!NODE_READY!"=="1" (
    call :check_claude_code
    if errorlevel 1 (
        set "install_claude="
        set /p "install_claude=是否自动安装 Claude Code? [Y/n]: "
        if "!install_claude!"=="" set "install_claude=Y"
        if /I "!install_claude!"=="N" (
            call :print_warn "跳过 Claude Code 安装"
        ) else (
            call :install_claude_code
            if errorlevel 1 exit /b 1
        )
    )
) else (
    call :print_warn "跳过 Claude Code 自动安装（未检测到 Node.js）"
)

call :print_step "选择要配置的工具："
echo 1) Claude Code
echo 2) Gemini CLI
echo 3) Codex
echo 4) VSCode Claude 插件
echo 5) 全部配置
echo 0) 跳过配置
set "choice="
set /p "choice=请选择 [1-5,0] (默认1): "
if "%choice%"=="" set "choice=1"

if "%choice%"=="1" (
    call :configure_claude_code_env
    if errorlevel 1 exit /b 1
) else if "%choice%"=="2" (
    call :configure_gemini_env
    if errorlevel 1 exit /b 1
) else if "%choice%"=="3" (
    call :configure_codex
    if errorlevel 1 exit /b 1
) else if "%choice%"=="4" (
    call :configure_vscode_claude
    if errorlevel 1 exit /b 1
) else if "%choice%"=="5" (
    call :configure_claude_code_env
    if errorlevel 1 exit /b 1
    call :configure_gemini_env
    if errorlevel 1 exit /b 1
    call :configure_codex
    if errorlevel 1 exit /b 1
    call :configure_vscode_claude
    if errorlevel 1 exit /b 1
) else if "%choice%"=="0" (
    call :print_info "跳过环境变量配置"
) else (
    call :print_warn "无效选择"
)

call :print_info "Windows 配置完成"
exit /b 0

:check_nodejs
set "NODE_VERSION="
for /f "delims=" %%i in ('node --version 2^>nul') do if not defined NODE_VERSION set "NODE_VERSION=%%i"
if defined NODE_VERSION (
    call :print_info "Node.js 已安装，版本：!NODE_VERSION!"
    exit /b 0
)
call :print_warn "Node.js 未安装"
exit /b 1

:install_nodejs_windows
call :print_step "安装 Node.js..."
set "INSTALLER_USED=0"

call :command_exists choco
if not errorlevel 1 (
    call :print_info "检测到 Chocolatey，使用 choco 安装 Node.js..."
    choco install nodejs -y
    if not errorlevel 1 set "INSTALLER_USED=1"
)

if "!INSTALLER_USED!"=="0" (
    call :command_exists scoop
    if not errorlevel 1 (
        call :print_info "检测到 Scoop，使用 scoop 安装 Node.js..."
        scoop install nodejs
        if not errorlevel 1 set "INSTALLER_USED=1"
    )
)

if "!INSTALLER_USED!"=="0" (
    call :command_exists winget
    if not errorlevel 1 (
        call :print_info "检测到 WinGet，使用 winget 安装 Node.js..."
        winget install --id OpenJS.NodeJS.LTS -e
        if not errorlevel 1 set "INSTALLER_USED=1"
    )
)

if "!INSTALLER_USED!"=="0" (
    call :print_warn "未检测到包管理器（Chocolatey/Scoop/WinGet）"
    call :print_info "请手动下载安装 Node.js："
    call :print_info "访问 https://nodejs.org/ 下载 LTS 版本"
    set "manual_wait="
    set /p "manual_wait=安装完成后按回车继续..."
)

call :check_nodejs
if not errorlevel 1 exit /b 0

if "!INSTALLER_USED!"=="1" (
    call :print_error "包管理器安装后仍未检测到 Node.js，请检查安装日志或手动安装"
) else (
    call :print_error "Node.js 安装失败或未检测到"
)
exit /b 1

:check_claude_code
set "CLAUDE_VERSION="
for /f "delims=" %%i in ('claude --version 2^>nul') do if not defined CLAUDE_VERSION set "CLAUDE_VERSION=%%i"
if defined CLAUDE_VERSION (
    call :print_info "Claude Code 已安装，版本：!CLAUDE_VERSION!"
    exit /b 0
)
call :print_warn "Claude Code 未安装"
exit /b 1

:install_claude_code
call :print_step "安装 Claude Code..."
call :command_exists npm
if errorlevel 1 (
    call :print_error "未找到 npm，请先安装 Node.js"
    exit /b 1
)

npm install -g @anthropic-ai/claude-code
if errorlevel 1 (
    call :print_error "Claude Code 安装失败"
    exit /b 1
)

call :check_claude_code
if errorlevel 1 (
    call :print_error "Claude Code 安装失败"
    exit /b 1
)

call :print_info "Claude Code 安装成功"
exit /b 0

:configure_claude_code_env
call :print_step "配置 Claude Code 环境变量..."
call :ensure_api_key
if errorlevel 1 exit /b 1

call :print_info "设置 ANTHROPIC_BASE_URL = %BASE_URL%/api"
call :set_windows_env "ANTHROPIC_BASE_URL" "%BASE_URL%/api"
if errorlevel 1 exit /b 1

call :print_info "设置 ANTHROPIC_AUTH_TOKEN = %API_KEY%"
call :set_windows_env "ANTHROPIC_AUTH_TOKEN" "%API_KEY%"
if errorlevel 1 exit /b 1

call :print_info "环境变量已设置（需要重新打开终端生效）"
exit /b 0

:configure_gemini_env
call :print_step "配置 Gemini CLI 环境变量..."
if not defined API_KEY (
    call :ensure_api_key
    if errorlevel 1 exit /b 1
)

call :print_info "设置 CODE_ASSIST_ENDPOINT = %BASE_URL%/gemini"
call :set_windows_env "CODE_ASSIST_ENDPOINT" "%BASE_URL%/gemini"
if errorlevel 1 exit /b 1

call :print_info "设置 GOOGLE_CLOUD_ACCESS_TOKEN = %API_KEY%"
call :set_windows_env "GOOGLE_CLOUD_ACCESS_TOKEN" "%API_KEY%"
if errorlevel 1 exit /b 1

call :print_info "设置 GOOGLE_GENAI_USE_GCA = true"
call :set_windows_env "GOOGLE_GENAI_USE_GCA" "true"
if errorlevel 1 exit /b 1

call :print_info "Gemini 环境变量已设置"
exit /b 0

:configure_codex
call :print_step "配置 Codex..."
if not defined API_KEY (
    call :ensure_api_key
    if errorlevel 1 exit /b 1
)

set "CODEX_DIR=%HOME%\.codex"
if not exist "%CODEX_DIR%" (
    mkdir "%CODEX_DIR%"
    if errorlevel 1 (
        call :print_error "创建目录 %CODEX_DIR% 失败"
        exit /b 1
    )
)

call :backup_file "%CODEX_DIR%\config.toml"
call :backup_file "%CODEX_DIR%\auth.json"

(
    echo model_provider = "crs"
    echo model = "gpt-5-codex"
    echo model_reasoning_effort = "high"
    echo disable_response_storage = true
    echo preferred_auth_method = "apikey"
    echo.
    echo [model_providers.crs]
    echo name = "crs"
    echo base_url = "%BASE_URL%/openai"
    echo wire_api = "responses"
) > "%CODEX_DIR%\config.toml"
call :print_info "已创建 %CODEX_DIR%\config.toml"

(
    echo {
    echo     "OPENAI_API_KEY": "%API_KEY%"
    echo }
) > "%CODEX_DIR%\auth.json"
call :print_info "已创建 %CODEX_DIR%\auth.json"

exit /b 0

:configure_vscode_claude
call :print_step "配置 VSCode Claude 插件..."
if not defined API_KEY (
    call :ensure_api_key
    if errorlevel 1 exit /b 1
)

set "CLAUDE_DIR=%HOME%\.claude"
if not exist "%CLAUDE_DIR%" (
    mkdir "%CLAUDE_DIR%"
    if errorlevel 1 (
        call :print_error "创建目录 %CLAUDE_DIR% 失败"
        exit /b 1
    )
)

call :backup_file "%CLAUDE_DIR%\config.json"

(
    echo {
    echo   "primaryApiKey": "crs"
    echo }
) > "%CLAUDE_DIR%\config.json"
call :print_info "已创建 %CLAUDE_DIR%\config.json"

exit /b 0

:ensure_api_key
if defined API_KEY (
    if not "%API_KEY%"=="" exit /b 0
)

call :print_warn "请输入你的 API 密钥（格式: cr_xxxxxxxxxx）"
set "input="
set /p "input=API密钥: "
if "!input!"=="" (
    call :print_error "API密钥不能为空"
    exit /b 1
)
set "API_KEY=!input!"
exit /b 0

:set_windows_env
set "ENV_NAME=%~1"
set "ENV_VALUE=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Environment]::SetEnvironmentVariable('%ENV_NAME%','%ENV_VALUE%',[System.EnvironmentVariableTarget]::User)" >nul
if errorlevel 1 (
    call :print_error "设置环境变量 %ENV_NAME% 失败"
    exit /b 1
)
exit /b 0

:clean_all_configs
call :print_warn "============================================"
call :print_warn "              警告！"
call :print_warn "============================================"
call :print_warn "您即将清除脚本所配置的所有环境变量和配置文件"
call :print_warn "这将删除："
call :print_warn "- Claude Code 环境变量 (ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN)"
call :print_warn "- Gemini CLI 环境变量 (CODE_ASSIST_ENDPOINT, GOOGLE_CLOUD_ACCESS_TOKEN, GOOGLE_GENAI_USE_GCA)"
call :print_warn "- Codex 配置目录 (~/.codex)"
call :print_warn "- VSCode Claude 插件配置目录 (~/.claude)"
call :print_warn ""
call :print_warn "注意：这不会卸载已安装的软件（Node.js, Claude Code等）"
call :print_warn "============================================"

set "confirm="
set /p "confirm=确定要继续吗？请输入 yes 确认: "
if /I not "!confirm!"=="yes" (
    call :print_info "已取消清除操作"
    exit /b 1
)

call :print_info "开始清除配置..."
call :clean_windows

call :print_info "============================================"
call :print_info "配置清除完成！"
call :print_info "如需重新配置，请再次运行此脚本"
call :print_info "============================================"
exit /b 0

:clean_windows
call :print_step "清除 Windows 配置..."
call :clean_windows_env "ANTHROPIC_BASE_URL"
call :clean_windows_env "ANTHROPIC_AUTH_TOKEN"
call :clean_windows_env "CODE_ASSIST_ENDPOINT"
call :clean_windows_env "GOOGLE_CLOUD_ACCESS_TOKEN"
call :clean_windows_env "GOOGLE_GENAI_USE_GCA"

set "CODEX_DIR=%HOME%\.codex"
if exist "%CODEX_DIR%" (
    call :print_info "删除 Codex 配置目录..."
    rmdir /S /Q "%CODEX_DIR%"
)

set "CLAUDE_DIR=%HOME%\.claude"
if exist "%CLAUDE_DIR%" (
    call :print_info "删除 VSCode Claude 配置目录..."
    rmdir /S /Q "%CLAUDE_DIR%"
)

call :print_info "Windows 配置清除完成"
exit /b 0

:clean_windows_env
set "ENV_NAME=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Environment]::SetEnvironmentVariable('%ENV_NAME%', $null, [System.EnvironmentVariableTarget]::User)" >nul
set "%~1="
call :print_info "已删除环境变量: %~1"
exit /b 0

:backup_file
if exist "%~1" (
    copy /Y "%~1" "%~1.bak" >nul
    if not errorlevel 1 call :print_info "备份文件: %~1 -> %~1.bak"
)
exit /b 0

:command_exists
where %~1 >nul 2>nul
exit /b %ERRORLEVEL%

:print_info
echo [INFO] %*
exit /b 0

:print_warn
echo [WARN] %*
exit /b 0

:print_error
echo [ERROR] %*
exit /b 0

:print_step
echo [STEP] %*
exit /b 0

:EOF
