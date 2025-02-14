#!/bin/bash

# 更新所有本地分支
# 使用方法: update-ab
# 它會在不同的工作目錄中檢出每個本地分支並執行 git pull
source "$(dirname "$0")/../lib/update-ab.sh"