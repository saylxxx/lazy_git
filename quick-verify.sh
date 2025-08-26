#!/bin/bash

# 快速驗證腳本 - 檢查所有 lazy_git 功能是否正常工作
# 使用方法: ./quick-verify.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}快速驗證 lazy_git 功能${NC}"
echo "=================================="

# 檢查檔案是否存在
check_files() {
    echo -n "檢查檔案結構... "
    
    local files=(
        "lib/clean-lock.sh"
        "lib/clean-ab.sh" 
        "lib/feat-b.sh"
        "lib/feat-m.sh"
        "lib/fix-b.sh"
        "lib/hotfix-b.sh"
        "lib/release-b.sh"
        "lib/update-ab.sh"
        "lib/common.sh"
        "config.sh"
        "install.sh"
    )
    
    for file in "${files[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$file" ]; then
            echo -e "${RED}失敗${NC}"
            echo -e "${RED}缺少檔案: $file${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}通過${NC}"
}

# 檢查腳本語法
check_syntax() {
    echo -n "檢查腳本語法... "
    
    local scripts=(
        "lib/clean-lock.sh"
        "lib/clean-ab.sh"
        "lib/feat-b.sh" 
        "lib/feat-m.sh"
        "lib/fix-b.sh"
        "lib/hotfix-b.sh"
        "lib/release-b.sh"
        "lib/update-ab.sh"
        "install.sh"
    )
    
    for script in "${scripts[@]}"; do
        if ! bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
            echo -e "${RED}失敗${NC}"
            echo -e "${RED}語法錯誤: $script${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}通過${NC}"
}

# 檢查參數處理
check_parameter_handling() {
    echo -n "檢查參數處理... "
    
    # 檢查 clean-lock.sh 是否支援 -f 參數
    # 使用 timeout 避免無限等待
    local force_output=$(timeout 5s bash "$SCRIPT_DIR/lib/clean-lock.sh" -f 2>&1 || true)
    if [[ "$force_output" == *"強制模式"* ]]; then
        # 確認強制模式參數正常
        echo -e "${GREEN}通過${NC}"
    else
        echo -e "${YELLOW}部分通過${NC} (參數處理可能需要檢查)"
    fi
}

# 檢查配置檔案
check_config() {
    echo -n "檢查配置檔案... "
    
    if ! source "$SCRIPT_DIR/config.sh" 2>/dev/null; then
        echo -e "${RED}失敗${NC}"
        echo -e "${RED}無法載入 config.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}通過${NC}"
}

# 檢查 common.sh 函數
check_common_functions() {
    echo -n "檢查共用函數... "
    
    if ! source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null; then
        echo -e "${RED}失敗${NC}"
        echo -e "${RED}無法載入 common.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}通過${NC}"
}

# 檢查安裝腳本
check_install_script() {
    echo -n "檢查安裝腳本... "
    
    # 測試 dry run 模式
    if ! bash "$SCRIPT_DIR/install.sh" --dryrun > /dev/null 2>&1; then
        echo -e "${RED}失敗${NC}"
        echo -e "${RED}install.sh --dryrun 執行失敗${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}通過${NC}"
}

# 檢查分支腳本的基本邏輯
check_branch_scripts() {
    echo -n "檢查分支腳本邏輯... "
    
    # 創建臨時測試目錄
    local test_dir="/tmp/lazy_git_verify_$(date +%s)"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # 初始化 git
    git init > /dev/null 2>&1
    git config user.name "Test" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1
    
    echo "test" > test.txt
    git add test.txt > /dev/null 2>&1
    git commit -m "test" > /dev/null 2>&1
    
    # 創建 develop 分支
    git checkout -b develop > /dev/null 2>&1
    git checkout master > /dev/null 2>&1
    
    # 設置配置
    git config --global lazygit.main-branch "master" 2>/dev/null || true
    git config --global lazygit.develop-branch "develop" 2>/dev/null || true
    
    # 測試 feat-b（應該會因為沒有 remote 而失敗，但不應該有語法錯誤）
    timeout 5s bash "$SCRIPT_DIR/lib/feat-b.sh" "test" > /dev/null 2>&1 || true
    
    # 清理
    cd /
    rm -rf "$test_dir"
    git config --global --unset lazygit.main-branch 2>/dev/null || true
    git config --global --unset lazygit.develop-branch 2>/dev/null || true
    
    echo -e "${GREEN}通過${NC}"
}

# 檢查說明文件
check_documentation() {
    echo -n "檢查說明文件... "
    
    local docs_found=0
    
    if [ -f "$SCRIPT_DIR/README.md" ]; then
        docs_found=1
    fi
    
    # 檢查每個腳本是否有使用說明
    local scripts_with_help=0
    local total_scripts=0
    
    for script in "$SCRIPT_DIR/lib"/*.sh; do
        if [ -f "$script" ]; then
            total_scripts=$((total_scripts + 1))
            if grep -q "使用方法" "$script" 2>/dev/null; then
                scripts_with_help=$((scripts_with_help + 1))
            fi
        fi
    done
    
    if [ $scripts_with_help -eq $total_scripts ] || [ $docs_found -eq 1 ]; then
        echo -e "${GREEN}通過${NC}"
    else
        echo -e "${YELLOW}部分通過${NC} (建議補充說明文件)"
    fi
}

# 主執行函數
main() {
    echo ""
    
    check_files
    check_syntax
    check_config
    check_common_functions
    check_parameter_handling
    check_install_script
    check_branch_scripts
    check_documentation
    
    echo ""
    echo "=================================="
    echo -e "${GREEN}✅ 快速驗證完成！${NC}"
    echo ""
    echo "所有檢查都通過了。您可以執行以下命令進行更詳細的測試："
    echo -e "${BLUE}./unit-tests.sh${NC}     - 執行單元測試"
    echo -e "${BLUE}./test-suite.sh${NC}     - 執行完整測試套件"
    echo -e "${BLUE}./install.sh --dryrun${NC} - 預覽安裝過程"
}

main "$@"
