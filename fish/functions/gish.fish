function gish_help
    echo "🐟 gish - Gitユーティリティ

[使用方法]
gish [サブコマンド:REQUIRED] [オプション]

[説明]
Git操作を補助するためのユーティリティツールです。

[サブコマンド]
fix-commit          コミットの日時・作成者情報を修正
help                ヘルプを表示

[オプション]
-h, --help   このヘルプを表示

[例]
gish fix-commit -d
gish fix-commit -u
gish help fix-commit"
end

function _gish_fix_commit_help
    echo "🐟 gish fix-commit - コミット修正

[使用方法]
gish fix-commit [オプション]

[説明]
Gitコミットの日時や作成者情報を修正します。
コミットを指定しない場合は、派生元コミットを自動検出します。

[オプション]
-d, --date [<datetime>]   日時修正（引数なし=同期、引数あり=固定日時）
-u, --user                作成者情報の修正（対話式で選択）
-b, --base <ref>          比較元のブランチを指定（デフォルト：main/master）
-r, --root                指定したコミット自体も処理対象に含める
-y, --yes                 確認プロンプトをスキップ
-h, --help                このヘルプを表示

[日時形式]
-d オプションで指定可能な形式：
  2025-09-01                           年月日のみ
  2025-09-01 12:00:00                  年月日＋時刻
  'Mon Sep 01 12:00:00 2025 +0900'     Git形式（タイムゾーン付き）

[例]
gish fix-commit -d                 CommitterDateをAuthorDateに同期
gish fix-commit -d '2025-09-01'    指定日時に統一
gish fix-commit -u                 作成者情報を対話式で修正
gish fix-commit -d -u abc123       日時と作成者を同時に修正
gish fix-commit -r abc123          指定コミット自体も含めて修正
gish fix-commit -d -u -y           確認なしで日時・作成者を修正"
end

function gish -d Git修正ツール
    if test (count $argv) -eq 0
        gish_help
        return 0
    end

    set -l subcommand $argv[1]

    switch $subcommand
        case fix-commit
            set -l fix_commit_args $argv[2..-1]
            _gish_fix_commit $fix_commit_args
            return $status
        case help
            if test (count $argv) -eq 2 && test "$argv[2]" = fix-commit
                _gish_fix_commit_help
            else
                gish_help
            end
            return 0
        case -h --help
            gish_help
            return 0
        case '*'
            gish_help
            return 1
    end
end

function _gish_normalize_date
    set -l input_date $argv[1]

    if test -z "$input_date"
        env LC_TIME=C date "+%a %b %d %H:%M:%S %Y %z"
        return 0
    end

    if string match -qr '^[A-Z][a-z][a-z] [A-Z][a-z][a-z] [0-9]' $input_date
        echo $input_date
        return 0
    end

    if string match -qr '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}' $input_date
        if not string match -qr '[0-9]{2}:[0-9]{2}' $input_date
            set input_date "$input_date 00:00:00"
        end

        if not string match -qr '[+-][0-9]{4}' $input_date
            set -l tz (date "+%z")
            set input_date "$input_date $tz"
        end

        if set -l git_date (env LC_TIME=C date -d "$input_date" "+%a %b %d %H:%M:%S %Y %z" 2>/dev/null)
            echo $git_date
            return 0
        end
    end

    if set -l git_date (env LC_TIME=C date -d "$input_date" "+%a %b %d %H:%M:%S %Y %z" 2>/dev/null)
        echo $git_date
        return 0
    end

    set_color red >&2
    echo "⛔ 指定された日時形式は正しくありません" >&2
    set_color normal >&2
    return 1
end

function _gish_validate_git_repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        set_color red
        echo "⛔ カレントディレクトリはGitリポジトリではありません"
        set_color normal
        return 1
    end
    return 0
end

function _gish_validate_commit
    set -l commit $argv[1]
    if not git rev-parse --verify $commit >/dev/null 2>&1
        set_color red
        echo "⛔ 指定されたコミットは存在しません"
        set_color normal
        return 1
    end
    return 0
end

