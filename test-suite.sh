#!/bin/bash

# 測試 lazy_git 功能的測試套件
# 使用方法: ./test-suite.sh [選項]
# 選項:
#   --setup-only    只設置測試環境，不執行測試
#   --cleanup-only  只清理測試環境
#   --verbose       詳細輸出
#   --quick         快速測試（跳過一些耗時的測試）

set -e

# 測試配置
TEST_DIR="/tmp/lazy_git_test_$(date +%Y%m%d_%H%M%S)"
LAZY_GIT_SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_VERBOSE=false
QUICK_MODE=false
SETUP_ONLY=false
CLEANUP_ONLY=false

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 統計變數
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

# 詳細輸出函數
verbose_log() {
    if [ "$TEST_VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# 解析命令列參數
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --setup-only)
                SETUP_ONLY=true
                shift
                ;;
            --cleanup-only)
                CLEANUP_ONLY=true
                shift
                ;;
            --verbose)
                TEST_VERBOSE=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            -h|--help)
                echo "使用方法: $0 [選項]"
                echo "選項:"
                echo "  --setup-only    只設置測試環境，不執行測試"
                echo "  --cleanup-only  只清理測試環境"
                echo "  --verbose       詳細輸出"
                echo "  --quick         快速測試"
                echo "  -h, --help      顯示此說明"
                exit 0
                ;;
            *)
                log_error "未知參數: $1"
                exit 1
                ;;
        esac
    done
}

# 設置測試環境
setup_test_environment() {
    log_info "設置測試環境..."
    
    # 創建測試目錄
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # 初始化 Git 倉庫
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # 創建初始檔案
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
    
    # 創建遠端倉庫模擬
    git remote add origin "$TEST_DIR.git"
    
    # 複製 lazy_git 檔案到測試環境
    mkdir -p lazy_git/{lib,aliases}
    cp -r "$LAZY_GIT_SOURCE_DIR/lib/"* lazy_git/lib/
    cp -r "$LAZY_GIT_SOURCE_DIR/aliases/"* lazy_git/aliases/
    cp "$LAZY_GIT_SOURCE_DIR/config.sh" lazy_git/
    cp "$LAZY_GIT_SOURCE_DIR/install-functions.sh" lazy_git/
    cp "$LAZY_GIT_SOURCE_DIR/install.sh" lazy_git/
    
    # 使用測試版本的 common.sh 避免 remote 操作問題
    cp "$LAZY_GIT_SOURCE_DIR/test-common.sh" lazy_git/lib/common.sh
    
    # 設置測試用的 git config
    git config --global lazygit.main-branch "master"
    git config --global lazygit.develop-branch "develop"
    
    # 創建測試分支
    create_test_branches
    
    log_success "測試環境設置完成: $TEST_DIR"
}

# 創建測試分支
create_test_branches() {
    verbose_log "創建測試分支..."
    
    # 創建 develop 分支
    git checkout -b develop
    echo "develop branch content" > develop.txt
    git add develop.txt
    git commit -m "Add develop content"
    
    # 創建一些測試分支
    for branch in test_branch_1 test_branch_2 feature_old_branch; do
        git checkout -b "$branch"
        echo "$branch content" > "$branch.txt"
        git add "$branch.txt"
        git commit -m "Add $branch content"
    done
    
    # 回到 master
    git checkout master
    
    verbose_log "測試分支創建完成"
}

# 測試函數執行器
run_test() {
    local test_name="$1"
    local test_function="$2"
    local should_skip="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$should_skip" = "true" ]; then
        log_skip "測試: $test_name (已跳過)"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return 0
    fi
    
    log_info "執行測試: $test_name"
    
    if $test_function; then
        log_success "測試通過: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "測試失敗: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 測試 clean-lock 功能
test_clean_lock() {
    verbose_log "測試 clean-lock 功能..."
    
    cd "$TEST_DIR"
    
    # 創建一些鎖定檔案
    mkdir -p .git
    touch .git/index.lock
    touch .git/HEAD.lock
    touch .git/ORIG_HEAD.lock
    
    # 測試強制模式
    bash lazy_git/lib/clean-lock.sh -f > /dev/null 2>&1
    
    # 驗證鎖定檔案已被刪除
    if [ ! -f .git/index.lock ] && [ ! -f .git/HEAD.lock ] && [ ! -f .git/ORIG_HEAD.lock ]; then
        return 0
    else
        return 1
    fi
}

