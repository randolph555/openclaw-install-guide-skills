#!/usr/bin/env python3
"""
OpenClaw 配置生成器
用法: python3 generate_config.py --provider <provider> --api-key <key> [--base-url <url>] [--model <model>] [--proxy <proxy>]
输出: 直接写入 ~/.openclaw/openclaw.json（合并模式，不覆盖已有配置）
"""

import argparse
import json
import os
import sys
from pathlib import Path

# 预设的模型配置模板
PROVIDER_TEMPLATES = {
    "gemini": {
        "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
        "api": "openai-completions",
        "models": [{"id": "gemini-2.5-flash", "name": "Gemini 2.5 Flash", "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 8192}],
        "default_model": "gemini-2.5-flash"
    },
    "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "api": "anthropic-messages",
        "models": [{"id": "claude-sonnet-4-20250514", "name": "Claude Sonnet 4", "input": ["text", "image"], "contextWindow": 200000, "maxTokens": 8192}],
        "default_model": "claude-sonnet-4-20250514"
    },
    "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "api": "openai-responses",
        "models": [{"id": "gpt-4o", "name": "GPT-4o", "input": ["text", "image"], "contextWindow": 128000, "maxTokens": 4096}],
        "default_model": "gpt-4o"
    },
    "qwen": {
        "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "api": "openai-completions",
        "models": [{"id": "qwen-max", "name": "通义千问 Max", "input": ["text", "image"], "contextWindow": 128000, "maxTokens": 8192}],
        "default_model": "qwen-max"
    },
    "deepseek": {
        "baseUrl": "https://api.deepseek.com/v1",
        "api": "openai-completions",
        "models": [{"id": "deepseek-chat", "name": "DeepSeek Chat", "input": ["text"], "contextWindow": 128000, "maxTokens": 8192}],
        "default_model": "deepseek-chat"
    },
    "moonshot": {
        "baseUrl": "https://api.moonshot.cn/v1",
        "api": "openai-completions",
        "models": [{"id": "moonshot-v1-128k", "name": "Kimi 128K", "input": ["text"], "contextWindow": 128000, "maxTokens": 8192}],
        "default_model": "moonshot-v1-128k"
    },
    "zhipu": {
        "baseUrl": "https://open.bigmodel.cn/api/paas/v4",
        "api": "openai-completions",
        "models": [{"id": "glm-4-flash", "name": "GLM-4 Flash", "input": ["text", "image"], "contextWindow": 128000, "maxTokens": 4096}],
        "default_model": "glm-4-flash"
    },
    "ollama": {
        "baseUrl": "http://localhost:11434/v1",
        "api": "openai-completions",
        "models": [{"id": "llama3.2", "name": "Llama 3.2", "input": ["text"], "contextWindow": 128000, "maxTokens": 4096}],
        "default_model": "llama3.2"
    }
}


def get_config_path():
    return Path.home() / ".openclaw" / "openclaw.json"


def get_env_path():
    return Path.home() / ".openclaw" / ".env"


def get_auth_profiles_path():
    return Path.home() / ".openclaw" / "agents" / "main" / "agent" / "auth-profiles.json"


def sync_auth_profiles(provider_name, api_key):
    """同步更新 auth-profiles.json 中对应 provider 的 token"""
    path = get_auth_profiles_path()
    profiles = {}
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            profiles = json.load(f)

    profile_key = f"{provider_name}:manual"
    profiles[profile_key] = {
        "provider": provider_name,
        "token": api_key,
        "createdAt": profiles.get(profile_key, {}).get("createdAt", "2026-01-01T00:00:00.000Z")
    }

    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(profiles, f, indent=2, ensure_ascii=False)
    print(f"Auth profile synced: {path} ({profile_key})")


def load_config(path):
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_config(path, config):
    path.parent.mkdir(parents=True, exist_ok=True)
    # 备份原文件
    if path.exists():
        backup = path.with_suffix(".json.bak")
        with open(path, "r") as src, open(backup, "w") as dst:
            dst.write(src.read())
    with open(path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)


