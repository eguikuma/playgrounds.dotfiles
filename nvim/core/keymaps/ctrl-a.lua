--[[
Ctrl+A でファイル全体を選択します

ノーマルモード、ビジュアルモード、インサートモードで使用できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Ctrl+A を押すとファイル全体を選択します

gg でファイル先頭に移動し、V で行選択モードに入り、G でファイル末尾まで選択します
]]
keymap("n", "<C-a>", "ggVG", { desc = "全選択" })

--[[
ビジュアルモードで Ctrl+A を押すとファイル全体を選択します

gg でファイル先頭に移動し、V で行選択モードに入り、G でファイル末尾まで選択します
]]
keymap("v", "<C-a>", "ggVG", { desc = "全選択" })

--[[
インサートモードで Ctrl+A を押すとファイル全体を選択します

exit_insert() でカーソル位置を保持したままノーマルモードに遷移し、
ファイル全体を選択します
全選択後は選択状態（ビジュアルモード）を維持するため、インサートモードには戻りません
]]
keymap("i", "<C-a>", function()
  primitives.mode.exit_insert()
  vim.cmd("normal! ggVG")
end, { desc = "全選択" })