# 測試 clean-ab 功能
test_clean_ab() {
    verbose_log "測試 clean-ab 功能..."
    
    cd "$TEST_DIR"
    
    # 確保有測試分支存在
    local branches_before=$(git branch | grep -v '\*' | wc -l)
    
    if [ "$branches_before" -eq 0 ]; then
        # 如果沒有分支，創建一個測試分支
        git checkout -b temp_test_branch
        git checkout master
    fi
    
    # 測試強制模式（自動回答 yes）
    bash lazy_git/lib/clean-ab.sh -f > /dev/null 2>&1
    
    # 驗證只剩下受保護的分支
    local remaining_branches=$(git branch | grep -v '\*' | grep -v master | grep -v develop | wc -l)
    
    if [ "$remaining_branches" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# 測試 feat-b 功能
test_feat_b() {
    verbose_log "測試 feat-b 功能..."
    
    cd "$TEST_DIR"
    
    # 確保在 develop 分支
    git checkout develop > /dev/null 2>&1
    
    # 執行 feat-b
    bash lazy_git/lib/feat-b.sh "test_feature" > /dev/null 2>&1
    
    # 檢查是否創建了正確的分支
    local current_branch=$(git symbolic-ref --short HEAD)
    local expected_pattern="feat_$(date +%Y%m%d)_test_feature"
    
    if [[ "$current_branch" == "$expected_pattern" ]]; then
        return 0
    else
        return 1
    fi
}

# 測試 feat-m 功能
test_feat_m() {
    verbose_log "測試 feat-m 功能..."
    
    cd "$TEST_DIR"
    
    # 確保在 master 分支
    git checkout master > /dev/null 2>&1
    
    # 執行 feat-m
    bash lazy_git/lib/feat-m.sh "test_master_feature" > /dev/null 2>&1
    
    # 檢查是否創建了正確的分支
    local current_branch=$(git symbolic-ref --short HEAD)
    local expected_pattern="feat_$(date +%Y%m%d)_test_master_feature"
    
    if [[ "$current_branch" == "$expected_pattern" ]]; then
        return 0
    else
        return 1
    fi
}

# 測試 fix-b 功能
test_fix_b() {
    verbose_log "測試 fix-b 功能..."
    
    cd "$TEST_DIR"
    
    # 確保在 develop 分支
    git checkout develop > /dev/null 2>&1
    
    # 執行 fix-b
    bash lazy_git/lib/fix-b.sh "test_fix" > /dev/null 2>&1
    
    # 檢查是否創建了正確的分支
    local current_branch=$(git symbolic-ref --short HEAD)
    local expected_pattern="fix_$(date +%Y%m%d)_test_fix"
    
    if [[ "$current_branch" == "$expected_pattern" ]]; then
        return 0
    else
        return 1
    fi
}

# 測試 hotfix-b 功能
test_hotfix_b() {
    verbose_log "測試 hotfix-b 功能..."
    
    cd "$TEST_DIR"
    
    # 確保在 master 分支
    git checkout master > /dev/null 2>&1
    
    # 執行 hotfix-b
    bash lazy_git/lib/hotfix-b.sh "test_hotfix" > /dev/null 2>&1
    
    # 檢查是否創建了正確的分支
    local current_branch=$(git symbolic-ref --short HEAD)
    local expected_pattern="hotfix$(date +%Y%m%d)_test_hotfix"
    
    if [[ "$current_branch" == "$expected_pattern" ]]; then
        return 0
    else
        return 1
    fi
}

# 測試 release-b 功能
test_release_b() {
    verbose_log "測試 release-b 功能..."
    
    cd "$TEST_DIR"
    
    # 確保在 master 分支
    git checkout master > /dev/null 2>&1
    
    # 執行 release-b
    bash lazy_git/lib/release-b.sh "test_release" > /dev/null 2>&1
    
    # 檢查是否創建了正確的分支
    local current_branch=$(git symbolic-ref --short HEAD)
    local expected_pattern="R$(date +%Y%m%d)_test_release"
    
    if [[ "$current_branch" == "$expected_pattern" ]]; then
        return 0
    else
        return 1
    fi
}

# 測試 update-ab 功能
test_update_ab() {
    verbose_log "測試 update-ab 功能..."
    
    cd "$TEST_DIR"
    
    # 這個測試比較複雜，在快速模式下跳過
    if [ "$QUICK_MODE" = true ]; then
        return 0
    fi
    
    # 確保在 master 分支
    git checkout master > /dev/null 2>&1
    
    # 測試靜默模式
    bash lazy_git/lib/update-ab.sh -q > /dev/null 2>&1
    
    # 如果執行沒有錯誤，就算通過
    return $?
}

# 測試安裝功能
test_installation() {
    verbose_log "測試安裝功能..."
    
    cd "$TEST_DIR"
    
    # 測試 dry run 模式
    bash lazy_git/install.sh --dryrun > /dev/null 2>&1
    
    return $?
}

# 執行所有測試
run_all_tests() {
    log_info "開始執行測試套件..."
    
    # 基本功能測試
    run_test "Clean Lock 功能" "test_clean_lock" false
    run_test "Clean All Branches 功能" "test_clean_ab" false
    run_test "Feature Branch (develop) 功能" "test_feat_b" false
    run_test "Feature Branch (master) 功能" "test_feat_m" false
    run_test "Fix Branch 功能" "test_fix_b" false
    run_test "Hotfix Branch 功能" "test_hotfix_b" false
    run_test "Release Branch 功能" "test_release_b" false
    run_test "Update All Branches 功能" "test_update_ab" "$QUICK_MODE"
    run_test "安裝功能" "test_installation" false
    
    # 顯示測試結果
    show_test_results
}

# 顯示測試結果
show_test_results() {
    echo ""
    echo "==============================================="
    echo "                測試結果總結"
    echo "==============================================="
    echo -e "總測試數量: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "通過測試: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失敗測試: ${RED}$FAILED_TESTS${NC}"
    echo -e "跳過測試: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo ""
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 所有測試都通過了！${NC}"
        exit 0
    else
        echo -e "${RED}❌ 有 $FAILED_TESTS 個測試失敗${NC}"
        exit 1
    fi
}

# 清理測試環境
cleanup_test_environment() {
    log_info "清理測試環境..."
    
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        log_success "測試環境已清理: $TEST_DIR"
    fi
    
    # 恢復 git config
    git config --global --unset lazygit.main-branch 2>/dev/null || true
    git config --global --unset lazygit.develop-branch 2>/dev/null || true
}

# 主函數
main() {
    parse_args "$@"
    
    if [ "$CLEANUP_ONLY" = true ]; then
        cleanup_test_environment
        exit 0
    fi
    
    # 設置清理陷阱
    trap cleanup_test_environment EXIT
    
    setup_test_environment
    
    if [ "$SETUP_ONLY" = true ]; then
        log_info "測試環境已設置，位置: $TEST_DIR"
        log_info "請手動清理或使用 --cleanup-only"
        trap - EXIT  # 移除自動清理
        exit 0
    fi
    
    run_all_tests
}

# 執行主函數
main "$@"
