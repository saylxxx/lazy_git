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

# 自動檢測當前倉庫的主分支名稱
detect_main_branch() {
    local remote_name=$1
    
    # 優先檢查 remote 的預設分支
    local remote_default=$(git symbolic-ref refs/remotes/$remote_name/HEAD 2>/dev/null | sed "s@^refs/remotes/$remote_name/@@")
    if [ -n "$remote_default" ]; then
        echo "$remote_default"
        return 0
    fi
    
    # 檢查 remote 是否有 main 或 master 分支
    local remote_branches=$(git ls-remote --heads $remote_name 2>/dev/null)
    
    if echo "$remote_branches" | grep -q "refs/heads/main$"; then
        echo "main"
        return 0
    elif echo "$remote_branches" | grep -q "refs/heads/master$"; then
        echo "master"
        return 0
    fi
    
    # 檢查本地分支
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
        return 0
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
        return 0
    fi
    
    # 回退到配置的主分支
    echo "$LAZYGIT_MAIN_BRANCH"
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
                local detected_main=$(detect_main_branch $remote_name)
                if [ "$detected_main" != "$branch" ]; then
                    echo "檢測到主分支應該是: $detected_main"
                    echo "建議執行: git config --global lazygit.main-branch $detected_main"
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