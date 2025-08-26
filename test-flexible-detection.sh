#!/bin/bash

# 測試彈性主分支檢測功能

echo "🧪 測試彈性主分支檢測功能"
echo "================================"

# 引用函數
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib/common.sh"

echo "📋 當前支援的主分支候選："
echo "$LAZYGIT_MAIN_CANDIDATES" | tr ' ' '\n' | sed 's/^/  - /'

echo ""
echo "🔍 當前倉庫檢測結果："
remote_name=$(get_remote_name)
echo "Remote: $remote_name"
detected_main=$(detect_main_branch $remote_name)
echo "檢測到的主分支: $detected_main"

echo ""
echo "📋 可用的 remote 分支："
git ls-remote --heads $remote_name 2>/dev/null | sed 's/.*refs\/heads\//  - /' | sort

echo ""
echo "💡 自訂主分支候選的方法："
echo "export LAZYGIT_MAIN_CANDIDATES=\"main master feature/production your-custom-branch\""
echo "然後重新執行相關命令"

echo ""
echo "🔧 手動設置主分支："
echo "git config --global lazygit.main-branch feature/production"
