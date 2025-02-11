#!/bin/bash

# 更新所有本地分支
# 使用方法: update-ab
# 它會在不同的工作目錄中檢出每個本地分支並執行 git pull

# 移除可能存在的 lock 檔案
rm -f .git/index.lock
rm -f .git/ORIG_HEAD.lock

# 獲取當前分支名稱
current_branch=$(git symbolic-ref --short HEAD)
echo "當前分支: $current_branch"

# 暫存未提交的變更
git stash -u

# 創建臨時目錄
temp_dir=$(mktemp -d)
echo "創建臨時目錄: $temp_dir"

# 更新所有本地分支
for branch in $(git branch --format='%(refname:short)' | grep -v "$current_branch"); do
  worktree_dir="$temp_dir/$branch"
  echo "更新分支: $branch"
  git worktree add $worktree_dir $branch
  (cd $worktree_dir && git pull)
  git worktree remove $worktree_dir
  sleep 1
done

# 切換回原來的分支
echo "切換回: $current_branch"
git checkout $current_branch

# 恢復暫存的變更
git stash pop

# 刪除臨時目錄
rm -rf $temp_dir
echo "刪除臨時目錄: $temp_dir"