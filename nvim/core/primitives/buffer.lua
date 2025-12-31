--[[
バッファに関する基本操作を提供します
]]

---@class PrimitivesBuffer
local module = {}

--[[
リストされているバッファの数を取得します

バッファリストに表示されているバッファ（:ls で表示されるバッファ）のみをカウントします
一時バッファや非表示バッファは含まれません
]]
function module.get_listed_count()
  return #vim.fn.getbufinfo({ buflisted = 1 })
end

return module
