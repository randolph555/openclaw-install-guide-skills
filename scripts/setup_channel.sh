#!/usr/bin/env bash
# OpenClaw 聊天平台快速配置脚本
# 用法: bash setup_channel.sh <platform> [参数...]
#
# 示例:
#   bash setup_channel.sh qq
#   bash setup_channel.sh feishu --app-id cli_xxx --app-secret xxx --bot-name "AI助手"
#   bash setup_channel.sh dingtalk --client-id dingxxx --client-secret xxx
#   bash setup_channel.sh telegram --bot-token xxx
#   bash setup_channel.sh discord --bot-token xxx

set -e

PLATFORM="$1"
shift || true

usage() {
    cat <<EOF
OpenClaw Channel Setup Script

Usage: bash setup_channel.sh <platform> [options]

Platforms:
  qq          QQ 机器人 (需要先在 QQ 开放平台创建)
  feishu      飞书 (需要 App ID 和 App Secret)
  dingtalk    钉钉 (需要 Client ID 和 Client Secret)
  telegram    Telegram (需要 Bot Token)
  discord     Discord (需要 Bot Token)

Options vary by platform. Run with platform name only to see required options.
EOF
    exit 1
}

if [ -z "$PLATFORM" ]; then
    usage
fi

restart_gateway() {
    echo "Restarting gateway..."
    openclaw gateway restart 2>&1 || true
    sleep 3
    echo "Gateway restarted."
}

verify_channel() {
    local channel=$1
    echo "Verifying $channel configuration..."
    sleep 2
    status=$(openclaw status 2>&1 || true)
    if echo "$status" | grep -qi "running"; then
        echo "OK: Gateway is running with $channel configured."
        echo "Please send a test message to verify."
    else
        echo "WARNING: Gateway may not be running. Run 'openclaw status' to check."
    fi
}

case "$PLATFORM" in
    qq)
        echo "=== QQ 机器人配置 ==="
        echo ""
        echo "步骤："
        echo "1. 打开 https://q.qq.com/qqbot/openclaw/login.html"
        echo "2. 用手机 QQ 扫码登录"
        echo "3. 点击'创建机器人'"
        echo "4. 复制页面上给出的 3 条命令并执行"
        echo ""
        echo "如果你已经有命令了，直接执行即可。"
        echo "通常是这样的格式："
        echo "  openclaw plugins install @sliverp/qqbot@latest"
        echo "  openclaw channels add --channel qqbot --token \"AppID:AppSecret\""
        echo "  openclaw gateway restart"
        ;;

    feishu)
        APP_ID=""
        APP_SECRET=""
        BOT_NAME="AI助手"
        DM_POLICY="open"

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --app-id) APP_ID="$2"; shift 2;;
                --app-secret) APP_SECRET="$2"; shift 2;;
                --bot-name) BOT_NAME="$2"; shift 2;;
                --dm-policy) DM_POLICY="$2"; shift 2;;
                *) echo "Unknown option: $1"; exit 1;;
            esac
        done

        if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
            echo "=== 飞书配置 ==="
            echo ""
            echo "需要参数: --app-id <App ID> --app-secret <App Secret> [--bot-name <名称>] [--dm-policy <open|pairing>]"
            echo ""
            echo "获取方式:"
            echo "1. 打开 https://open.feishu.cn/app"
            echo "2. 创建自建应用"
            echo "3. 在'凭证与基础信息'中复制 App ID 和 App Secret"
            echo "4. 在'权限管理'中添加: im:message, im:message:send_as_bot"
            echo "5. 发布应用版本"
            echo ""
            echo "dm-policy 说明:"
            echo "  open    - 任何人发消息都会回复（个人使用推荐，默认）"
            echo "  pairing - 新用户需要配对码批准后才能聊天（多人共用推荐）"
            exit 1
        fi

        echo "Installing feishu plugin (@m1heng-clawd/feishu, supports image/streaming/voice)..."
        openclaw plugins install @m1heng-clawd/feishu 2>&1 || true

        echo "Configuring feishu channel (dmPolicy=$DM_POLICY)..."
        openclaw config set channels.feishu.enabled true 2>&1
        openclaw config set channels.feishu.dmPolicy "$DM_POLICY" 2>&1
        openclaw config set channels.feishu.accounts.main.appId "$APP_ID" 2>&1
        openclaw config set channels.feishu.accounts.main.appSecret "$APP_SECRET" 2>&1
        openclaw config set channels.feishu.accounts.main.botName "$BOT_NAME" 2>&1

        restart_gateway
        verify_channel "feishu"
        ;;

    dingtalk)
        CLIENT_ID=""
        CLIENT_SECRET=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --client-id) CLIENT_ID="$2"; shift 2;;
                --client-secret) CLIENT_SECRET="$2"; shift 2;;
                *) echo "Unknown option: $1"; exit 1;;
            esac
        done

        if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
            echo "=== 钉钉配置 ==="
            echo ""
            echo "需要参数: --client-id <Client ID> --client-secret <Client Secret>"
            echo ""
            echo "获取方式:"
            echo "1. 打开 https://open-dev.dingtalk.com"
            echo "2. 创建企业内部应用 -> 机器人"
            echo "3. 复制 ClientID 和 ClientSecret"
            exit 1
        fi

        echo "Configuring dingtalk channel..."
        openclaw config set channels.dingtalk.enabled true 2>&1
        openclaw config set channels.dingtalk.clientId "$CLIENT_ID" 2>&1
        openclaw config set channels.dingtalk.clientSecret "$CLIENT_SECRET" 2>&1

        restart_gateway
        verify_channel "dingtalk"
        ;;

    telegram)
        BOT_TOKEN=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --bot-token) BOT_TOKEN="$2"; shift 2;;
                *) echo "Unknown option: $1"; exit 1;;
            esac
        done

        if [ -z "$BOT_TOKEN" ]; then
            echo "=== Telegram 配置 ==="
            echo ""
            echo "需要参数: --bot-token <Bot Token>"
            echo ""
            echo "获取方式:"
            echo "1. 在 Telegram 搜索 @BotFather"
            echo "2. 发送 /newbot"
            echo "3. 按提示创建机器人"
            echo "4. 复制给出的 Token"
            exit 1
        fi

        echo "Configuring telegram channel..."
        openclaw config set channels.telegram.enabled true 2>&1
        openclaw config set channels.telegram.botToken "$BOT_TOKEN" 2>&1

        restart_gateway
        verify_channel "telegram"
        ;;

    discord)
        BOT_TOKEN=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --bot-token) BOT_TOKEN="$2"; shift 2;;
                *) echo "Unknown option: $1"; exit 1;;
            esac
        done

        if [ -z "$BOT_TOKEN" ]; then
            echo "=== Discord 配置 ==="
            echo ""
            echo "需要参数: --bot-token <Bot Token>"
            echo ""
            echo "获取方式:"
            echo "1. 打开 https://discord.com/developers/applications"
            echo "2. New Application -> Bot -> Reset Token"
            echo "3. 开启 Message Content Intent"
            echo "4. 复制 Token"
            exit 1
        fi

        echo "Configuring discord channel..."
        openclaw config set channels.discord.enabled true 2>&1
        openclaw config set channels.discord.botToken "$BOT_TOKEN" 2>&1

        restart_gateway
        verify_channel "discord"
        ;;

    *)
        echo "Unknown platform: $PLATFORM"
        usage
        ;;
esac
