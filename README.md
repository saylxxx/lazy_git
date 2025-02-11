# Lazy Git

Git 懶人包；滿足日常開發需求的 Git 別名腳本。

## 安裝

1. download 或 clone 專案到本地機器。
2. 確保您已安裝 Git。
3. 執行以下命令來安裝 Git 配置和別名腳本：

   ```bash
   ./install.sh
   ```

   這個腳本會將 `.gitconfig` 和別名腳本複製到您的主目錄中。

## 使用

安裝完成後，您可以在終端中使用這些別名。例如：

- 使用 `git update-ab` 更新所有本地分支。
- 使用 `git clean-ab` 刪除 develop 與 master 以外的所有本地分支。
- 使用 `git lista` 來查看所有自訂的別名。

## 安裝腳本說明

`install.sh` 腳本會執行以下操作：

1. 創建必要的目錄。
2. 檢查 `aliases` 目錄是否存在。
3. 備份現有的 `.gitconfig` 文件。
4. 複製 `aliases` 目錄中的腳本並設置可執行權限。
5. 生成 `lista.sh` 腳本。
6. 讀取目前已存在的 `.gitconfig` 文件中的用戶名和郵箱。
7. 生成新的 `.gitconfig` 文件並複製到用戶主目錄。

### 原先 gitconfig 內容安排

在執行 `install.sh` 腳本後，原先的 `.gitconfig` 文件會被備份到 `~/git-config-history` 目錄，文件名會加上時間戳。例如：
~/.gitconfig -> ~/git-config-history/.gitconfig_20250102140037

### 新的 `.gitconfig` 文件會包含以下內容

- 用戶名和郵箱（從原先的 `.gitconfig` 文件中讀取，若不存在則使用預設值）。
- 所有自訂的 Git 別名，這些別名會指向 `~/git-aliases` 目錄中的對應腳本。
- `lista` 別名，用於列出所有自訂的 Git 別名及其對應的命令。
