function counter_help
    echo "📊 counter - ファイル行数・サイズカウントツール

[使用方法]
counter [対象 | オプション]

[説明]
指定されたファイルまたはディレクトリ内のファイルの行数とサイズをカウントします。
※ デフォルトで隠しファイルおよび隠しディレクトリは除外されます。
※ デフォルトで.gitignoreに記載されたパターンは除外されます。

[オプション]
-h, --help        このヘルプを表示
-a, --all         .gitignoreを無視して全ファイルを対象
-d, --dir DIR     スキャンするディレクトリ（デフォルト：カレント）
-i, --include PAT 含めるパターン（カンマ区切りで複数指定可能）
                  ファイル名またはパスの一部にマッチ
                  例：-i \"*.ts\" または -i \"*.ts,*.tsx\"
-e, --exclude PAT 除外するパターン（カンマ区切りで複数指定可能）
                  例：-e \"node_modules,dist\"
-f, --format FMT  出力フォーマット
	- simple：合計のみ表示
	- detail：全ファイルの詳細を表示（デフォルト）
	- tree：ツリー構造で表示
-n, --number NUM  カウントするファイル数を制限（デフォルト：制限なし）
-s, --sort TYPE   ソート方式を指定
	- size：ファイルサイズ順（降順）
	- lines：行数順（降順）
	- name：ファイル名順（昇順、デフォルト）

[例]
counter some_dir
counter file1.ts file2.ts
counter -d ./src -i \"*.ts\"
counter -d ./src -e \"node_modules,dist\"
counter src -f tree
counter -n 10 -s size
counter src -a"
end

