--[[
Ctrl+F でファイル内検索をトグルします

ノーマルモードで使用できます
もう一度押すと検索を終了します
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Ctrl+F を押すとファイル内検索を開始します

/ で検索モードに入り、検索パターンを入力できます
Enter で検索を実行します
]]
keymap("n", "<C-f>", "/", { noremap = true, desc = "ファイル内検索" })

--[[
検索モード中に Ctrl+F を押すと検索を終了します
]]
keymap("c", "<C-f>", function()
  local cmdtype = vim.fn.getcmdtype()
  if cmdtype == "/" or cmdtype == "?" then
    return "<C-c>"
  end
  return ""
end, { noremap = true, expr = true, desc = "検索モード終了" })
