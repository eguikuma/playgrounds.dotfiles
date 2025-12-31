--[[
Ctrl+← で左の単語に移動します

ノーマルモード、インサートモードで使用できます
行頭で止まります（Ctrl+Shift+← は選択しながら移動）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Ctrl+← を押すと左の単語に移動します
]]
keymap("n", "<C-Left>", primitives.word.move_to_previous, { desc = "単語移動（左）" })

--[[
インサートモードで Ctrl+← を押すと左の単語に移動します
]]
keymap("i", "<C-Left>", primitives.word.move_to_previous, { desc = "単語移動（左）" })
