--[[
<leader>+↓ で下側に分割します

ノーマルモードで使用できます
現在のウィンドウの下側に新しいウィンドウを作成します
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで <leader>+↓ を押すと下側に分割します

belowright split で現在のウィンドウの下側に水平分割します
]]
keymap("n", "<leader><Down>", "<cmd>belowright split<cr>", { desc = "下側に分割" })
