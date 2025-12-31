--[[
Ctrl+Shift+↓ で行全体を下方向に選択します

ノーマルモード、ビジュアルモード、インサートモードで使用できます
空行も選択に含まれます（Shift+↓ と同様に空行も超えて選択できます）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
下方向に行全体を選択します
]]
local function select_line_down()
  local line_number = primitives.cursor.get_current_line_number()
  local last_line_number = primitives.cursor.get_last_line_number()
  local mode = primitives.mode.get_current()

  if primitives.mode.is_normal(mode) then
    if primitives.cursor.is_at_last_line(line_number, last_line_number) then
      vim.cmd("normal! V")
    else
      vim.cmd("normal! Vj")
    end
  elseif primitives.mode.is_visual(mode) then
    if primitives.cursor.is_at_last_line(line_number, last_line_number) then
      vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>V", true, false, true))
    else
      vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>Vj", true, false, true))
    end
  else
    --[[
    行単位ビジュアルモードの場合
    ]]
    if not primitives.cursor.is_at_last_line(line_number, last_line_number) then
      vim.cmd("normal! j")
    end
  end
end

--[[
ノーマルモードで Ctrl+Shift+↓ を押すと行全体を下に選択します
]]
keymap("n", "<C-S-Down>", select_line_down, { desc = "行選択（下）" })

--[[
ビジュアルモードで Ctrl+Shift+↓ を押すと選択範囲を下の行まで拡張します
]]
keymap("v", "<C-S-Down>", select_line_down, { desc = "行選択（下）" })

--[[
インサートモードで Ctrl+Shift+↓ を押すと行全体を下に選択します

exit_insert を使用してカーソル位置を保持したままノーマルモードに遷移します
]]
keymap("i", "<C-S-Down>", function()
  primitives.mode.exit_insert()
  select_line_down()
end, { desc = "行選択（下）" })