function _gish_find_default_branch
    if git show-ref --verify --quiet refs/heads/main
        echo main
    else if git show-ref --verify --quiet refs/heads/master
        echo master
    else
        return 1
    end
    return 0
end

function _gish_detect_base_commit
    set -l base_branch $argv[1]

    set -l commit_hash (git show-branch --sha1-name 2>/dev/null | command grep '*' | command grep -v (git rev-parse --abbrev-ref HEAD) | command grep '+' | head -1 | awk -F'[]~^[]' '{print $2}' 2>/dev/null)

    if test -z "$commit_hash"
        set commit_hash (git merge-base $base_branch (git rev-parse --abbrev-ref HEAD) 2>/dev/null)

        if test "$commit_hash" = (git rev-parse HEAD 2>/dev/null)
            set commit_hash (git rev-list --max-parents=0 HEAD 2>/dev/null)
        end
    end

    if test -n "$commit_hash"
        echo $commit_hash
        return 0
    end

    return 1
end

function _gish_fix_commit
    argparse h/help d/date u/user 'b/base=' r/root y/yes -- $argv
    or return 1

    if set -q _flag_help
        _gish_fix_commit_help
        return 0
    end

    set -l fix_commit_date false
    set -l date_str ""
    set -l fix_commit_user false
    set -l base_branch ""
    set -l include_root false
    set -l skip_confirm false
    set -l remaining_args

    if set -q _flag_date
        set fix_commit_date true
        # $argv の最初の要素が日付形式の場合、date_str として使用
        if test (count $argv) -ge 1
            set -l first_arg $argv[1]
            # "-" で始まらず、数字を含む場合は日付として扱う
            if not string match -q -- '-*' $first_arg
                if string match -qr '[0-9]' $first_arg
                    set date_str $first_arg
                    set argv $argv[2..-1]
                end
            end
        end
    end

    if set -q _flag_user
        set fix_commit_user true
    end

    if set -q _flag_base
        set base_branch $_flag_base
    end

    if set -q _flag_root
        set include_root true
    end

    if set -q _flag_yes
        set skip_confirm true
    end

    # 残りの引数をセット
    set remaining_args $argv

    _gish_validate_git_repo
    or return 1

    if test $fix_commit_date != true && test $fix_commit_user != true
        _gish_fix_commit_help
        return 1
    end

    set -l normalized_date ""
    if test $fix_commit_date = true && test -n "$date_str"
        set normalized_date (_gish_normalize_date "$date_str")
        if test $status -ne 0
            return 1
        end
    end

    if test -z "$base_branch"
        set base_branch (_gish_find_default_branch)
        if test $status -ne 0
            set_color red
            echo "⛔ mainもしくはmasterブランチが見つかりません"
            set_color normal
            return 1
        end
    end

    set -l target_commit
    if test (count $remaining_args) -ge 1
        set target_commit $remaining_args[1]
        _gish_validate_commit $target_commit
        or return 1
    else
        set target_commit (_gish_detect_base_commit $base_branch)
        if test $status -ne 0 || test -z "$target_commit"
            set_color red
            echo "⛔ 派生元コミットを検出できません"
            set_color normal
            return 1
        end
    end

    _gish_execute_fix_commit "$target_commit" $fix_commit_date "$normalized_date" $fix_commit_user $include_root $skip_confirm
    return $status
end

function _gish_collect_user_info
    set -l commit_range $argv[1]

    set -l authors (git log --format="%an|%ae" $commit_range 2>/dev/null | sort | uniq -c | sort -nr)
    set -l committers (git log --format="%cn|%ce" $commit_range 2>/dev/null | sort | uniq -c | sort -nr)

    set -l all_users
    for line in $authors
        set -l count (echo $line | awk '{print $1}')
        set -l user (echo $line | awk '{$1=""; print $0}' | string trim)
        set all_users $all_users "author:$count:$user"
    end

    for line in $committers
        set -l count (echo $line | awk '{print $1}')
        set -l user (echo $line | awk '{$1=""; print $0}' | string trim)
        if not contains "author:$count:$user" $all_users
            set all_users $all_users "committer:$count:$user"
        end
    end

    for user in $all_users
        echo $user
    end
