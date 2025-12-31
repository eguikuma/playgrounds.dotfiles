--[[
Backspace で検索結果の移動または選択範囲を削除します

ノーマルモード、ビジュアルモードで使用できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Backspace を押すと前の検索結果に移動します

検索ハイライトが有効な場合は前の検索結果に移動します
検索ハイライトが無効な場合は何もしません
]]
keymap("n", "<BS>", function()
  if primitives.search.is_highlight_active() then
    vim.cmd("normal! N")
  end
end, { noremap = true, desc = "前の検索結果に移動" })

--[[
ビジュアルモードで Backspace を押すと選択範囲を削除します

"_ でブラックホールレジスタを指定し、d で削除します
ブラックホールレジスタを使うことで、削除したテキストがクリップボードやレジスタを上書きするのを防ぎます
]]
keymap("v", "<BS>", '"_d', { noremap = true, desc = "選択範囲を削除" })
