# 聊天平台接入详细指南

## QQ 机器人（最简单，推荐国内用户首选）

腾讯专门给 OpenClaw 开了简化入口，3 步搞定。

### 步骤 1：扫码登录 QQ 开放平台

告诉用户：
> 打开浏览器，访问这个网址：https://q.qq.com/qqbot/openclaw/login.html
> 然后用手机 QQ 扫一下页面上的二维码就能登录。

注意：这个不是 QQ 开放平台的常规入口，是腾讯专门给 OpenClaw 用户开的简化流程。

如果用户没注册过 QQ 开放平台，扫码后会要求实名认证：填姓名、身份证号、手机号，然后人脸识别，几分钟搞定。

### 步骤 2：创建机器人

> 登录进去后，页面上有个"创建机器人"的按钮，直接点一下就行了。不用填名字、不用写简介、不用上传头像，它会自动创建好。

一个 QQ 号最多创建 5 个机器人。

### 步骤 3：执行配置命令

创建完后页面会显示 3 条命令。帮用户依次执行：

```bash
# 1. 安装 QQ 机器人插件
openclaw plugins install @sliverp/qqbot@latest

# 2. 配置机器人（页面上会给出完整命令，包含 Token）
openclaw channels add --channel qqbot --token "AppID:AppSecret"

# 3. 重启让配置生效
openclaw gateway restart
```

Token 格式是 `AppID:AppSecret`，中间用冒号分隔。页面上创建完会直接给拼好的命令，让用户复制粘贴就行。

### 验证

> 打开手机 QQ，在联系人里搜索你刚创建的机器人。给它发一条"你好"，如果收到回复就说明成功了。

如果不回复：
```bash
openclaw gateway status       # 看 Gateway 是否在运行
openclaw logs --follow        # 看实时日志找报错
```

### 补充说明
- 用 WebSocket 长连接，不需要公网 IP、不需要域名
- 国内云服务器和本地电脑都能用
- 要求 OpenClaw 版本 >= 2026.2.9

---

## 飞书（功能最强，适合办公场景）

飞书接入稍复杂但功能最强——能以你的身份操作飞书：写文档、建表格、约日程。

### 插件选择

飞书插件有多个，功能差异很大。**推荐使用社区版 `@m1heng-clawd/feishu`**，内置插件有图片发送 bug。

| 插件 | 图片识别 | 发图片 | 流式回复(SSE) | 语音 | 飞书工具 | 推荐 |
|------|---------|--------|--------------|------|---------|------|
| `@m1heng-clawd/feishu` | 有 | 有 | 有(卡片流式) | 有 | 文档/Wiki/多维表格/日历 | **首选** |
| `@xzq-xu/feishu` | 有 | 有 | 有(可配置) | 音频 | 无 | 生产级备选 |
| `@max1874/feishu` | 有 | 有 | 有(卡片) | 有 | 无 | 备选 |
| 内置 `@openclaw/feishu` | 有 | **有bug** | 有 | 有 | 无 | 不推荐 |
| 飞书官方插件 | 有 | 有 | 有 | 有 | OAuth全功能 | 进阶用户 |

**内置插件已知问题**：发图片时只会把文件路径当文本发出去，不会发送实际图片（GitHub issue #25200）。

### 使用推荐插件 `@m1heng-clawd/feishu`（推荐）

社区最火的飞书插件（4.1k+ stars），支持图片收发、流式卡片回复（打字机效果）、语音、PDF/Excel 文件识别，还自带飞书文档/Wiki/多维表格/日历等工具。

#### 1. 创建飞书应用

告诉用户：
> 我们需要在飞书的开发平台创建一个"应用"，这样你的小龙虾才能跟飞书通信。

1. 打开 https://open.feishu.cn/app
2. 用飞书账号登录
3. 点击"创建自建应用"
4. 填写应用名称（比如"我的AI助手"）和描述，上传一个图标（随便选个）
5. 创建完成

#### 2. 获取凭证

在应用详情页面：
1. 进入"凭证与基础信息"
2. 复制 **App ID**（长这样：`cli_xxxxxx`）
3. 复制 **App Secret**

#### 3. 配置权限

