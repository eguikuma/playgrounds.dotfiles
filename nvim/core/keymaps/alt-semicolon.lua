--[[
Alt+; で境界線を左に移動します

ノーマルモード、ターミナルモードで使用できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ノーマルモードで Alt+; を押すと境界線を左に移動します
]]
local function resize_left()
  --[[
  分割されていない場合は何もしません
  ]]
  if not primitives.window.has_multiple() then
    return
  end

  local current_window_number = vim.fn.winnr()
  local left_window_number = vim.fn.winnr("h")
  if left_window_number ~= current_window_number then
    vim.cmd("vertical resize +3")
  else
    vim.cmd("vertical resize -3")
  end
end

keymap("n", "<M-;>", resize_left, { desc = "境界線を左に移動" })

keymap("t", "<M-;>", resize_left, { desc = "境界線を左に移動" })
