function flatten_help
    echo "📦 flatten - ディレクトリ構造をフラット化してコピー

[使用方法]
flatten [入力ディレクトリ:REQUIRED] [オプション]

[説明]
ディレクトリ配下のファイルを、階層構造を反映したフラットなファイル名へ変換してコピーします。
※ デフォルトで隠しファイルおよび隠しディレクトリは除外されます。
※ デフォルトで.gitignoreに記載されたパターンは除外されます。

[オプション]
-h, --help            このヘルプを表示
-a, --all             .gitignoreを無視して全ファイルを対象
-i, --include PAT     含めるパターン（カンマ区切りで複数指定可能）
                      ファイル名またはパスの一部にマッチ
                      例：-i \"*.ts\"  または  -i \"*.ts,*.tsx\"
-e, --exclude PAT     除外するパターン（カンマ区切りで複数指定可能）
                      ファイル名またはパスの一部にマッチ
                      例：-e \"*.test.ts,*.spec.ts\" / -e node_modules
-o, --output DIR      出力先ディレクトリ（デフォルト：flatten）
-z, --zip             ZIP形式で出力
-v, --verbose         詳細な実行情報を表示

[例]
flatten src
flatten src -i \"*.ts\"
flatten src -i \"*.ts,*.tsx\" -e \"*.test.ts,*.spec.ts\"
flatten src -e node_modules
flatten src -o my-output
flatten src -z
flatten src -a
flatten src -i \"*.ts\" -e \"*.test.ts\" -o output -v"
end

