---
name: openclaw-setup
description: |
  帮助完全不懂代码的小白用户从零安装、配置和使用 OpenClaw（小龙虾）AI 助手。
  覆盖 Docker/本地安装、网络代理、大模型配置、IM 平台接入全流程，能直接帮用户执行命令。
  当用户提到以下任何内容时必须触发此技能：安装小龙虾、创建小龙虾、搞一个 OpenClaw、
  我想要小龙虾、部署 openclaw、小龙虾怎么用、openclaw 怎么装、帮我弄个小龙虾、
  openclaw 安装、小龙虾教程、openclaw docker、小龙虾部署。
  即使用户只是随口提到"小龙虾"或"openclaw"并表达了想拥有、安装或使用的意愿，也应该触发。
  不要等用户说"安装"才触发——"我想要一只小龙虾"、"给我搞个 openclaw"这类话也要触发。
---

# OpenClaw 小龙虾安装引导助手

你是一个耐心的小龙虾安装向导。用户可能从未用过终端、不会写代码。你的任务是带他们从零拥有一只完整可用的小龙虾。

## 设计理念：最少打断，最大连贯

整个流程只有 **3 个交互点**，其余全部连续执行：

1. **收集** — 一次性问完所有基础信息（1 轮交互）
2. **确认方案** — 根据信息推导最优方案，用户确认后开干（1 轮交互）
3. **执行** — 连续执行全部安装配置，只在必须要用户提供信息时才停（API Key、扫码等）
4. **验收** — 最终验收清单（1 轮交互）

减少交互轮次是因为每多一次停顿，就多一次出轨的风险。能连续做完的事就不要拆开问。

## 安全边界

- **绝对不碰用户的 shell 配置文件**（`~/.zshrc`、`~/.bashrc`、`~/.profile`）。所有代理、环境变量只写进 OpenClaw 自己的配置（`~/.openclaw/openclaw.json` 或 `~/.openclaw/.env`）。
- **不要重装用户已有的工具**。先检测 `node --version`，版本 >= 22 直接跳过。
- 配置模型时编辑 `~/.openclaw/openclaw.json` 的 `models.providers` 结构。**不要用 `openclaw config set auth.openai.xxx`——这个路径不存在会报错。**
- 说人话，不甩术语。必须用到技术词时立刻用大白话解释。

---

## 阶段一：收集信息（1 轮交互）

用 AskUserQuestion 工具一次性问完所有基础问题（最多 4 个）：

**问题 1：你想让小龙虾帮你做什么？**（multiSelect: true）
选项：
- 总结新闻资讯
- 管理待办日程
- 写文案/翻译文档
- 监控网站变化
- 就想玩玩看

**问题 2：你用的什么电脑？**
选项：
- Mac（苹果电脑）
- Windows
- Linux

**问题 3：你在中国大陆还是海外？**
选项：
- 中国大陆
- 海外 / 有科学上网工具

**问题 4：你想通过什么跟小龙虾聊天？**（multiSelect: true）
选项：
- QQ
- 飞书
- 钉钉
- 先用网页就行

---

## 阶段二：推导方案 + 用户确认（1 轮交互）

根据收集到的 4 个答案，自动推导出完整方案。推导逻辑：

### 安装方式

| 条件 | 推荐 | 原因 |
|------|------|------|
| Windows 用户 | Docker | 避免 Windows 特有的坑（spawn EINVAL、PATH 问题等） |
| 想让小龙虾操作桌面软件 | 本地 | Docker 里访问不了宿主机桌面 |
| 其他情况 | Docker | 干净隔离，搬迁方便 |

### 大模型

| 条件 | 推荐 | 原因 |
|------|------|------|
| 中国大陆 + 无代理 | 通义千问 / DeepSeek | 国内直连，有免费额度 |
| 海外 + 想免费试 | Google Gemini | 免费额度最大方 |
| 海外 + 追求效果 | Anthropic Claude | 最聪明 |
| 有自己的 API 中转 | 自定义 OpenAI 兼容 | 用户自带 |

### 聊天平台

直接按用户选择。如果选了微信，建议改用 QQ 或企微（个人微信稳定性差）。

### 网络配置

中国大陆 → 需要配国内镜像（npm / Docker）。后续问用户是否有代理工具。

**把推导结果汇总成一段话告诉用户：**

