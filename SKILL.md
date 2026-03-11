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

整个流程只有 **4 个交互点**，其余全部连续执行：

1. **收集** — 一次性问完所有基础信息（1 轮交互）
2. **确认方案** — 根据信息推导最优方案，用户确认后开干（1 轮交互）
3. **执行** — 连续执行全部安装配置，只在必须要用户提供信息时才停（API Key、扫码等）
4. **技能 + 验收** — 选装技能包 + 最终验收清单（1 轮交互）

减少交互轮次是因为每多一次停顿，就多一次出轨的风险。能连续做完的事就不要拆开问。

## 安全边界

- **绝对不碰用户的 shell 配置文件**（`~/.zshrc`、`~/.bashrc`、`~/.profile`）。所有代理、环境变量只写进 OpenClaw 自己的配置（`~/.openclaw/openclaw.json` 或 `~/.openclaw/.env`）。
- **不要重装用户已有的工具**。先检测 `node --version`，版本 >= 22 直接跳过。
- 配置模型时编辑 `~/.openclaw/openclaw.json` 的 `models.providers` 结构。**不要用 `openclaw config set auth.openai.xxx`——这个路径不存在会报错。**
- 说人话，不甩术语。必须用到技术词时立刻用大白话解释。

## 配置架构（关键知识）

OpenClaw 有**三层配置文件**，改错地方或漏改是最常见的故障原因：

| 文件 | 路径 | 谁管理 |
|------|------|--------|
| 主配置 | `~/.openclaw/openclaw.json` | 用户编辑 |
| Agent 模型定义 | `~/.openclaw/agents/main/agent/models.json` | daemon 重启自动生成 |
| 认证凭证 | `~/.openclaw/agents/main/agent/auth-profiles.json` | 用户或 wizard 生成 |

**关键规则：**
- 三个文件中的 provider 名、baseUrl、apiKey/token **必须一致**
- `models.json` 是 daemon 重启时自动生成的，改了 `openclaw.json` 后必须 `openclaw daemon restart`
- 热加载（config hot reload）**不会**重新生成 `models.json`
- 重启后要检查 `models.json`，apiKey 有时不会正确同步，需手动修复后再重启一次

详细说明参考：`{baseDir}/references/troubleshooting.md`

---

## 阶段一：收集信息（1 轮交互）

用 AskUserQuestion 工具一次性问完所有基础问题（最多 4 个）：

**问题 1：你已经有大模型的 API Key 了吗？**
选项：
- 有 OpenAI / Claude / Gemini 等官方 Key
- 有第三方中转/CDN 的 Key（比如代理商给的）
- 没有，帮我推荐一个

**问题 2：你用的什么电脑？**
选项：
- Mac（苹果电脑）
- Windows
- Linux

**问题 3：你想怎么安装小龙虾？**
选项：
- 本地安装（直接装在电脑上，推荐 Mac/Linux）(Recommended)
- Docker 安装（隔离干净，适合不想折腾环境的）
- 不懂，帮我选

**问题 4：你想通过什么跟小龙虾聊天？**（multiSelect: true）
选项：
- 飞书
- 微信
- QQ
- 先用网页就行

---

## 阶段二：推导方案 + 用户确认（1 轮交互）

根据收集到的 4 个答案，自动推导出完整方案。推导逻辑：

### 安装方式

如果用户选了具体方式，直接用。如果选了「不懂，帮我选」：

| 条件 | 推荐 | 原因 |
|------|------|------|
| Mac / Linux 用户 | 本地安装 | 最简单，一行命令搞定 |
| Windows 用户 | Docker | 避免 Windows 特有的坑（spawn EINVAL、PATH 问题等） |

### 大模型

如果用户已有 Key → 直接问他 provider 信息（后续在阶段三收集）。

如果用户有第三方中转 Key → 后续问 API 地址、Key、模型名。

如果用户没有 Key → 根据网络环境推荐：

| 条件 | 推荐 | 原因 |
|------|------|------|
| 中国大陆 | DeepSeek / 通义千问 | 国内直连，价格便宜，有免费额度 |
| 海外 + 想免费试 | Google Gemini | 免费额度最大方 |
| 海外 + 追求效果 | Anthropic Claude | 最聪明 |
| 电脑性能好（16G+）想离线 | Ollama 本地模型 | 完全免费不联网 |

判断用户在中国大陆还是海外：跑 `bash {baseDir}/scripts/detect_env.sh`，看 `network.in_china` 字段。

### 聊天平台

直接按用户选择。如果选了微信，告知目前微信接入需要使用第三方插件（稳定性一般），建议同时配一个飞书或 QQ 作为备选。

### 网络配置

中国大陆 → 需要配国内镜像（npm / Docker）。后续问用户是否有代理工具。

**把推导结果汇总成一段话告诉用户：**

> 根据你的情况，我帮你定了这个方案：
> - **安装方式**：本地安装（一行命令搞定）
> - **大模型**：DeepSeek（国内便宜好用）
> - **聊天平台**：飞书
> - **网络**：需要配国内 npm 镜像
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
3. 安装 OpenClaw：`npm install -g openclaw@latest` 或一键脚本
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

**【需要用户输入】** 根据阶段一收集到的情况分三条路线：

**路线 A：用户已有官方 Key**
问用户是哪家的（OpenAI / Claude / Gemini / DeepSeek 等），拿到 Key 后用脚本配置。

