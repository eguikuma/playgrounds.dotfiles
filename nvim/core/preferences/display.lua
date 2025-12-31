--[[
表示に関する設定です
]]

--[[
行番号を表示します
]]
vim.opt.number = true

--[[
カーソル行をハイライトします
]]
vim.opt.cursorline = true

--[[
キー入力待機中の表示を無効化します
]]
vim.opt.showcmd = false

--[[
タブラインを常に表示します
]]
vim.opt.showtabline = 2

--[[
バッファを開くたびに行番号を設定します
]]
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    if vim.bo.buftype == "" then
      vim.wo.number = true
    end
  end,
})
