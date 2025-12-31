--[[
検索に関する基本操作を提供します
]]

---@class PrimitivesSearch
local module = {}

--[[
検索ハイライトが有効かどうかを判定します

v:hlsearch はハイライトが表示されている場合に1を返します
nohlsearch コマンド実行後は0になります
]]
function module.is_highlight_active()
  return vim.v.hlsearch == 1
end

return module
