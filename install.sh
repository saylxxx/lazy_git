#!/bin/bash

# 定義目錄變數
GIT_CONFIG_DIR=~/git-config
GIT_ALIASES_DIR=~/git-aliases
ALIASES_DIR=aliases
GIT_CONFIG_HISTORY_DIR=~/git-config-history

# 確保目錄存在
mkdir -p "$GIT_CONFIG_DIR"
mkdir -p "$GIT_ALIASES_DIR"
mkdir -p "$GIT_CONFIG_HISTORY_DIR"

# 檢查 aliases 目錄是否存在
if [ ! -d "$ALIASES_DIR" ]; then
    echo "Error: $ALIASES_DIR directory does not exist."
    exit 1
fi

# 備份現有的 .gitconfig
if [ -f ~/.gitconfig ]; then
    timestamp=$(date +%Y%m%d%H%M%S)
    mv ~/.gitconfig "$GIT_CONFIG_HISTORY_DIR/.gitconfig_$timestamp"
    echo "現有的 .gitconfig 已備份到 $GIT_CONFIG_HISTORY_DIR/.gitconfig_$timestamp"
fi

# 複製 alias 腳本到用戶主目錄並設置可執行權限
for alias_script in "$ALIASES_DIR"/*.sh; do
    cp "$alias_script" "$GIT_ALIASES_DIR/$(basename "$alias_script")"
    chmod +x "$GIT_ALIASES_DIR/$(basename "$alias_script")"
done

# 生成 lista.sh 內容
{
    echo "#!/bin/bash"
    echo ""
    echo "# 列出所有自訂的別名及其對應的命令"
    echo "echo \"以下是所有自訂的 Git 別名：\""
    echo "declare -A aliases"
    echo "aliases=("

    # 手動添加 lista 別名的描述
    echo "    [\"lista\"]=\"列出所有自訂的 Git 別名及其對應的命令\""
    
    for alias_script in "$ALIASES_DIR"/*.sh; do
        alias_name=$(basename "$alias_script" .sh)
        description=$(sed -n '/^# /p' "$alias_script" | sed 's/# //')
        if [ "$alias_name" != "lista" ]; then
            echo "    [\"$alias_name\"]=\"$description\""
        fi
    done
    
    echo ")"
    echo ""
    echo "# 列出別名和描述"
    echo "echo \"lista:\""
    echo "echo \"\${aliases[lista]}\" | while IFS= read -r line; do"
    echo "    echo \"    \$line\""
    echo "done"
    echo "echo \"\""
    echo "for alias in \$(echo \${!aliases[@]} | tr ' ' '\n' | sort); do"
    echo "    if [ \"\$alias\" != \"lista\" ]; then"
    echo "        echo \"\$alias:\""
    echo "        echo \"\${aliases[\$alias]}\" | while IFS= read -r line; do"
    echo "            echo \"    \$line\""
    echo "        done"
    echo "        echo \"\""
    echo "    fi"
    echo "done"
} > "$GIT_ALIASES_DIR/lista.sh"

chmod +x "$GIT_ALIASES_DIR/lista.sh"

# 讀取目前已存在的 gitconfig 的內容
if [ -f ~/.gitconfig ]; then
    current_name=$(git config --global user.name)
    current_email=$(git config --global user.email)
else
    current_name="mip.yang"
    current_email="mip.yang@homeplus.net.tw"
fi

# 生成 gitconfig 內容
{
    echo "[user]"
    echo "    name = $current_name"
    echo "    email = $current_email"
    echo "[alias]"
    
    for alias_script in "$ALIASES_DIR"/*.sh; do
        alias_name=$(basename "$alias_script" .sh)
        echo "    $alias_name = \"!$GIT_ALIASES_DIR/$alias_name.sh\""
    done
    
    # 添加 lista 別名
    echo "    lista = \"!$GIT_ALIASES_DIR/lista.sh\""
} > "$GIT_CONFIG_DIR/.gitconfig"

# 複製生成的 .gitconfig 到用戶主目錄
cp "$GIT_CONFIG_DIR/.gitconfig" ~/.gitconfig

# 確保 .gitignore 和 README.md 文件存在
[ ! -f .gitignore ] && echo "# Ignore files" > .gitignore
[ ! -f README.md ] && echo "# Project README" > README.md

echo "Git 配置和別名腳本已安裝完成。"