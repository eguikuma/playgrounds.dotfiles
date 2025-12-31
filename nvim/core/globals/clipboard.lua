--[[
システムクリップボードとの連携を設定します

WSL2 環境では win32yank.exe を使用してクリップボードを共有します
]]

--[[
win32yank.exe が利用可能かどうかを確認します

利用可能な場合のみ clipboard provider を設定します
利用できない場合は Neovim のデフォルト動作にフォールバックします
]]
if vim.fn.executable("win32yank.exe") == 1 then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
end
