#!/bin/bash

# 預設的 user name 和 email
DEFAULT_USER_NAME="mip.yang"
DEFAULT_USER_EMAIL="mip.yang@homeplus.net.tw"

# 預設的分支名稱
DEFAULT_MAIN_BRANCH="master"
DEFAULT_DEVELOP_BRANCH="develop"

# 主分支候選列表（可自訂）
# 按優先順序排列：越前面的優先級越高
# 用戶可以透過設置 LAZYGIT_MAIN_CANDIDATES 環境變數來自訂
DEFAULT_MAIN_CANDIDATES="main master production feature/production release/production prod release/main release/master"
LAZYGIT_MAIN_CANDIDATES=${LAZYGIT_MAIN_CANDIDATES:-$DEFAULT_MAIN_CANDIDATES}

# 設定 lazygit 相關變數
LAZYGIT_MAIN_BRANCH=$(git config --global lazygit.main-branch)
LAZYGIT_MAIN_BRANCH=${LAZYGIT_MAIN_BRANCH:-$DEFAULT_MAIN_BRANCH}

LAZYGIT_DEVELOP_BRANCH=$(git config --global lazygit.develop-branch)
LAZYGIT_DEVELOP_BRANCH=${LAZYGIT_DEVELOP_BRANCH:-$DEFAULT_DEVELOP_BRANCH}

LAZYGIT_EXCLUDED_BRANCHES_FILE="$HOME/.lazygit_excluded_branches"
if [ -f "$LAZYGIT_EXCLUDED_BRANCHES_FILE" ]; then
    LAZYGIT_EXCLUDED_BRANCHES=$(cat "$LAZYGIT_EXCLUDED_BRANCHES_FILE")
else
    LAZYGIT_EXCLUDED_BRANCHES="main dev release develop master production"
fi
LAZYGIT_EXCLUDED_BRANCHES="$LAZYGIT_EXCLUDED_BRANCHES $LAZYGIT_MAIN_BRANCH $LAZYGIT_DEVELOP_BRANCH"
LAZYGIT_EXCLUDED_BRANCHES=$(echo "$LAZYGIT_EXCLUDED_BRANCHES" | tr ' ' '\n' | sort | uniq | tr '\n' ' ')

# 設定 user 相關變數
USER_NAME=$(git config --global user.name || echo "$DEFAULT_USER_NAME")
USER_EMAIL=$(git config --global user.email || echo "$DEFAULT_USER_EMAIL")

# 需要生成的配置段落
GENERATE_SECTIONS=("user" "alias" "lazygit")

# 跨作業系統的參數
OS_TYPE=$(uname)
if [[ "$OS_TYPE" == "Linux" ]]; then
    USER_HOME=~
    GIT_CONFIG_DIR="$USER_HOME/git-config"
    GIT_ALIASES_DIR="$USER_HOME/git-aliases"
    GIT_LIB_DIR="$USER_HOME/git-lib"
    GIT_CONFIG_HISTORY_DIR="$USER_HOME/git-config-history"
elif [[ "$OS_TYPE" == "MINGW"* || "$OS_TYPE" == "CYGWIN"* ]]; then
    USER_HOME=$(echo $USERPROFILE | sed 's/\\/\//g')
    GIT_CONFIG_DIR="$USER_HOME/git-config"
    GIT_ALIASES_DIR="$USER_HOME/git-aliases"
    GIT_LIB_DIR="$USER_HOME/git-lib"
    GIT_CONFIG_HISTORY_DIR="$USER_HOME/git-config-history"
else
    echo "不支援的操作系統: $OS_TYPE"
    exit 1
fi
