#!/bin/bash

# 此腳本用於更新所有本地分支
# 它會在不同的工作目錄中檢出每個本地分支並執行 git pull，然後刪除工作目錄

# 移除可能存在的鎖文件
rm -f .git/index.lock
rm -f .git/ORIG_HEAD.lock

# 獲取當前分支名稱
current_branch=$(git symbolic-ref --short HEAD)
echo "當前分支: $current_branch"

# 暫存當前的變更
git stash -u

# 創建一個臨時目錄來存放工作目錄
temp_dir=$(mktemp -d)
echo "創建臨時目錄: $temp_dir"

# 更新所有本地分支
for branch in $(git branch | grep -v '\\*'); do
  worktree_dir="$temp_dir/$branch"
  git worktree add -b $branch $worktree_dir origin/$branch
  (cd $worktree_dir && git pull)
  git worktree remove $worktree_dir
  sleep 1 
done

# 切換回原本的分支
echo "切換回: $current_branch"
git checkout $current_branch

# 恢復暫存的變更
git stash pop

# 刪除臨時目錄
rm -rf $temp_dir
echo "刪除臨時目錄: $temp_dir"