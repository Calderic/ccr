# CCR - Cross-Platform Configuration Resource

一个跨平台的自动配置脚本，用于快速配置开发工具环境。支持 Claude Code、Gemini CLI 和 Codex 等 AI 编程工具的一键配置。

## ✨ 特性

- **跨平台支持**：完全兼容 macOS、Windows、Linux (包括 WSL)
- **一键配置**：自动检测系统环境，智能安装和配置所需工具
- **一键还原**：支持完全清除所有配置，操作完全可逆
- **安全可靠**：所有操作均可审查，无任何隐藏行为
- **自动化程度高**：智能检测已安装工具，避免重复操作

## 🚀 快速开始

### 推荐方式

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/Calderic/ccr/main/config_setup.sh

# 添加执行权限
chmod +x config_setup.sh

# 运行脚本
./config_setup.sh
```

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/Calderic/ccr.git
cd ccr

# 运行脚本
chmod +x config_setup.sh
./config_setup.sh
```

## 🛠️ 支持的工具

| 工具 | 说明 | 配置内容 |
|------|------|----------|
| **Claude Code** | Anthropic 官方 CLI 工具 | 环境变量: `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN` |
| **Gemini CLI** | Google Gemini 命令行工具 | 环境变量: `CODE_ASSIST_ENDPOINT`, `GOOGLE_CLOUD_ACCESS_TOKEN` |
| **Codex** | 代码助手工具 | 配置文件: `~/.codex/config.toml`, `~/.codex/auth.json` |

## 📋 功能说明

### 配置功能

1. **自动检测系统环境**
   - 识别操作系统（macOS/Windows/Linux）
   - 检测已安装的包管理器
   - 自动配置对应的 shell 环境

2. **智能安装依赖**
   - **Node.js**: 使用各平台最优安装方式
     - macOS: Homebrew 或官网下载
     - Windows: Chocolatey/Scoop/WinGet 或手动安装
     - Linux: 发行版包管理器或 NodeSource 仓库
   - **Claude Code**: 通过 npm 全局安装

3. **环境变量配置**
   - 自动写入对应的 shell 配置文件
   - Windows: 永久设置用户级环境变量
   - macOS/Linux: 写入 `.zshrc`/`.bashrc` 等

### 清除功能

- **完全可逆**：删除所有由脚本创建的配置
- **安全备份**：清除前自动备份配置文件
- **选择性清除**：不会删除已安装的软件（如 Node.js）

## 🔧 系统要求

### 通用要求
- Bash shell 支持
- 网络连接（用于下载依赖）

### 各平台要求

#### macOS
- macOS 10.14+
- 推荐安装 Homebrew（脚本可自动安装）

#### Windows
- Windows 10+
- PowerShell 5.0+ 或 PowerShell Core
- 推荐使用 Git Bash、WSL 或 PowerShell

#### Linux
- 支持主流发行版：Ubuntu/Debian、Fedora/CentOS/RHEL、Arch/Manjaro
- sudo 权限（用于安装系统包）

## 📖 使用示例

### 基本配置流程

```bash
# 1. 运行脚本
./config_setup.sh

# 2. 选择操作
# 1) 配置工具环境
# 2) 清除所有配置
# 0) 退出

# 3. 选择配置工具
# 1) Claude Code
# 2) Gemini CLI
# 3) Codex
# 4) 全部配置
# 0) 跳过配置

# 4. 输入 API 密钥
# API密钥: cr_xxxxxxxxxx

# 5. 完成配置
```

### 配置验证

```bash
# 验证环境变量
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_AUTH_TOKEN

# 验证 Claude Code 安装
claude --version

# 测试 Claude Code
claude "Hello, world!"
```

## 🛡️ 安全说明

### 脚本安全性
- **开源透明**：所有代码公开可审查
- **无恶意行为**：不包含任何恶意代码或隐藏操作
- **权限最小化**：仅请求必要的系统权限
- **本地运行**：所有操作在本地执行，不上传任何数据

### API 密钥安全
- **本地存储**：API 密钥仅存储在本地环境变量或配置文件中
- **用户控制**：用户完全控制密钥的输入和使用
- **不传输**：脚本不会将密钥发送到任何第三方服务器

## 🔄 常见问题

### Q: 安装失败怎么办？
A: 请检查：
1. 网络连接是否正常
2. 是否有足够的磁盘空间
3. 是否有必要的权限
4. 查看错误信息并按提示操作

### Q: 如何更新配置？
A: 重新运行脚本即可，脚本会自动覆盖旧配置

### Q: 如何完全卸载？
A: 运行脚本选择"清除所有配置"选项，或手动删除：
- 环境变量：`ANTHROPIC_*`, `CODE_ASSIST_*`, `GOOGLE_*`
- 配置文件：`~/.codex/`
- npm 包：`npm uninstall -g @anthropic-ai/claude-code`

### Q: 支持哪些 Shell？
A: 支持 Bash、Zsh、以及大部分 POSIX 兼容的 Shell

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如遇问题请：
1. 查看本文档的常见问题部分
2. 在 GitHub 提交 Issue
3. 查看脚本输出的错误信息和建议