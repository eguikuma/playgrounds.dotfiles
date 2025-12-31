--[[
ターミナルに関する設定です
]]

--[[
ttimeoutlen の初期値を保存します

Neovim 起動時の ttimeoutlen を記憶しておき、ターミナルバッファから離れたときに復元します
]]
---@diagnostic disable-next-line: undefined-field
local original_ttimeoutlen = vim.opt.ttimeoutlen:get()

--[[
ターミナルバッファに入ったときに ttimeoutlen を短くします

キーコードのタイムアウト時間をミリ秒で指定します
Esc キーを押したときに Neovim がエスケープシーケンスの開始かどうかを判断するために待機する時間です
そのため、Esc を押してからノーマルモードに戻るまでラグが発生します
]]
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "term://*",
  callback = function()
    vim.opt.ttimeoutlen = 10
  end,
})

--[[
ターミナルバッファから離れたときに ttimeoutlen を元に戻します
]]
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = "term://*",
  callback = function()
    vim.opt.ttimeoutlen = original_ttimeoutlen
  end,
})

--[[
ターミナルを開いたときの設定です

TermOpen イベントはターミナルバッファが作成されたときに発生します
ターミナルバッファでは行番号やサインカラムは不要なので非表示にします
]]
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    --[[
    ターミナルバッファでは行番号を非表示にします

    ターミナルの出力に行番号は不要であり表示領域を確保するためです
    ]]
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false

    --[[
    サインカラムを非表示にします

    ターミナルでは Git 差分などの表示が不要です
    ]]
    vim.opt_local.signcolumn = "no"
  end,
})
