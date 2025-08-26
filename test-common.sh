#!/bin/bash

# 測試專用的 common.sh - 避免 remote 操作
# 這個版本用於測試環境，不會執行實際的 remote 操作

# 確保目錄存在
ensure_home_directory() {
    if [ -z "$HOME" ]; then
        if [ -n "$USERPROFILE" ]; then
            HOME=$(echo $USERPROFILE | sed 's/\\/\//g')
        else
            HOME=~
        fi
    fi
}

# 確認 remote 名稱（測試版本）
get_remote_name() {
    # 在測試環境中，直接返回 origin
    echo "origin"
}

# 檢查本地是否有指定分支（測試版本）
ensure_branch_exists() {
    local branch=$1
    local remote_name=$2
    
    # 在測試環境中，如果分支不存在就創建它
    if ! git show-ref --verify --quiet refs/heads/$branch; then
        echo "創建測試分支: $branch"
        git checkout -b $branch > /dev/null 2>&1
        git checkout master > /dev/null 2>&1
    fi
}

# 切換到指定分支（測試版本）
checkout_and_pull_branch() {
    local branch=$1
    local remote_name=$2
    
    # 在測試環境中，只切換分支，不執行 pull
    git checkout $branch > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "無法切換到分支 $branch。"
        exit 1
    fi
    
    echo "已切換到分支: $branch (測試模式，跳過 pull)"
}
