# OpenClaw 故障排查手册

## 配置架构（必读）

OpenClaw 有**三层配置文件**，改错地方或漏改就会出问题：

| 文件 | 路径 | 作用 | 谁管理 |
|------|------|------|--------|
| 主配置 | `~/.openclaw/openclaw.json` | 全局配置源头，用户唯一应该编辑的文件 | 用户手动编辑 |
| Agent 模型定义 | `~/.openclaw/agents/main/agent/models.json` | embedded runner 读取的模型信息 | **daemon 重启时自动生成** |
| 认证凭证 | `~/.openclaw/agents/main/agent/auth-profiles.json` | embedded runner API 认证用 | 用户手动或 wizard 生成 |
| 日志 | `/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log` | 运行时日志 | 自动生成 |

### 关键规则

1. **`models.json` 是自动生成的** — daemon 重启时从 `openclaw.json` 生成，手动改可能被 linter 还原。
2. **embedded runner 认证链** — 它用 `auth-profiles.json` 的 token 做 API 认证，provider 名必须匹配 `models.json` 中的 provider 名。
3. **config hot reload ≠ daemon restart** — 热加载只更新 `openclaw.json` 的部分设置，**不会重新生成 `models.json`**。改了模型配置后必须 `openclaw daemon restart`。
4. **重启后必须检查 models.json** — 有时 apiKey 等字段不会正确同步过来，需要手动确认并可能需要二次重启。

### 三个文件必须一致

```
openclaw.json         → models.providers.<name>.baseUrl / apiKey
models.json           → providers.<name>.baseUrl / apiKey
auth-profiles.json    → <name>:manual.token
```

**provider 名必须统一。** 例如都用 `openai`，不能一个叫 `openai` 一个叫 `custom-xxx`，否则 embedded runner 找不到匹配的认证信息。

### daemon restart vs gateway restart

| 命令 | 作用 | 何时用 |
|------|------|--------|
| `openclaw daemon restart` | 重启整个守护进程，重新加载所有配置，重新生成 `models.json` | **改了配置后用这个** |
| `openclaw gateway restart` | 只重启网关 HTTP 服务 | 仅网络层面问题 |

---

## 排查流程

遇到 OpenClaw 问题时，按以下顺序诊断：

### 第一步：确认 daemon 状态

```bash
openclaw daemon status
```

确认 `Runtime: running` 和 `RPC probe: ok`。

### 第二步：查日志

```bash
# 看最近日志
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# 搜索错误
grep -i "error\|502\|fail\|timeout" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -30

# 看飞书/平台相关
grep -i "feishu\|dispatch\|embedded" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -20
```

### 第三步：确认三个配置文件一致

读取并对比以下三个文件中的 provider 名、baseUrl、apiKey/token 是否一致：

```bash
cat ~/.openclaw/openclaw.json | python3 -c "import sys,json;d=json.load(sys.stdin);print(json.dumps(d.get('models',{}).get('providers',{}),indent=2))"
cat ~/.openclaw/agents/main/agent/models.json
cat ~/.openclaw/agents/main/agent/auth-profiles.json
```

---

## 问题诊断详解

### 502 Upstream request failed

**最常见原因：CDN/中转站不完整支持 OpenAI Responses API。**

#### 症状

- 第一条消息正常回复
- 第二条消息（或使用工具后的消息）报 502
- 用 `/new` 或 `/clear` 开新会话后又能回复一次

#### 根因

OpenClaw 使用 OpenAI Responses API (`/v1/responses`)。对话历史中会包含 `function_call` 和 `function_call_output` 类型的 input item（工具调用记录）。

很多第三方 CDN/中转（如 Sub2API 系列）不支持这些 item 类型：
- 第一条消息没有工具调用历史 → 成功
- OpenClaw 使用工具后，历史中出现 `function_call` item → 第二条就 502

#### 排查方法

1. 观察 502 是否只出现在第二条及之后的消息
2. `/new` 开新会话后是否能恢复一次
3. 用抓包代理（见下方）确认请求 payload 中是否有 `type: "function_call"` 的 input item

#### 解决

换一个完整支持 OpenAI Responses API 的 CDN，包括支持 `function_call`、`function_call_output` 等所有 input item 类型。

完整切换步骤见下方「切换 CDN / API 地址」。

---

### 模型配置不生效

#### 症状

改了 `openclaw.json` 但 agent 还在用旧模型/旧 key。

#### 排查 checklist

1. **只改了 `models.providers` 没改 `agents.defaults.model.primary`** → 两处都要改
2. **改完没重启 daemon** → `openclaw daemon restart`
3. **`models.json` 没同步更新** → 重启后读取 `~/.openclaw/agents/main/agent/models.json` 确认
4. **`auth-profiles.json` 的 provider 名不匹配** → 确保和 `models.json` 中的 provider 名一致
5. **`auth-profiles.json` 的 token 还是旧 key** → 手动更新

#### 正确的完整模型配置

