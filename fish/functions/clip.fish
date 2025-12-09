function clip_help
    echo "📋 clip - クリップボードにコピー

[使用方法]
clip [ファイルパス] [オプション]
[コマンド] | clip

[説明]
ファイル内容やコマンド出力をクリップボードにコピーします。
日本語や改行もそのまま保持されます。

[オプション]
-h, --help     このヘルプを表示

[例]
clip memo.txt
pwd | clip
echo \"hello\" | clip"
end

function clip -d クリップボードにコピー
    argparse h/help -- $argv
    or return

    if set -q _flag_help
        clip_help
        return 0
    end

    if not isatty stdin
        cat | fish_clipboard_copy
        if test $status -eq 0
            set_color green
            echo "✅ クリップボードへのコピーに成功しました"
            set_color normal
        else
            set_color red
            echo "⛔ クリップボードへのコピーに失敗しました" >&2
            set_color normal
            return 1
        end
        return 0
    end

    if test (count $argv) -ne 1
        clip_help
        return 1
    end

    set -l file_path $argv[1]

    if not test -f $file_path
        set_color red
        echo "⛔ $file_path は存在しません" >&2
        set_color normal
        return 1
    end

    command cat $file_path | fish_clipboard_copy

    if test $status -eq 0
        set_color green
        echo "✅ クリップボードへのコピーに成功しました"
        set_color normal
    else
        set_color red
        echo "⛔ クリップボードへのコピーに失敗しました" >&2
        set_color normal
        return 1
    end
end
