#!/usr/bin/env bash
# OpenClaw 环境检测脚本
# 用法: bash detect_env.sh
# 输出: JSON 格式的环境信息，供 skill 直接读取使用

set -e

# 颜色（仅终端显示用）
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 结果变量
OS=""
OS_VERSION=""
ARCH=""
NODE_INSTALLED=false
NODE_VERSION=""
NODE_OK=false
NPM_INSTALLED=false
NPM_VERSION=""
DOCKER_INSTALLED=false
DOCKER_VERSION=""
DOCKER_COMPOSE_INSTALLED=false
DOCKER_COMPOSE_VERSION=""
DOCKER_RUNNING=false
OPENCLAW_INSTALLED=false
OPENCLAW_VERSION=""
OPENCLAW_RUNNING=false
NETWORK_GITHUB=false
NETWORK_GOOGLE=false
NETWORK_NPM=false
NETWORK_CHINA_MIRROR=false
IN_CHINA=false
HAS_PROXY=false
PROXY_ADDR=""
NPM_REGISTRY=""

# --- 检测操作系统 ---
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            OS="mac"
            OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            ;;
        Linux*)
            OS="linux"
            if [ -f /etc/os-release ]; then
                OS_VERSION=$(. /etc/os-release && echo "$PRETTY_NAME")
            else
                OS_VERSION="unknown"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            OS_VERSION=$(cmd /c ver 2>/dev/null | tr -d '\r' || echo "unknown")
            ;;
        *)
            OS="unknown"
            OS_VERSION="unknown"
            ;;
    esac
    ARCH=$(uname -m)
}

# --- 检测 Node.js ---
detect_node() {
    if command -v node &>/dev/null; then
        NODE_INSTALLED=true
        NODE_VERSION=$(node --version 2>/dev/null | tr -d 'v')
        local major
        major=$(echo "$NODE_VERSION" | cut -d. -f1)
        if [ "$major" -ge 22 ] 2>/dev/null; then
            NODE_OK=true
        fi
    fi
    if command -v npm &>/dev/null; then
        NPM_INSTALLED=true
        NPM_VERSION=$(npm --version 2>/dev/null)
        NPM_REGISTRY=$(npm config get registry 2>/dev/null)
    fi
}

# --- 检测 Docker ---
detect_docker() {
    if command -v docker &>/dev/null; then
        DOCKER_INSTALLED=true
        DOCKER_VERSION=$(docker --version 2>/dev/null | sed 's/Docker version //' | cut -d, -f1)
        if docker info &>/dev/null; then
            DOCKER_RUNNING=true
        fi
    fi
    if command -v docker-compose &>/dev/null || docker compose version &>/dev/null 2>&1; then
        DOCKER_COMPOSE_INSTALLED=true
        DOCKER_COMPOSE_VERSION=$(docker compose version 2>/dev/null | sed 's/Docker Compose version //' || docker-compose --version 2>/dev/null | sed 's/docker-compose version //' | cut -d, -f1)
    fi
}

# --- 检测 OpenClaw ---
detect_openclaw() {
    if command -v openclaw &>/dev/null; then
        OPENCLAW_INSTALLED=true
        OPENCLAW_VERSION=$(openclaw --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        if openclaw status 2>/dev/null | grep -qi "running"; then
            OPENCLAW_RUNNING=true
        fi
    fi
}

# --- 检测网络 ---
detect_network() {
    if curl -sI --max-time 5 https://github.com &>/dev/null; then
        NETWORK_GITHUB=true
    fi
    if curl -sI --max-time 5 https://www.google.com &>/dev/null; then
        NETWORK_GOOGLE=true
    fi
    if curl -sI --max-time 5 https://registry.npmjs.org &>/dev/null; then
        NETWORK_NPM=true
    fi
    if curl -sI --max-time 5 https://registry.npmmirror.com &>/dev/null; then
        NETWORK_CHINA_MIRROR=true
    fi

    # 判断是否在国内：能访问国内镜像但不能访问 Google
    if [ "$NETWORK_CHINA_MIRROR" = true ] && [ "$NETWORK_GOOGLE" = false ]; then
        IN_CHINA=true
    fi

    # 检测代理
    if [ -n "$HTTP_PROXY" ] || [ -n "$http_proxy" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$https_proxy" ]; then
        HAS_PROXY=true
        PROXY_ADDR="${HTTP_PROXY:-${http_proxy:-${HTTPS_PROXY:-$https_proxy}}}"
    fi
}

# --- 执行所有检测 ---
detect_os
detect_node
detect_docker
detect_openclaw
detect_network

# --- 输出 JSON ---
cat <<ENDJSON
{
  "os": "$OS",
  "os_version": "$OS_VERSION",
  "arch": "$ARCH",
  "node": {
    "installed": $NODE_INSTALLED,
    "version": "$NODE_VERSION",
    "version_ok": $NODE_OK
  },
  "npm": {
    "installed": $NPM_INSTALLED,
    "version": "$NPM_VERSION",
    "registry": "$NPM_REGISTRY"
  },
  "docker": {
    "installed": $DOCKER_INSTALLED,
    "version": "$DOCKER_VERSION",
    "compose_installed": $DOCKER_COMPOSE_INSTALLED,
    "compose_version": "$DOCKER_COMPOSE_VERSION",
    "running": $DOCKER_RUNNING
  },
  "openclaw": {
    "installed": $OPENCLAW_INSTALLED,
    "version": "$OPENCLAW_VERSION",
    "running": $OPENCLAW_RUNNING
  },
  "network": {
    "github": $NETWORK_GITHUB,
    "google": $NETWORK_GOOGLE,
    "npm_registry": $NETWORK_NPM,
    "china_mirror": $NETWORK_CHINA_MIRROR,
    "in_china": $IN_CHINA,
    "has_proxy": $HAS_PROXY,
    "proxy_addr": "$PROXY_ADDR"
  }
}
ENDJSON
