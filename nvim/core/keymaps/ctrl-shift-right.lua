--[[
Ctrl+Shift+→ で単語単位で右に選択します

ノーマルモード、ビジュアルモード、インサートモードで使用できます
行末で止まります（Shift+→ は1文字単位で選択）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
単語の先頭まで選択を拡張します（右方向、行末で止まる）

virtualedit=onemore が設定されている場合、行末の1文字右（column = line_length + 1）にカーソルを置けます
]]
local function select_word_right()
  local column = primitives.cursor.get_current_column_number()
  local line_length = primitives.cursor.get_current_line_length()

  --[[
  行末より右の場合は何もしません
  virtualedit=onemore では column = line_length + 1 まで移動可能
  ]]
  if primitives.cursor.is_at_line_end(column, line_length) then
    return
  end

  --[[
  単語境界を検出します
  ]]
  local next_position = primitives.word.get_next_boundary_column()

  --[[
  行末を超えない範囲で移動します
  selection=exclusive なので、選択範囲の終端は次の単語の1つ手前になります
  ]]
  local destination_position = next_position
  if destination_position > line_length + 1 then
    destination_position = line_length + 1
  end

  --[[
  単語境界まで移動します
  ]]
  vim.fn.cursor(0, destination_position)
end

--[[
ノーマルモードで Ctrl+Shift+→ を押すと右の単語を選択します
]]
keymap("n", "<C-S-Right>", function()
  local column = primitives.cursor.get_current_column_number()
  local line_length = primitives.cursor.get_current_line_length()

  --[[
  行末より右の場合は何もしません
  ]]
  if primitives.cursor.is_at_line_end(column, line_length) then
    return
  end

  vim.cmd("normal! v")
  select_word_right()
end, { desc = "単語選択（右）" })

--[[
ビジュアルモードで Ctrl+Shift+→ を押すと選択範囲を右の単語まで拡張します
]]
keymap("v", "<C-S-Right>", function()
  select_word_right()
end, { desc = "単語選択（右）" })

--[[
インサートモードで Ctrl+Shift+→ を押すと右の単語を選択します

exit_insert を使用してカーソル位置を保持したままノーマルモードに遷移します
]]
keymap("i", "<C-S-Right>", function()
  local column = primitives.cursor.get_current_column_number()
  local line_length = primitives.cursor.get_current_line_length()

  --[[
  行末より右の場合は何もしません
  ]]
  if primitives.cursor.is_at_line_end(column, line_length) then
    return
  end

  primitives.mode.exit_insert()
  vim.cmd("normal! v")
  select_word_right()
end, { desc = "単語選択（右）" })
