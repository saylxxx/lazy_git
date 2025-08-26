#!/bin/bash

# 更新本地 master 分支到最新版，並建立一個以 hotfix 開頭的日期分支
# 使用方法: hotfix-b [描述] [日期]
# 使用範例:
#   ./hotfix-b.sh "描述"
#   ./hotfix-b.sh "描述" 20250212  # 會建立 hotfix20250212_描述 分支
#   ./hotfix-b.sh "" 20250212      # 會建立 hotfix20250212 分支

# 引用共用函數
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

hotfix_branch() {
    # 確認 remote 名稱
    remote_name=$(get_remote_name)
    
    # 智能檢測主分支名稱
    detected_main=$(detect_main_branch $remote_name)
    main_branch=$(git config --global lazygit.main-branch || echo "$detected_main")
    
    # 如果配置的分支與檢測的不同，使用檢測到的分支
    if [ "$main_branch" != "$detected_main" ]; then
        echo "注意：配置的主分支是 '$main_branch'，但檢測到的是 '$detected_main'"
        echo "使用檢測到的分支: $detected_main"
        main_branch="$detected_main"
    fi

    # 確保本地存在 main 分支
    ensure_branch_exists $main_branch $remote_name

    # 切換到 main 分支並更新
    checkout_and_pull_branch $main_branch $remote_name

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
    if [ $? -ne 0 ]; then
        echo "無法建立新分支 $branch_name。"
        exit 1
    fi
}

hotfix_branch "$@"