#!/bin/bash

# 除錯分支命名測試
echo "開始除錯分支命名測試..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="/tmp/debug_branch_test_$(date +%s)"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "測試目錄: $TEST_DIR"

# 設置 Git
git init
git config user.name "Test User"
git config user.email "test@example.com"
git remote add origin "https://github.com/test/test.git"

echo "initial commit" > README.md
git add README.md
git commit -m "Initial commit"

# 創建 develop 分支
git checkout -b develop
echo "develop content" > develop.txt
git add develop.txt
git commit -m "Add develop"
git checkout master

# 設置配置
git config --global lazygit.main-branch "master"
git config --global lazygit.develop-branch "develop"

echo "Git 倉庫設置完成"
echo "分支列表:"
git branch -a

echo ""
echo "測試 feat-b..."
set -x
bash "$SCRIPT_DIR/lib/feat-b.sh" "test_feature"
set +x

echo ""
echo "當前分支:"
git symbolic-ref --short HEAD

echo ""
echo "所有分支:"
git branch

# 清理
cd /
rm -rf "$TEST_DIR"
git config --global --unset lazygit.main-branch 2>/dev/null || true
git config --global --unset lazygit.develop-branch 2>/dev/null || true

echo "除錯測試完成"
