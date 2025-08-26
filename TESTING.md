# Lazy Git 測試

## 快速開始

```bash
# 快速驗證 (10-30秒)
./quick-verify.sh

# 完整測試 (1-3分鐘)
./unit-tests.sh

# 端到端測試 (3-10分鐘)
./test-suite.sh
```

## 已測試功能

### 核心腳本

- clean-lock.sh - 清理 Git 鎖檔案 (支援 -f/--force)
- clean-ab.sh - 批量刪除分支 (支援 -f/--force)
- feat-b.sh - 基於 develop 創建功能分支
- feat-m.sh - 基於 main/master 創建功能分支
- fix-b.sh - 基於 develop 創建修復分支
- hotfix-b.sh - 基於 main/master 創建緊急修復分支
- release-b.sh - 基於 main/master 創建發布分支
- update-ab.sh - 更新所有分支 (支援 -q/--quiet)

### 智能分支檢測

- 自動檢測 main vs master
- 自動檢測 develop vs dev vs development
- 分支檢測工具 ./lib/detect-branches.sh

## 測試環境

測試使用隔離環境，不會影響實際的 Git 倉庫或遠端操作。
