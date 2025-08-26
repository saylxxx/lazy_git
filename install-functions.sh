#!/bin/bash

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

# 複製 lib 腳本到用戶主目錄並設置可執行權限
copy_lib_scripts() {
    for lib_script in "$LIB_DIR"/*.sh; do
        cp "$lib_script" "$GIT_LIB_DIR/$(basename "$lib_script")"
        chmod +x "$GIT_LIB_DIR/$(basename "$lib_script")"
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
    } >"$GIT_ALIASES_DIR/lista.sh"

    chmod +x "$GIT_ALIASES_DIR/lista.sh"
}

# 讀取目前已存在的 gitconfig 的內容並生成新的 gitconfig
generate_gitconfig() {
    # 確保目錄存在
    mkdir -p "$GIT_CONFIG_DIR"

    # 生成 gitconfig 內容
    {
        # 還原其它配置
        if [ -f "$BACKUP_FILE" ]; then
            awk -v sections="${GENERATE_SECTIONS[*]}" '
            BEGIN {
                split(sections, section_array)
                for (i in section_array) {
                    section_map[section_array[i]] = 1
                }
            }
            /^\[/ {
                in_section = 0
                section_name = gensub(/^\[(.*)\]$/, "\\1", "g")
                if (section_map[section_name]) {
                    in_section = 1
                }
            }
            !in_section
            ' "$BACKUP_FILE"
        fi

        for section in "${GENERATE_SECTIONS[@]}"; do
            case $section in
                "user")
                    echo "[user]"
                    echo "    name = $USER_NAME"
                    echo "    email = $USER_EMAIL"
                    ;;
                "alias")
                    echo "[alias]"
                    for alias_script in "$ALIASES_DIR"/*.sh; do
                        alias_name=$(basename "$alias_script" .sh)
                        echo "    $alias_name = \"!$GIT_LIB_DIR/$alias_name.sh\""
                    done
                    echo "    lista = \"!$GIT_ALIASES_DIR/lista.sh\""
                    ;;
                "lazygit")
                    echo "[lazygit]"
                    echo "    # 全域預設設定 - 智能檢測會自動選擇最佳主分支"
                    echo "    # 如需為特定專案設定不同分支，請使用:"
                    echo "    # git manage-main-branch set <分支名>"
                    echo "    main-branch = $LAZYGIT_MAIN_BRANCH"
                    echo "    develop-branch = $LAZYGIT_DEVELOP_BRANCH"
                    ;;
            esac
        done
    } >"$GIT_CONFIG_DIR/.gitconfig"
}

# 打印保留的其它配置
print_preserved_config() {
    if [ -f ~/.gitconfig ]; then
        echo "將被保留的其它配置:"
        awk -v sections="${GENERATE_SECTIONS[*]}" '
        BEGIN {
            split(sections, section_array)
            for (i in section_array) {
                section_map[section_array[i]] = 1
            }
        }
        /^\[/ {
            in_section = 0
            section_name = gensub(/^\[(.*)\]$/, "\\1", "g")
            if (section_map[section_name]) {
                in_section = 1
            }
        }
        !in_section
        ' ~/.gitconfig
    fi
}