#!/usr/bin/env bash
# OpenClaw 完整验收检查脚本
# 用法: bash verify_install.sh [--channel <channel_name>]
# 输出: JSON 格式的验收报告

set -e

CHANNEL="${1:-}"

OPENCLAW_OK=false
OPENCLAW_VERSION=""
GATEWAY_OK=false
GATEWAY_PID=""
TOKEN_SET=false
MODEL_OK=false
MODEL_NAME=""
DOCTOR_OK=false
DOCTOR_OUTPUT=""
CHANNEL_OK=false
CHANNEL_NAME=""
WEB_UI_OK=false
GATEWAY_MODE=""
SECURITY_OK=false

# --- 检查 OpenClaw 安装 ---
if command -v openclaw &>/dev/null; then
    OPENCLAW_OK=true
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
fi

# --- 检查 Gateway 状态 ---
status_output=$(openclaw status 2>&1 || true)
if echo "$status_output" | grep -qi "running"; then
    GATEWAY_OK=true
    GATEWAY_PID=$(echo "$status_output" | grep -oE 'pid [0-9]+' | grep -oE '[0-9]+' || echo "")
fi

# --- 检查 Token ---
config_file="$HOME/.openclaw/openclaw.json"
if [ -f "$config_file" ]; then
    if python3 -c "
import json, sys
with open('$config_file') as f:
    c = json.load(f)
token = c.get('gateway', {}).get('token', '')
sys.exit(0 if token else 1)
" 2>/dev/null; then
        TOKEN_SET=true
    fi
fi

# --- 检查模型配置 ---
if [ -f "$config_file" ]; then
    MODEL_NAME=$(python3 -c "
import json
with open('$config_file') as f:
    c = json.load(f)
primary = c.get('agents', {}).get('defaults', {}).get('model', {})
if isinstance(primary, dict):
    print(primary.get('primary', ''))
elif isinstance(primary, str):
    print(primary)
else:
    print('')
" 2>/dev/null || echo "")
    if [ -n "$MODEL_NAME" ]; then
        MODEL_OK=true
    fi
fi

# --- 检查 Gateway mode ---
if [ -f "$config_file" ]; then
    GATEWAY_MODE=$(python3 -c "
import json
with open('$config_file') as f:
    c = json.load(f)
print(c.get('gateway', {}).get('mode', 'local'))
" 2>/dev/null || echo "unknown")
fi

# --- 安全检查 ---
if [ "$TOKEN_SET" = true ] && [ "$GATEWAY_MODE" = "local" ]; then
    SECURITY_OK=true
fi

# --- 检查 Web UI ---
if curl -sI --max-time 5 http://127.0.0.1:18789/ 2>/dev/null | head -1 | grep -qE "200|301|302"; then
    WEB_UI_OK=true
fi

# --- 运行 doctor ---
doctor_output=$(openclaw doctor 2>&1 || true)
if echo "$doctor_output" | grep -qi "all checks passed\|no issues"; then
    DOCTOR_OK=true
fi
# 截取前 500 字符避免 JSON 过大
DOCTOR_OUTPUT=$(echo "$doctor_output" | head -20 | tr '"' "'" | tr '\n' ' ' | cut -c1-500)

# --- 检查通道 ---
if [ -n "$CHANNEL" ] && [ "$CHANNEL" != "web" ]; then
    CHANNEL_NAME="$CHANNEL"
    # 尝试检查通道是否配置
    if [ -f "$config_file" ]; then
        channel_enabled=$(python3 -c "
import json
with open('$config_file') as f:
    c = json.load(f)
channels = c.get('channels', {})
ch = channels.get('$CHANNEL', {})
print('true' if ch.get('enabled', False) else 'false')
" 2>/dev/null || echo "false")
        if [ "$channel_enabled" = "true" ]; then
            CHANNEL_OK=true
        fi
    fi
elif [ "$CHANNEL" = "web" ] || [ -z "$CHANNEL" ]; then
    CHANNEL_NAME="web"
    CHANNEL_OK=$WEB_UI_OK
fi

# --- 汇总结果 ---
ALL_PASS=true
for check in "$OPENCLAW_OK" "$GATEWAY_OK" "$TOKEN_SET" "$MODEL_OK" "$WEB_UI_OK" "$SECURITY_OK"; do
    if [ "$check" != "true" ]; then
        ALL_PASS=false
        break
    fi
done

# --- 输出 JSON ---
cat <<ENDJSON
{
  "all_pass": $ALL_PASS,
  "checks": {
    "openclaw_installed": {"pass": $OPENCLAW_OK, "detail": "$OPENCLAW_VERSION"},
    "gateway_running": {"pass": $GATEWAY_OK, "detail": "pid $GATEWAY_PID"},
    "gateway_token": {"pass": $TOKEN_SET, "detail": ""},
    "model_configured": {"pass": $MODEL_OK, "detail": "$MODEL_NAME"},
    "web_ui_accessible": {"pass": $WEB_UI_OK, "detail": "http://127.0.0.1:18789/"},
    "security": {"pass": $SECURITY_OK, "detail": "mode=$GATEWAY_MODE, token=$TOKEN_SET"},
    "doctor": {"pass": $DOCTOR_OK, "detail": "$DOCTOR_OUTPUT"},
    "channel": {"pass": $CHANNEL_OK, "detail": "$CHANNEL_NAME"}
  }
}
ENDJSON
