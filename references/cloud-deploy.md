# 云端部署指南

适合想让小龙虾 24 小时在线的用户。

## 方案选择

| 方案 | 费用 | 难度 | 适合谁 |
|------|------|------|--------|
| 阿里云一键部署 | ~¥40/月起 | 最简单 | 想省事的 |
| 腾讯云轻量服务器 | ~¥199/年活动价 | 简单 | 想便宜的 |
| 1Panel 面板 | 服务器费 + 免费面板 | 简单 | 喜欢图形界面管理的 |
| 自有 VPS + Docker | 按 VPS 费用 | 中等 | 有经验的 |

## 阿里云一键部署

告诉用户：
> 阿里云有专门为小龙虾做的一键部署镜像，就像买个预装好系统的电脑，开机就能用。

1. 打开阿里云轻量应用服务器：https://swas.console.aliyun.com
2. 创建服务器，在镜像选择里搜"OpenClaw"
3. 选择配置（推荐 2 核 4G，约 ¥40-60/月）
4. 确认创建并付款
5. 等几分钟服务器启动
6. 在控制台找到服务器公网 IP
7. 浏览器打开 `http://公网IP:18789/chat`

默认版本是 v2026.2.3，基于 Alibaba Cloud Linux 3，已预装 Node.js、Docker、OpenClaw 及所有核心依赖。

## 腾讯云轻量服务器

1. 打开 https://cloud.tencent.com/product/lighthouse
2. 新用户有活动价（2 核 4G 约 ¥199/年）
3. 创建服务器，系统选 Ubuntu 22.04
4. 通过 SSH 登录服务器
5. 使用 Docker 方式安装（参考 docker-install.md）

## 安全加固（必做！）

云服务器部署后**必须**做安全配置，这是最重要的一步：

### 1. 不要暴露 18789 端口

> 默认端口 18789 暴露到公网且无认证是最致命的安全隐患。已知超过 1300+ 个 OpenClaw 实例裸奔在公网上。

**正确做法：**
```bash
# 确认网关模式是 local（只允许本地访问）
openclaw config set gateway.mode local
```

### 2. 设置反向代理 + 认证

如果需要从外网访问，用反向代理 + 密码保护：

**方案 A：Cloudflare Tunnel（推荐，免费）**

1. 注册 Cloudflare 账号
2. 添加你的域名
3. 安装 cloudflared：
```bash
# Linux
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```
4. 创建隧道并连接到 localhost:18789

**方案 B：Nginx 反向代理 + Basic Auth**

```bash
sudo apt install nginx apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd yourname
```

### 3. 防火墙配置

```bash
# 只开放 SSH（22）和 HTTPS（443），不要开 18789
sudo ufw allow 22
sudo ufw allow 443
sudo ufw enable
```

### 4. 定期更新

```bash
# Docker 方式
docker compose pull
docker compose up -d

# 本地安装方式
npm update -g openclaw
```

## 远程访问方案对比

| 方式 | 安全性 | 复杂度 | 推荐 |
|------|--------|--------|------|
| QQ/飞书/Telegram 机器人 | 高 | 低 | 最推荐 |
| Cloudflare Tunnel | 高 | 中 | 推荐 |
| Nginx + Basic Auth | 中 | 中 | 可以 |
| 直接暴露端口 | 极低 | 低 | 绝对不要！|

告诉用户：
> 最安全最方便的远程访问方式就是通过 QQ/飞书机器人。你只要在手机上给机器人发消息就行，完全不需要暴露任何端口。
