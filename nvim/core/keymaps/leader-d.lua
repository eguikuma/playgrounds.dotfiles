--[[
Leader+D でウィンドウまたはバッファを閉じます

ノーマルモードで使用できます
複数ウィンドウならウィンドウを、単一ウィンドウなら先にバッファを閉じます
]]

local keymap = vim.keymap.set
local primitives = require("core.primitives")

--[[
ウィンドウ数とバッファ数に応じて閉じる対象を切り替えます
]]
local function smart_close()
  local window_count = primitives.window.get_count()
  local buffer_count = primitives.buffer.get_listed_count()

  --[[
  単一ウィンドウかつ単一バッファの場合は何もしません
  ]]
  if window_count == 1 and buffer_count <= 1 then
    return
  end

  --[[
  複数ウィンドウの場合はウィンドウを閉じます
  ]]
  if window_count > 1 then
    vim.cmd("close")
    return
  end

  --[[
  単一ウィンドウで複数バッファの場合はバッファを閉じます
  ]]
  vim.cmd("bdelete!")
end

--[[
ノーマルモードで Leader+D を押すとスマートクローズを実行します
]]
keymap(
  "n",
  "<Leader>d",
  smart_close,
  { noremap = true, desc = "ウィンドウまたはバッファを閉じる" }
)
