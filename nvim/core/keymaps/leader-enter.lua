--[[
Leader+Enter で次のバッファに切り替えます

ノーマルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Leader+Enter を押すと次のバッファに切り替えます

<cmd>bnext<cr> で次のバッファに移動します
]]
keymap("n", "<Leader><CR>", "<cmd>bnext<cr>", {
  noremap = true,
  silent = true,
  desc = "次のバッファに切り替え",
})
