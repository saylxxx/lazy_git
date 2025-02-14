#!/bin/bash

# 更新所有本地分支
# 使用方法: update-ab
# 它會在不同的工作目錄中檢出每個本地分支並執行 git pull

# 引用共用函數
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

update_all_branches() {
    rm -f .git/index.lock
    rm -f .git/ORIG_HEAD.lock

    current_branch=$(git symbolic-ref --short HEAD)
    echo "當前分支: $current_branch"

    git stash -u

    temp_dir=$(mktemp -d)
    echo "創建臨時目錄: $temp_dir"

    for branch in $(git branch --format='%(refname:short)' | grep -v "$current_branch"); do
        worktree_dir="$temp_dir/$branch"
        echo "更新分支: $branch"
        git worktree add $worktree_dir $branch
        (cd $worktree_dir && git pull)
        git worktree remove $worktree_dir
        sleep 1
    done

    echo "切換回: $current_branch"
    git checkout $current_branch

    git stash pop

    rm -rf $temp_dir
    echo "刪除臨時目錄: $temp_dir"
}

update_all_branches