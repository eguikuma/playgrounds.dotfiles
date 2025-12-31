--[[
Ctrl+Shift+C で Claude Code をトグルします

ノーマルモード、ビジュアルモード、インサートモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Ctrl+Shift+C を押すと Claude Code をトグルします
]]
keymap("n", "<C-S-c>", "<cmd>ClaudeCode<cr>", { noremap = true, desc = "Claude Code をトグル" })

--[[
ビジュアルモードで Ctrl+Shift+C を押すと Claude Code をトグルします
]]
keymap("v", "<C-S-c>", "<cmd>ClaudeCode<cr>", { noremap = true, desc = "Claude Code をトグル" })

--[[
インサートモードで Ctrl+Shift+C を押すと Claude Code をトグルします
]]
keymap("i", "<C-S-c>", "<cmd>ClaudeCode<cr>", { noremap = true, desc = "Claude Code をトグル" })

--[[
ターミナルモードで Ctrl+Shift+C を押すと Claude Code をトグルします
]]
keymap("t", "<C-S-c>", "<cmd>ClaudeCode<cr>", { noremap = true, desc = "Claude Code をトグル" })