def deep_merge(base, override):
    """递归合并两个字典，override 的值优先"""
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def generate_model_config(provider, api_key, base_url=None, model=None, api_protocol=None):
    """生成 models.providers 配置块"""
    if provider == "custom":
        if not base_url or not model:
            print("Error: --base-url and --model are required for custom provider", file=sys.stderr)
            sys.exit(1)
        protocol = api_protocol or "openai-responses"
        # 使用 "openai" 作为 provider 名，确保和 auth-profiles.json 中的 "openai:manual" 匹配
        return {
            "providers": {
                "openai": {
                    "baseUrl": base_url,
                    "apiKey": api_key,
                    "api": protocol,
                    "models": [{"id": model, "name": model, "input": ["text", "image"], "contextWindow": 128000, "maxTokens": 8192}]
                }
            }
        }, f"openai/{model}"

    template = PROVIDER_TEMPLATES.get(provider)
    if not template:
        print(f"Error: Unknown provider '{provider}'. Available: {', '.join(PROVIDER_TEMPLATES.keys())}, custom", file=sys.stderr)
        sys.exit(1)

    effective_base_url = base_url or template["baseUrl"]
    effective_model = model or template["default_model"]
    models = template["models"]
    # 如果用户指定了模型且不在预设列表中，添加进去
    if effective_model not in [m["id"] for m in models]:
        models = models + [{"id": effective_model, "name": effective_model, "contextWindow": 128000, "maxTokens": 8192}]

    return {
        "providers": {
            provider: {
                "baseUrl": effective_base_url,
                "apiKey": api_key,
                "api": template["api"],
                "models": models
            }
        }
    }, f"{provider}/{effective_model}"


def set_proxy(proxy_addr):
    """将代理写入 ~/.openclaw/.env（不碰系统配置）"""
    env_path = get_env_path()
    env_path.parent.mkdir(parents=True, exist_ok=True)

    existing = {}
    if env_path.exists():
        with open(env_path, "r") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    existing[k] = v

    existing["HTTP_PROXY"] = proxy_addr
    existing["HTTPS_PROXY"] = proxy_addr
    existing["NO_PROXY"] = "127.0.0.1,localhost,::1"

    with open(env_path, "w") as f:
        for k, v in existing.items():
            f.write(f"{k}={v}\n")

    print(f"Proxy written to {env_path}")


def main():
    parser = argparse.ArgumentParser(description="OpenClaw Config Generator")
    parser.add_argument("--provider", required=True,
                        help="Model provider: gemini, anthropic, openai, qwen, deepseek, moonshot, zhipu, ollama, custom")
    parser.add_argument("--api-key", required=True, help="API key")
    parser.add_argument("--base-url", help="Custom base URL (required for 'custom' provider)")
    parser.add_argument("--model", help="Model ID (uses provider default if not specified)")
    parser.add_argument("--api-protocol",
                        help="API protocol: openai-completions, openai-responses, or anthropic-messages. "
                             "Note: OpenAI official API has migrated to /v1/responses (openai-responses). "
                             "Most third-party providers still use openai-completions. For custom provider, defaults to openai-completions.")
    parser.add_argument("--proxy", help="Proxy address (e.g., http://127.0.0.1:7890)")
    parser.add_argument("--dry-run", action="store_true", help="Print config without writing")

    args = parser.parse_args()

    # 生成模型配置
    model_providers, primary_model = generate_model_config(
        args.provider, args.api_key, args.base_url, args.model, args.api_protocol
    )

    new_config = {
        "models": deep_merge({"mode": "merge"}, model_providers),
        "agents": {
            "defaults": {
                "model": {
                    "primary": primary_model
                },
                "imageModel": {
                    "primary": primary_model
                },
                "models": {
                    primary_model: {}
                }
            }
        }
    }

    if args.dry_run:
        print(json.dumps(new_config, indent=2, ensure_ascii=False))
        return

    # 合并到现有配置
    config_path = get_config_path()
    existing = load_config(config_path)
    merged = deep_merge(existing, new_config)
    save_config(config_path, merged)
    print(f"Config written to {config_path}")
    print(f"Primary model: {primary_model}")

    # 同步 auth-profiles.json（确保 embedded runner 能认证）
    provider_name = args.provider if args.provider != "custom" else "openai"
    sync_auth_profiles(provider_name, args.api_key)

    # 配置代理
    if args.proxy:
        set_proxy(args.proxy)

    # 验证
    print("\nValidating...")
    ret = os.system("openclaw config validate 2>&1")
    if ret == 0:
        print("Config valid!")
    else:
        print("Warning: config validation returned non-zero. Check the output above.", file=sys.stderr)


if __name__ == "__main__":
    main()
