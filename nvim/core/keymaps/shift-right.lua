--[[
Shift+→ で選択範囲を右に1文字拡張します

ノーマルモード、ビジュアルモードで使用できます
行末で止まります（Ctrl+Shift+→ は単語単位で選択）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
右に1文字選択を拡張します（行末で止まる）

virtualedit=onemore が設定されている場合、行末の1文字右（column = line_length + 1）にカーソルを置けます
]]
local function select_character_right()
  local column = primitives.cursor.get_current_column_number()
  local line_length = primitives.cursor.get_current_line_length()

  --[[
  行末より右の場合は何もしません
  virtualedit=onemore では column = line_length + 1 まで移動可能
  ]]
  if primitives.cursor.is_at_line_end(column, line_length) then
    return
  end

  local mode = primitives.mode.get_current()

  if primitives.mode.is_normal(mode) then
    vim.cmd("normal! vl")
  else
    vim.cmd("normal! l")
  end
end

--[[
ノーマルモードで Shift+→ を押すと右に1文字選択します
]]
keymap("n", "<S-Right>", select_character_right, { desc = "選択拡張（右）" })

--[[
ビジュアルモードで Shift+→ を押すと選択範囲を右に拡張します
]]
keymap("v", "<S-Right>", select_character_right, { desc = "選択拡張（右）" })
