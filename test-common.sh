#!/bin/bash

# test-common.sh - 測試版本的 common.sh
# 用於單元測試，避免實際執行可能有副作用的 Git 操作

# 確保目錄存在
ensure_home_directory() {
    if [ -z "$HOME" ]; then
        if [ -n "$USERPROFILE" ]; then
            HOME=$(echo $USERPROFILE | sed 's/\\/\//g')
        else
            HOME=~
        fi
    fi
}

# 確認 remote 名稱（測試版本）
get_remote_name() {
    # 在測試環境中，總是返回 origin
    echo "origin"
}

# 智能檢測主分支（測試版本）
smart_detect_main_branch() {
    local remote_name=$1
    local interactive=${2:-false}  # 測試模式預設為非互動
    
    # 1. 檢查是否已有專案級設定
    local project_main=$(git config lazygit.main-branch 2>/dev/null)
    if [ -n "$project_main" ]; then
        echo "$project_main"
        return 0
    fi
    
    # 2. 檢查 remote 的預設分支（測試版本簡化）
    local remote_default=$(git symbolic-ref refs/remotes/$remote_name/HEAD 2>/dev/null | sed "s@^refs/remotes/$remote_name/@@")
    if [ -n "$remote_default" ]; then
        echo "$remote_default"
        return 0
    fi
    
    # 3. 在測試環境中，檢查本地分支而不是 remote
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    local main_candidates_str=${LAZYGIT_MAIN_CANDIDATES:-"main master production feature/production release/production prod release/main release/master"}
    local main_candidates=($main_candidates_str)
    local found_candidates=()
    
    # 檢查本地分支
    for candidate in "${main_candidates[@]}"; do
        if git show-ref --verify --quiet refs/heads/$candidate 2>/dev/null; then
            found_candidates+=("$candidate")
        fi
    done
    
    # 4. 根據找到的候選分支數量決定行為
    if [ ${#found_candidates[@]} -eq 0 ]; then
        # 沒有找到候選分支，使用全域設定或預設值
        local global_main=$(git config --global lazygit.main-branch 2>/dev/null)
        echo "${global_main:-master}"
        return 0
    elif [ ${#found_candidates[@]} -eq 1 ]; then
        # 只有一個候選分支，直接使用
        echo "${found_candidates[0]}"
        return 0
    else
        # 多個候選分支，在測試模式下使用優先級最高的
        echo "${found_candidates[0]}"
        return 0
    fi
}

# 原有的檢測函數（保持向後相容）
detect_main_branch() {
    smart_detect_main_branch "$1" false
}

# 自動檢測當前倉庫的開發分支名稱（測試版本）
detect_develop_branch() {
    local remote_name=$1
    
    # 檢查本地分支
    for branch in develop dev development; do
        if git show-ref --verify --quiet refs/heads/$branch; then
            echo "$branch"
            return 0
        fi
    done
    
    # 回退到配置的開發分支
    echo "${LAZYGIT_DEVELOP_BRANCH:-develop}"
}

# 檢查本地是否有指定分支（測試版本 - 不執行實際操作）
ensure_branch_exists() {
    local branch=$1
    local remote_name=$2
    
    if ! git show-ref --verify --quiet refs/heads/$branch; then
        echo "測試模式：會檢查分支 $branch 是否存在"
        # 在測試中不執行實際的分支創建
        return 0
    fi
}

# 切換到指定分支並更新（測試版本 - 不執行實際操作）
checkout_and_pull_branch() {
    local branch=$1
    local remote_name=$2
    
    echo "測試模式：會切換到分支 $branch 並從 $remote_name 更新"
    # 在測試中不執行實際的切換和拉取
    return 0
}

# 創建帶日期的分支名稱
get_date_branch_name() {
    local prefix="$1"
    local description="$2"
    local date_override="$3"
    
    local date_str
    if [ -n "$date_override" ]; then
        date_str="$date_override"
    else
        date_str=$(date +%Y%m%d)
    fi
    
    if [ -n "$description" ]; then
        echo "${prefix}_${date_str}_${description}"
    else
        echo "${prefix}_${date_str}"
    fi
}

# 創建帶日期的特殊格式分支名稱（hotfix, release）
get_special_date_branch_name() {
    local prefix="$1"
    local description="$2"
    local date_override="$3"
    
    local date_str
    if [ -n "$date_override" ]; then
        date_str="$date_override"
    else
        date_str=$(date +%Y%m%d)
    fi
    
    if [ -n "$description" ]; then
        echo "${prefix}${date_str}_${description}"
    else
        echo "${prefix}${date_str}"
    fi
}

# 測試模式標記
export LAZY_GIT_TEST_MODE=true