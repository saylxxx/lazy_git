#!/bin/bash

# 自動配置 lazy_git 分支設定工具
# 使用方法: detect-branches
# 這個工具會自動檢測當前 Git 倉庫的主分支和開發分支，並更新配置

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

# 引用共用函數
source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

detect_and_configure_branches() {
    echo "🔍 自動檢測 Git 倉庫分支配置..."
    echo "================================="
    
    # 檢查是否在 Git 倉庫中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ 錯誤：當前目錄不是 Git 倉庫"
        exit 1
    fi
    
    # 獲取 remote 名稱
    local remote_name=$(get_remote_name)
    echo "📡 Remote: $remote_name"
    
    # 檢測主分支
    echo ""
    echo "🔍 檢測主分支..."
    local detected_main=$(detect_main_branch $remote_name)
    local current_main=$(git config --global lazygit.main-branch || echo "$DEFAULT_MAIN_BRANCH")
    
    echo "當前配置的主分支: $current_main"
    echo "檢測到的主分支: $detected_main"
    
    if [ "$detected_main" != "$current_main" ]; then
        echo ""
        read -p "是否要將主分支配置更新為 '$detected_main'？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git config --global lazygit.main-branch "$detected_main"
            echo "✅ 主分支配置已更新為: $detected_main"
        else
            echo "⏭️  跳過主分支配置更新"
        fi
    else
        echo "✅ 主分支配置正確"
    fi
    
    # 檢測開發分支
    echo ""
    echo "🔍 檢測開發分支..."
    local detected_develop=$(detect_develop_branch $remote_name)
    local current_develop=$(git config --global lazygit.develop-branch || echo "$DEFAULT_DEVELOP_BRANCH")
    
    echo "當前配置的開發分支: $current_develop"
    echo "檢測到的開發分支: $detected_develop"
    
    if [ "$detected_develop" != "$current_develop" ]; then
        echo ""
        read -p "是否要將開發分支配置更新為 '$detected_develop'？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git config --global lazygit.develop-branch "$detected_develop"
            echo "✅ 開發分支配置已更新為: $detected_develop"
        else
            echo "⏭️  跳過開發分支配置更新"
        fi
    else
        echo "✅ 開發分支配置正確"
    fi
    
    # 顯示可用的 remote 分支
    echo ""
    echo "📋 可用的 remote 分支："
    git ls-remote --heads $remote_name | sed 's/.*refs\/heads\//  - /' | sort
    
    # 顯示當前配置
    echo ""
    echo "🔧 當前 lazy_git 配置："
    echo "主分支: $(git config --global lazygit.main-branch || echo "$DEFAULT_MAIN_BRANCH")"
    echo "開發分支: $(git config --global lazygit.develop-branch || echo "$DEFAULT_DEVELOP_BRANCH")"
    
    echo ""
    echo "✅ 分支檢測完成！"
    echo ""
    echo "💡 提示："
    echo "- 如需手動設置：git config --global lazygit.main-branch <分支名>"
    echo "- 如需手動設置：git config --global lazygit.develop-branch <分支名>"
    echo "- 查看當前設置：git config --global --get-regexp lazygit"
}

detect_and_configure_branches
