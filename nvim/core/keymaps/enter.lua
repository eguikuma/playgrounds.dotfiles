--[[
Enter で検索結果の移動を行います

ノーマルモードで使用できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Enter を押すと次の検索結果に移動します

検索ハイライトが有効な場合は次の検索結果に移動します
検索ハイライトが無効な場合は何もしません
]]
keymap("n", "<CR>", function()
  if primitives.search.is_highlight_active() then
    vim.cmd("normal! n")
  end
end, { noremap = true, desc = "次の検索結果に移動" })
