#!/bin/bash

# 定義別名和描述
declare -A aliases
aliases=(
    ["update-all-branches"]="更新所有本地分支"
    ["delete-unused-branches"]="刪除所有本地分支，排除 master 和 develop"
    ["lista"]="列出所有自訂的別名及其對應的命令"
)

# 列出別名和描述
for alias in "${!aliases[@]}"; do
    echo "$alias - ${aliases[$alias]}"
done
