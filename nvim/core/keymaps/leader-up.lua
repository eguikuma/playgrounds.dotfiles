--[[
<leader>+↑ で上側に分割します

ノーマルモードで使用できます
現在のウィンドウの上側に新しいウィンドウを作成します
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで <leader>+↑ を押すと上側に分割します

aboveleft split で現在のウィンドウの上側に水平分割します
]]
keymap("n", "<leader><Up>", "<cmd>aboveleft split<cr>", { desc = "上側に分割" })
