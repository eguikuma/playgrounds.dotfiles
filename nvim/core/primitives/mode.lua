--[[
モードに関する基本操作を提供します
]]

---@class PrimitivesMode
local module = {}

--[[
現在のモードを取得します
]]
function module.get_current()
  return vim.fn.mode()
end

--[[
ノーマルモードかどうかを判定します
]]
function module.is_normal(mode)
  return mode == "n"
end

--[[
ビジュアルモード（文字単位）かどうかを判定します
]]
function module.is_visual(mode)
  return mode == "v"
end

--[[
インサートモードからノーマルモードへ遷移します

stopinsert はカーソル位置を1文字左に移動させる場合があるため、事前にカーソル位置を記憶し、遷移後に復元します

getcurpos() と setpos() を使用することで、より正確にカーソル位置を復元できます
]]
function module.exit_insert()
  local cursor_position = vim.fn.getcurpos()
  vim.cmd("stopinsert")
  vim.fn.setpos(".", cursor_position)
end

return module
