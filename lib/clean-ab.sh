#!/bin/bash

# 刪除所有本地分支，排除配置的主分支和開發分支
# 使用方法: clean-ab
# 如果沒有本地分支，顯示 '完成'

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

# 刪除所有本地分支，排除配置的主分支和開發分支
clean_ab_branches() {
    branches=$(git branch | grep -v '\*')
    for branch in $LAZYGIT_EXCLUDED_BRANCHES; do
        branches=$(echo "$branches" | grep -v "$branch")
    done

    if [ -z "$branches" ]; then
        echo '完成'
    else
        echo "$branches" | while read branch; do
            git branch -D "$branch"
        done
    fi
}

clean_ab_branches