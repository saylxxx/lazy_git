#!/bin/bash

# 單元測試 - 專門測試各個功能的核心邏輯
# 使用方法: ./unit-tests.sh [測試名稱]

set -e

# 測試配置
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_OUTPUT_DIR="/tmp/lazy_git_unit_test_$(date +%Y%m%d_%H%M%S)"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 測試統計
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 測試工具函數
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  期望: '$expected'"
        echo -e "  實際: '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local substring="$1"
    local string="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "$string" == *"$substring"* ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  在字串中找不到: '$substring'"
        echo -e "  字串內容: '$string'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f "$filepath" ]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  檔案不存在: '$filepath'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_not_exists() {
    local filepath="$1"
    local message="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ ! -f "$filepath" ]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  檔案不應該存在: '$filepath'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 設置測試環境
setup_test_git_repo() {
    local test_dir="$1"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    git init > /dev/null 2>&1
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@example.com" > /dev/null 2>&1
    
    echo "initial commit" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1
    
    # 添加 remote（測試用的假 remote）
    git remote add origin "https://github.com/test/test.git" > /dev/null 2>&1
    
    # 設置 lazy_git 配置
    git config --global lazygit.main-branch "master"
    git config --global lazygit.develop-branch "develop"
    
    # 創建 develop 分支
    git checkout -b develop > /dev/null 2>&1
    echo "develop content" > develop.txt
    git add develop.txt > /dev/null 2>&1
    git commit -m "Add develop" > /dev/null 2>&1
    git checkout master > /dev/null 2>&1
}

# 測試 clean-lock.sh 參數解析
test_clean_lock_params() {
    echo -e "${BLUE}測試 clean-lock 參數解析${NC}"
    
    # 保存當前工作目錄
    local original_pwd=$(pwd)
    
    local test_dir="$TEST_OUTPUT_DIR/clean_lock_test"
    setup_test_git_repo "$test_dir"
    
    # 創建鎖定檔案
    mkdir -p .git
    touch .git/index.lock
    touch .git/HEAD.lock
    
    # 測試強制模式
    local output=$(bash "$SCRIPT_DIR/lib/clean-lock.sh" -f 2>&1)
    
    assert_contains "強制模式" "$output" "clean-lock -f 應該顯示強制模式訊息"
    assert_file_not_exists ".git/index.lock" "index.lock 應該被刪除"
    assert_file_not_exists ".git/HEAD.lock" "HEAD.lock 應該被刪除"
    
    # 還原工作目錄
    cd "$original_pwd"
}

# 測試 clean-ab.sh 參數解析
test_clean_ab_params() {
    echo -e "${BLUE}測試 clean-ab 參數解析${NC}"
    
    # 保存當前工作目錄
    local original_pwd=$(pwd)
    
    local test_dir="$TEST_OUTPUT_DIR/clean_ab_test"
    setup_test_git_repo "$test_dir"
    
    # 創建測試分支
    git checkout -b test_branch > /dev/null 2>&1
    git checkout master > /dev/null 2>&1
    
    # 測試強制模式
    local output=$(bash "$SCRIPT_DIR/lib/clean-ab.sh" -f 2>&1)
    
    assert_contains "強制模式" "$output" "clean-ab -f 應該顯示強制模式訊息"
    
    # 還原工作目錄
    cd "$original_pwd"
}

