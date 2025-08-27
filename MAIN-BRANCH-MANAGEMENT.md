# 主分支管理指南

## 概述

lazy_git 提供兩個層級的主分支管理：
- **專案級設定**：只影響當前專案（推薦）
- **全域設定**：影響所有專案（需謹慎使用）

## 配置優先級

1. **專案級設定** (`git config lazygit.main-branch`) - 最高優先級
2. Remote 預設分支自動檢測
3. 候選分支自動檢測 (main, master, production, etc.)
4. **全域設定** (`git config --global lazygit.main-branch`) - 較低優先級  
5. 系統預設值 (master)

## 專案級管理（推薦）

### 查看狀態
```bash
git manage-main-branch
```

### 設定專案主分支
```bash
git manage-main-branch set main
git manage-main-branch set production
```

### 重置專案設定
```bash
git manage-main-branch reset
```

### 互動式設定
```bash
git manage-main-branch
# 然後按照提示選擇
```

## 全域管理（謹慎使用）

⚠️ **警告**：全域設定會影響所有沒有專案級設定的 Git 倉庫！

### 查看全域狀態
```bash
git manage-global-main
```

### 設定全域主分支
```bash
git manage-global-main set main
```

### 重置全域設定
```bash
git manage-global-main reset
```

## 最佳實踐

### 1. 優先使用專案級設定
```bash
# 為每個專案設定各自的主分支
cd /path/to/project1
git manage-main-branch set main

cd /path/to/project2  
git manage-main-branch set production
```

### 2. 全域設定作為預設值
```bash
# 只在確定大部分專案使用相同主分支時才設定
git manage-global-main set main
```

### 3. 檢查配置狀態
```bash
# 檢查當前專案設定
git manage-main-branch

# 檢查全域設定
git manage-global-main
```

## 範例情境

### 情境 1：多專案使用不同主分支
```bash
# 專案 A 使用 main
cd ~/projects/webapp
git manage-main-branch set main

# 專案 B 使用 production  
cd ~/projects/api
git manage-main-branch set production

# 專案 C 使用 master
cd ~/projects/legacy
git manage-main-branch set master
```

### 情境 2：大部分專案使用相同主分支
```bash
# 設定全域預設為 main
git manage-global-main set main

# 少數專案使用特殊設定
cd ~/projects/special-project
git manage-main-branch set production
```

## 檢查實際使用的主分支
```bash
# 使用 detect-branches 工具檢查
git detect-branches

# 查看 feat-b 等命令將使用的分支
git manage-main-branch
```

## 故障排除

### 問題：分支檢測不正確
```bash
# 檢查配置
git manage-main-branch

# 重新設定
git manage-main-branch set <正確的主分支名>
```

### 問題：多專案衝突
```bash
# 檢查全域設定
git manage-global-main

# 為特定專案設定獨立配置
cd /path/to/specific/project
git manage-main-branch set <專案特定的主分支>
```

### 問題：恢復預設行為
```bash
# 清除專案設定
git manage-main-branch reset

# 清除全域設定
git manage-global-main reset
```
