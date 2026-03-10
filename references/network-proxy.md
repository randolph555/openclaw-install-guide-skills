# 网络与代理配置指南

中国大陆用户在安装和使用 OpenClaw 时经常遇到网络问题。这份指南覆盖所有常见的网络场景。

## 判断是否需要代理

先帮用户测试网络状况：

```bash
# 测试能不能访问 GitHub
curl -I https://github.com --max-time 10

# 测试能不能访问 npm 仓库
curl -I https://registry.npmjs.org --max-time 10
```

- 如果都能访问 → 不需要代理，只配个国内镜像加速就行
- 如果超时或连不上 → 需要配代理或完全使用国内替代方案

## 场景一：有科学上网工具

问用户：
> 你有没有类似 Clash、V2Ray、SS 这样的工具？如果有的话告诉我它的代理地址和端口。一般长这样：`http://127.0.0.1:7890` 或 `socks5://127.0.0.1:1080`。

拿到代理地址后配置：

### 本地安装配代理

**重要：不要往 `~/.zshrc`、`~/.bashrc` 等系统配置文件写代理设置，这会影响用户电脑上的其他程序。**

正确做法是把代理配置写进 OpenClaw 自己的环境文件 `~/.openclaw/.env`：

```bash
# 编辑 ~/.openclaw/.env，加入以下内容：
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
NO_PROXY=127.0.0.1,localhost,::1
```

帮用户用 Edit 工具写入这个文件即可，不要碰用户的 shell 配置。

如果用户需要临时在当前终端窗口使用代理（比如安装过程中需要），可以临时设置（关掉终端窗口就失效，不影响系统）：

Mac / Linux：
```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export no_proxy=127.0.0.1,localhost,::1
```

Windows PowerShell：
```powershell
$env:HTTP_PROXY = "http://127.0.0.1:7890"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"
$env:NO_PROXY = "127.0.0.1,localhost,::1"
```

**极其重要**：`NO_PROXY` 必须包含 `127.0.0.1,localhost,::1`！不设这个的话，小龙虾连自己本地的浏览器都会走代理，会报 `Failed to start Chrome CDP` 错误。

### Docker 安装配代理

在 `docker-compose.yml` 中添加 environment：
```yaml
services:
  openclaw-gateway:
    environment:
      - HTTP_PROXY=http://host.docker.internal:7890
      - HTTPS_PROXY=http://host.docker.internal:7890
      - NO_PROXY=127.0.0.1,localhost,::1
```

注意 Docker 里要用 `host.docker.internal` 而不是 `127.0.0.1` 来访问宿主机的代理。

### systemd 服务配代理（Linux 服务器）

```bash
mkdir -p ~/.config/systemd/user/openclaw.service.d/
cat > ~/.config/systemd/user/openclaw.service.d/proxy.conf <<EOF
[Service]
Environment="http_proxy=http://127.0.0.1:7890"
Environment="https_proxy=http://127.0.0.1:7890"
Environment="no_proxy=127.0.0.1,localhost,::1"
EOF
systemctl --user daemon-reload
systemctl --user restart openclaw
```

**坑点**：`openclaw config set` 会触发内部热重启，但热重启不会加载 systemd 的环境变量。改完配置后必须用 `systemctl --user restart openclaw` 来重启，不能只靠热重启。

## 场景二：没有代理工具

### npm 镜像源（本地安装必配）

```bash
npm config set registry https://registry.npmmirror.com
```

### Docker 镜像加速（Docker 安装必配）

Mac/Windows：
- Docker Desktop → Settings → Docker Engine → 加入：
```json
{
  "registry-mirrors": ["https://docker.1ms.run"]
}
```

Linux：
```bash
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.1ms.run"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### GitHub 文件下载加速

如果需要从 GitHub 下载文件但访问不了，可以用镜像：
- 把 `https://github.com/` 替换为 `https://ghproxy.com/https://github.com/`
- 或把 `https://raw.githubusercontent.com/` 替换为 `https://ghproxy.com/https://raw.githubusercontent.com/`

### 使用汉化版（自带国内优化）

汉化版 OpenClaw 内置了国内镜像配置：
```bash
# 国内 Docker 镜像
docker pull 1186258278/openclaw-zh:latest
```

## 场景三：完全无外网访问

如果用户既没有代理也完全访问不了外网，那就：

1. **使用国内大模型**：选择通义千问（Qwen）、Kimi（Moonshot AI）、智谱 GLM 等国内模型，不需要访问国外服务器
2. **使用国内 IM**：选择飞书、钉钉、QQ，不需要代理
3. **避免使用** Telegram、Discord、Claude、GPT 等需要访问海外的服务

## 哪些服务需要代理（速查表）

| 服务 | 需要代理？ | 说明 |
|------|-----------|------|
| npm install openclaw | 配国内镜像即可 | 不需要代理 |
| Docker pull | 配镜像加速即可 | 不需要代理 |
| Anthropic Claude API | 需要 | 海外服务 |
| OpenAI GPT API | 需要 | 海外服务 |
| Google Gemini API | 需要 | 海外服务 |
| 通义千问 API | 不需要 | 国内服务 |
| Kimi API | 不需要 | 国内服务 |
| 智谱 GLM API | 不需要 | 国内服务 |
| Telegram | 需要 | 海外服务 |
| Discord | 需要 | 海外服务 |
| 飞书 | 不需要 | 国内服务 |
| 钉钉 | 不需要 | 国内服务 |
| QQ | 不需要 | 国内服务 |
| 微信/企业微信 | 不需要 | 国内服务 |