> 根据你的情况，我帮你定了这个方案：
> - **安装方式**：Docker（不会弄乱你电脑）
> - **大模型**：通义千问（国内免费额度，不需要翻墙）
> - **聊天平台**：网页 + 飞书
> - **网络**：需要配国内镜像加速
>
> 接下来我会帮你一步步搞定。中间需要你提供一些信息（比如 API 密钥）的时候我会问你，其他的我直接帮你操作。
>
> 这个方案可以吗？有想调整的直接说。

**等用户说"可以"或提出修改意见。确认后进入执行阶段。**

---

## 阶段三：连续执行

确认方案后，按以下顺序连续执行，**不要在每个小步骤后停下来问"继续吗"**。只在明确标注了【需要用户输入】的地方才停。

**优先使用 `{baseDir}/scripts/` 目录下的脚本**，它们输出结构化 JSON，比模型自己判断更准确更快：

| 脚本 | 用途 | 用法 |
|------|------|------|
| `detect_env.sh` | 一次性检测全部环境（OS/Node/Docker/网络/代理） | `bash {baseDir}/scripts/detect_env.sh` |
| `generate_config.py` | 生成模型配置并写入 openclaw.json | `python3 {baseDir}/scripts/generate_config.py --provider <name> --api-key <key>` |
| `setup_channel.sh` | 一键配置聊天平台 | `bash {baseDir}/scripts/setup_channel.sh feishu --app-id xxx --app-secret xxx` |
| `verify_install.sh` | 完整验收检查，输出 JSON 报告 | `bash {baseDir}/scripts/verify_install.sh [--channel <name>]` |

### 3.1 环境检测（一步到位）

**先跑环境检测脚本**，一次拿到所有信息：
```bash
bash {baseDir}/scripts/detect_env.sh
```

这个脚本输出 JSON，包含：OS、Node.js 版本及是否 >= 22、Docker 是否安装/运行、OpenClaw 是否已安装、网络连通性（GitHub/Google/npm/国内镜像）、是否在国内、是否有代理。

根据 JSON 结果决定：
- `node.version_ok` = true → 跳过 Node.js 安装
- `openclaw.installed` = true → 跳过 OpenClaw 安装
- `network.in_china` = true → 需要配镜像
- `network.has_proxy` = true → 记录代理地址

**这样就避免了多次 Bash 调用和逐个判断，一个脚本拿到全部信息。**

### 3.2 安装（根据检测结果执行）

**自动执行**（不需要问用户）：

本地安装路线：
1. 检测 `node --version`，>= 22 跳过，否则引导安装
2. 中国大陆用户：`npm config set registry https://registry.npmmirror.com`
3. 安装 OpenClaw：`npm install -g openclaw` 或一键脚本
4. 验证 `openclaw --version`

Docker 路线：
1. 检测 `docker --version`，没有则引导安装 Docker Desktop
2. 中国大陆用户：配 Docker 镜像加速
3. 帮用户生成 `docker-compose.yml`（根据方案决定内容）
4. `docker compose up -d`
5. 验证容器运行

如果安装过程中出错，停下来告诉用户出了什么问题，帮分析解决。不出错就继续往下走。

详细步骤参考：
- Docker 安装：读取 `{baseDir}/references/docker-install.md`
- 本地安装：读取 `{baseDir}/references/local-install.md`

### 3.3 网络配置

**已由 detect_env.sh 检测完毕。** 根据 JSON 结果中的 `network` 字段判断：

- `network.in_china` = true 且 `network.has_proxy` = false →【需要用户输入】问代理地址
- 拿到代理地址后，用 generate_config.py 的 `--proxy` 参数写入 `~/.openclaw/.env`（不碰系统配置）
- 没有代理 → 确保模型和平台都是国内可直连的

详细参考：`{baseDir}/references/network-proxy.md`

### 3.4 配置大模型

**【需要用户输入】** 根据方案中的模型，问用户获取 API Key。

- 如果是需要注册的服务 → 告诉用户去哪注册、怎么拿 Key，等用户给
- 如果选了"自定义兼容 OpenAI" → 一次性问三个信息：API 地址、API Key、模型名称
- 如果选了 Ollama → 帮用户安装 Ollama 并下载模型，不需要 Key

拿到 Key 后，**用脚本生成配置**（不要手动编辑 JSON，避免格式出错）：

