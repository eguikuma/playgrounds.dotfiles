function ccc_help
    echo "🧹 ccc - Cyclic Cleanup Commands

[使用方法]
ccc [オプション]

[説明]
定期的に実行すべきシステムメンテナンスコマンドを選択して実行します。
矢印キー(↑↓)で選択し、Enterで実行できます。
※ fzfが必要です (https://github.com/junegunn/fzf)

[オプション]
-h, --help     このヘルプを表示
-y, --yes      確認をスキップして実行（全コマンド実行）
-v, --verbose  詳細な実行情報を表示

[例]
ccc
ccc -y"
end

function clear_memory_cache -d システムのメモリキャッシュをクリア
    set -l verbose $argv[1]

    if test "$verbose" = true
        set_color cyan
        echo "⚙️ メモリキャッシュをクリアしています"
        set_color normal
    end

    if sudo sh -c "/usr/bin/echo 3 >/proc/sys/vm/drop_caches"
        set_color green
        echo "✅ メモリキャッシュのクリアに成功しました"
        set_color normal
    else
        set_color red
        echo "⛔ メモリキャッシュのクリアに失敗しました" >&2
        set_color normal
    end
end

function update_packages -d システムパッケージを更新
    set -l verbose $argv[1]

    if test "$verbose" = true
        set_color cyan
        echo "⚙️️ システムパッケージを更新しています"
        set_color normal
    end

    if sudo apt update && sudo apt upgrade -y
        set_color green
        echo "✅ システムパッケージの更新に成功しました"
        set_color normal
    else
        set_color red
        echo "⛔ システムパッケージの更新に失敗しました" >&2
        set_color normal
    end
end

function remove_unused_packages -d 不要なパッケージを削除
    set -l verbose $argv[1]

    if test "$verbose" = true
        set_color cyan
        echo "⚙️️ 不要なパッケージを削除しています"
        set_color normal
    end

    if sudo apt autoremove -y
        set_color green
        echo "✅ 不要なパッケージの削除に成功しました"
        set_color normal
    else
        set_color red
        echo "⛔ 不要なパッケージの削除に失敗しました" >&2
        set_color normal
    end
end

function run_all_commands -d すべてのメンテナンスコマンドを実行
    set -l verbose $argv[1]
    set -l commands $argv[2..-1]

    for command in $commands
        $command $verbose
    end

    if test $status -eq 0
        set_color green
        echo "✅ メンテナンスコマンドの実行に成功しました"
        set_color normal
    else
        set_color red
        echo "⛔ メンテナンスコマンドの実行に失敗しました" >&2
        set_color normal
    end
end

function create_preview
    set -l index $argv[1]
    set -l title $argv[2]
    set -l description $argv[3]

    echo "$title

    $description" >"/tmp/ccc_preview_$index.txt"
end

function ccc -d "Cyclic Cleanup Commands - 定期的なシステムメンテナンス"
    argparse h/help y/yes v/verbose -- $argv
    or return

    if set -q _flag_help
        ccc_help
        return 0
    end

    set -l verbose false
    if set -q _flag_verbose
        set verbose true
    end

    set -l yes_flag false
    if set -q _flag_yes
        set yes_flag true
    end

    if not command -v fzf >/dev/null
        set_color red
        echo "⛔ fzfコマンドが見つかりません" >&2
        set_color normal
        return 1
    end

    set -l commands "clear_memory_cache:メモリキャッシュのクリア:システムのメモリキャッシュをクリアします" \
        "update_packages:システムパッケージの更新:apt updateとapt upgradeを実行します" \
        "remove_unused_packages:不要なパッケージの削除:apt autoremoveを実行して不要なパッケージを削除します" \
        "run_all_commands:すべてのコマンドを実行:すべてのコマンドを順番に実行します"
    set -l command_names
    for command in $commands
        set -l command_name (string split -m 1 ":" $command)[1]

        if test "$command_name" != run_all_commands
            set -a command_names $command_name
        end
    end

    if test "$yes_flag" = true
        run_all_commands $verbose $command_names
        return 0
    end

    set file_list /tmp/ccc_preview_*.txt
    if count $file_list >/dev/null
        rm $file_list
    end

    set -l task_options
    for i in (seq (count $commands))
        set -l parts (string split ":" $commands[$i])
        set -l function $parts[1]
        set -l title $parts[2]
        set -l description $parts[3]

        set -a task_options $function

        create_preview (expr $i - 1) $title $description
    end

    set -l selected_function (
        printf "%s\n" $task_options | \
        fzf --layout=reverse \
            --prompt="🧹 " \
            --no-info \
            --height=~70% \
            --preview="cat /tmp/ccc_preview_{n}.txt" \
            --preview-window=right:60%:wrap
    )

    rm -f /tmp/ccc_preview_*.txt

    if test -z "$selected_function"
        echo "ℹ️ 操作をキャンセルしました"
        return 0
    end

    for i in (seq (count $commands))
        set -l parts (string split ":" $commands[$i])
        set -l function $parts[1]
        set -l title $parts[2]

        if test "$function" = "$selected_function"
            set_color yellow
            echo "🧹 $title"
            set_color normal

            $function $verbose $command_names

            return 0
        end
    end

    return 1
end
