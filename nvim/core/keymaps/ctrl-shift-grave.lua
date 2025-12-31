--[[
Ctrl+Shift+` でターミナルを起動します

ノーマルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ターミナルを開いてターミナルモードに入ります

terminal コマンドで新しいターミナルバッファを作成します
startinsert で自動的にターミナルモードに入ります
]]
local function open_terminal()
  vim.cmd("terminal")
  vim.cmd("startinsert")
end

--[[
ノーマルモードで Ctrl+Shift+` を押すとターミナルを起動します
]]
keymap("n", "<C-S-`>", open_terminal, {
  noremap = true,
  silent = true,
  desc = "ターミナルを起動",
})
