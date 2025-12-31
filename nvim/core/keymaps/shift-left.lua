--[[
Shift+← で選択範囲を左に1文字拡張します

ノーマルモード、ビジュアルモードで使用できます
行頭で止まります（Ctrl+Shift+← は単語単位で選択）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
左に1文字選択を拡張します（行頭で止まる）
]]
local function select_character_left()
  local column = primitives.cursor.get_current_column_number()

  --[[
  行頭の場合は何もしません
  ]]
  if primitives.cursor.is_at_line_start(column) then
    return
  end

  local mode = primitives.mode.get_current()

  if primitives.mode.is_normal(mode) then
    vim.cmd("normal! vh")
  else
    vim.cmd("normal! h")
  end
end

--[[
ノーマルモードで Shift+← を押すと左に1文字選択します
]]
keymap("n", "<S-Left>", select_character_left, { desc = "選択拡張（左）" })

--[[
ビジュアルモードで Shift+← を押すと選択範囲を左に拡張します
]]
keymap("v", "<S-Left>", select_character_left, { desc = "選択拡張（左）" })
