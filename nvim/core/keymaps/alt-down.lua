--[[
Alt+↓ で下のウィンドウに移動します

ノーマルモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Alt+↓ を押すと下のウィンドウに移動します
]]
keymap("n", "<A-Down>", "<C-w>j", { noremap = true, desc = "下へ移動" })

--[[
ターミナルモードで Alt+↓ を押すと下のウィンドウに移動します

<C-\><C-n> でノーマルモードに戻り <C-w>j で下のウィンドウに移動します
]]
keymap("t", "<A-Down>", "<C-\\><C-n><C-w>j", { noremap = true, desc = "下へ移動" })