function counter -d ファイル行数とサイズをカウントする
    argparse h/help a/all 'd/dir=' 'i/include=' 'e/exclude=' 'f/format=' 'n/number=' 's/sort=' -- $argv
    or return

    if set -q _flag_help
        counter_help
        return 0
    end

    function __format_size
        set -l size $argv[1]

        if test $size -lt 1024
            echo "$size B"
        else if test $size -lt 1048576
            set -l kb_size (math "round($size / 1024 * 10) / 10")
            echo "$kb_size KB"
        else if test $size -lt 1073741824
            set -l mb_size (math "round($size / 1048576 * 10) / 10")
            echo "$mb_size MB"
        else
            set -l gb_size (math "round($size / 1073741824 * 100) / 100")
            echo "$gb_size GB"
        end
    end

    set -l target_paths
    set -l include_patterns
    set -l exclude_patterns
    set -l format detail
    set -l max_files 0
    set -l sort_type name

    set -l ignore_gitignore false
    if set -q _flag_all
        set ignore_gitignore true
    end

    if set -q _flag_dir
        set -a target_paths $_flag_dir
    end

    if set -q _flag_include
        set include_patterns (string split "," $_flag_include)
    end

    if set -q _flag_exclude
        set exclude_patterns (string split "," $_flag_exclude)
    end

    if set -q _flag_format
        switch $_flag_format
            case simple detail tree
                set format $_flag_format
            case '*'
                set_color red
                echo "⛔ 指定されたフォーマット方式は存在しません" >&2
                set_color normal
                return 1
        end
    end

    if set -q _flag_number
        if not string match -qr '^[0-9]+$' -- $_flag_number
            set_color red
            echo "⛔ カウント数には正の整数を指定してください" >&2
            set_color normal
            return 1
        end
        set max_files $_flag_number
    end

    if set -q _flag_sort
        switch $_flag_sort
            case size lines name
                set sort_type $_flag_sort
            case '*'
                set_color red
                echo "⛔ 指定されたソート方式は存在しません" >&2
                set_color normal
                return 1
        end
    end

    for arg in $argv
        switch $arg
            case '-*'
                continue
            case '*'
                set -a target_paths $arg
        end
    end

    if test (count $target_paths) -eq 0
        set target_paths "."
    end

    # 検索処理
    set_color cyan
    echo "⚙️️ ファイルを検索しています"
    set_color normal

    set -l all_files
    set -l current_dir (pwd)

    for target in $target_paths
        # 末尾のスラッシュを除去
        set target (string replace -r '/$' '' $target)

        if test -f $target
            set -a all_files (realpath $target 2>/dev/null; or echo $target)
        else if test -d $target
            # ディレクトリの絶対パスを取得（cdするとfishでは親シェルも移動するためrealpathを使用）
            set -l abs_target_dir (realpath $target)

            # Gitリポジトリかどうかを確認
            set -l is_git_repo false
            set -l git_root ""
            if git -C $target rev-parse --git-dir >/dev/null 2>&1
                set is_git_repo true
                set git_root (git -C $target rev-parse --show-toplevel 2>/dev/null)
            end

            if test "$ignore_gitignore" = true
                # --all オプション: .gitignoreを無視
                if command -v fd >/dev/null 2>&1
                    set -a all_files (command fd --type f --no-ignore . $target 2>/dev/null)
                else
                    set -a all_files (command find $target -type f -not -path '*/.*' 2>/dev/null)
                end
            else
                # デフォルト: .gitignoreを尊重
                if test "$is_git_repo" = true
                    # git_rootからの相対パスを計算
                    set -l relative_input (string replace "$git_root/" "" $abs_target_dir)
                    if test "$relative_input" = "$abs_target_dir"
                        set relative_input ""
                    end

                    # git ls-files実行
                    set -l git_files
                    if test -z "$relative_input"
                        set git_files (git -C $git_root ls-files --cached --others --exclude-standard 2>/dev/null)
                    else
                        set git_files (git -C $git_root ls-files --cached --others --exclude-standard "$relative_input/" 2>/dev/null)
                    end

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
                else if command -v fd >/dev/null 2>&1
                    set -a all_files (command fd --type f . $target 2>/dev/null)
                else
                    set_color yellow >&2
                    echo "⚠️ .gitignoreの尊重にはfdまたはGitリポジトリが必要です" >&2
                    set_color normal >&2
                    set -a all_files (command find $target -type f -not -path '*/.*' 2>/dev/null)
                end
            end
        else
            set_color red
            echo "⛔ $target は存在しません" >&2
            set_color normal
        end
    end

    # -i で指定された具体的なファイル名を直接追加
    if test (count $target_paths) -gt 0
        set -l base_dir $target_paths[1]
        set base_dir (string replace -r '/$' '' $base_dir)
        if not test -d $base_dir
            set base_dir "."
        end
        set -l abs_base_dir (realpath $base_dir)

        for pattern in $include_patterns
            if not string match -q '*\**' $pattern; and not string match -q '*\?*' $pattern
                set -l target_file "$abs_base_dir/$pattern"
                if test -f "$target_file"
                    if not contains $target_file $all_files
                        set -a all_files $target_file
                    end
                end
            end
        end
    end

    # 重複除去・空エントリ除去・ソート
    set all_files (printf "%s\n" $all_files | string match -v '' | sort -u)

    if test (count $all_files) -eq 0
        set_color red
        echo "⛔ 指定されたファイルは存在しません" >&2
        set_color normal
        return 1
    end

    # フィルタリング処理
    set_color cyan
    echo "⚙️️ フィルタリングしています"
    set_color normal

    set -l files
    for file in $all_files
        if test -z "$file"
            continue
        end

        set -l basename (basename $file)

        # 含めるパターンチェック（指定がある場合のみ）
        if test (count $include_patterns) -gt 0
            set -l included false
            for pattern in $include_patterns
                if string match -q $pattern $basename
                    set included true
                    break
                end
                if not string match -q '\**' $pattern
                    if string match -q "*$pattern*" $file
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
                if string match -q "*$pattern*" $file
                    set excluded true
                    break
                end
            end
        end

        if test "$excluded" = false
            set -a files $file
        end
    end

    if test (count $files) -eq 0
        set_color red
        echo "⛔ 指定されたパターンに一致するファイルは見つかりません" >&2
        set_color normal
        return 1
    end

    set -l total_file_count (count $files)

    # 解析処理
    set_color cyan
    echo "⚙️️ ファイルを解析しています"
    set_color normal

    set -l file_info_list
    set -l processed_count 0
    set -l progress_interval 100

    if test $total_file_count -gt 1000
        set progress_interval 500
    else if test $total_file_count -gt 100
        set progress_interval 50
    else
        set progress_interval 25
    end

    for file in $files
        if test -z "$file"
            continue
        end

        set -l lines (wc -l < "$file" 2>/dev/null; or echo 0)
        set -l size (stat -c%s "$file" 2>/dev/null; or echo 0)
        set -a file_info_list "$file:$lines:$size"

        set processed_count (math $processed_count + 1)

        if test (math $processed_count % $progress_interval) -eq 0
            set -l percentage (math "round($processed_count * 100 / $total_file_count)")
            printf "\r%d/%d (%d%%) " $processed_count $total_file_count $percentage
        end
    end

    if test $total_file_count -gt $progress_interval
        printf "\r%50s\r" " "
    end

    # ソート処理
    set_color cyan
    echo "⚙️️ ファイルをソートしています"
    set_color normal

    switch $sort_type
        case size
            set file_info_list (printf "%s\n" $file_info_list | sort -t: -k3 -nr)
        case lines
            set file_info_list (printf "%s\n" $file_info_list | sort -t: -k2 -nr)
        case name
            set file_info_list (printf "%s\n" $file_info_list | sort -t: -k1)
    end

    if test $max_files -gt 0
        set file_info_list (printf "%s\n" $file_info_list | head -n $max_files)
    end

    echo

    switch $format
        case simple
            set -l total_lines 0
            set -l total_size 0
            set -l file_count 0
            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l lines $parts[2]
                set -l size $parts[3]
                set total_lines (math $total_lines + $lines)
                set total_size (math $total_size + $size)
                set file_count (math $file_count + 1)
            end

            set -l formatted_total_size (__format_size $total_size)

            echo "ℹ️ $file_count ファイルです"
            echo "ℹ️ $total_lines 行です"
            echo "ℹ️ $formatted_total_size です"

        case detail
            set -l max_length 0
            set -l total_lines 0
            set -l total_size 0
            set -l file_count 0

            # 相対パスの最大長を計算
            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l file $parts[1]
                # 絶対パスを相対パスに変換
                set -l display_path (string replace "$current_dir/" "" $file)
                set -l length (string length -- $display_path)
                set max_length (math "max($max_length, $length)")
            end
            set max_length (math $max_length + 3)

            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l file $parts[1]
                set -l lines $parts[2]
                set -l size $parts[3]
                set -l formatted_size (__format_size $size)
                set total_lines (math $total_lines + $lines)
                set total_size (math $total_size + $size)
                set file_count (math $file_count + 1)

                # 絶対パスを相対パスに変換して表示
                set -l display_path (string replace "$current_dir/" "" $file)
                printf " %s" $display_path

                set -l padding (math $max_length - (string length -- $display_path))
                printf "%"$padding"s" " "

                printf "│ "
                set_color green
                printf "%d行" $lines
                printf "(%s)\n" $formatted_size
                set_color normal
            end

            set -l formatted_total_size (__format_size $total_size)

            echo
            echo "ℹ️ $file_count ファイルです"
            echo "ℹ️ $total_lines 行です"
            echo "ℹ️ $formatted_total_size です"

        case tree
            function __print_tree
                set -l path $argv[1]
                set -l prefix $argv[2]
                set -l is_last $argv[3]
                set -l lines $argv[4]
                set -l formatted_size $argv[5]

                set -l basename (basename $path)
                if test $is_last = true
                    printf "%s└── " $prefix
                else
                    printf "%s├── " $prefix
                end

                set_color normal
                printf "%s " $basename

                set_color green
                printf "(%d行" $lines
                printf ", "
                printf "%s)\n" $formatted_size
                set_color normal
            end

            set -l total_lines 0
            set -l total_size 0
            set -l file_count 0
            set -l prev_dir ""

            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l file $parts[1]
                set -l lines $parts[2]
                set -l size $parts[3]
                set -l formatted_size (__format_size $size)
                set total_lines (math $total_lines + $lines)
                set total_size (math $total_size + $size)
                set file_count (math $file_count + 1)

                # 絶対パスを相対パスに変換
                set -l display_path (string replace "$current_dir/" "" $file)
                set -l dir (dirname $display_path)
                set -l depth (string replace -r '^\./' '' $dir | string split '/' | count)
                set -l prefix "    "
                if test $depth -gt 1
                    set prefix (string repeat --count (math $depth - 1) "    ")
                end

                if test $dir != $prev_dir
                    echo "  $dir/"
                end

                if test $depth -eq 1
                    set prefix "    "
                end

                set -l is_last true
                set -l current_index 0
                for info_check in $file_info_list
                    set current_index (math $current_index + 1)
                    if test "$info_check" = "$info"
                        break
                    end
                end

                if test $current_index -lt (count $file_info_list)
                    set -l next_info $file_info_list[(math $current_index + 1)]
                    set -l next_parts (string split ":" $next_info)
                    set -l next_file $next_parts[1]
                    set -l next_display_path (string replace "$current_dir/" "" $next_file)
                    if test (dirname $next_display_path) = $dir
                        set is_last false
                    end
                end

                __print_tree $display_path $prefix $is_last $lines $formatted_size
                set prev_dir $dir
            end

            set -l formatted_total_size (__format_size $total_size)

            echo
            echo "ℹ️ $file_count ファイルです"
            echo "ℹ️ $total_lines 行です"
            echo "ℹ️ $formatted_total_size です"
    end

    functions -e __print_tree
    functions -e __format_size
end