# 測試分支命名規則
test_branch_naming() {
    echo -e "${BLUE}測試分支命名規則${NC}"
    
    # 保存當前工作目錄
    local original_pwd=$(pwd)
    
    local test_dir="$TEST_OUTPUT_DIR/branch_naming_test"
    setup_test_git_repo "$test_dir"
    
    # 備份原始的 common.sh 並使用測試版本
    cp "$SCRIPT_DIR/lib/common.sh" "$SCRIPT_DIR/lib/common.sh.backup"
    cp "$SCRIPT_DIR/test-common.sh" "$SCRIPT_DIR/lib/common.sh"
    
    local current_date=$(date +%Y%m%d)
    
    # 測試 feat-b
    cd "$test_dir" && git checkout develop > /dev/null 2>&1
    bash "$SCRIPT_DIR/lib/feat-b.sh" "test_feature" > /dev/null 2>&1
    local feat_branch=$(git symbolic-ref --short HEAD)
    assert_equals "feat_${current_date}_test_feature" "$feat_branch" "feat-b 應該創建正確命名的分支"
    
    # 測試 feat-m  
    cd "$test_dir" && git checkout master > /dev/null 2>&1
    bash "$SCRIPT_DIR/lib/feat-m.sh" "test_master_feature" > /dev/null 2>&1
    local feat_m_branch=$(git symbolic-ref --short HEAD)
    assert_equals "feat_${current_date}_test_master_feature" "$feat_m_branch" "feat-m 應該創建正確命名的分支"
    
    # 測試 fix-b
    cd "$test_dir" && git checkout develop > /dev/null 2>&1
    bash "$SCRIPT_DIR/lib/fix-b.sh" "test_fix" > /dev/null 2>&1
    local fix_branch=$(git symbolic-ref --short HEAD)
    assert_equals "fix_${current_date}_test_fix" "$fix_branch" "fix-b 應該創建正確命名的分支"
    
    # 測試 hotfix-b
    cd "$test_dir" && git checkout master > /dev/null 2>&1
    bash "$SCRIPT_DIR/lib/hotfix-b.sh" "test_hotfix" > /dev/null 2>&1
    local hotfix_branch=$(git symbolic-ref --short HEAD)
    assert_equals "hotfix${current_date}_test_hotfix" "$hotfix_branch" "hotfix-b 應該創建正確命名的分支"
    
    # 測試 release-b
    cd "$test_dir" && git checkout master > /dev/null 2>&1
    bash "$SCRIPT_DIR/lib/release-b.sh" "test_release" > /dev/null 2>&1
    local release_branch=$(git symbolic-ref --short HEAD)
    assert_equals "R${current_date}_test_release" "$release_branch" "release-b 應該創建正確命名的分支"
    
    # 恢復原始的 common.sh
    mv "$SCRIPT_DIR/lib/common.sh.backup" "$SCRIPT_DIR/lib/common.sh"
    
    # 還原工作目錄
    cd "$original_pwd"
}

# 測試配置讀取
test_config_reading() {
    echo -e "${BLUE}測試配置讀取${NC}"
    
    # 設置測試配置
    git config --global lazygit.main-branch "main"
    git config --global lazygit.develop-branch "dev"
    
    # 測試讀取配置
    local main_branch=$(git config --global lazygit.main-branch)
    local develop_branch=$(git config --global lazygit.develop-branch)
    
    assert_equals "main" "$main_branch" "應該能讀取自訂的主分支名稱"
    assert_equals "dev" "$develop_branch" "應該能讀取自訂的開發分支名稱"
    
    # 恢復預設配置
    git config --global lazygit.main-branch "master"
    git config --global lazygit.develop-branch "develop"
}

# 測試 update-ab 參數
test_update_ab_params() {
    echo -e "${BLUE}測試 update-ab 參數解析${NC}"
    
    # 保存當前工作目錄
    local original_pwd=$(pwd)
    
    local test_dir="$TEST_OUTPUT_DIR/update_ab_test"
    setup_test_git_repo "$test_dir"
    
    # 測試靜默模式
    local output=$(timeout 10s bash "$SCRIPT_DIR/lib/update-ab.sh" -q 2>&1 || true)
    
    # 在靜默模式下，輸出應該比較簡潔
    assert_contains "更新完成" "$output" "update-ab -q 應該顯示簡潔的完成訊息"
    
    # 還原工作目錄
    cd "$original_pwd"
}

