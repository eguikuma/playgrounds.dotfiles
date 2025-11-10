function h_help
    echo "📚 h - コマンドヘルプ表示ツール

[使用方法]
h [コマンド名 | オプション]

[説明]
自作コマンドのヘルプを表示します。
関数名_helpとしてヘルプ関数を作成することで、ヘルプを表示できます。
コマンドを追加した場合は、`known_commands`に関数名を追加してください。

[オプション]
-h, --help     このヘルプを表示
-a, --all      すべてのコードを表示

[例]
h
h counter"
end

function h --description 自作コマンドのヘルプを表示
    argparse h/help a/all -- $argv
    or return

    if set -q _flag_help
        h_help
        return 0
    end

    set -l known_commands ccc clip counter flatten gish h killer open repeat

    set -l custom_commands
    for cmd in $known_commands
        if functions -q $cmd
            set -l description (functions -Dv $cmd)
            if test -n "$description"
                set -a custom_commands $cmd
            end
        end
    end

    set -l target_command
    if test (count $argv) -eq 1
        set target_command $argv[1]
    else if test (count $argv) -eq 0
        echo "
    🛠️ コマンド一覧
    "
        for cmd in $custom_commands
            echo "    $cmd"
        end

        echo
        read -l -P "ヘルプを表示するコマンドを入力 > " cmd_input

        if test -n "$cmd_input"
            set target_command $cmd_input
        else
            echo "ℹ️ 操作をキャンセルしました"
            return 0
        end
    else
        set_color red
        echo "⛔ コマンド名を入力してください"
        set_color normal
        return 1
    end

    if not contains $target_command $custom_commands
        set_color red
        echo "⛔ 選択されたコマンドは存在しません"
        set_color normal
        return 1
    end

    set -l help_command "$target_command"_help
    set -l has_help (functions -v $help_command)
    set -l description (functions -Dv $target_command)

    if set -q _flag_all
        functions $target_command
    else
        if test -n "$has_help"
            echo
            $help_command
        else
            set_color yellow
            echo "⚠️ ヘルプがありません"
            set_color normal
        end
    end
end
