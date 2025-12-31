--[[
カーソルに関する基本操作を提供します
]]

---@class PrimitivesCursor
local module = {}

--[[
カーソルのカラム位置を取得します
]]
function module.get_current_column_number()
  return vim.fn.col(".")
end

--[[
現在の行の長さを取得します

vim.fn.col("$") は行末の次の位置を返すため、1を引いて行の長さにします
]]
function module.get_current_line_length()
  return vim.fn.col("$") - 1
end

--[[
カーソルの行番号を取得します
]]
function module.get_current_line_number()
  return vim.fn.line(".")
end

--[[
ファイルの最終行番号を取得します
]]
function module.get_last_line_number()
  return vim.fn.line("$")
end

--[[
現在の行の内容を取得します
]]
function module.get_current_line_content()
  return vim.fn.getline(".")
end

--[[
カーソルが行頭にいるかを判定します
]]
function module.is_at_line_start(column)
  return column <= 1
end

--[[
カーソルが行末より右にいるかを判定します

virtualedit=onemore が設定されている場合、行末の1文字右（column = line_length + 1）にカーソルを置けます
]]
function module.is_at_line_end(column, line_length)
  return column > line_length
end

--[[
カーソルが最初の行にいるかを判定します
]]
function module.is_at_first_line(line_number)
  return line_number <= 1
end

--[[
カーソルが最後の行にいるかを判定します
]]
function module.is_at_last_line(line_number, last_line_number)
  return line_number >= last_line_number
end

return module
