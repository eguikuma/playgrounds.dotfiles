--[[
<leader>+← で左側に分割します

ノーマルモードで使用できます
現在のウィンドウの左側に新しいウィンドウを作成します
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで <leader>+← を押すと左側に分割します

aboveleft vsplit で現在のウィンドウの左側に垂直分割します
]]
keymap("n", "<leader><Left>", "<cmd>aboveleft vsplit<cr>", { desc = "左側に分割" })