在应用管理页面：
1. 进入"权限管理"
2. 搜索并添加以下权限：
   - `im:message` — 接收和发送消息
   - `im:message:send_as_bot` — 以机器人身份发消息
   - `im:resource` — 读取消息中的图片/文件（图片识别需要）
   - `contact:contact.base:readonly` — 读取联系人基本信息（飞书插件需要用来解析发送者身份，不加会报 99991672 权限错误）
3. 发布应用版本（审核通常很快）

**常见权限报错**：如果日志出现 `code: 99991672, Access denied. One of the following scopes is required: [contact:contact.base:readonly...]`，说明缺少联系人权限。去飞书开放平台 → 你的应用 → 权限管理，搜索 `contact:contact.base:readonly` 添加即可。

#### 4. 配置 OpenClaw

```bash
# 安装社区飞书插件（推荐，支持图片/流式/语音）
openclaw plugins install @m1heng-clawd/feishu

# 如果之前装了内置插件，先卸载避免冲突
# openclaw plugins uninstall @openclaw/feishu

openclaw config set channels.feishu.enabled true
openclaw config set channels.feishu.dmPolicy open
openclaw config set channels.feishu.accounts.main.appId "cli_xxx你的AppID"
openclaw config set channels.feishu.accounts.main.appSecret "你的AppSecret"
openclaw config set channels.feishu.accounts.main.botName "我的AI助手"
openclaw gateway restart
```

使用 WebSocket 长连接模式，不需要公网 IP。

#### 流式回复配置

`@m1heng-clawd/feishu` 支持三种渲染模式：
- `auto`（默认）— 短回复直接发，长回复用卡片流式
- `card` — 始终用飞书卡片，有打字机效果
- `raw` — 直接发文本，不做流式

```bash
# 可选：强制使用卡片流式
openclaw config set channels.feishu.renderMode card
```

#### dmPolicy 私聊访问策略

dmPolicy 控制谁可以通过私聊（DM）与机器人对话：

| 策略 | 说明 | 推荐场景 |
|------|------|----------|
| `open` | 任何人发消息都会直接回复，无需审批 | **个人使用（推荐默认）** |
| `pairing` | 新用户首次发消息会收到配对码，需要管理员执行 `openclaw pairing approve <code>` 批准后才能聊天 | 多人共用、需要控制访问的场景 |
| `allowlist` | 只有白名单中的用户才能聊天 | 严格控制访问 |
| `disabled` | 禁用私聊 | 只允许群聊使用 |

**重要**：如果使用 `pairing` 策略，用户首次给机器人发消息时会看到类似这样的提示：
> OpenClaw: access not configured for this user. Pairing code: 2TXVEKZS

此时需要在安装了 OpenClaw 的机器上执行：
```bash
openclaw pairing approve 2TXVEKZS
```
批准后用户就可以正常聊天了。

**建议**：个人使用直接用 `open`，省去审批步骤。团队/公司共用时改为 `pairing` 防止非授权人员使用。

#### 5. 验证

在飞书里搜索你创建的应用机器人：
1. 发一条文字消息 → 应该收到流式卡片回复
2. 发一张图片 → 机器人应该能识别图片内容并回复
3. 发一个文件(PDF/Excel) → 机器人应该能读取内容

如果发消息后没有收到回复，检查：
1. `openclaw status` — Gateway 是否在运行
2. `openclaw logs --follow` — 查看实时日志
3. 如果日志显示 "access not configured" → 说明 dmPolicy 是 `pairing`，需要执行 `openclaw pairing approve <code>`，或改为 `openclaw config set channels.feishu.dmPolicy open`

### 使用内置飞书插件（简单版，不推荐）

如果社区插件安装失败，可以退回内置插件。注意：内置插件发图片有 bug（发文件路径文本而非实际图片）。

```bash
openclaw plugins install @openclaw/feishu
# 配置方式同上
```

### 其他飞书插件

- **`@xzq-xu/feishu`** — 生产级插件，支持多账号、可配置流式参数（自定义卡片标题、合并延迟）、按用户设置工具策略。适合企业部署。
- **`@max1874/feishu`** — 功能全面的备选，支持图片/语音/流式。
- **飞书官方插件** — 飞书团队开发，能以你的身份操作飞书（写文档、建表格、日程），功能最强但需要 OAuth 授权，配置复杂。适合深度飞书用户。官方插件和其他插件不能同时用。

### 注意事项

