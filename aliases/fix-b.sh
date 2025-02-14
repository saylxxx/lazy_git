#!/bin/bash

# 更新本地 develop 分支到最新版，並建立一個以 fix 開頭的日期分支
# 使用方法: fix-b [描述]
# 如果沒有提供描述，則只會使用日期作為分支名稱; e.g., fix_20200101
source "$(dirname "$0")/../lib/fix-b.sh"