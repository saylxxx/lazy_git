#!/bin/bash

# 更新本地 master 分支到最新版，並建立一個以 feat 開頭的日期分支
# 使用方法: feat-m [描述]
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

# 智能檢測主分支名稱
detected_main=$(smart_detect_main_branch "$remote_name" false)
main_branch="$detected_main"

# 如果檢測失敗，回退到配置值
if [ -z "$main_branch" ]; then
    main_branch=$(git config lazygit.main-branch 2>/dev/null || git config --global lazygit.main-branch 2>/dev/null || echo "$DEFAULT_MAIN_BRANCH")
fi

# 確保本地存在 main 分支
ensure_branch_exists $main_branch $remote_name

# 切換到 main 分支並更新
checkout_and_pull_branch $main_branch $remote_name

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