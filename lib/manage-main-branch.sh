#!/bin/bash

# lazy_git 主分支管理工具
# 使用方法: 
#   manage-main-branch          # 互動式管理
#   manage-main-branch set <分支名>  # 直接設定
#   manage-main-branch reset    # 重置設定

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

# 引用共用函數
source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

# 確保目錄存在
ensure_home_directory

show_help() {
    echo "lazy_git 主分支管理工具"
    echo "========================"
    echo ""
    echo "使用方法:"
    echo "  $(basename "$0")              # 互動式管理"
    echo "  $(basename "$0") set <分支名>  # 直接設定專案主分支"
    echo "  $(basename "$0") reset        # 重置專案設定"
    echo "  $(basename "$0") status       # 顯示當前狀態"
    echo ""
    echo "範例:"
    echo "  $(basename "$0") set production"
    echo "  $(basename "$0") reset"
}

show_status() {
    echo "🔍 當前主分支配置狀態"
    echo "===================="
    echo ""
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ 不在 Git 倉庫中"
        return 1
    fi
    
    local remote_name=$(get_remote_name 2>/dev/null || echo "origin")
    echo "📡 Remote: $remote_name"
    echo ""
    
    # 顯示可用分支
    echo "📋 可用的 remote 分支："
    git ls-remote --heads $remote_name 2>/dev/null | sed 's/.*refs\/heads\//  - /' | sort
    echo ""
    
    # 顯示配置
    local project_main=$(git config lazygit.main-branch 2>/dev/null)
    local global_main=$(git config --global lazygit.main-branch 2>/dev/null)
    
    if [ -n "$project_main" ]; then
        echo "✓ 專案主分支設定: $project_main"
    else
        echo "- 專案主分支設定: 未設定"
    fi
    
    if [ -n "$global_main" ]; then
        echo "✓ 全域主分支設定: $global_main"
    else
        echo "- 全域主分支設定: 未設定"
    fi
    
    echo ""
    echo "🎯 智能檢測結果:"
    local detected=$(smart_detect_main_branch $remote_name false 2>/dev/null)
    echo "  檢測到的主分支: $detected"
}

interactive_manage() {
    echo "🔧 互動式主分支管理"
    echo "=================="
    echo ""
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ 不在 Git 倉庫中"
        return 1
    fi
    
    local remote_name=$(get_remote_name)
    
    # 顯示當前狀態
    show_status
    echo ""
    
    # 檢測可用的候選分支
    local remote_branches=$(git ls-remote --heads $remote_name 2>/dev/null)
    local main_candidates_str=${LAZYGIT_MAIN_CANDIDATES:-"main master production feature/production"}
    local main_candidates=($main_candidates_str)
    local found_candidates=()
    
    for candidate in "${main_candidates[@]}"; do
        if echo "$remote_branches" | grep -q "refs/heads/$candidate$"; then
            found_candidates+=("$candidate")
        fi
    done
    
    if [ ${#found_candidates[@]} -eq 0 ]; then
        echo "❌ 沒有找到任何候選主分支"
        echo "可用分支："
        git ls-remote --heads $remote_name | sed 's/.*refs\/heads\//  - /'
        echo ""
        echo "請手動設定: git config lazygit.main-branch <分支名>"
        return 1
    fi
    
    echo "🎯 發現的主分支候選："
    for i in "${!found_candidates[@]}"; do
        echo "  $((i+1)). ${found_candidates[$i]}"
    done
    echo "  0. 手動輸入分支名稱"
    echo "  r. 重置專案設定"
    echo ""
    
    while true; do
        echo -n "請選擇主分支 [1-${#found_candidates[@]}/0/r]: "
        read -r choice
        
        if [ "$choice" = "r" ] || [ "$choice" = "R" ]; then
            git config --unset lazygit.main-branch 2>/dev/null
            echo "✅ 已重置專案主分支設定"
            break
        elif [ "$choice" = "0" ]; then
            echo -n "請輸入分支名稱: "
            read -r custom_branch
            if [ -n "$custom_branch" ]; then
                git config lazygit.main-branch "$custom_branch"
                echo "✅ 已設定專案主分支為: $custom_branch"
                break
            else
                echo "❌ 分支名稱不能為空"
            fi
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#found_candidates[@]} ]; then
            local selected="${found_candidates[$((choice-1))]}"
            git config lazygit.main-branch "$selected"
            echo "✅ 已設定專案主分支為: $selected"
            break
        else
            echo "❌ 無效選擇，請重新輸入"
        fi
    done
}

set_main_branch() {
    local branch_name="$1"
    if [ -z "$branch_name" ]; then
        echo "❌ 請指定分支名稱"
        echo "使用方法: $(basename "$0") set <分支名>"
        return 1
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ 不在 Git 倉庫中"
        return 1
    fi
    
    git config lazygit.main-branch "$branch_name"
    echo "✅ 已設定專案主分支為: $branch_name"
}

reset_main_branch() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ 不在 Git 倉庫中"
        return 1
    fi
    
    git config --unset lazygit.main-branch 2>/dev/null
    echo "✅ 已重置專案主分支設定"
}

# 主程式邏輯
case "${1:-}" in
    "set")
        set_main_branch "$2"
        ;;
    "reset")
        reset_main_branch
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        interactive_manage
        ;;
    *)
        echo "❌ 未知的參數: $1"
        show_help
        exit 1
        ;;
esac
