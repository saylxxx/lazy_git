#!/bin/bash

# 更新本地 develop 分支到最新版，並建立一個以 fix 開頭的日期分支
# 使用方法: fix-b [描述]
# 如果沒有提供描述，則只會使用日期作為分支名稱; e.g., fix_20200101

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

# 引用共用函數
source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

fix_branch() {
    # 確認 remote 名稱
    remote_name=$(get_remote_name)
    
    # 智能檢測開發分支
    develop_branch=$(detect_develop_branch $remote_name)

    # 確保本地存在 develop 分支
    ensure_branch_exists $develop_branch $remote_name

    # 切換到 develop 分支並更新
    checkout_and_pull_branch $develop_branch $remote_name

    current_date=$(date +%Y%m%d)

    if [ -n "$1" ]; then
        branch_name="fix_${current_date}_$1"
    else
        branch_name="fix_${current_date}"
    fi

    git checkout -b $branch_name
    if [ $? -ne 0 ]; then
        echo "無法建立新分支 $branch_name。"
        exit 1
    fi
}

fix_branch "$@"