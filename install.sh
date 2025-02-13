#!/bin/bash
timestamp=$(date +%Y%m%d%H%M%S)

GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
VERSION="1.0.0-$GIT_HASH-$timestamp"

# 檢查是否 dry run 模式
DRY_RUN=false
if [[ "$1" == "--dryrun" ]]; then
    DRY_RUN=true
fi

# 檢查操作系統
OS_TYPE=$(uname)
if [[ "$OS_TYPE" == "Linux" ]]; then
    USER_HOME=~
    GIT_CONFIG_DIR="$USER_HOME/git-config"
    GIT_ALIASES_DIR="$USER_HOME/git-aliases"
    ALIASES_DIR=aliases
    GIT_CONFIG_HISTORY_DIR="$USER_HOME/git-config-history"
elif [[ "$OS_TYPE" == "MINGW"* || "$OS_TYPE" == "CYGWIN"* ]]; then
    USER_HOME=$(echo $USERPROFILE | sed 's/\\/\//g')
    GIT_CONFIG_DIR="$USER_HOME/git-config"
    GIT_ALIASES_DIR="$USER_HOME/git-aliases"
    ALIASES_DIR=aliases
    GIT_CONFIG_HISTORY_DIR="$USER_HOME/git-config-history"
else
    echo "不支援的操作系統: $OS_TYPE"
    exit 1
fi

# Dry run: 打印相關資訊後退出
if [ "$DRY_RUN" = true ]; then
    echo "操作系統: $OS_TYPE"
    echo "USER_HOME: $USER_HOME"
    echo "GIT_CONFIG_DIR: $GIT_CONFIG_DIR"
    echo "GIT_ALIASES_DIR: $GIT_ALIASES_DIR"
    echo "ALIASES_DIR: $ALIASES_DIR"
    echo "GIT_CONFIG_HISTORY_DIR: $GIT_CONFIG_HISTORY_DIR"
    echo "版本號: $VERSION"
    
    if [ -f ~/.gitconfig ]; then
        echo "將被保留的非 user 和 alias 配置:"
        awk '/^\[/{in_section=0} /^\[user\]/{in_section=1} /^\[alias\]/{in_section=1} !in_section' ~/.gitconfig
    fi
    
    exit 0
fi

# 確保目錄存在
mkdir -p "$GIT_CONFIG_DIR"
mkdir -p "$GIT_ALIASES_DIR"
mkdir -p "$GIT_CONFIG_HISTORY_DIR"

# 設置備份文件路徑
BACKUP_FILE="$GIT_CONFIG_HISTORY_DIR/.gitconfig_$timestamp"

# 檢查 aliases 目錄是否存在
if [ ! -d "$ALIASES_DIR" ]; then
    echo "Error: $ALIASES_DIR directory does not exist."
    exit 1
fi

# 備份現有的 .gitconfig
backup_gitconfig() {
    if [ -f ~/.gitconfig ]; then
        mv ~/.gitconfig "$BACKUP_FILE"
        echo "現有的 .gitconfig 已備份到 $BACKUP_FILE"
    fi
}

# 複製 alias 腳本到用戶主目錄並設置可執行權限
copy_alias_scripts() {
    for alias_script in "$ALIASES_DIR"/*.sh; do
        cp "$alias_script" "$GIT_ALIASES_DIR/$(basename "$alias_script")"
        chmod +x "$GIT_ALIASES_DIR/$(basename "$alias_script")"
    done
}

# 生成 lista.sh 內容
generate_lista_script() {
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
        echo ""
        echo "echo \"$VERSION\""
    } > "$GIT_ALIASES_DIR/lista.sh"

    chmod +x "$GIT_ALIASES_DIR/lista.sh"
}

# 讀取目前已存在的 gitconfig 的內容並生成新的 gitconfig
generate_gitconfig() {
    if [ -f ~/.gitconfig ]; then
        current_name=$(git config --global user.name)
        current_email=$(git config --global user.email)
    else
        current_name="mip.yang"
        current_email="mip.yang@homeplus.net.tw"
    fi

    # 生成 gitconfig 內容
    {
        # 還原原先的非 user 和 alias 配置
        if [ -f "$BACKUP_FILE" ]; then
            awk '/^\[/{in_section=0} /^\[user\]/{in_section=1} /^\[alias\]/{in_section=1} !in_section' "$BACKUP_FILE"
        fi

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
}

# 執行安裝
backup_gitconfig
copy_alias_scripts
generate_lista_script
generate_gitconfig

# 複製生成的 .gitconfig 到用戶主目錄
cp "$GIT_CONFIG_DIR/.gitconfig" ~/.gitconfig

echo "Git 配置和別名腳本已安裝完成，版本號: $VERSION"