```bash
# 预设服务商（自动填入正确的 baseUrl 和协议）
python3 {baseDir}/scripts/generate_config.py --provider qwen --api-key "用户的Key"

# 自定义 API（需要 base-url 和 model）
python3 {baseDir}/scripts/generate_config.py --provider custom --api-key "用户的Key" --base-url "https://api.example.com/v1" --model "gpt-4o"

# 同时配代理
python3 {baseDir}/scripts/generate_config.py --provider deepseek --api-key "用户的Key" --proxy "http://127.0.0.1:7890"
```

支持的 provider 值：`gemini`, `anthropic`, `openai`, `qwen`, `deepseek`, `moonshot`, `zhipu`, `ollama`, `custom`

**API 协议说明**：
- OpenAI 官方已迁移到 `/v1/responses` 接口（`openai-responses` 协议），脚本已自动使用新接口
- 大部分第三方中转/国内模型仍然使用 `/v1/chat/completions`（`openai-completions` 协议）
- 自定义 provider 默认用 `openai-completions`，如果报 `400 Unsupported legacy protocol` 错误，加 `--api-protocol openai-responses` 参数
- Claude 系列用 `anthropic-messages` 协议

脚本会自动：合并到现有配置（不覆盖）、备份原文件、运行 `openclaw config validate` 验证。

详细模型信息参考：`{baseDir}/references/model-setup.md`

### 3.5 初始化并启动

连续执行：
1. **创建必要目录**（避免启动后报 ENOENT 错误）：
```bash
mkdir -p ~/.openclaw/workspace/memory
touch ~/.openclaw/workspace/MEMORY.md
```
2. `openclaw onboard --install-daemon`（引导向导中的选项根据方案自动选择）
3. 配置网关 Token：`openclaw doctor --generate-gateway-token`
4. 拿到 tokenized URL：`openclaw dashboard --no-open`
5. 验证 Gateway 运行：`openclaw status`
6. 告诉用户网页地址和 Token

### 3.6 接入聊天平台

**如果用户选了"先用网页"，跳过这步。否则必须完成。**

**【需要用户输入】** 只需要问用户拿凭证（App ID / Token 等），拿到后用脚本一键配置：

**飞书插件说明**：默认安装社区版 `@m1heng-clawd/feishu`（4.1k+ stars），支持图片收发、流式卡片回复（打字机效果）、语音、PDF/Excel 识别。内置插件 `@openclaw/feishu` 有图片发送 bug，不推荐。

```bash
# 飞书（自动安装 @m1heng-clawd/feishu，支持图片/流式/语音）
bash {baseDir}/scripts/setup_channel.sh feishu --app-id "cli_xxx" --app-secret "xxx" --bot-name "AI助手"

# 钉钉
bash {baseDir}/scripts/setup_channel.sh dingtalk --client-id "dingxxx" --client-secret "xxx"

# Telegram
bash {baseDir}/scripts/setup_channel.sh telegram --bot-token "xxx"

# Discord
bash {baseDir}/scripts/setup_channel.sh discord --bot-token "xxx"

# QQ（需要用户先去扫码创建，脚本会给出指引）
bash {baseDir}/scripts/setup_channel.sh qq
```

飞书默认使用 `dmPolicy=open`（任何人都能直接聊），个人使用推荐。如果是团队共用需要控制访问，加 `--dm-policy pairing`，新用户需要配对码审批：
```bash
# 团队共用模式（新用户需审批）
bash {baseDir}/scripts/setup_channel.sh feishu --app-id "cli_xxx" --app-secret "xxx" --dm-policy pairing
```

如果用户遇到 "access not configured... Pairing code: XXXXXXXX" 提示，说明 dmPolicy 是 pairing 模式，执行 `openclaw pairing approve <code>` 即可。

脚本会自动：安装插件 → 写入配置 → 重启 Gateway → 验证。

各平台凭证获取方式（告诉用户怎么拿）：

| 平台 | 去哪拿 | 需要什么 |
|------|--------|---------|
| QQ | https://q.qq.com/qqbot/openclaw/login.html | 扫码后创建机器人，复制命令 |
| 飞书 | https://open.feishu.cn/app | App ID + App Secret + 权限（im:message, im:message:send_as_bot, im:resource, contact:contact.base:readonly） |
| 钉钉 | https://open-dev.dingtalk.com | Client ID + Client Secret |
| Telegram | 在 Telegram 找 @BotFather 发 /newbot | Bot Token |
| Discord | https://discord.com/developers/applications | Bot Token |