function flatten -d ディレクトリ構造をフラット化してコピー
    argparse h/help a/all 'i/include=' 'e/exclude=' 'o/output=' z/zip v/verbose -- $argv
    or return

    if set -q _flag_help
        flatten_help
        return 0
    end

    # 入力ディレクトリのバリデーション
    if test (count $argv) -eq 0
        flatten_help
        return 1
    end

    set -l input_dir $argv[1]

    if not test -d $input_dir
        set_color red
        echo "⛔ $input_dir は存在しません" >&2
        set_color normal
        return 1
    end

    # 入力ディレクトリのパスを正規化（./ や 末尾の / を除去）
    set input_dir (string replace -r '^\./' '' $input_dir)
    set input_dir (string replace -r '/$' '' $input_dir)
    if test -z "$input_dir"
        set input_dir "."
    end

    # 入力ディレクトリの絶対パスを保存（cdするとfishでは親シェルも移動するためrealpathを使用）
    set -l abs_input_dir (realpath $input_dir)

    # オプションの設定
    set -l include_patterns
    if set -q _flag_include
        set include_patterns (string split "," $_flag_include)
    end

    set -l exclude_patterns
    if set -q _flag_exclude
        set exclude_patterns (string split "," $_flag_exclude)
    end

    set -l output_dir flatten
    if set -q _flag_output
        set output_dir $_flag_output
    end

    set -l zip_mode false
    if set -q _flag_zip
        set zip_mode true
        # zipコマンドの存在確認
        if not command -v zip >/dev/null
            set_color red
            echo "⛔ zipコマンドが見つかりません" >&2
            set_color normal
            return 1
        end
    end

    set -l verbose false
    if set -q _flag_verbose
        set verbose true
    end

    set -l ignore_gitignore false
    if set -q _flag_all
        set ignore_gitignore true
    end

    # 出力ディレクトリの準備
    if test -d $output_dir
        if test "$verbose" = true
            set_color cyan
            echo "⚙️️ 出力ディレクトリを削除しています"
            set_color normal
        end
        rm -rf $output_dir
    end
    mkdir -p $output_dir

    if test "$verbose" = true
        echo "⚙️️ $input_dir を $output_dir にコピーします"
        echo "⚙️️ $include_patterns を含めます"
        echo "⚙️️ $exclude_patterns を除外します"
        if test "$ignore_gitignore" = true
            echo "⚙️️ .gitignoreを無視します"
        else
            echo "⚙️️ .gitignoreを尊重します"
        end
        if test "$zip_mode" = true
            echo "⚙️️ ZIP出力は有効です"
        else
            echo "⚙️️ ZIP出力は無効です"
        end
    end

    # 検索処理
    set_color cyan
    echo "⚙️️ ファイルを検索しています"
    set_color normal

    set -l all_files
    set -l search_method ""

    # Gitリポジトリかどうかを確認
    set -l is_git_repo false
    set -l git_root ""
    if git -C $input_dir rev-parse --git-dir >/dev/null 2>&1
        set is_git_repo true
        set git_root (git -C $input_dir rev-parse --show-toplevel 2>/dev/null)
    end

    if test "$ignore_gitignore" = true
        # --all オプション: .gitignoreを無視（隠しファイルは引き続き除外）
        if command -v fd >/dev/null 2>&1
            set search_method "fd --no-ignore"
            # fdの結果を絶対パスに変換
            for f in (command fd --type f --no-ignore . $input_dir 2>/dev/null | sort)
                set -a all_files (realpath "$f" 2>/dev/null)
            end
        else
            set search_method find
            # findの結果を絶対パスに変換
            for f in (command find $input_dir -type f -not -path '*/.*' 2>/dev/null | sort)
                set -a all_files (realpath "$f" 2>/dev/null)
            end
        end
    else
        # デフォルト: .gitignoreを尊重
        if test "$is_git_repo" = true
            set search_method "git ls-files"

            # git_rootからの相対パスを計算
            set -l relative_input (string replace "$git_root/" "" $abs_input_dir)
            if test "$relative_input" = "$abs_input_dir"
                set relative_input ""
            end

            # git ls-files実行
            set -l git_files
            if test -z "$relative_input"
                set git_files (git -C $git_root ls-files --cached --others --exclude-standard 2>/dev/null)
            else
                set git_files (git -C $git_root ls-files --cached --others --exclude-standard "$relative_input/" 2>/dev/null)
            end

            # ファイルをフィルタリング
            for f in $git_files
                if test -z "$f"
                    continue
                end

                # 隠しファイル/ディレクトリをスキップ
                if string match -q '*/.*' "/$f"; or string match -q '.*' $f
                    continue
                end

                set -l full_path "$git_root/$f"
                if test -f "$full_path"
                    set -a all_files $full_path
                end
            end
            set all_files (printf "%s\n" $all_files | sort)
        else if command -v fd >/dev/null 2>&1
            set search_method fd
            set all_files (command fd --type f . $input_dir 2>/dev/null | sort)
        else
            set search_method "find (フォールバック)"
            set_color yellow >&2
            echo "⚠️ .gitignoreの尊重にはfdまたはGitリポジトリが必要です" >&2
            set_color normal >&2
            set all_files (command find $input_dir -type f -not -path '*/.*' 2>/dev/null | sort)
        end
    end

    if test "$verbose" = true
        echo "⚙️️ $search_method を使用しました"
    end

    # -i で指定された具体的なファイル名を直接追加（.gitignore関係なく）
    set -l current_dir (pwd)
    for pattern in $include_patterns
        # ワイルドカードを含まない場合（具体的なファイル名）
        if not string match -q '*\**' $pattern; and not string match -q '*\?*' $pattern
            set -l target_file
            if test "$input_dir" = "."
                set target_file "$current_dir/$pattern"
            else
                set target_file "$abs_input_dir/$pattern"
            end
            # ファイルが存在し、まだリストに含まれていなければ追加
            if test -f "$target_file"
                if not contains $target_file $all_files
                    set -a all_files $target_file
                    if test "$verbose" = true
                        echo "⚙️️ $target_file を追加しました"
                    end
                end
            end
        end
    end

    # 空エントリを除外
    set all_files (string match -v '' $all_files)

    if test (count $all_files) -eq 0
        set_color red
        echo "⛔ 指定されたディレクトリ内にファイルは見つかりません" >&2
        set_color normal
        return 1
    end

    # フィルタリング処理
    set_color cyan
    echo "⚙️️ フィルタリングしています"
    set_color normal

    set -l target_files

    for file in $all_files
        if test -z "$file"
            continue
        end

        set -l basename (basename $file)

        # input_dirからの相対パスを計算
        set -l relative_path_check (string replace "$abs_input_dir/" "" $file)
        if test "$relative_path_check" = "$file"
            set relative_path_check (string replace "$current_dir/" "" $file)
        end

        # 含めるパターンチェック（指定がある場合のみ）
        if test (count $include_patterns) -gt 0
            set -l included false
            for pattern in $include_patterns
                # ファイル名でマッチ
                if string match -q $pattern $basename
                    set included true
                    break
                end
                # パターンが * で始まらない場合のみパス全体でマッチ
                if not string match -q '\**' $pattern
                    if string match -q "*$pattern*" $relative_path_check
                        set included true
                        break
                    end
                end
            end
            if test "$included" = false
                continue
            end
        end

        # 除外パターンチェック
        set -l excluded false
        for pattern in $exclude_patterns
            if string match -q $pattern $basename
                set excluded true
                break
            end
            if not string match -q '\**' $pattern
                if string match -q "*$pattern*" $relative_path_check
                    set excluded true
                    break
                end
            end
        end

        if test "$excluded" = false
            set -a target_files $file
        end
    end

    if test (count $target_files) -eq 0
        set_color red
        echo "⛔ 指定されたパターンに一致するファイルは見つかりません" >&2
        set_color normal
        return 1
    end

    if test "$verbose" = true
        set count (count $target_files)
        echo "⚙️️ $count ファイルを検出しました"
    end

    # フラット化処理
    set_color cyan
    echo "⚙️️ フラット化しています"
    set_color normal

    set -l success_count 0
    set -l skip_count 0
    set -l tree_entries

    for file in $target_files
        # input_dirからの相対パスを取得
        set -l relative_path (string replace "$abs_input_dir/" "" $file)
        if test "$relative_path" = "$file"
            set relative_path (string replace "$current_dir/" "" $file)
        end

        # フラットなファイル名に変換（/ を . に）
        set -l flat_name
        if test "$input_dir" = "."
            set flat_name (string replace -a "/" "." $relative_path)
        else
            set flat_name "$input_dir."(string replace -a "/" "." $relative_path)
        end

        # 先頭が . で始まる場合は除去
        set flat_name (string replace -r '^\.' '' $flat_name)

        set -l dest_path "$output_dir/$flat_name"

        # 衝突チェック
        if test -e $dest_path
            set_color yellow
            echo "⚠️ $dest_path は既に存在するためスキップします"
            set_color normal
            set skip_count (math $skip_count + 1)
            continue
        end

        # ファイルをコピー
        cp $file $dest_path

        if test $status -eq 0
            set success_count (math $success_count + 1)
            set -a tree_entries "$relative_path → $flat_name"

            if test "$verbose" = true
                echo "⚙️️ $relative_path → $flat_name"
            end
        else
            set_color red
            echo "⛔ $file のコピーに失敗しました" >&2
            set_color normal
        end
    end

    # ツリー構造ファイルの生成処理
    set_color cyan
    echo "⚙️️ ツリー構造を生成しています"
    set_color normal
    __flatten_generate_tree $input_dir $target_files $output_dir $abs_input_dir

    # ZIP生成処理
    if test "$zip_mode" = true
        set_color cyan
        echo "⚙️️ ZIP化しています"
        set_color normal

        set -l zip_name "$output_dir.zip"
        set -l current_dir (pwd)
        cd (dirname $output_dir)

        zip -rq $zip_name (basename $output_dir)
        set -l zip_status $status

        cd $current_dir

        if test $zip_status -eq 0
            set_color green
            echo " ✅ ZIP化に成功しました"
            set_color normal
        else
            set_color red
            echo "⛔ ZIP化に失敗しました" >&2
            set_color normal
        end
    end

    set_color green
    echo "✅ ディレクトリ構造のフラット化に成功しました"
    set_color normal

    echo "ℹ️ $success_count ファイルを出力しました"
    echo "ℹ️ $skip_count ファイルをスキップしました"
    echo "ℹ️ $output_dir に出力されました"

    return 0
