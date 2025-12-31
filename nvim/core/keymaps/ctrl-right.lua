--[[
Ctrl+→ で右の単語に移動します

ノーマルモード、インサートモードで使用できます
行末で止まります（Ctrl+Shift+→ は選択しながら移動）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Ctrl+→ を押すと右の単語に移動します
]]
keymap("n", "<C-Right>", primitives.word.move_to_next, { desc = "単語移動（右）" })

--[[
インサートモードで Ctrl+→ を押すと右の単語に移動します
]]
keymap("i", "<C-Right>", primitives.word.move_to_next, { desc = "単語移動（右）" })
