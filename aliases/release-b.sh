#!/bin/bash

# 更新本地 master 分支到最新版，並建立一個以 R 開頭的日期分支
# 使用方法: release-b [描述] [日期]
# 使用範例:
#   ./release-b.sh "描述"
#   ./release-b.sh "描述" 20250212  # 會建立 R20250212_描述 分支
#   ./release-b.sh "" 20110101      # 會建立 R20110101 分支

git checkout master
git pull origin master

if [ -n "$2" ]; then
  current_date=$2
else
  current_date=$(date +%Y%m%d)
fi

if [ -n "$1" ]; then
  branch_name="R${current_date}_$1"
else
  branch_name="R${current_date}"
fi

git checkout -b $branch_name