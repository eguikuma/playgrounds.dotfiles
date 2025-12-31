--[[
Alt+→ で右のウィンドウに移動します

ノーマルモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Alt+→ を押すと右のウィンドウに移動します
]]
keymap("n", "<A-Right>", "<C-w>l", { noremap = true, desc = "右へ移動" })

--[[
ターミナルモードで Alt+→ を押すと右のウィンドウに移動します

<C-\><C-n> でノーマルモードに戻り <C-w>l で右のウィンドウに移動します
]]
keymap("t", "<A-Right>", "<C-\\><C-n><C-w>l", { noremap = true, desc = "右へ移動" })
