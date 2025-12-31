--[[
Alt+↑ で上のウィンドウに移動します

ノーマルモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Alt+↑ を押すと上のウィンドウに移動します
]]
keymap("n", "<A-Up>", "<C-w>k", { noremap = true, desc = "上へ移動" })

--[[
ターミナルモードで Alt+↑ を押すと上のウィンドウに移動します

<C-\><C-n> でノーマルモードに戻り <C-w>k で上のウィンドウに移動します
]]
keymap("t", "<A-Up>", "<C-\\><C-n><C-w>k", { noremap = true, desc = "上へ移動" })
