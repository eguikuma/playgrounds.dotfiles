--[[
ウィンドウに関する設定です
]]

--[[
特定のバッファを開いたときにウィンドウ分割を解除します

これらのバッファはデフォルトで新しいウィンドウを開きますが
この設定によりフルスクリーンで表示されます
]]
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf", "terminal", "vim", "checkhealth" },
  callback = function()
    vim.cmd("only")
  end,
})
