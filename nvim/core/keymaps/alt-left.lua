--[[
Alt+← で左のウィンドウに移動します

ノーマルモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Alt+← を押すと左のウィンドウに移動します
]]
keymap("n", "<A-Left>", "<C-w>h", { noremap = true, desc = "左へ移動" })

--[[
ターミナルモードで Alt+← を押すと左のウィンドウに移動します

<C-\><C-n> でノーマルモードに戻り <C-w>h で左のウィンドウに移動します
]]
keymap("t", "<A-Left>", "<C-\\><C-n><C-w>h", { noremap = true, desc = "左へ移動" })