- Gateway 每 60 秒探测一次飞书，会消耗 API 配额。一台机器每月约消耗 27,000 次调用。
- 如果多台机器共用同一个飞书 App，容易超出免费配额。建议每台机器创建不同的飞书应用。
- dmPolicy 修改后需要 `openclaw gateway restart` 才能生效。
- 社区插件和内置插件不能同时启用，安装新的会自动替换旧的。

---

## 钉钉

### 1. 创建钉钉应用

1. 打开 https://open-dev.dingtalk.com
2. 用钉钉账号登录
3. 创建应用 → 选择"企业内部应用" → 机器人
4. 填写应用信息
5. 在"凭证与基础信息"中复制 ClientID 和 ClientSecret

### 2. 配置 OpenClaw

```bash
openclaw config set channels.dingtalk.enabled true
openclaw config set channels.dingtalk.clientId "dingxxxxxxxx"
openclaw config set channels.dingtalk.clientSecret "你的ClientSecret"
openclaw gateway restart
```

或使用交互式向导：
```bash
openclaw channels add
# 选择 DingTalk，然后填入 ClientID 和 ClientSecret
```

### 3. 高级版（AI Card 流式输出）

钉钉官方团队开源了 `dingtalk-openclaw-connector`，支持类似 ChatGPT 的打字机效果。如果用户想要更好的体验可以考虑。

---

## Telegram

### 1. 创建 Bot

告诉用户：
> 在 Telegram 里搜索 @BotFather（注意是官方认证的那个），给它发消息 `/newbot`，然后按提示操作。

步骤：
1. 打开 Telegram，搜索 `@BotFather`
2. 发送 `/newbot`
3. 输入机器人名称（比如 "My AI Assistant"）
4. 输入机器人用户名（必须以 bot 结尾，比如 `myai_openclaw_bot`）
5. BotFather 会返回一个 Token，复制它

### 2. 配置

```bash
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.botToken "你的Token"
openclaw gateway restart
```

### 注意
- 国内需要代理才能用 Telegram
- 适合海外用户或有代理的用户

---

## Discord

### 1. 创建 Bot

1. 打开 https://discord.com/developers/applications
2. 点 "New Application"
3. 进入 Bot 页面，点 "Reset Token" 获取 Token
4. 开启 "Message Content Intent" 权限
5. 在 OAuth2 页面生成邀请链接，把 Bot 邀请到你的服务器

### 2. 配置

```bash
openclaw config set channels.discord.enabled true
openclaw config set channels.discord.botToken "你的Token"
openclaw gateway restart
```

### 注意
- 国内需要代理

---

## 企业微信

### 1. 创建自建应用

1. 登录企业微信管理后台 https://work.weixin.qq.com
2. 进入"应用管理" → "创建应用"
3. 填写应用信息
4. 复制 CorpID、AgentID、Secret

### 2. 配置回调

需要有公网 IP 或域名。配置回调 URL：
- URL 格式：`http://你的公网IP:18789/wecom`
- 消息加密方式选"兼容模式"

**重要**：把服务器的公网 IP 加到企业微信的"可信 IP"白名单里，否则能收到消息但不回复。

### 3. 配置 OpenClaw

```bash
openclaw config set channels.wecom.enabled true
# 按提示填入 CorpID、AgentID、Secret、Token、EncodingAESKey
openclaw gateway restart
```

### 4. 个人微信访问

通过企业微信的"微信插件"功能，在"我的企业 → 微信插件"扫码，就可以在个人微信里使用了。

限制：不能被加进微信群，只能一对一聊。

---

## 个人微信（不太推荐）

告诉用户：
> 直接连个人微信的稳定性不太好，而且有被封号的风险。如果你一定要用微信，建议走企业微信的方案更安全。

如果用户坚持要用：
```bash
openclaw plugins install @openclaw/wechat
# 需要配置 apiKey、proxyUrl 等
# 首次启动会显示二维码，用微信扫码登录
```

建议：
- 用小号测试
- iPad 协议比 Web 协议稳定
- 有被风控的可能

---

## 一键安装中国 IM 统合包

如果用户想同时接入多个中国平台（飞书+钉钉+QQ+企微），可以用统合包：

```bash
git clone https://github.com/BytePioneer-AI/openclaw-china.git
cd openclaw-china
pnpm install
pnpm build
openclaw plugins install -l ./packages/channels
openclaw china setup    # 交互式配置向导
```

这个包提供了统一的交互式配置体验，比一个个手动配置省事很多。
