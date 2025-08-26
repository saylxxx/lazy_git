#!/bin/bash

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

# 確認 remote 名稱
get_remote_name() {
    remote_name=$(git remote | grep -E 'origin|github' | head -n 1)
    if [ -z "$remote_name" ]; then
        echo "找不到 remote 名稱，請確認您的 remote 設定。"
        exit 1
    fi
    echo $remote_name
}

# 智能檢測主分支，支援互動式選擇
smart_detect_main_branch() {
    local remote_name=$1
    local interactive=${2:-true}  # 預設為互動模式
    
    # 1. 檢查是否已有專案級設定
    local project_main=$(git config lazygit.main-branch 2>/dev/null)
    if [ -n "$project_main" ]; then
        echo "$project_main"
        return 0
    fi
    
    # 2. 檢查 remote 的預設分支
    local remote_default=$(git symbolic-ref refs/remotes/$remote_name/HEAD 2>/dev/null | sed "s@^refs/remotes/$remote_name/@@")
    if [ -n "$remote_default" ]; then
        echo "$remote_default"
        return 0
    fi
    
    # 3. 收集所有可能的主分支候選
    local remote_branches=$(git ls-remote --heads $remote_name 2>/dev/null)
    local main_candidates_str=${LAZYGIT_MAIN_CANDIDATES:-"main master production feature/production release/production prod release/main release/master"}
    local main_candidates=($main_candidates_str)
    local found_candidates=()
    
    for candidate in "${main_candidates[@]}"; do
        if echo "$remote_branches" | grep -q "refs/heads/$candidate$"; then
            found_candidates+=("$candidate")
        fi
    done
    
    # 4. 根據找到的候選分支數量決定行為
    if [ ${#found_candidates[@]} -eq 0 ]; then
        # 沒有找到候選分支，使用全域設定或預設值
        local global_main=$(git config --global lazygit.main-branch 2>/dev/null)
        echo "${global_main:-$DEFAULT_MAIN_BRANCH}"
        return 0
    elif [ ${#found_candidates[@]} -eq 1 ]; then
        # 只有一個候選分支，直接使用
        echo "${found_candidates[0]}"
        return 0
    else
        # 多個候選分支，需要處理
        if [ "$interactive" = "true" ]; then
            # 互動模式：讓用戶選擇
            echo "發現多個可能的主分支:" >&2
            for i in "${!found_candidates[@]}"; do
                echo "  $((i+1)). ${found_candidates[$i]}" >&2
            done
            echo "" >&2
            
            while true; do
                echo -n "請選擇主分支 [1-${#found_candidates[@]}] 或按 Enter 使用第一個 (${found_candidates[0]}): " >&2
                read -r choice
                
                if [ -z "$choice" ]; then
                    # 空輸入，使用第一個
                    echo "${found_candidates[0]}"
                    break
                elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#found_candidates[@]} ]; then
                    # 有效選擇
                    local selected="${found_candidates[$((choice-1))]}"
                    echo "$selected"
                    
                    # 詢問是否要保存為專案設定
                    echo -n "是否要將 '$selected' 設為此專案的預設主分支? [y/N]: " >&2
                    read -r save_choice
                    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
                        git config lazygit.main-branch "$selected"
                        echo "已設定專案主分支為: $selected" >&2
                    fi
                    break
                else
                    echo "無效選擇，請輸入 1-${#found_candidates[@]} 的數字" >&2
                fi
            done
            return 0
        else
            # 非互動模式：使用優先級最高的分支並發出警告
            echo "警告：發現多個可能的主分支: ${found_candidates[*]}" >&2
            echo "使用優先級最高的分支: ${found_candidates[0]}" >&2
            echo "如需更改，請執行: git config lazygit.main-branch <分支名>" >&2
            echo "${found_candidates[0]}"
            return 0
        fi
    fi
}

# 原有的檢測函數（保持向後相容）
detect_main_branch() {
    smart_detect_main_branch "$1" false
}

# 自動檢測當前倉庫的開發分支名稱
detect_develop_branch() {
    local remote_name=$1
    
    # 檢查 remote 是否有常見的開發分支
    local remote_branches=$(git ls-remote --heads $remote_name 2>/dev/null)
    
    for branch in develop dev development; do
        if echo "$remote_branches" | grep -q "refs/heads/$branch$"; then
            echo "$branch"
            return 0
        fi
    done
    
    # 檢查本地分支
    for branch in develop dev development; do
        if git show-ref --verify --quiet refs/heads/$branch; then
            echo "$branch"
            return 0
        fi
    done
    
    # 回退到配置的開發分支
    echo "$LAZYGIT_DEVELOP_BRANCH"
}

# 檢查本地是否有指定分支，若無則從 remote 拉取
ensure_branch_exists() {
    local branch=$1
    local remote_name=$2
    
    if ! git show-ref --verify --quiet refs/heads/$branch; then
        echo "本地不存在分支 $branch，嘗試從 remote 拉取..."
        
        # 檢查 remote 是否有該分支
        if git ls-remote --heads $remote_name | grep -q "refs/heads/$branch$"; then
            git fetch $remote_name $branch:$branch
            if [ $? -ne 0 ]; then
                echo "無法從 remote 拉取分支 $branch。"
                exit 1
            fi
            echo "成功從 remote 拉取分支 $branch。"
        else
            echo "警告：remote 上不存在分支 $branch"
            echo "可用的 remote 分支："
            git ls-remote --heads $remote_name | sed 's/.*refs\/heads\//  - /'
            
            # 如果是主分支，嘗試自動檢測
            if [ "$branch" = "$LAZYGIT_MAIN_BRANCH" ]; then
                echo "嘗試自動檢測正確的主分支..."
                local detected_main=$(smart_detect_main_branch "$remote_name" false)
                if [ "$detected_main" != "$branch" ]; then
                    echo "檢測到主分支應該是: $detected_main"
                    echo "建議執行: git config lazygit.main-branch $detected_main"
                fi
            fi
            
            exit 1
        fi
    fi
}

# 切換到指定分支並更新
checkout_and_pull_branch() {
    local branch=$1
    local remote_name=$2
    git checkout $branch
    if [ $? -ne 0 ]; then
        echo "無法切換到分支 $branch。"
        exit 1
    fi

    git pull $remote_name $branch
    if [ $? -ne 0 ]; then
        echo "無法從 remote 更新分支 $branch。"
        exit 1
    fi
}