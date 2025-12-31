--[[
Shift+↑ で選択範囲を上に拡張します

ノーマルモード、ビジュアルモードで使用できます
空行も超えて自由に選択できます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
上方向に選択を拡張します
]]
local function select_up()
  local line_number = primitives.cursor.get_current_line_number()

  --[[
  最初の行の場合は何もしません
  ]]
  if primitives.cursor.is_at_first_line(line_number) then
    return
  end

  local mode = primitives.mode.get_current()

  if primitives.mode.is_normal(mode) then
    --[[
    ノーマルモードから選択開始
    ]]
    vim.cmd("normal! vk")
  else
    --[[
    ビジュアルモードで上に移動
    ]]
    vim.cmd("normal! k")

    --[[
    行末の場合は行末+1に移動（exclusive対策）

    selection=exclusive では選択終端のカーソル位置が含まれないため、
    上に移動した後、カーソルが行末にある場合は行末の1文字右に移動します
    virtualedit=onemore が有効なので、行末の1文字右にカーソルを置けます
    ]]
    local column = primitives.cursor.get_current_column_number()
    local line_length = primitives.cursor.get_current_line_length()
    if column >= line_length and line_length > 0 then
      vim.cmd("normal! $l")
    end
  end
end

--[[
ノーマルモードで Shift+↑ を押すと上に選択します
]]
keymap("n", "<S-Up>", select_up, { desc = "選択拡張（上）" })

--[[
ビジュアルモードで Shift+↑ を押すと選択範囲を上に拡張します
]]
keymap("v", "<S-Up>", select_up, { desc = "選択拡張（上）" })
