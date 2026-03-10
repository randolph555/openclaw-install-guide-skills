# 本地安装详细指南（Node.js 方式）

## 重要：先检测现有环境！

在安装任何东西之前，先帮用户跑检测（直接用 Bash 工具执行）：

```bash
node --version 2>&1
npm --version 2>&1
which node 2>&1 || where node 2>&1
```

**判断逻辑：**
- 版本 >= 22 → 告诉用户"你的 Node.js 版本没问题，不用重装"，**直接跳到安装 OpenClaw**
- 版本 < 22 → 告诉用户需要升级。先问："你电脑上有没有其他项目在用当前版本的 Node.js？"
  - 有其他项目 → 推荐用 nvm 管理多版本，不要直接覆盖安装
  - 没有/不确定 → 可以直接升级
- 没安装 → 引导安装

**绝对不要在用户已有正确版本的情况下重新安装。**

---

## Mac 用户

### 1. 安装 Node.js 22+（如果需要）

告诉用户：
> Node.js 是让小龙虾能运行的基础工具，就像汽车需要发动机。版本一定要 22 以上，低了会报错。

**方式一：用 Homebrew 安装（推荐）**

先检查有没有 Homebrew：
```bash
brew --version
```

如果没有，先装 Homebrew：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

然后装 Node.js：
```bash
brew install node@22
```

**方式二：官网下载安装包**
1. 打开 https://nodejs.org
2. 下载 LTS 版本（v22.x）
3. 双击 .pkg 文件安装，一路"继续"

验证：
```bash
node --version   # 要显示 v22.x.x 或更高
npm --version    # 要显示版本号
```

### 2. 国内用户配 npm 镜像

```bash
npm config set registry https://registry.npmmirror.com
```

### 3. 安装 OpenClaw

**方式一：一键脚本（推荐）**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**方式二：npm 安装**
```bash
npm install -g openclaw
```

验证：
```bash
openclaw --version
```

### 4. 运行 onboard 向导

```bash
openclaw onboard --install-daemon
```

---

## Windows 用户

### 1. 安装 Node.js 22+

告诉用户：
> 我们先装一个叫 Node.js 的工具，它是小龙虾运行的"发动机"。

**方式一：官网下载（最适合小白）**
1. 打开 https://nodejs.org
2. 点击下载 LTS 版本（确认是 v22.x）
3. 双击 .msi 安装包
4. **全部默认选项，一路"Next"**
5. 最后一步如果有勾选 "Automatically install necessary tools" 的选项，**勾上它**（这会安装 C++ 编译工具，后面可能用得上）
6. 安装完成

**关键步骤：装完后关掉 PowerShell 重新打开！** Windows 的 PowerShell 不会自动刷新路径，不重开会一直报"node 不是内部或外部命令"。

**方式二：用 winget 安装**
```powershell
winget install OpenJS.NodeJS.LTS
```

**方式三：社区一键部署工具**

社区开发了 Windows 一键部署工具，自动下载便携版 Node.js，不污染系统环境变量，全程国内镜像。搜索 "openclaw windows 一键部署" 可以找到。

验证（在新的 PowerShell 窗口中）：
```powershell
node --version   # 要显示 v22.x.x 或更高
npm --version    # 要显示版本号
```

### 2. 国内用户配 npm 镜像

```powershell
npm config set registry https://registry.npmmirror.com
```

### 3. 安装 OpenClaw

**方式一：一键脚本**
```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

国内用户如果下载慢，用汉化版的脚本（自带国内镜像）：
```powershell
iwr -useb https://raw.githubusercontent.com/1186258278/OpenClawChineseTranslation/main/install.ps1 | iex
```
加 `-China` 参数可自动走国内镜像。

**方式二：npm 安装**
```powershell
npm install -g openclaw
```

验证：
```powershell
openclaw --version
```

**如果报"openclaw 不是内部或外部命令"：**
1. 运行 `npm config get prefix` 查看 npm 全局路径
2. 把输出的路径添加到系统 Path 环境变量
3. 关掉 PowerShell 重新打开

### 4. 运行 onboard 向导

```powershell
openclaw onboard --install-daemon
```

### Windows 特有的坑

| 报错 | 原因和解决 |
|------|-----------|
| `spawn EINVAL` | Windows 调用 .cmd 文件方式不同。用管理员权限运行 PowerShell |
| `ETIMEDOUT` | 网络问题。配镜像源 `npm config set registry https://registry.npmmirror.com` |
| `node-gyp rebuild failed` | 缺 C++ 编译工具。安装 Visual Studio Build Tools 或在 Node.js 安装时勾选自动安装 |
| `openclaw 不是命令` | PATH 没配。见上面的解决步骤 |
| Windows Defender 弹窗 | 把 Node.js 目录加进 Defender 排除列表：设置→病毒防护→排除项 |
| PowerShell 执行策略限制 | 管理员 PowerShell 运行 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |

### Windows 版本要求

- Windows 11：完全支持
- Windows 10 21H2（Build 19044）及以上：支持
- 更老的 Windows 10：可能有问题，建议升级或用 Docker 方式

---

## Linux 用户

### 1. 安装 Node.js 22+

**Ubuntu / Debian：**
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**CentOS / RHEL / Fedora：**
```bash
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs
```

**通用（nvm 方式，推荐进阶用户）：**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 22
nvm use 22
```

验证：
```bash
node --version
npm --version
```

### 2. 国内用户配 npm 镜像

```bash
npm config set registry https://registry.npmmirror.com
```

### 3. 安装 OpenClaw

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```
或
```bash
npm install -g openclaw
```

### 4. 运行 onboard 向导

```bash
openclaw onboard --install-daemon
```

---

## 安装验证清单

帮用户逐个确认：

1. `openclaw --version` → 显示版本号
2. `openclaw doctor` → 全部绿色 OK 最佳
3. `openclaw status` → Gateway 运行中
4. 浏览器打开 `http://127.0.0.1:18789/chat` → 看到聊天界面
5. 发一条"你好"→ 收到回复
