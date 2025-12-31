--[[
Ctrl+Shift+← で単語単位で左に選択します

ノーマルモード、ビジュアルモード、インサートモードで使用できます
行頭で止まります（Shift+← は1文字単位で選択）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
単語の先頭まで選択を拡張します（左方向、行頭で止まる）
]]
local function select_word_left()
  local column = primitives.cursor.get_current_column_number()

  --[[
  行頭の場合は何もしません
  ]]
  if primitives.cursor.is_at_line_start(column) then
    return
  end

  --[[
  単語境界を検出します
  ]]
  local previous_position = primitives.word.get_previous_boundary_column()

  --[[
  単語境界まで移動します
  ]]
  vim.fn.cursor(0, previous_position)
end

--[[
ノーマルモードで Ctrl+Shift+← を押すと左の単語を選択します
]]
keymap("n", "<C-S-Left>", function()
  local column = primitives.cursor.get_current_column_number()

  --[[
  行頭の場合は何もしません
  ]]
  if primitives.cursor.is_at_line_start(column) then
    return
  end

  vim.cmd("normal! v")
  select_word_left()
end, { desc = "単語選択（左）" })

--[[
ビジュアルモードで Ctrl+Shift+← を押すと選択範囲を左の単語まで拡張します
]]
keymap("v", "<C-S-Left>", function()
  select_word_left()
end, { desc = "単語選択（左）" })

--[[
インサートモードで Ctrl+Shift+← を押すと左の単語を選択します

exit_insert を使用してカーソル位置を保持したままノーマルモードに遷移します
]]
keymap("i", "<C-S-Left>", function()
  local column = primitives.cursor.get_current_column_number()

  --[[
  行頭の場合は何もしません
  ]]
  if primitives.cursor.is_at_line_start(column) then
    return
  end

  primitives.mode.exit_insert()
  vim.cmd("normal! v")
  select_word_left()
end, { desc = "単語選択（左）" })
