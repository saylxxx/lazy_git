#!/bin/bash

# lazy_git 全域主分支管理工具
# 使用方法: 
#   manage-global-main          # 顯示並管理全域設定
#   manage-global-main set <分支名>  # 設定全域主分支
#   manage-global-main reset    # 重置全域設定

# 引用路徑處理器
source "$(dirname "$0")/path-helper.sh"

# 取得正確的 config.sh 路徑
CONFIG_PATH=$(get_config_path)

# 引用共用函數
source "$CONFIG_PATH"
source "$(dirname "$0")/common.sh"

show_help() {
    echo "lazy_git 全域主分支管理工具"
    echo "=========================="
    echo ""
    echo "⚠️  警告：全域設定會影響所有專案！"
    echo "建議優先使用專案級設定：git manage-main-branch"
    echo ""
    echo "使用方法:"
    echo "  $(basename "$0")              # 顯示全域設定狀態"
    echo "  $(basename "$0") set <分支名>  # 設定全域主分支"
    echo "  $(basename "$0") reset        # 重置全域設定"
    echo ""
    echo "範例:"
    echo "  $(basename "$0") set main      # 設定全域主分支為 main"
    echo "  $(basename "$0") reset         # 清除全域設定"
}

show_global_status() {
    echo "🌍 全域主分支配置狀態"
    echo "==================="
    echo ""
    
    local global_main=$(git config --global lazygit.main-branch 2>/dev/null)
    local global_develop=$(git config --global lazygit.develop-branch 2>/dev/null)
    
    if [ -n "$global_main" ]; then
        echo "✓ 全域主分支設定: $global_main"
    else
        echo "- 全域主分支設定: 未設定"
    fi
    
    if [ -n "$global_develop" ]; then
        echo "✓ 全域開發分支設定: $global_develop"
    else
        echo "- 全域開發分支設定: 未設定"
    fi
    
    echo ""
    echo "⚠️  注意事項："
    echo "   - 全域設定會作為所有專案的預設值"
    echo "   - 專案級設定優先於全域設定"
    echo "   - 建議為不同專案設定各自的主分支"
    echo ""
    echo "💡 建議命令："
    echo "   git manage-main-branch        # 管理當前專案的主分支"
    echo "   git manage-main-branch set main  # 為當前專案設定主分支"
}

set_global_main_branch() {
    local branch_name="$1"
    if [ -z "$branch_name" ]; then
        echo "❌ 請指定分支名稱"
        echo "使用方法: $(basename "$0") set <分支名>"
        return 1
    fi
    
    echo "⚠️  警告：即將設定全域主分支為 '$branch_name'"
    echo "這會影響所有沒有專案級設定的 Git 倉庫"
    echo ""
    read -p "確定要繼續嗎？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        return 0
    fi
    
    git config --global lazygit.main-branch "$branch_name"
    echo "✅ 已設定全域主分支為: $branch_name"
    echo ""
    echo "💡 提醒：如需為特定專案設定不同的主分支，請使用："
    echo "   git manage-main-branch set <分支名>"
}

reset_global_main_branch() {
    local global_main=$(git config --global lazygit.main-branch 2>/dev/null)
    
    if [ -z "$global_main" ]; then
        echo "ℹ️  全域主分支設定不存在，無需重置"
        return 0
    fi
    
    echo "⚠️  警告：即將重置全域主分支設定 '$global_main'"
    echo "這會影響所有依賴全域設定的 Git 倉庫"
    echo ""
    read -p "確定要繼續嗎？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        return 0
    fi
    
    git config --global --unset lazygit.main-branch 2>/dev/null
    echo "✅ 已重置全域主分支設定"
}

# 主程式邏輯
case "${1:-}" in
    "set")
        set_global_main_branch "$2"
        ;;
    "reset")
        reset_global_main_branch
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        show_global_status
        ;;
    *)
        echo "❌ 未知的命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
