--[[
Ctrl+Alt+← で左の単語に移動します

Ctrl+← と同じ動作です
ノーマルモード、インサートモードで使用できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Ctrl+Alt+← を押すと左の単語に移動します
]]
keymap("n", "<C-M-Left>", primitives.word.move_to_previous, { desc = "単語移動（左）" })

--[[
インサートモードで Ctrl+Alt+← を押すと左の単語に移動します
]]
keymap("i", "<C-M-Left>", primitives.word.move_to_previous, { desc = "単語移動（左）" })
