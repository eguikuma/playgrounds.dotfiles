function killer_help
    echo "🔪 killer - ポートを使用中のプロセスを強制終了するツール

[使用方法]
killer [ポート番号:REQUIRED]

[オプション]
-h, --help     このヘルプを表示します

[例]
killer 3000
killer --help"
end

function killer -d 指定したポートを使用中のプロセスを強制終了します
    argparse h/help -- $argv
    or return

    if set -q _flag_help
        killer_help
        return 0
    end

    if test (count $argv) -ne 1
        killer_help
        return 1
    end

    set -l port $argv[1]

    if not string match -qr '^[0-9]+$' -- $port
        set_color red
        echo "⛔ ポート番号には正の整数を指定してください"
        set_color normal
        return 1
    end

    set -l match_line (ss -tulnp | command grep ":$port" | head -n1)

    if test -z "$match_line"
        return 1
    end

    set -l pid (echo $match_line | sed -n 's/.*pid=\([0-9]*\).*/\1/p')
    set -l pname (ps -p $pid -o comm=)

    if test -z "$pid"
        set_color red
        echo "⛔ ポート番号に対応するプロセスが見つかりません"
        set_color normal
        return 1
    end

    echo "
    ┌──────────────────────────────────────────────────────────────
    │ ポート番号：$port
    │ プロセスID：$pid
    │ プロセス名：$pname
    └──────────────────────────────────────────────────────────────"

    set_color normal
    read -l -P "このプロセスを強制終了しますか？ (y/N) >" confirm

    if not string match -qr '^[Yy]' -- $confirm
        echo "ℹ️ 操作をキャンセルしました"
        return 0
    end

    kill -9 $pid

    if test $status -eq 0
        set_color green
        echo "✅ プロセスの強制終了に成功しました"
        set_color normal
    else
        set_color red
        echo "⛔ プロセスの強制終了に失敗しました"
        set_color normal
        return 1
    end
end
