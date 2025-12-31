--[[
Ctrl+Alt+→ で右の単語に移動します

Ctrl+→ と同じ動作です
ノーマルモード、インサートモードで使用できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Ctrl+Alt+→ を押すと右の単語に移動します
]]
keymap("n", "<C-M-Right>", primitives.word.move_to_next, { desc = "単語移動（右）" })

--[[
インサートモードで Ctrl+Alt+→ を押すと右の単語に移動します
]]
keymap("i", "<C-M-Right>", primitives.word.move_to_next, { desc = "単語移動（右）" })
