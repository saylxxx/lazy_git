#!/bin/bash

# 安裝腳本

timestamp=$(date +%Y%m%d%H%M%S)

# 獲取版本號
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
VERSION="1.0.0-$GIT_HASH-$timestamp"

# 檢查是否 dry run 模式
DRY_RUN=false
if [[ "$1" == "--dryrun" ]]; then
    DRY_RUN=true
fi

ALIASES_DIR=aliases
LIB_DIR=lib

# 引用共用函數和配置文件
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/$LIB_DIR/common.sh"
source "$(dirname "$0")/install-functions.sh"

# Dry run: 打印相關資訊後退出
if [ "$DRY_RUN" = true ]; then
    echo "操作系統: $OS_TYPE"
    echo ""
    echo "USER_HOME: $USER_HOME"
    echo "GIT_CONFIG_DIR: $GIT_CONFIG_DIR"
    echo "GIT_ALIASES_DIR: $GIT_ALIASES_DIR"
    echo "GIT_LIB_DIR: $GIT_LIB_DIR"
    echo "GIT_CONFIG_HISTORY_DIR: $GIT_CONFIG_HISTORY_DIR"
    echo ""
    echo "版本號: $VERSION"
    echo ""
    echo "LAZYGIT_MAIN_BRANCH: $LAZYGIT_MAIN_BRANCH"
    echo "LAZYGIT_DEVELOP_BRANCH: $LAZYGIT_DEVELOP_BRANCH"
    echo "LAZYGIT_EXCLUDED_BRANCHES: $LAZYGIT_EXCLUDED_BRANCHES"
    echo ""
    echo "USER_NAME: $USER_NAME"
    echo "USER_EMAIL: $USER_EMAIL"
    echo ""
    echo "GENERATE_SECTIONS: ${GENERATE_SECTIONS[*]}"
    echo ""
    print_preserved_config
    echo ""
    exit 0
fi

# 確保目錄存在
mkdir -p "$GIT_CONFIG_DIR"
mkdir -p "$GIT_ALIASES_DIR"
mkdir -p "$GIT_LIB_DIR"
mkdir -p "$GIT_CONFIG_HISTORY_DIR"

# 設置備份文件路徑
BACKUP_FILE="$GIT_CONFIG_HISTORY_DIR/.gitconfig_$timestamp"

# 檢查 aliases 目錄是否存在
if [ ! -d "$ALIASES_DIR" ]; then
    echo "Error: $ALIASES_DIR directory does not exist."
    exit 1
fi

# 檢查 lib 目錄是否存在
if [ ! -d "$LIB_DIR" ]; then
    echo "Error: $LIB_DIR directory does not exist."
    exit 1
fi

# 備份現有的 .gitconfig 文件
backup_gitconfig

# 複製別名腳本到 git-aliases 目錄
copy_alias_scripts

# 複製 lib 腳本到 git-lib 目錄
copy_lib_scripts

# 複製 config.sh 到 git-lib 目錄
cp "$(dirname "$0")/config.sh" "$GIT_LIB_DIR/config.sh"

# 生成 .gitconfig 文件
generate_lista_script
generate_gitconfig

# 複製生成的 .gitconfig 到用戶主目錄
cp "$GIT_CONFIG_DIR/.gitconfig" ~/.gitconfig

echo "Git 配置和別名腳本已安裝完成，版本號: $VERSION"