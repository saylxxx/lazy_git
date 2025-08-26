#!/bin/bash

# 簡化測試腳本
echo "開始簡化測試..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "腳本目錄: $SCRIPT_DIR"

# 檢查基本檔案
echo "檢查基本檔案:"
for file in lib/clean-lock.sh lib/feat-b.sh config.sh; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo "✓ $file 存在"
    else
        echo "✗ $file 不存在"
    fi
done

# 檢查語法
echo "檢查語法:"
for script in lib/clean-lock.sh lib/feat-b.sh; do
    if bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
        echo "✓ $script 語法正確"
    else
        echo "✗ $script 語法錯誤"
    fi
done

echo "簡化測試完成"
