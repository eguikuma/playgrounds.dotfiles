--[[
Ctrl+E でファイラーをトグルします

ノーマルモードで使用できます
開いている状態でもう一度押すと閉じます（neo-treeプラグイン）
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Ctrl+E を押すとneo-treeをトグルします

Neotree toggle コマンドでファイルツリーの表示/非表示を切り替えます
]]
keymap(
  "n",
  "<C-e>",
  "<cmd>Neotree toggle<cr>",
  { noremap = true, desc = "ファイラーをトグル" }
)
