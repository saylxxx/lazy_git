#!/bin/bash

# 刪除所有本地分支，排除 master 和 develop
# 使用方法: clean-ab
# 如果沒有本地分支，顯示 '完成'

f() {
    branches=$(git branch | grep -v '\\*' | grep -v 'master' | grep -v 'develop')
    if [ -z "$branches" ]; then
        echo '完成'
    else
        echo "$branches" | xargs -n 1 git branch -D
    fi
}
f