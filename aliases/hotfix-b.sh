#!/bin/bash

# 更新本地 master 分支到最新版，並建立一個以 hotfix 開頭的日期分支
# 使用方法: hotfix-b [描述] [日期]
# 使用範例:
#   ./hotfix-b.sh "描述"
#   ./hotfix-b.sh "描述" 20250212  # 會建立 hotfix20250212_描述 分支
#   ./hotfix-b.sh "" 20250212      # 會建立 hotfix20250212 分支

git checkout master
git pull origin master

if [ -n "$2" ]; then
  current_date=$2
else
  current_date=$(date +%Y%m%d)
fi

if [ -n "$1" ]; then
  branch_name="hotfix${current_date}_$1"
else
  branch_name="hotfix${current_date}"
fi

git checkout -b $branch_name