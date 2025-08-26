#!/bin/bash

# 自動檢測並配置 Git 倉庫的分支設定
# 使用方法: detect-branches
# 幫助解決不同專案使用不同主分支名稱的問題
source "$(dirname "$0")/../lib/detect-branches.sh"
