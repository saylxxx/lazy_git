# lazy_git 智能主分支檢測完整方案

## 🎯 解決的問題
當專案目錄有多個主分支候選（如同時有 main, master, production）時，如何智能選擇合適的主分支。

## ✅ 實現的功能

### 1. 智能分層檢測邏輯
```bash
# 檢測優先順序：
1. 專案級 Git 配置：git config lazygit.main-branch
2. Remote 預設分支：git symbolic-ref refs/remotes/origin/HEAD  
3. 候選分支掃描：按照 LAZYGIT_MAIN_CANDIDATES 順序檢測
4. 全域 Git 配置：git config --global lazygit.main-branch
5. 系統預設值：DEFAULT_MAIN_BRANCH
```

### 2. 多分支智能處理
- **單一分支**：自動選擇
- **多個分支**：
  - 非互動模式：選擇優先級最高的，並發出警告
  - 互動模式：讓用戶選擇，可保存為專案設定

### 3. 專案級配置支援
```bash
# 設定專案主分支（只影響當前專案）
git config lazygit.main-branch production

# 設定全域主分支（影響所有專案）
git config --global lazygit.main-branch main

# 查看當前設定
git config --get-regexp lazygit
```

### 4. 彈性候選配置
```bash
# 環境變數自訂候選順序
export LAZYGIT_MAIN_CANDIDATES="production main master feature/production"

# 預設候選順序（可在 config.sh 中修改）
DEFAULT_MAIN_CANDIDATES="main master production feature/production release/production prod release/main release/master"
```

### 5. 管理工具
```bash
# 互動式管理
./lib/manage-main-branch.sh

# 直接設定
./lib/manage-main-branch.sh set production

# 查看狀態
./lib/manage-main-branch.sh status

# 重置設定
./lib/manage-main-branch.sh reset
```

## 🔧 實際使用場景

### 場景 1：只有一個候選分支
```bash
# 專案只有 master 分支
→ 自動選擇 master，無需用戶介入
```

### 場景 2：多個候選分支
```bash
# 專案有 main, master, production
→ 互動式選擇，可保存為專案設定
→ 非互動模式選擇優先級最高的 main
```

### 場景 3：特殊分支命名
```bash
# 專案使用 feature/production 作為主分支
→ 已包含在預設候選中，會被智能檢測到
```

### 場景 4：不同專案不同需求
```bash
# 專案 A 使用 production
git config lazygit.main-branch production

# 專案 B 使用 main
git config lazygit.main-branch main

# 每個專案獨立配置，互不影響
```

## 📋 使用流程

### 初次使用專案
1. 執行任何 lazy_git 命令（如 feat-m）
2. 系統自動檢測可用的主分支候選
3. 如果有多個候選，會啟動互動選擇
4. 選擇後可選擇保存為專案設定

### 已配置專案
1. 直接使用專案設定的主分支
2. 無需重複選擇

### 管理現有配置
```bash
# 查看當前狀態
./lib/manage-main-branch.sh status

# 修改配置
./lib/manage-main-branch.sh

# 重置回自動檢測
./lib/manage-main-branch.sh reset
```

## 🎉 優勢

1. **自動化**：大部分情況無需用戶介入
2. **彈性**：支援各種特殊分支命名
3. **專案隔離**：每個專案可以有獨立設定
4. **用戶友善**：提供清楚的選擇界面
5. **向後相容**：不影響現有功能
6. **可配置**：支援自訂候選順序

這個方案確保了在同主機的任何專案下，lazy_git 都能智能選擇合適的主分支，必要時提供用戶友善的互動選擇界面。
