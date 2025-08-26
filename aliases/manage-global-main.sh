#!/bin/bash

# Git 別名腳本 - 全域主分支管理工具
git_lib_dir="$HOME/git-lib"

exec "$git_lib_dir/manage-global-main.sh" "$@"
