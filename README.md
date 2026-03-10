# OpenClaw Setup Skill (小龙虾安装引导助手)

一个 Claude Code / Codex 技能，帮助完全不懂代码的小白用户从零安装、配置和使用 [OpenClaw（小龙虾）](https://github.com/openclaw/openclaw) AI 助手。

## 它能做什么

只需要说一句 **"帮我装个小龙虾"**，AI 就会手把手带你完成全部流程：

- **环境检测** — 自动检测系统、Node.js、Docker、网络环境
- **安装 OpenClaw** — 支持 Docker 和本地安装（Mac / Windows / Linux）
- **网络代理** — 自动检测是否需要代理，配置到 OpenClaw 内部（不碰系统环境变量）
- **大模型配置** — 支持 OpenAI / Claude / Gemini / 国内模型 / Ollama / 自定义 OpenAI 兼容
- **IM 平台接入** — 飞书、钉钉、QQ、Telegram、Discord 一键配置
- **安全加固** — Gateway Token、访问控制
- **完整验收** — 自动验收检查，确保一切正常

## 安装

### Claude Code

```bash
git clone https://github.com/randolph555/openclaw-install-guide-skills.git ~/.claude/skills/openclaw-setup
```

### Codex

```bash
git clone https://github.com/randolph555/openclaw-install-guide-skills.git ~/.codex/skills/openclaw-setup
```

### 手动安装

```bash
# 克隆到任意位置
git clone https://github.com/randolph555/openclaw-install-guide-skills.git

# 复制到 Claude Code 技能目录
cp -r openclaw-install-guide-skills ~/.claude/skills/openclaw-setup

# 确保脚本有执行权限
chmod +x ~/.claude/skills/openclaw-setup/scripts/*.sh
chmod +x ~/.claude/skills/openclaw-setup/scripts/*.py
```

安装完成后重启 Claude Code 即可使用。

## 使用方式

安装好技能后，在 Claude Code 中说以下任何一句话都会自动触发：

- "帮我装个小龙虾"
- "我想要一只小龙虾"
- "帮我搞个 OpenClaw"
- "openclaw 怎么安装"
- "小龙虾怎么部署"

然后跟着引导走就行，AI 会尽量减少打断，连续帮你完成。

## 项目结构

```
├── SKILL.md                    # 技能主文件（触发条件 + 执行流程）
├── README.md                   # 本文件
├── scripts/
│   ├── detect_env.sh           # 一次性环境检测（输出 JSON）
│   ├── generate_config.py      # 大模型配置生成（8 种预设 + 自定义）
│   ├── setup_channel.sh        # IM 平台一键配置（飞书/钉钉/QQ/TG/Discord）
│   └── verify_install.sh       # 完整验收检查（输出 JSON）
└── references/
    ├── model-setup.md          # 各大模型详细配置指南
    ├── channels-setup.md       # 各 IM 平台接入详细指南
    ├── docker-install.md       # Docker 安装指南
    ├── local-install.md        # 本地安装指南（Mac/Win/Linux）
    ├── network-proxy.md        # 网络代理配置指南
    └── cloud-deploy.md         # 云端部署指南
```

## 设计理念

- **最少打断** — 全流程只有 3 个交互点，其余连续执行
- **脚本优先** — 确定性操作全用脚本，减少幻觉，提高速度和稳定性
- **不碰系统环境** — 绝对不修改 `~/.zshrc` 等 shell 配置，代理只写进 OpenClaw 内部
- **完整交付** — 不是装完就走，而是配好模型、接好平台、验收通过才算完成

## 支持的大模型

| 模型 | 协议 |
|------|------|
| OpenAI (GPT-4o 等) | openai-responses |
| Claude (Anthropic) | anthropic-messages |
| Google Gemini | openai-completions |
| 深度求索 DeepSeek | openai-completions |
| 阿里通义千问 | openai-completions |
| 零一万物 Yi | openai-completions |
| Ollama (本地模型) | openai-completions |
| 自定义 OpenAI 兼容 | openai-completions / openai-responses |

## 支持的 IM 平台

| 平台 | 插件 | 特点 |
|------|------|------|
| 飞书 | `@m1heng-clawd/feishu` (推荐) | 图片收发、流式回复、语音、文档工具 |
| 钉钉 | 内置 | 企业内部应用 |
| QQ | `@sliverp/qqbot` | 腾讯简化入口，3 步搞定 |
| Telegram | 内置 | 海外用户首选 |
| Discord | 内置 | 海外用户 |

## License

MIT

## 说明

- 本技能的脚本根据 OpenClaw 官方文档和社区资料编写，尚未在所有环境下完整测试。如遇到问题欢迎提 issue。
- 不同操作系统、Node.js 版本、OpenClaw 版本可能存在兼容差异，脚本会尽量做检测和容错。
- 欢迎 PR 补充更多平台支持或修复兼容性问题。