end

function _gish_interactive_user_selection
    set -l commit_range $argv[1]

    echo "1) CommitterをAuthorに同期" >&2
    echo "2) 既存のユーザー情報" >&2
    echo "3) 新しいユーザー情報" >&2

    read -l -P "選択 (1-3) > " selection

    switch $selection
        case 1
            echo "mode:sync"
            return 0
        case 2
            set -l user_info (_gish_collect_user_info $commit_range)
            if test (count $user_info) -eq 0
                set_color red >&2
                echo "⛔ 範囲内にユーザー情報が見つかりません" >&2
                set_color normal >&2
                return 1
            end

            echo >&2
            set -l i 1
            for info in $user_info
                set -l count (echo $info | cut -d: -f2)
                set -l user (echo $info | cut -d: -f3)
                echo "$i) $user ($count commits)" >&2
                set i (math $i + 1)
            end

            set -l git_name (git config user.name 2>/dev/null)
            set -l git_email (git config user.email 2>/dev/null)
            set -l git_config_index -1
            if test -n "$git_name" && test -n "$git_email"
                set git_config_index $i
                echo "$i) [git config] $git_name <$git_email>" >&2
                set i (math $i + 1)
            end

            read -l -P "選択 (1-"(math $i - 1)") > " user_selection

            if not string match -qr '^[0-9]+$' -- $user_selection
                set_color red >&2
                echo "⛔ 選択された番号は存在しません" >&2
                set_color normal >&2
                return 1
            end

            if test $user_selection -le (count $user_info)
                set -l selected_info $user_info[$user_selection]
                set -l user (echo $selected_info | cut -d: -f3)
                set -l name (echo $user | cut -d'|' -f1)
                set -l email (echo $user | cut -d'|' -f2)
                echo "mode:existing"
                echo "name:$name"
                echo "email:$email"
            else if test $git_config_index -ne -1 && test $user_selection -eq $git_config_index
                echo "mode:existing"
                echo "name:$git_name"
                echo "email:$git_email"
            else
                set_color red >&2
                echo "⛔ 選択された番号は存在しません" >&2
                set_color normal >&2
                return 1
            end
            return 0
        case 3
            echo >&2
            read -l -P "名前 > " new_name
            read -l -P "メール > " new_email

            if test -z "$new_name" || test -z "$new_email"
                set_color red >&2
                echo "⛔ 名前またはメールアドレスが入力されていません" >&2
                set_color normal >&2
                return 1
            end

            echo "mode:new"
            echo "name:$new_name"
            echo "email:$new_email"
            return 0
        case '*'
            set_color red >&2
            echo "⛔ 選択された番号は存在しません" >&2
            set_color normal >&2
            return 1
    end
end

function _gish_select_target_user
    echo "1) Authorのみ" >&2
    echo "2) Committerのみ" >&2
    echo "3) AuthorとCommitter両方" >&2

    read -l -P "選択 (1-3) > " target_selection

    switch $target_selection
        case 1
            echo "target:author"
        case 2
            echo "target:committer"
        case 3
            echo "target:both"
        case '*'
            set_color red >&2
            echo "⛔ 選択された番号は存在しません" >&2
            set_color normal >&2
            return 1
    end
    return 0
end

function _gish_execute_fix_commit
    set -l target_commit $argv[1]
    set -l fix_commit_date $argv[2]
    set -l date_str $argv[3]
    set -l fix_commit_user $argv[4]
    set -l include_root $argv[5]
    set -l skip_confirm $argv[6]

    set -l commit_range
    if test $include_root = true
        set -l root_commit (git rev-list --max-parents=0 HEAD 2>/dev/null)
        if test "$target_commit" = "$root_commit"
            set commit_range HEAD
        else
            set commit_range "$target_commit^..HEAD"
        end
    else
        set commit_range "$target_commit..HEAD"
    end

    set -l user_mode ""
    set -l user_name ""
    set -l user_email ""
    set -l user_target ""

    if test $fix_commit_user = true
        set -l user_selection_result (_gish_interactive_user_selection $commit_range)
        if test $status -ne 0
            return 1
        end

        for line in $user_selection_result
            set -l key (echo $line | cut -d: -f1)
            set -l value (echo $line | cut -d: -f2-)

            switch $key
                case mode
                    set user_mode $value
                case name
                    set user_name $value
                case email
                    set user_email $value
            end
        end

        if test "$user_mode" != sync
            set -l target_result (_gish_select_target_user)
            if test $status -ne 0
                return 1
            end
            set user_target (echo $target_result | cut -d: -f2)
        end
    end

    set -l commit_short (git rev-parse --short $target_commit)
    set -l commit_subject (git show -s --format='%s' $target_commit)

    echo "┌──────────────────────────────────────────────────────────────────────
