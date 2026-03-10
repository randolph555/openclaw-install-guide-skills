# 大模型配置详细指南

## 配置原理

OpenClaw 的模型配置存在 `~/.openclaw/openclaw.json` 文件里，核心结构是 `models.providers`。
不要用 `openclaw config set auth.openai.xxx`——这个路径不存在会报错。

正确方式有两种：
1. **直接帮用户编辑 `~/.openclaw/openclaw.json`**（推荐，你可以用 Edit 工具操作）
2. **用 `openclaw config wizard`** 交互式引导

配置的核心 JSON 结构：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "供应商名称": {
        "baseUrl": "API地址",
        "apiKey": "密钥",
        "api": "协议类型",
        "models": [
          {
            "id": "模型ID",
            "name": "显示名称",
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "供应商名称/模型ID"
      }
    }
  }
}
```

**协议规则**：
- Claude 系列 → `"api": "anthropic-messages"`
- 其他所有模型（GPT/Gemini/国内模型/Ollama）→ `"api": "openai-completions"`

**敏感信息保护**：apiKey 可以用环境变量代替。在 `~/.openclaw/.env` 文件中写入 `MY_API_KEY=sk-xxx`，然后配置中用 `"apiKey": "${MY_API_KEY}"` 引用。

---

## 选择建议

| 条件 | 推荐方案 |
|------|---------|
| 想免费试试 | Google Gemini（免费额度最大方）或 Ollama 本地模型 |
| 中国大陆无代理 | 通义千问 / Kimi / 智谱 GLM / DeepSeek |
| 追求最佳效果 | Anthropic Claude Sonnet 4.6 |
| 已有 ChatGPT Plus | OpenAI GPT |
| 电脑性能好（16G+ 内存）想完全离线 | Ollama + llama3.2 |
| 省钱但要好效果 | DeepSeek（最便宜的高质量模型） |
| 有自己的 API 中转/代理 | 自定义兼容 OpenAI 的方式 |

---

## 方案一：Google Gemini（推荐新手首选）

**为什么推荐**：免费额度最大方，注册简单。

### 获取 API Key

1. 打开 https://aistudio.google.com/apikey
2. 用 Google 账号登录（如果没有需要先注册一个）
3. 点击 "Create API Key"
4. 复制生成的 Key（长这样：`AIzaSy...`）
5. **立即保存！关掉页面后可能看不到了**

### 配置到 OpenClaw

帮用户编辑 `~/.openclaw/openclaw.json`，在 JSON 中写入或合并以下内容：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "google": {
        "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
        "apiKey": "用户的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "gemini-2.5-flash",
            "name": "Gemini 2.5 Flash",
            "contextWindow": 1000000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "google/gemini-2.5-flash"
      }
    }
  }
}
```

### 注意
- 需要能访问 Google（国内用户需要代理）
- 免费额度有限制，超出会收费

---

## 方案二：Anthropic Claude（效果最好）

### 获取 API Key

1. 打开 https://console.anthropic.com
2. 注册账号（需要邮箱和手机号验证）
3. 登录后点左侧菜单的 "API Keys"
4. 点 "Create Key"，起个名字（比如 "openclaw"）
5. **立刻复制保存！创建后只显示一次！** Key 长这样：`sk-ant-api03-...`

### 充值
新账号有 $5 免费额度。用完后：Settings → Billing → 添加信用卡 → 建议先设 $10-20 限额。

### 配置到 OpenClaw

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "sk-ant-api03-用户的Key",
        "api": "anthropic-messages",
        "models": [
          {
            "id": "claude-sonnet-4-20250514",
            "name": "Claude Sonnet 4",
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-20250514"
      }
    }
  }
}
```

注意 Claude 系列用 `"api": "anthropic-messages"`，不是 `openai-completions`。

### 费用参考
- Claude Sonnet 4.6：约 $3(输入) / $15(输出) 每百万 token
- 日常使用大约每天 $0.5 - $2

---

## 方案三：OpenAI GPT

### 获取 API Key

1. 打开 https://platform.openai.com/api-keys
2. 注册/登录
3. 点 "Create new secret key"
4. 复制保存 Key（长这样：`sk-proj-...`）
5. 充值：Billing → 添加支付方式 → 建议先充 $10

### 配置到 OpenClaw

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "sk-proj-用户的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "gpt-4o",
            "name": "GPT-4o",
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o"
      }
    }
  }
}
```

---

## 方案四：国内大模型（无需代理）

全部使用 `"api": "openai-completions"` 协议。

### 通义千问（阿里）

获取 Key：
1. 打开 https://dashscope.console.aliyun.com/
2. 用支付宝/淘宝账号登录
3. 在"API-KEY管理"中创建 Key → 复制保存

