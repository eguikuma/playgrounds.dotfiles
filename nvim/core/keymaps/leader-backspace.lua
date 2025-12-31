--[[
Leader+Backspace で前のバッファに切り替えます

ノーマルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Leader+Backspace を押すと前のバッファに切り替えます

<cmd>bprev<cr> で前のバッファに移動します
]]
keymap("n", "<Leader><BS>", "<cmd>bprev<cr>", {
  noremap = true,
  silent = true,
  desc = "前のバッファに切り替え",
})
