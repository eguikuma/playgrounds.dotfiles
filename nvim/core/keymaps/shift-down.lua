--[[
Shift+↓ で選択範囲を下に拡張します

ノーマルモード、ビジュアルモードで使用できます
空行も超えて自由に選択できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
下方向に選択を拡張します
]]
local function select_down()
  local line_number = primitives.cursor.get_current_line_number()
  local last_line_number = primitives.cursor.get_last_line_number()

  --[[
  最後の行の場合は何もしません
  ]]
  if primitives.cursor.is_at_last_line(line_number, last_line_number) then
    return
  end

  local mode = primitives.mode.get_current()

  if primitives.mode.is_normal(mode) then
    --[[
    ノーマルモードから選択開始
    ]]
    vim.cmd("normal! vj")
  else
    --[[
    ビジュアルモードで下に移動
    ]]
    vim.cmd("normal! j")
  end
end

--[[
ノーマルモードで Shift+↓ を押すと下に選択します
]]
keymap("n", "<S-Down>", select_down, { desc = "選択拡張（下）" })

--[[
ビジュアルモードで Shift+↓ を押すと選択範囲を下に拡張します
]]
keymap("v", "<S-Down>", select_down, { desc = "選択拡張（下）" })
