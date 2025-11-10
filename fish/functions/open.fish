function open_help
    echo "🔗 open - ファイル・ディレクトリ・URL オープンツール

[使用方法]
open [対象 | オプション]

[説明]
指定されたファイル、ディレクトリ、またはURLをWindows側のデフォルトアプリケーションで開きます。
複数の項目を同時に開くことも可能です。

[オプション]
-h, --help        このヘルプを表示
-d, --directory   ディレクトリとして強制的に開く
-f, --fast        高速モード（ディレクトリはexplorer.exe優先）
-s, --slow        互換モード（常にwslview使用）
-v, --verbose     詳細な実行情報を表示

[例]
open file.txt
open image.jpg document.pdf
open .
open -f ~/Documents
open -s file.html
open https://github.com
open -d file.txt
open -v file.html"
end

function open -d "ファイル・ディレクトリ・URLをWindows側で開く"
    argparse h/help d/directory f/fast s/slow v/verbose -- $argv
    or return

    if set -q _flag_help
        open_help
        return 0
    end

    if test (count $argv) -eq 0
        set argv "."
    end

    set -l verbose false
    if set -q _flag_verbose
        set verbose true
    end

    set -l force_directory false
    if set -q _flag_directory
        set force_directory true
    end

    set -l fast_mode false
    set -l slow_mode false
    if set -q _flag_fast
        set fast_mode true
    end
    if set -q _flag_slow
        set slow_mode true
    end

    if test "$fast_mode" = false -a "$slow_mode" = false
        set fast_mode true
    end

    set -l use_wslview false
    set -l use_explorer false
    set -l use_cmd false
    set -l selection_reason ""

    if test "$slow_mode" = true
        if command -v wslview >/dev/null
            set use_wslview true
            set selection_reason "互換モード（wslview優先）"
        else if command -v explorer.exe >/dev/null
            set use_explorer true
            set selection_reason "互換モード（wslview未検出、explorer.exe使用）"
        else
            set use_cmd true
            set selection_reason "互換モード（フォールバック、cmd.exe使用）"
        end
    else
        if command -v explorer.exe >/dev/null -a command -v wslview >/dev/null
            set use_explorer true
            set use_wslview true
            set selection_reason "高速モード（用途別最適化）"
        else if command -v wslview >/dev/null
            set use_wslview true
            set selection_reason "高速モード（wslviewのみ利用可能）"
        else if command -v explorer.exe >/dev/null
            set use_explorer true
            set selection_reason "高速モード（explorer.exeのみ利用可能）"
        else
            set use_cmd true
            set selection_reason "高速モード（フォールバック、cmd.exe使用）"
        end
    end

    if test "$verbose" = true
        echo "⚙️ $selection_reason を選択しました"
    end

    set -l success_count 0
    set -l skip_count 0

    for target in $argv
        set -l is_url false
        if string match -qr '^https?://' -- $target
            set is_url true
        end

        if test "$force_directory" = true -a "$is_url" = false
            if test -f $target
                set target (dirname $target)
            end
        end

        if test "$is_url" = false
            if not test -e $target
                set_color yellow
                echo "⚠️ $target は存在しないためスキップします"
                set_color normal
                set skip_count (math $skip_count + 1)
                continue
            end
        end

        if test "$verbose" = true
            if test "$is_url" = true
                echo "⚙️ $target というURLを開いています"
            else if test -d $target
                echo "⚙️ $target というディレクトリを開いています"
            else
                echo "⚙️ $target というファイルを開いています"
            end
        end

        set -l command_success false
        set -l exit_code 0
        set -l used_command ""

        if test "$fast_mode" = true -a "$use_explorer" = true -a "$use_wslview" = true
            if test "$is_url" = false -a -d "$target"
                set use_wslview false
                set used_command "explorer.exe (ディレクトリ最適化)"
            else if test "$is_url" = true
                set use_explorer false
                set used_command "wslview (URL最適化)"
            else
                set use_explorer false
                set used_command "wslview (ファイル最適化)"
            end
        end

        if test "$use_wslview" = true
            set used_command (test -n "$used_command" && echo "$used_command" || echo "wslview")
            if test "$verbose" = true
                wslview "$target"
                set exit_code $status
            else
                wslview "$target" >/dev/null 2>&1
                set exit_code $status
            end

            if test $exit_code -le 2
                set command_success true
            end
        else if test "$use_explorer" = true
            if test "$is_url" = true
                set used_command "cmd.exe (URL対応)"
                if test "$verbose" = true
                    cmd.exe /c start "$target"
                    set exit_code $status
                else
                    cmd.exe /c start "$target" >/dev/null 2>&1
                    set exit_code $status
                end
                if test $exit_code -le 2
                    set command_success true
                end
            else
                set used_command (test -n "$used_command" && echo "$used_command" || echo "explorer.exe")
                set -l windows_path (wslpath -w "$target" 2>/dev/null)
                if test $status -eq 0
                    if test "$verbose" = true
                        explorer.exe "$windows_path"
                        set exit_code $status
                    else
                        explorer.exe "$windows_path" >/dev/null 2>&1
                        set exit_code $status
                    end
                    if test $exit_code -le 1
                        set command_success true
                    end
                end
            end
        else if test "$use_cmd" = true
            set used_command "cmd.exe"
            if test "$is_url" = false
                set -l windows_path (wslpath -w "$target" 2>/dev/null)
                if test $status -eq 0
                    set target "$windows_path"
                end
            end

            if test "$verbose" = true
                cmd.exe /c start "$target"
                set exit_code $status
            else
                cmd.exe /c start "$target" >/dev/null 2>&1
                set exit_code $status
            end

            if test $exit_code -le 2
                set command_success true
            end
        end

        if test "$verbose" = true
            echo "⚙️ $used_command を使用しました"
            echo "⚙️ 終了コードは $exit_code でした"
        end
    end

    return 0
end
