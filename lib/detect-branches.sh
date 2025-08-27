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
    local detected_main=$(smart_detect_main_branch "$remote_name" false)
    local current_project_main=$(git config lazygit.main-branch 2>/dev/null)
    local current_global_main=$(git config --global lazygit.main-branch 2>/dev/null)
    
    echo "當前專案主分支配置: ${current_project_main:-"(未設定)"}"
    echo "當前全域主分支配置: ${current_global_main:-"(未設定)"}"
    echo "智能檢測到的主分支: $detected_main"
    
    # 決定是否需要更新專案配置
    local should_update_main=false
    if [ -z "$current_project_main" ]; then
        if [ -n "$detected_main" ]; then
            should_update_main=true
            echo ""
            echo "💡 建議為此專案設定專屬的主分支配置"
        fi
    elif [ "$detected_main" != "$current_project_main" ]; then
        should_update_main=true
        echo ""
        echo "⚠️  檢測到的主分支與專案配置不符"
    fi
    
    if [ "$should_update_main" = true ]; then
        echo ""
        read -p "是否要將專案主分支配置設定為 '$detected_main'？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git config lazygit.main-branch "$detected_main"
            echo "✅ 專案主分支配置已設定為: $detected_main"
        else
            echo "⏭️  跳過主分支配置更新"
        fi
    else
        echo "✅ 主分支配置正確"
    fi
    
    # 檢測開發分支
    echo ""
    echo "🔍 檢測開發分支..."
    local detected_develop=$(detect_develop_branch "$remote_name")
    local current_project_develop=$(git config lazygit.develop-branch 2>/dev/null)
    local current_global_develop=$(git config --global lazygit.develop-branch 2>/dev/null)
    
    echo "當前專案開發分支配置: ${current_project_develop:-"(未設定)"}"
    echo "當前全域開發分支配置: ${current_global_develop:-"(未設定)"}"
    echo "檢測到的開發分支: $detected_develop"
    
    # 決定是否需要更新專案配置
    local should_update_develop=false
    if [ -z "$current_project_develop" ]; then
        if [ -n "$detected_develop" ] && [ "$detected_develop" != "$DEFAULT_DEVELOP_BRANCH" ]; then
            should_update_develop=true
            echo ""
            echo "💡 建議為此專案設定專屬的開發分支配置"
        fi
    elif [ "$detected_develop" != "$current_project_develop" ]; then
        should_update_develop=true
        echo ""
        echo "⚠️  檢測到的開發分支與專案配置不符"
    fi
    
    if [ "$should_update_develop" = true ]; then
        echo ""
        read -p "是否要將專案開發分支配置設定為 '$detected_develop'？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git config lazygit.develop-branch "$detected_develop"
            echo "✅ 專案開發分支配置已設定為: $detected_develop"
        else
            echo "⏭️  跳過開發分支配置更新"
        fi
    else
        echo "✅ 開發分支配置正確"
    fi
    
    # 顯示可用的 remote 分支
    echo ""
    echo "📋 可用的 remote 分支："
    if git ls-remote --heads "$remote_name" >/dev/null 2>&1; then
        git ls-remote --heads "$remote_name" | sed 's/.*refs\/heads\//  - /' | sort
    else
        echo "  (無法取得 remote 分支資訊)"
    fi
    
    # 顯示當前配置
    echo ""
    echo "🔧 當前 lazy_git 配置："
    local final_project_main=$(git config lazygit.main-branch 2>/dev/null)
    local final_global_main=$(git config --global lazygit.main-branch 2>/dev/null)
    local final_project_develop=$(git config lazygit.develop-branch 2>/dev/null)
    local final_global_develop=$(git config --global lazygit.develop-branch 2>/dev/null)
    
    echo "專案主分支: ${final_project_main:-"(未設定，將使用全域或預設值)"}"
    echo "全域主分支: ${final_global_main:-"$DEFAULT_MAIN_BRANCH"}"
    echo "專案開發分支: ${final_project_develop:-"(未設定，將使用全域或預設值)"}"
    echo "全域開發分支: ${final_global_develop:-"$DEFAULT_DEVELOP_BRANCH"}"
    
    echo ""
    echo "✅ 分支檢測完成！"
    echo ""
    echo "💡 提示："
    echo "- 專案級設定：git config lazygit.main-branch <分支名>"
    echo "- 全域級設定：git config --global lazygit.main-branch <分支名>"
    echo "- 查看專案設定：git config --get-regexp lazygit"
    echo "- 查看全域設定：git config --global --get-regexp lazygit"
    echo "- 使用互動式管理：git manage-main-branch"
}

detect_and_configure_branches
