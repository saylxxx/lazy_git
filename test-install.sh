#!/bin/bash

# 測試安裝功能是否正確包含所有 alias
echo "測試安裝功能..."

cd /home/vagrant/code_latest/test_spec/samples/lazy_git

# 創建臨時測試目錄
TEST_DIR="/tmp/lazy_git_install_test_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 初始化 Git 環境
git init
git config user.name "Test User"
git config user.email "test@example.com"

# 複製 lazy_git 檔案
cp -r /home/vagrant/code_latest/test_spec/samples/lazy_git/* .

# 執行安裝 (實際安裝到臨時目錄)
export USER_HOME="$TEST_DIR"
export GIT_CONFIG_DIR="$TEST_DIR/git-config"
export GIT_ALIASES_DIR="$TEST_DIR/git-aliases"
export GIT_LIB_DIR="$TEST_DIR/git-lib"
export GIT_CONFIG_HISTORY_DIR="$TEST_DIR/git-config-history"

bash install.sh

echo ""
echo "檢查生成的 .gitconfig 中的 alias..."
echo "======================================"

if [ -f "$GIT_CONFIG_DIR/.gitconfig" ]; then
    echo "找到的 Git alias:"
    grep -A 20 '\[alias\]' "$GIT_CONFIG_DIR/.gitconfig" | head -15
    
    echo ""
    echo "檢查 feat-m alias..."
    if grep -q "feat-m" "$GIT_CONFIG_DIR/.gitconfig"; then
        echo "✓ feat-m alias 已正確安裝"
    else
        echo "✗ feat-m alias 未找到"
    fi
    
    echo ""
    echo "檢查所有預期的 alias..."
    for alias in clean-ab clean-lock feat-b feat-m fix-b hotfix-b release-b update-ab lista; do
        if grep -q "$alias" "$GIT_CONFIG_DIR/.gitconfig"; then
            echo "✓ $alias"
        else
            echo "✗ $alias"
        fi
    done
else
    echo "✗ .gitconfig 檔案未找到"
fi

echo ""
echo "檢查複製的檔案..."
echo "===================="
echo "Aliases 目錄內容:"
ls -la "$GIT_ALIASES_DIR" | grep "\.sh$" || echo "無 shell 檔案"

echo ""
echo "Lib 目錄內容:"
ls -la "$GIT_LIB_DIR" | grep "\.sh$" || echo "無 shell 檔案"

# 清理
cd /
rm -rf "$TEST_DIR"

echo ""
echo "安裝測試完成"
