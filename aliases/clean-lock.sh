#!/bin/bash

# 刪除 .git/ORIG_HEAD.lock, .git/index.lock, 和其他鎖定檔案
# 使用方法: clean-lock
# 不論有沒有檔案都會試著去移除，顯示 '完成'
source "$(dirname "$0")/../lib/clean-lock.sh"