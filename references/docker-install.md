# Docker 安装详细指南

## Mac 用户

### 1. 安装 Docker Desktop

告诉用户：
> 我们先装 Docker，它就像一个"虚拟小电脑"，小龙虾住在里面比较干净安全。

引导步骤：
1. 打开浏览器，访问 https://www.docker.com/products/docker-desktop/
2. 点击"Download for Mac"按钮
   - 如果是 M1/M2/M3/M4 芯片（2020年以后的 Mac）→ 选 "Apple Silicon"
   - 如果是老款 Mac → 选 "Intel Chip"
   - 不确定的话：点左上角苹果图标 → 关于本机 → 看"芯片"那一行
3. 下载完打开 .dmg 文件，把 Docker 图标拖到应用程序文件夹
4. 从启动台打开 Docker Desktop，等它启动完毕（菜单栏出现鲸鱼图标）

验证安装：
```bash
docker --version
docker compose version
```

### 2. 拉取并启动 OpenClaw

**国内用户（先配镜像加速）：**

帮用户创建/修改 Docker Desktop 镜像配置：
- 打开 Docker Desktop → Settings → Docker Engine
- 在 JSON 配置里加入：
```json
{
  "registry-mirrors": ["https://docker.1ms.run"]
}
```
- 点 Apply & Restart

**拉取镜像并启动：**

方式一：使用官方脚本（推荐）
```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
./docker-setup.sh
```

方式二：手动 docker-compose（如果 git 不可用）

帮用户在桌面或某个目录创建文件 `docker-compose.yml`：
```yaml
version: "3.8"
services:
  openclaw-gateway:
    image: openclaw/openclaw:latest
    ports:
      - "127.0.0.1:18789:18789"
    volumes:
      - ~/.openclaw:/home/node/.openclaw
      - openclaw-workspace:/home/node/.openclaw/workspace
    restart: unless-stopped
    environment:
      - TZ=Asia/Shanghai

volumes:
  openclaw-workspace:
```

然后运行：
```bash
docker compose up -d
```

方式三：使用中国 IM 整合版（想接飞书/钉钉/QQ的首选）
```bash
wget https://raw.githubusercontent.com/justlovemaki/OpenClaw-Docker-CN-IM/main/docker-compose.yml
wget https://raw.githubusercontent.com/justlovemaki/OpenClaw-Docker-CN-IM/main/.env.example
cp .env.example .env
```
然后帮用户编辑 .env 文件填入配置，再 `docker compose up -d`。

### 3. 运行 onboard 向导

```bash
docker compose run --rm openclaw-cli onboard
```

或如果用手动方式：
```bash
docker exec -it <container_name> openclaw onboard
```

---

## Windows 用户

### 1. 安装 Docker Desktop

告诉用户：
> Windows 上装 Docker 需要先开启一个叫"虚拟化"的功能。不用担心，我带你一步步来。

**检查虚拟化是否开启：**
1. 按 Ctrl+Shift+Esc 打开任务管理器
2. 点"性能"标签
3. 看右下角有没有"虚拟化: 已启用"
4. 如果没启用，需要进 BIOS 开启（这个比较复杂，可能需要看电脑品牌的教程）

**安装 WSL2（Docker 需要它）：**
```powershell
wsl --install
```
装完需要**重启电脑**。

**安装 Docker Desktop：**
1. 打开 https://www.docker.com/products/docker-desktop/
2. 点 "Download for Windows"
3. 双击安装包，勾选 "Use WSL 2 instead of Hyper-V"
4. 一路下一步
5. 安装完**重启电脑**
6. 启动 Docker Desktop，等托盘图标变绿

验证：打开 PowerShell 运行
```powershell
docker --version
docker compose version
```

### 2. 后续步骤同 Mac

拉取镜像、配置、运行 onboard 向导的步骤与 Mac 相同。
国内用户同样需要配置 Docker 镜像加速。

### Windows 常见坑

- **"Docker Desktop requires a newer WSL kernel version"** → 运行 `wsl --update`
- **"Hardware assisted virtualization is not enabled"** → 需要进 BIOS 开启虚拟化
- **Docker Desktop 一直转圈启动不了** → 以管理员身份运行 PowerShell，执行 `wsl --shutdown` 然后重开 Docker Desktop

---

## Linux 用户

### 1. 安装 Docker Engine

```bash
# 使用官方脚本安装（国内用户加 --mirror Aliyun）
curl -fsSL https://get.docker.com | sudo sh -s -- --mirror Aliyun

# 把当前用户加入 docker 组（不用每次都 sudo）
sudo usermod -aG docker $USER

# 重新登录让权限生效（或者运行 newgrp docker）
newgrp docker

# 验证
docker --version
docker compose version
```

### 2. 国内用户配镜像加速

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.1ms.run"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 3. 后续同 Mac

拉取镜像、启动、onboard 步骤相同。

---

## Docker 部署验证清单

帮用户逐个检查：

1. `docker compose ps` → 容器状态应该是 "Up"
2. `curl http://127.0.0.1:18789/healthz` → 应返回健康状态
3. 浏览器打开 `http://127.0.0.1:18789/chat` → 应看到聊天界面
4. 发一条消息测试 → 应收到回复

## Docker 常用运维命令

| 操作 | 命令 |
|------|------|
| 查看容器状态 | `docker compose ps` |
| 查看日志 | `docker compose logs -f` |
| 重启 | `docker compose restart` |
| 停止 | `docker compose down` |
| 更新版本 | `docker compose pull && docker compose up -d` |
| 进入容器 | `docker compose exec openclaw-gateway /bin/bash` |
| 备份配置 | `cp -r ~/.openclaw ~/.openclaw.backup` |

## 版本注意

推荐使用 2026.3.2 或更新的版本。2026.2.12 版本存在已知 Bug（Issue #15141）导致心跳和消息处理异常，如果遇到请升级。
