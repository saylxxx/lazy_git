#!/bin/bash

# 更新本地 develop 分支到最新版，並建立一個以 feat 開頭的日期分支
# 使用方法: feat-b [描述]
# 如果沒有提供描述，則只會使用日期作為分支名稱; e.g., feat_20200101

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

# 引用共用函數
source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"


# 確保目錄存在
ensure_home_directory

# 確認 remote 名稱
remote_name=$(get_remote_name)

# 智能檢測開發分支名稱
detected_develop=$(detect_develop_branch $remote_name)
develop_branch=$(git config --global lazygit.develop-branch || echo "$detected_develop")

# 如果配置的分支與檢測的不同，使用檢測到的分支
if [ "$develop_branch" != "$detected_develop" ]; then
    echo "注意：配置的開發分支是 '$develop_branch'，但檢測到的是 '$detected_develop'"
    echo "使用檢測到的分支: $detected_develop"
    develop_branch="$detected_develop"
fi

# 確保本地存在 develop 分支
ensure_branch_exists $develop_branch $remote_name

# 切換到 develop 分支並更新
checkout_and_pull_branch $develop_branch $remote_name

current_date=$(date +%Y%m%d)

if [ -n "$1" ]; then
  branch_name="feat_${current_date}_$1"
else
  branch_name="feat_${current_date}"
fi

git checkout -b $branch_name
if [ $? -ne 0 ]; then
    echo "無法建立新分支 $branch_name。"
    exit 1
fi