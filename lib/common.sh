#!/bin/bash

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

# 確認 remote 名稱
get_remote_name() {
    remote_name=$(git remote | grep -E 'origin|github' | head -n 1)
    if [ -z "$remote_name" ]; then
        echo "找不到 remote 名稱，請確認您的 remote 設定。"
        exit 1
    fi
    echo $remote_name
}

# 檢查本地是否有指定分支，若無則從 remote 拉取
ensure_branch_exists() {
    local branch=$1
    local remote_name=$2
    if ! git show-ref --verify --quiet refs/heads/$branch; then
        echo "本地不存在分支 $branch，從 remote 拉取..."
        git fetch $remote_name $branch:$branch
        if [ $? -ne 0 ]; then
            echo "無法從 remote 拉取分支 $branch。"
            exit 1
        fi
    fi
}

# 切換到指定分支並更新
checkout_and_pull_branch() {
    local branch=$1
    local remote_name=$2
    git checkout $branch
    if [ $? -ne 0 ]; then
        echo "無法切換到分支 $branch。"
        exit 1
    fi

    git pull $remote_name $branch
    if [ $? -ne 0 ]; then
        echo "無法從 remote 更新分支 $branch。"
        exit 1
    fi
}