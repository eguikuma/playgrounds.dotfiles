--[[
Leader+R でウィンドウを均等サイズにします

ノーマルモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Leader+R を押すとウィンドウを均等サイズにします
]]
keymap("n", "<Leader>r", function()
  vim.cmd("wincmd =")
end, { noremap = true, desc = "ウィンドウを均等サイズにする" })
