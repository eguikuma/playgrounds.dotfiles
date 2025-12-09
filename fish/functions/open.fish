function open_help
    echo "🔗 open - ファイル・ディレクトリ・URL オープンツール

[使用方法]
open [対象 | オプション]

[説明]
指定されたファイル、ディレクトリ、またはURLをWindows側のデフォルトアプリケーションで開きます。
複数の項目を同時に開くことも可能です。

[オプション]
-h, --help        このヘルプを表示
-b, --browser     ブラウザで開く（ファイルのみ有効）
-d, --directory   ディレクトリとして強制的に開く
-v, --verbose     詳細な実行情報を表示

[例]
open file.txt
open image.jpg document.pdf
open .
open ~/Documents
open https://github.com
open -d file.txt
open -v file.html
open -b README.md

[環境変数]
BROWSER_CMD    -b オプションで使用するブラウザ"
end

function open -d "ファイル・ディレクトリ・URLをWindows側で開く"
    argparse h/help b/browser d/directory v/verbose -- $argv
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

    set -l force_browser false
    if set -q _flag_browser
        set force_browser true

        # 許可リスト
        set -l allowed_browsers chrome

        # BROWSER_CMD が未設定の場合
        if not set -q BROWSER_CMD; or test -z "$BROWSER_CMD"
            set_color red
            echo "⛔ BROWSER_CMD 環境変数が設定されていません" >&2
            set_color normal
            return 1
        end

        # 許可リストに含まれているか確認
        if not contains $BROWSER_CMD $allowed_browsers
            set_color red
            echo "⛔ BROWSER_CMD に無効な値が設定されています：$BROWSER_CMD" >&2
            echo "⛔ 許可されている値：$allowed_browsers" >&2
            set_color normal
            return 1
        end
    end

    # コマンドの利用可否を確認
    set -l use_explorer false
    set -l use_cmd false

    if command -v explorer.exe >/dev/null
        set use_explorer true
    else
        set use_cmd true
    end

    if test "$verbose" = true
        if test "$use_explorer" = true
            echo "⚙️ explorer.exe を使用します"
        else
            echo "⚙️ cmd.exe を使用します（フォールバック）"
        end
    end

    for target in $argv
        set -l is_url false
        if string match -qr '^https?://' -- $target
            set is_url true
        end

        # -d オプション：ファイルが指定された場合は親ディレクトリを開く
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
                continue
            end
        end

        # -b オプション：ディレクトリには適用できない
        set -l open_in_browser false
        if test "$force_browser" = true -a "$is_url" = false
            if test -d $target
                set_color yellow
                echo "⚠️ ディレクトリには -b オプションは適用できません: $target"
                set_color normal
            else
                set open_in_browser true
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

        set -l exit_code 0
        set -l used_command ""

        if test "$use_explorer" = true
            # URL または -b オプション指定のファイルは適切な方法で開く
            if test "$is_url" = true -o "$open_in_browser" = true
                if test "$is_url" = true
                    # URLは cmd.exe start で開く（デフォルトブラウザ）
                    set used_command "cmd.exe start"
                    if test "$verbose" = true
                        cmd.exe /c start "" "$target" 2>/dev/null
                        set exit_code $status
                    else
                        cmd.exe /c start "" "$target" >/dev/null 2>&1
                        set exit_code $status
                    end
                else
                    # -b オプション：PowerShell経由でブラウザを直接起動
                    set used_command "powershell.exe Start-Process $BROWSER_CMD"
                    set -l windows_path (wslpath -w "$target" 2>/dev/null)
                    if test $status -ne 0
                        set_color yellow
                        echo "⚠️ パス変換に失敗しました: $target"
                        set_color normal
                        continue
                    end
                    # バックスラッシュをスラッシュに変換して file:/// URL を作成
                    set -l file_url "file:///"(string replace -a '\\' '/' "$windows_path")
                    if test "$verbose" = true
                        powershell.exe Start-Process "$BROWSER_CMD" -ArgumentList "'$file_url'" 2>/dev/null
                        set exit_code $status
                    else
                        powershell.exe Start-Process "$BROWSER_CMD" -ArgumentList "'$file_url'" >/dev/null 2>&1
                        set exit_code $status
                    end
                end
            else
                # ファイル・ディレクトリは Windows パスに変換して explorer.exe で開く
                set used_command "explorer.exe"
                set -l windows_path (wslpath -w "$target" 2>/dev/null)
                if test $status -eq 0
                    if test "$verbose" = true
                        explorer.exe "$windows_path"
                        set exit_code $status
                    else
                        explorer.exe "$windows_path" >/dev/null 2>&1
                        set exit_code $status
                    end
                end
            end
        else if test "$use_cmd" = true
            # cmd.exe をフォールバックとして使用
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
        end

        if test "$verbose" = true
            echo "⚙️ $used_command を使用しました"
            echo "⚙️ 終了コードは $exit_code でした"
        end
    end

    return 0
end
