--[[
<leader>+→ で右側に分割します

ノーマルモードで使用できます
現在のウィンドウの右側に新しいウィンドウを作成します
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで <leader>+→ を押すと右側に分割します

belowright vsplit で現在のウィンドウの右側に垂直分割します
]]
keymap("n", "<leader><Right>", "<cmd>belowright vsplit<cr>", { desc = "右側に分割" })