# 測試智能分支檢測
test_smart_branch_detection() {
    echo -e "${BLUE}測試智能分支檢測${NC}"
    
    # 保存當前工作目錄
    local original_pwd=$(pwd)
    
    # 保存原有的全域配置
    local original_global_main=$(git config --global lazygit.main-branch 2>/dev/null || echo "")
    local original_global_develop=$(git config --global lazygit.develop-branch 2>/dev/null || echo "")
    
    # 載入必要的函數
    source "$SCRIPT_DIR/lib/path-helper.sh"
    CONFIG_PATH=$(get_config_path)
    source "$CONFIG_PATH"
    source "$SCRIPT_DIR/lib/common.sh"
    
    # 測試案例 1: 專案級別配置優先
    local test_dir="$TEST_OUTPUT_DIR/smart_project_config_test"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    git init > /dev/null 2>&1
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@example.com" > /dev/null 2>&1
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1
    git branch -M main > /dev/null 2>&1
    git checkout -b production > /dev/null 2>&1
    git checkout main > /dev/null 2>&1
    
    # 設定專案級別配置
    git config lazygit.main-branch "production"
    
    local detected_project=$(smart_detect_main_branch origin false)
    assert_equals "production" "$detected_project" "專案級別配置應該有最高優先權"
    
    # 清理專案配置
    git config --unset lazygit.main-branch 2>/dev/null || true
    
    # 測試案例 2: 全域設定回退
    local test_dir2="$TEST_OUTPUT_DIR/smart_global_test"
    mkdir -p "$test_dir2"
    cd "$test_dir2"
    
    git init > /dev/null 2>&1
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@example.com" > /dev/null 2>&1
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1
    # 保持預設的 master 分支
    
    # 設定全域配置
    git config --global lazygit.main-branch "main"
    
    local detected_global=$(smart_detect_main_branch origin false)
    assert_equals "main" "$detected_global" "應該使用全域配置的主分支"
    
    # 測試案例 3: 預設值回退
    git config --global --unset lazygit.main-branch 2>/dev/null || true
    
    local detected_default=$(smart_detect_main_branch origin false)
    assert_equals "master" "$detected_default" "應該回退到預設主分支"
    
    # 還原工作目錄
    cd "$original_pwd"
    
    # 還原原有的全域配置
    if [ -n "$original_global_main" ]; then
        git config --global lazygit.main-branch "$original_global_main"
    else
        git config --global --unset lazygit.main-branch 2>/dev/null || true
    fi
    
    if [ -n "$original_global_develop" ]; then
        git config --global lazygit.develop-branch "$original_global_develop"
    else
        git config --global --unset lazygit.develop-branch 2>/dev/null || true
    fi
}

# 測試檔案結構
test_file_structure() {
    echo -e "${BLUE}測試檔案結構${NC}"
    
    assert_file_exists "$SCRIPT_DIR/lib/clean-lock.sh" "clean-lock.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/clean-ab.sh" "clean-ab.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/feat-b.sh" "feat-b.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/feat-m.sh" "feat-m.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/fix-b.sh" "fix-b.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/hotfix-b.sh" "hotfix-b.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/release-b.sh" "release-b.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/update-ab.sh" "update-ab.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/lib/common.sh" "common.sh 應該存在"
    assert_file_exists "$SCRIPT_DIR/config.sh" "config.sh 應該存在"
}

# 執行指定測試或所有測試
run_tests() {
    local test_name="$1"
    
    echo -e "${YELLOW}開始執行單元測試...${NC}"
    echo ""
    
    if [ -n "$test_name" ]; then
        case "$test_name" in
            "clean-lock")
                test_clean_lock_params
                ;;
            "clean-ab")
                test_clean_ab_params
                ;;
            "branch-naming")
                test_branch_naming
                ;;
            "config")
                test_config_reading
                ;;
            "update-ab")
                test_update_ab_params
                ;;
            "smart-detection")
                test_smart_branch_detection
                ;;
            "file-structure")
                test_file_structure
                ;;
            *)
                echo -e "${RED}未知的測試名稱: $test_name${NC}"
                echo "可用的測試: clean-lock, clean-ab, branch-naming, config, update-ab, smart-detection, file-structure"
                exit 1
                ;;
        esac
    else
        test_file_structure
        test_config_reading
        test_clean_lock_params
        test_clean_ab_params
        test_branch_naming
        test_update_ab_params
        test_smart_branch_detection
    fi
}

# 顯示測試結果
show_results() {
    echo ""
    echo "==============================================="
    echo -e "執行測試: ${BLUE}$TESTS_RUN${NC}"
    echo -e "通過測試: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失敗測試: ${RED}$TESTS_FAILED${NC}"
    echo "==============================================="
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 所有測試通過！${NC}"
        exit 0
    else
        echo -e "${RED}❌ 有測試失敗${NC}"
        exit 1
    fi
}

# 清理函數
cleanup() {
    if [ -d "$TEST_OUTPUT_DIR" ]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
    
    # 恢復 git config
    git config --global --unset lazygit.main-branch 2>/dev/null || true
    git config --global --unset lazygit.develop-branch 2>/dev/null || true
}

# 主函數
main() {
    # 設置清理陷阱
    trap cleanup EXIT
    
    # 執行測試
    run_tests "$1"
    
    # 顯示結果
    show_results
}

# 執行主函數
main "$@"
