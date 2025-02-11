#!/bin/bash

# 切換到新的分支，分支名稱格式為 feat_MMDD_desc
# 使用方法: checkout-b [desc]
# 如果沒有提供 desc，預設為 "update"; e.g., feat_0101_update

desc=${1:-update}
git checkout -b feat_$(date +%m%d)_${desc}