配置：
```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "qwen": {
        "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "apiKey": "用户的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen-max",
            "name": "通义千问 Max",
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "qwen/qwen-max"
      }
    }
  }
}
```

注意：阿里百炼的 API Key 有地域区分（北京/新加坡），Base URL 和 Key 地域要一致。

### Kimi（月之暗面）

获取 Key：https://platform.moonshot.cn → 注册 → 创建 API Key

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "moonshot": {
        "baseUrl": "https://api.moonshot.cn/v1",
        "apiKey": "用户的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "moonshot-v1-128k",
            "name": "Kimi 128K",
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "moonshot/moonshot-v1-128k"
      }
    }
  }
}
```

### 智谱 GLM

获取 Key：https://open.bigmodel.cn → 注册 → 创建 API Key

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "zhipu": {
        "baseUrl": "https://open.bigmodel.cn/api/paas/v4",
        "apiKey": "用户的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "glm-4-flash",
            "name": "GLM-4 Flash",
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "zhipu/glm-4-flash"
      }
    }
  }
}
```

### DeepSeek

获取 Key：https://platform.deepseek.com → 注册 → 创建 API Key

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "deepseek": {
        "baseUrl": "https://api.deepseek.com/v1",
        "apiKey": "用户的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "deepseek-chat",
            "name": "DeepSeek Chat",
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "deepseek/deepseek-chat"
      }
    }
  }
}
```

---

## 方案五：Ollama 本地模型（完全免费离线）

告诉用户：
> 这个方案是把"大脑"直接装在你电脑上，完全免费、不联网。但需要你的电脑有至少 16G 内存。

### 安装 Ollama

Mac：`brew install ollama`
Windows：打开 https://ollama.com → 下载安装包 → 双击安装
Linux：`curl -fsSL https://ollama.com/install.sh | sh`

### 下载模型

```bash
ollama serve                # 启动服务
ollama pull llama3.2        # 新窗口执行，约 4GB
ollama pull qwen2.5:7b      # 中文更强
```

### 配置到 OpenClaw

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1",
        "apiKey": "ollama",
        "api": "openai-completions",
        "models": [
          {
            "id": "llama3.2",
            "name": "Llama 3.2",
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.2"
      }
    }
  }
}
```

### 注意事项
- 至少 8G 可用内存（推荐 16G+）
- 首次下载模型需要几 GB 流量
- 效果不如 Claude/GPT，但日常聊天和简单任务够用

---

## 方案六：自定义兼容 OpenAI 的 API（中转/代理服务）

适合有自己的 API 中转服务、代理商、或者公司内部网关的用户。

问用户三个信息：
1. **API 地址**（Base URL）：比如 `https://openai.cdn01.cn/v1`
2. **API Key**：服务商给的密钥
3. **模型名称**：比如 `gpt-4o`、`claude-sonnet-4`

拿到后帮用户配置。通用模板：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "custom": {
        "baseUrl": "用户给的API地址",
        "apiKey": "用户给的Key",
        "api": "openai-completions",
        "models": [
          {
            "id": "用户给的模型名",
            "name": "用户给的模型名",
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "custom/用户给的模型名"
      }
    }
  }
}
```

**协议选择**：
- 如果用户说用的是 Claude 系列模型 → 把 `"api"` 改成 `"anthropic-messages"`
- 其他所有情况 → 用 `"openai-completions"`

**注意**：Base URL 末尾是否需要 `/v1` 取决于服务商，有些带有些不带。如果配了报错，试试加上或去掉 `/v1`。

---

## 配置完成后的验证

帮用户验证配置是否生效：

```bash
# 验证配置文件格式
openclaw config validate

# 重启 Gateway 加载新配置
openclaw gateway restart

# 测试模型是否能用
openclaw agent --message "你好，请做个自我介绍"
```

如果报错，常见原因：
- API Key 错了或过期了 → 去对应平台重新生成
- Base URL 不对 → 检查是否需要 `/v1` 后缀
- 配额用完了 → 去对应平台充值
- 网络不通 → 需要代理（参考 network-proxy.md）

## API Key 安全提醒

告诉用户：
> API Key 就像你银行卡的密码，绝对不能给别人看。千万不要发到群里、贴到网上。如果不小心泄露了，立刻去对应平台重新生成一个新的，旧的就作废了。

推荐用 `.env` 文件保护密钥：
```bash
# 编辑 ~/.openclaw/.env
echo 'MY_API_KEY=用户的Key' >> ~/.openclaw/.env
```
然后在 openclaw.json 中用 `"apiKey": "${MY_API_KEY}"` 引用。
