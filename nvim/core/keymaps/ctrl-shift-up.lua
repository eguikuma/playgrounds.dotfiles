--[[
Ctrl+Shift+↑ で行全体を上方向に選択します

ノーマルモード、ビジュアルモード、インサートモードで使用できます
空行も選択に含まれます（Shift+↑ と同様に空行も超えて選択できます）
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
上方向に行全体を選択します
]]
local function select_line_up()
  local line_number = primitives.cursor.get_current_line_number()
  local mode = primitives.mode.get_current()

  if primitives.mode.is_normal(mode) then
    if primitives.cursor.is_at_first_line(line_number) then
      vim.cmd("normal! V")
    else
      vim.cmd("normal! Vk")
    end
  elseif primitives.mode.is_visual(mode) then
    if primitives.cursor.is_at_first_line(line_number) then
      vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>V", true, false, true))
    else
      vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>Vk", true, false, true))
    end
  else
    --[[
    行単位ビジュアルモードの場合
    ]]
    if not primitives.cursor.is_at_first_line(line_number) then
      vim.cmd("normal! k")
    end
  end
end

--[[
ノーマルモードで Ctrl+Shift+↑ を押すと行全体を上に選択します
]]
keymap("n", "<C-S-Up>", select_line_up, { desc = "行選択（上）" })

--[[
ビジュアルモードで Ctrl+Shift+↑ を押すと選択範囲を上の行まで拡張します
]]
keymap("v", "<C-S-Up>", select_line_up, { desc = "行選択（上）" })

--[[
インサートモードで Ctrl+Shift+↑ を押すと行全体を上に選択します

exit_insert を使用してカーソル位置を保持したままノーマルモードに遷移します
]]
keymap("i", "<C-S-Up>", function()
  primitives.mode.exit_insert()
  select_line_up()
end, { desc = "行選択（上）" })