│ 開始コミット：$commit_short
│ メッセージ：$commit_subject"

    if test $include_root = true
        echo "│ 処理範囲：指定コミットから HEAD まで（コミット自体も含む）"
    else
        echo "│ 処理範囲：指定コミットの次から HEAD まで"
    end

    if test $fix_commit_date = true
        if test -n "$date_str"
            echo "│ 日時修正：固定日時 ($date_str) に設定"
        else
            echo "│ 日時修正：CommitterDateをAuthorDateに同期"
        end
    end

    if test $fix_commit_user = true
        switch $user_mode
            case sync
                echo "│ 作成者修正：CommitterをAuthorに統一"
            case existing new
                echo "│ 作成者修正：$user_name <$user_email>"
                switch $user_target
                    case author
                        echo "│ 適用対象：Author のみ"
                    case committer
                        echo "│ 適用対象：Committer のみ"
                    case both
                        echo "│ 適用対象：Author と Committer 両方"
                end
        end
    end

    echo "└──────────────────────────────────────────────────────────────────────"

    if test $skip_confirm != true
        read -l -P "この設定でコミット情報を修正しますか？ (y/N) > " confirm
        if not string match -qr '^[Yy]' -- $confirm
            echo "ℹ️ 操作をキャンセルしました"
            return 0
        end
    end

    set -l env_filter ""

    set -l date_part ""
    set -l user_part ""

    if test $fix_commit_date = true
        if test -n "$date_str"
            set date_part "export GIT_AUTHOR_DATE=\"$date_str\"; export GIT_COMMITTER_DATE=\"$date_str\";"
        else
            set date_part "export GIT_COMMITTER_DATE=\"\$GIT_AUTHOR_DATE\";"
        end
    end

    if test $fix_commit_user = true
        switch $user_mode
            case sync
                set user_part "export GIT_COMMITTER_NAME=\"\$GIT_AUTHOR_NAME\"; export GIT_COMMITTER_EMAIL=\"\$GIT_AUTHOR_EMAIL\";"
            case existing new
                switch $user_target
                    case author
                        set user_part "export GIT_AUTHOR_NAME=\"$user_name\"; export GIT_AUTHOR_EMAIL=\"$user_email\";"
                    case committer
                        set user_part "export GIT_COMMITTER_NAME=\"$user_name\"; export GIT_COMMITTER_EMAIL=\"$user_email\";"
                    case both
                        set user_part "export GIT_AUTHOR_NAME=\"$user_name\"; export GIT_AUTHOR_EMAIL=\"$user_email\"; export GIT_COMMITTER_NAME=\"$user_name\"; export GIT_COMMITTER_EMAIL=\"$user_email\";"
                end
        end
    end

    set env_filter "$date_part $user_part"

    set -x FILTER_BRANCH_SQUELCH_WARNING 1
    set_color cyan
    echo "⚙️️ コミット情報を修正しています"
    set_color normal

    if git filter-branch --force --env-filter "$env_filter" -- $commit_range
        set_color green
        echo "✅ コミット情報の修正に成功しました"
        set_color normal
        set -e FILTER_BRANCH_SQUELCH_WARNING
        return 0
    else
        set_color red
        echo "⛔ コミット情報の修正に失敗しました"
        set_color normal
        set -e FILTER_BRANCH_SQUELCH_WARNING
        return 1
    end
end