`openclaw.json` 中需要同时配置 `models.providers` 和 `agents.defaults`：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "openai": {
        "api": "openai-responses",
        "baseUrl": "https://your-cdn.com/v1",
        "apiKey": "sk-your-key",
        "models": [{
          "id": "model-name",
          "name": "model-name",
          "input": ["text", "image"],
          "contextWindow": 200000,
          "maxTokens": 8192
        }]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": { "primary": "openai/model-name" },
      "imageModel": { "primary": "openai/model-name" },
      "models": { "openai/model-name": {} }
    }
  }
}
```

`auth-profiles.json` 中 provider 名必须匹配：

```json
{
  "openai:manual": {
    "provider": "openai",
    "token": "sk-your-key",
    "createdAt": "2026-01-01T00:00:00.000Z"
  }
}
```

---

### 图片功能不可用

#### 症状

不能识别用户发的图片，或不能给用户发图片。

#### 排查 checklist

1. **模型定义中 `input` 字段没包含 `"image"`** → 在 `openclaw.json` 的 models 数组中加上 `"input": ["text", "image"]`
2. **没配 `imageModel`** → 在 `agents.defaults` 中添加 `"imageModel": { "primary": "openai/model-name" }`
3. **`imageModel` 引用的 provider 在 `auth-profiles.json` 中不存在** → 统一 provider 名
4. **CDN 不支持图片输入** → 换 CDN 或确认 CDN 支持多模态
5. **飞书缺少 `im:resource` 权限** → 去飞书开放平台添加该权限
6. **使用了内置 `@openclaw/feishu` 插件** → 换用社区版 `@m1heng-clawd/feishu`（内置插件有图片 bug）

---

### 消息发了没反应（无回复无报错）

#### 排查步骤

1. `openclaw daemon status` → 确认运行中
2. 查日志看消息是否被接收：
   ```bash
   grep "dispatching to agent" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -5
   ```
3. 看是否有 `typing TTL reached` → 说明 API 调用超时（2 分钟），通常是 key 无效或 CDN 不可达
4. 确认 `models.json` 的 apiKey 和 `auth-profiles.json` 的 token 都是正确的 key
5. 如果重启后 `models.json` 的 key 还是旧的 → 手动改 + 再 `openclaw daemon restart`

---

### Setup Wizard 不兼容自定义 API

OpenClaw 的 `openclaw doctor` / `openclaw setup` 向导只支持验证：
- OpenAI-compatible（Chat Completions：`/v1/chat/completions`）
- Anthropic-compatible（Messages API）

如果你的 CDN 只支持 Responses API (`/v1/responses`)，向导验证会失败。

**解决：** 跳过向导，手动编辑 `openclaw.json`，设置 `"api": "openai-responses"`，然后 `openclaw daemon restart`。

---

## 操作手册

### 切换 CDN / API 地址（完整步骤）

**每一步都不能少**，漏一步就可能出问题：

1. **编辑 `~/.openclaw/openclaw.json`** — 改 `models.providers` 中的 `baseUrl` 和 `apiKey`
2. **编辑 `~/.openclaw/agents/main/agent/auth-profiles.json`** — 改对应 provider 的 `token`
3. **`openclaw daemon restart`**
4. **检查 `~/.openclaw/agents/main/agent/models.json`** — 确认 `baseUrl` 和 `apiKey` 都已更新为新值
5. 如果 `apiKey` 没更新 → 手动改 `models.json` → 再 `openclaw daemon restart` 一次
6. 在聊天平台发 `/new` 开新会话 → 发测试消息验证

或者使用 `generate_config.py` 脚本自动完成步骤 1-2：
```bash
python3 {baseDir}/scripts/generate_config.py --provider openai --api-key "新Key" --base-url "https://新CDN地址/v1" --model "模型名"
```
然后执行步骤 3-6。

### 抓包调试（进阶）

当怀疑是 CDN 不兼容时，可以用 Node.js 代理抓取 OpenClaw 发出的实际请求：

```javascript
// /tmp/proxy-dump.js
const http = require('http');
const https = require('https');
const fs = require('fs');

const TARGET = 'https://your-cdn.com';  // 真实 CDN 地址

http.createServer((req, res) => {
  let body = [];
  req.on('data', chunk => body.push(chunk));
  req.on('end', () => {
    const payload = Buffer.concat(body).toString();
    fs.writeFileSync('/tmp/openclaw-request.json', payload);
    console.log(`Captured ${payload.length} bytes`);

    const url = new URL(req.url, TARGET);
    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: req.method,
      headers: { ...req.headers, host: url.hostname }
    };

    const proxy = https.request(options, proxyRes => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res);
    });
    proxy.on('error', e => { res.writeHead(502); res.end(e.message); });
    proxy.end(payload);
  });
}).listen(19999, () => console.log('Proxy on :19999'));
```

使用方法：
1. 启动代理：`node /tmp/proxy-dump.js`
2. 临时把 `models.json` 的 `baseUrl` 改为 `http://127.0.0.1:19999/v1`
3. `openclaw daemon restart`
4. 在聊天平台发消息
5. 查看 `/tmp/openclaw-request.json` 分析请求内容
6. 测试完后改回正确的 `baseUrl` 并重启

---

## API 协议兼容性速查

| 协议 | OpenClaw 配置值 | 端点 | 特性 |
|------|----------------|------|------|
| OpenAI Responses | `openai-responses` | `/v1/responses` | 支持 `function_call` items、流式、图片 |
| OpenAI Chat Completions | `openai-completions` | `/v1/chat/completions` | 传统格式，大部分中转支持 |
| Anthropic Messages | `anthropic-messages` | `/v1/messages` | Claude 系列 |

### 选择建议

- **OpenAI 官方 / 完整兼容的 CDN** → `openai-responses`
- **大部分国内中转 / 第三方 CDN** → 先试 `openai-responses`，如果第二条消息 502 就说明 CDN 不完整支持，需要换 CDN
- **测试 CDN 兼容性** → 发一条消息看是否正常 → 再发第二条（触发工具调用后）看是否还正常
- 注意：`openai-completions` 虽然兼容性好，但会丢失 OpenClaw 的部分高级功能（工具调用等）

### 已知 CDN 兼容性

| CDN 类型 | Responses API 完整支持 | 备注 |
|----------|----------------------|------|
| OpenAI 官方 | 完整支持 | |
| Sub2API 系列 | 不完整 | 不支持 `function_call` input items |
| 完整代理（透传原始请求） | 取决于上游 | 纯透传的通常没问题 |
