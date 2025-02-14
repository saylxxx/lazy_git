#!/bin/bash

# 刪除所有本地分支，排除配置的主分支和開發分支
# 使用方法: clean-ab
# 如果沒有本地分支，顯示 '完成'
source "$(dirname "$0")/../lib/clean-ab.sh"