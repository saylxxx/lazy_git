#!/bin/bash

# 此腳本用於更新所有本地分支
# 它會切換到每個本地分支並執行 git pull，然後返回到原本的分支

current_branch=$(git symbolic-ref --short HEAD)
echo "當前分支: $current_branch"

# 更新所有本地分支
git branch | grep -v '\\*' | xargs -I {} sh -c 'git checkout {} && git pull'

# 切換回原本的分支
echo "切換回: $current_branch"
git checkout $current_branch