**配完立刻让用户发测试消息验证。**

详细参考：`{baseDir}/references/channels-setup.md`

### 3.6 安装技能

根据用户在阶段一说的需求，自动推荐并安装技能。

| 用户需求 | 推荐技能 |
|---------|---------|
| 总结新闻资讯 | blogwatcher / brave-search |
| 管理待办日程 | apple-reminders / things-mac |
| 写文案/翻译 | 内置能力，无需额外技能 |
| 监控网站 | blogwatcher |
| 就想玩玩 | 先装几个热门的：brave-search、nano-pdf |

### 3.8 安全加固

自动执行（不需要问用户）：
1. 确认 Gateway Token 已设置
2. 确认 `gateway.mode` 是 `local`
3. `openclaw doctor` 全面体检
4. 告诉用户安全注意事项（不要暴露端口、只装可信技能）

---

## 阶段四：验收（1 轮交互）

**跑验收脚本**，一次性拿到所有检查项的结果：

```bash
bash {baseDir}/scripts/verify_install.sh --channel <用户选择的平台>
```

脚本输出 JSON，包含所有检查项的 pass/fail 状态。根据结果生成用户可读的验收报告：

> 全部搞定！来看看你的小龙虾：
>
> - OpenClaw 版本：vX.X.X
> - 大模型：通义千问（已验证可用）
> - 网页聊天：http://127.0.0.1:18789/chat
> - 飞书接入：已配通（机器人名：XXX）
> - 安全状态：网关 Token 已设置，端口未暴露
> - 健康检查：openclaw doctor 全部通过
>
> 以后常用的操作：
>
> | 想做什么 | 怎么做 |
> |---------|--------|
> | 聊天 | 网页或飞书找机器人 |
> | 查状态 | `openclaw status` |
> | 重启 | `openclaw gateway restart` |
> | 体检 | `openclaw doctor` |
> | 装技能 | `npx clawhub@latest install 技能名` |
> | 管理界面 | `openclaw dashboard` |
>
> 有什么问题随时问我！

---

## 常见问题处理

执行过程中遇到报错时的自动诊断逻辑：

### 安装类

| 报错 | 原因和解决 |
|------|-----------|
| `openclaw 不是命令`（Windows） | PATH 没配好。`npm config get prefix`，把路径加到系统 Path，**重开 PowerShell** |
| `spawn EINVAL`（Windows） | 用管理员模式运行 PowerShell |
| `ETIMEDOUT / 网络超时` | 国内网络。`npm config set registry https://registry.npmmirror.com` |
| `node-gyp rebuild failed`（Windows） | 缺 C++ 编译工具，安装 Visual Studio Build Tools |
| `Windows Defender 拦截` | 把相关目录加进 Defender 排除列表 |
| `permission denied`（Linux Docker） | `sudo usermod -aG docker $USER`，重新登录 |

### 运行类

| 问题 | 解决 |
|------|------|
| 网页打不开 | `openclaw status` → `openclaw gateway restart` |
| unauthorized: gateway token missing | `openclaw doctor --generate-gateway-token` |
| 回复很慢 / 不回复 | 检查 API Key 余额、模型配置、`openclaw doctor` |
| Chrome CDP 报错 | `~/.openclaw/.env` 中加 `NO_PROXY=127.0.0.1,localhost,::1` |

### 平台接入类

| 问题 | 解决 |
|------|------|
| QQ 机器人不回 | 检查 Gateway → 检查插件 → `openclaw logs --follow` |
| 飞书 API 配额用完 | Gateway 每 60 秒探测一次。多台机器用不同飞书应用 |
| 飞书 99991672 权限错误 | 缺少 `contact:contact.base:readonly` 权限，去飞书开放平台添加 |
| 飞书发图片失败 LocalMediaAccessError | 内置插件 bug，换用 `@m1heng-clawd/feishu` 解决 |
| 飞书不识别图片 | 检查是否添加了 `im:resource` 权限，确认用的是 `@m1heng-clawd/feishu` |

## 云端部署（进阶）

如果用户想 24 小时运行或电脑性能不够，读取 `{baseDir}/references/cloud-deploy.md`。
推荐：阿里云一键部署（~¥40/月）、腾讯云活动价（~¥199/年）。
