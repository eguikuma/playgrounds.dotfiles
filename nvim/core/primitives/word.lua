--[[
単語に関する基本操作を提供します
]]

local cursor = require("core.primitives.cursor")

---@class PrimitivesWord
local module = {}

--[[
文字クラスを判定します
]]
function module.get_character_class(character)
  if character == "" then
    return "space"
  end

  --[[
  英数字とアンダースコアの判定をします
  ]]
  if character:match("[%w_]") then
    return "word"
  end

  --[[
  空白文字の判定をします
  ]]
  if character:match("%s") then
    return "space"
  end

  --[[
  その他の記号の場合です
  ]]
  return "symbol"
end

--[[
次の単語境界位置を取得します（右方向、行内のみ）

現在の文字クラスと空白をスキップし、次の単語の先頭位置を返します
行末を超える場合は行末+1を返します
]]
function module.get_next_boundary_column()
  local line_content = cursor.get_current_line_content()
  local column = cursor.get_current_column_number()
  local line_length = #line_content

  --[[
  行末より右の場合は移動しません
  ]]
  if column > line_length then
    return column
  end

  --[[
  現在位置の文字クラスを取得します
  ]]
  local current_character = line_content:sub(column, column)
  local current_class = module.get_character_class(current_character)
  local position = column

  --[[
  現在の文字クラスをスキップします

  例：`###` の先頭にいる場合、すべての `#` をスキップします
  ]]
  while position <= line_length do
    local character = line_content:sub(position, position)
    if module.get_character_class(character) ~= current_class then
      break
    end
    position = position + 1
  end

  --[[
  空白をスキップします
  ]]
  while position <= line_length do
    local character = line_content:sub(position, position)
    if module.get_character_class(character) ~= "space" then
      break
    end
    position = position + 1
  end

  return position
end

--[[
前の単語境界位置を取得します（左方向、行内のみ）

空白と現在の文字クラスをスキップし、単語の先頭位置を返します
行頭を超える場合は1を返します
]]
function module.get_previous_boundary_column()
  local line_content = cursor.get_current_line_content()
  local column = cursor.get_current_column_number()

  --[[
  行頭の場合は移動しません
  ]]
  if cursor.is_at_line_start(column) then
    return 1
  end

  --[[
  現在位置の1つ左から開始します
  ]]
  local position = column - 1

  --[[
  空白をスキップします
  ]]
  while position >= 1 do
    local character = line_content:sub(position, position)
    if module.get_character_class(character) ~= "space" then
      break
    end
    position = position - 1
  end

  --[[
  行頭に達した場合は1を返します
  ]]
  if position < 1 then
    return 1
  end

  --[[
  現在位置の文字クラスを取得します
  ]]
  local current_character = line_content:sub(position, position)
  local current_class = module.get_character_class(current_character)

  --[[
  現在の文字クラスをスキップします

  例：`WSL2` の末尾にいる場合、すべての英数字をスキップして先頭に移動します
  ]]
  while position >= 1 do
    local character = line_content:sub(position, position)
    if module.get_character_class(character) ~= current_class then
      break
    end
    position = position - 1
  end

  --[[
  1つ右に戻って単語の先頭位置を返します
  ]]
  return position + 1
end

--[[
前の単語の先頭に移動します（左方向、行頭で止まる）
]]
function module.move_to_previous()
  local column = cursor.get_current_column_number()

  --[[
  行頭の場合は何もしません
  ]]
  if cursor.is_at_line_start(column) then
    return
  end

  --[[
  単語境界を検出します
  ]]
  local previous_position = module.get_previous_boundary_column()

  --[[
  検出した位置に移動します
  ]]
  vim.fn.cursor(0, previous_position)
end

--[[
次の単語の先頭に移動します（右方向、行末で止まる）

virtualedit=onemore が設定されている場合、行末の1文字右（column = line_length + 1）にカーソルを置けます
]]
function module.move_to_next()
  local column = cursor.get_current_column_number()
  local line_length = cursor.get_current_line_length()

  --[[
  行末より右の場合は何もしません
  virtualedit=onemore では column = line_length + 1 まで移動可能
  ]]
  if cursor.is_at_line_end(column, line_length) then
    return
  end

  --[[
  単語境界を検出します
  ]]
  local next_position = module.get_next_boundary_column()

  --[[
  行末を超えない範囲で移動します
  virtualedit=onemore により、行末の1つ右（line_length + 1）まで移動可能
  ]]
  if next_position > line_length + 1 then
    vim.fn.cursor(0, line_length + 1)
  else
    vim.fn.cursor(0, next_position)
  end
end

return module