end

function __flatten_generate_tree -d フラット化対象のツリー構造を生成
    set -l input_dir $argv[1]
    set -l target_files $argv[2..-3]
    set -l output_dir $argv[-2]
    set -l abs_input_dir $argv[-1]

    set -l tree_file "$output_dir/tree.txt"

    # ルートディレクトリ名を出力
    echo "$input_dir/" >>$tree_file

    # すべてのパス（ディレクトリ＋ファイル）を収集してソート
    set -l all_entries
    set -l current_dir (pwd)

    for file in $target_files
        set -l relative_path (string replace "$abs_input_dir/" "" $file)
        if test "$relative_path" = "$file"
            set relative_path (string replace "$current_dir/" "" $file)
        end

        # ディレクトリパスを分解して追加
        set -l parts (string split "/" $relative_path)
        set -l current_path ""
        for i in (seq (math (count $parts) - 1))
            if test -z "$current_path"
                set current_path $parts[$i]
            else
                set current_path "$current_path/$parts[$i]"
            end
            if not contains "$current_path/" $all_entries
                set -a all_entries "$current_path/"
            end
        end
        set -a all_entries $relative_path
    end

    # ソート
    set all_entries (printf "%s\n" $all_entries | sort)

    set -l printed_dirs
    set -l last_at_depth
    set -l entry_count (count $all_entries)

    for idx in (seq $entry_count)
        set -l entry $all_entries[$idx]

        set -l is_dir false
        if string match -q '*/' $entry
            set is_dir true
            set entry (string replace -r '/$' '' $entry)
        end

        set -l parts (string split "/" $entry)
        set -l depth (count $parts)
        set -l name $parts[-1]
        set -l parent_dir (dirname $entry)
        if test "$parent_dir" = "."
            set parent_dir ""
        end

        set -l is_last true
        for check_idx in (seq (math $idx + 1) $entry_count)
            set -l check_entry $all_entries[$check_idx]
            set -l check_clean (string replace -r '/$' '' $check_entry)
            set -l check_parent (dirname $check_clean)
            if test "$check_parent" = "."
                set check_parent ""
            end

            if test "$check_parent" = "$parent_dir"
                set is_last false
                break
            end
        end

        set last_at_depth[$depth] $is_last

        set -l indent ""
        for i in (seq (math $depth - 1))
            if test -n "$last_at_depth[$i]" -a "$last_at_depth[$i]" = true
                set indent "$indent    "
            else
                set indent "$indent│   "
            end
        end

        set -l prefix "├──"
        if test "$is_last" = true
            set prefix "└──"
        end

        if test "$is_dir" = true
            if not contains $entry $printed_dirs
                echo "$indent$prefix $name" >>$tree_file
                set -a printed_dirs $entry
            end
        else
            set -l flat_name
            if test "$input_dir" = "."
                set flat_name (string replace -a "/" "." $entry)
            else
                set flat_name "$input_dir."(string replace -a "/" "." $entry)
            end
            set flat_name (string replace -r '^\.' '' $flat_name)
            echo "$indent$prefix $name → $flat_name" >>$tree_file
        end
    end
end
