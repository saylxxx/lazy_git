#!/bin/bash

# 更新本地 master 分支到最新版，並建立一個以 hotfix 開頭的日期分支
# 使用方法: hotfix-b [描述]
# 如果沒有提供描述，則只會使用日期作為分支名稱; e.g., hotfix20200101

git checkout master
git pull origin master

current_date=$(date +%Y%m%d)

if [ -n "$1" ]; then
  branch_name="hotfix${current_date}_$1"
else
  branch_name="hotfix${current_date}"
fi

git checkout -b $branch_name