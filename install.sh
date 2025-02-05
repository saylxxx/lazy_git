#!/bin/bash

# 複製 .gitconfig 到用戶主目錄
cp gitconfig ~/.gitconfig

# 複製 git-aliases.sh 到用戶主目錄並設置可執行權限
cp git-aliases.sh ~/git-aliases.sh
chmod +x ~/git-aliases.sh

echo "Git 配置和別名腳本已安裝完成。"