**路线 B：用户有第三方中转 Key**
一次性问三个信息：API 地址（Base URL）、API Key、模型名称。
提醒用户：第三方中转需要完整支持 OpenAI Responses API，否则工具调用会 502。如果不确定，先配上试试，第一条消息能回复、第二条也能回复就没问题。

**路线 C：用户没有 Key**
根据推导结果，告诉用户去哪注册、怎么拿 Key，等用户给。

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
- 自定义 provider（`--provider custom`）默认用 `openai-responses`，如果 CDN 不支持会在第二条消息时 502，此时需要换支持完整 Responses API 的 CDN
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

### 3.7 安装技能包

**用 AskUserQuestion 展示技能目录，让用户勾选想装的：**

**问题：你想给小龙虾装哪些技能？**（multiSelect: true）
选项：
- 联网搜索 (brave-search) — 让小龙虾能搜索互联网，回答实时问题。免费，需要 Brave API Key（免费额度够用）
- 读 PDF (nano-pdf) — 读取和分析 PDF 文件内容。免费，无需额外 Key
- 监控网站 (blogwatcher) — 定时监控网站/RSS 变化并通知你。免费，无需额外 Key
- 先不装了，以后再说

**注意事项：**
- 标注了「需要 API Key」的技能，装完后还需要配对应的 Key 才能用
- 告诉用户以后随时可以装：`npx clawhub@latest install 技能名`
- 如果用户选了需要 Key 的技能，安装后立刻告诉用户去哪拿 Key、怎么配

安装命令：
```bash
npx clawhub@latest install brave-search
npx clawhub@latest install nano-pdf
npx clawhub@latest install blogwatcher
```

装完后 `openclaw daemon restart` 让技能生效。

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
> - 大模型：XXX（已验证可用）
> - 网页聊天：http://127.0.0.1:18789/chat
> - 聊天平台：XXX 已配通
> - 已安装技能：brave-search、nano-pdf
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

执行过程中遇到报错时的自动诊断逻辑。**完整排查手册参考：`{baseDir}/references/troubleshooting.md`**

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

### 模型配置类（重要）

| 问题 | 原因和解决 |
|------|-----------|
| 502 Upstream request failed（第二条消息起） | CDN 不完整支持 Responses API 的 `function_call` input items。换完整支持的 CDN。详见 troubleshooting.md |
| 502 只在 embedded run 时出现 | `auth-profiles.json` 的 provider 名或 token 与 `models.json` 不匹配。统一三个配置文件的 provider 名和 key |
| 模型配置不生效 | 只改了 `models.providers` 没改 `agents.defaults.model.primary`，或改完没 `openclaw daemon restart` |
| `models.json` 还是旧 key | daemon 重启时 apiKey 有时不同步。手动改 `models.json` 后再重启一次 |
| Setup Wizard 验证失败 | CDN 只支持 `/v1/responses` 但 wizard 用 `/v1/chat/completions` 验证。跳过 wizard，手动配置 `"api": "openai-responses"` |
| typing TTL reached (2m) 后无回复 | API key 无效或 CDN 不可达。检查 `models.json` 和 `auth-profiles.json` 中的 key 是否正确 |

### 图片功能类

| 问题 | 解决 |
|------|------|
| 不能识别图片 | 模型定义中加 `"input": ["text", "image"]`，配置 `agents.defaults.imageModel` |
| imageModel 报 Unknown model | `imageModel` 引用的 provider 在 `auth-profiles.json` 中不存在，统一 provider 名 |
| 飞书发图片失败 LocalMediaAccessError | 内置 `@openclaw/feishu` 插件 bug，换用 `@m1heng-clawd/feishu` |
| 飞书不识别图片 | 检查飞书应用是否有 `im:resource` 权限 |
| read ETIMEDOUT（图片请求） | `models.json` 中 apiKey 是占位符 `"OPENAI_API_KEY"`。确保真实 key 已同步到 `models.json` |

### 平台接入类

| 问题 | 解决 |
|------|------|
| QQ 机器人不回 | 检查 Gateway → 检查插件 → `openclaw logs --follow` |
| 飞书 API 配额用完 | Gateway 每 60 秒探测一次。多台机器用不同飞书应用 |
| 飞书 99991672 权限错误 | 缺少 `contact:contact.base:readonly` 权限，去飞书开放平台添加 |

### 快速切换 CDN（完整步骤）

推荐使用 `generate_config.py` 脚本自动完成配置同步：

```bash
python3 {baseDir}/scripts/generate_config.py --provider openai --api-key "新Key" --base-url "https://新CDN/v1" --model "模型名" --api-protocol openai-responses
```

脚本会自动更新 `openclaw.json` 和 `auth-profiles.json`。然后：

1. `openclaw daemon restart`
2. 检查 `~/.openclaw/agents/main/agent/models.json` 确认 baseUrl 和 apiKey 已更新
3. 如果 apiKey 没更新 → 手动改 `models.json` → 再重启一次
4. 在聊天平台发 `/new` 开新会话 → 发测试消息验证

## 云端部署（进阶）

如果用户想 24 小时运行或电脑性能不够，读取 `{baseDir}/references/cloud-deploy.md`。
推荐：阿里云一键部署（~¥40/月）、腾讯云活动价（~¥199/年）。
