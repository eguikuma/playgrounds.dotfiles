--[[
ウィンドウに関する基本操作を提供します
]]

---@class PrimitivesWindow
local module = {}

--[[
ウィンドウの総数を取得します

winnr("$") は最後のウィンドウ番号を返すため、これがウィンドウの総数になります
]]
function module.get_count()
  return vim.fn.winnr("$")
end

--[[
ウィンドウが複数存在するかを判定します

分割されていない場合は1、分割されている場合は2以上になります
]]
function module.has_multiple()
  return module.get_count() > 1
end

return module
