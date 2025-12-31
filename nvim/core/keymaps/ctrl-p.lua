--[[
Ctrl+P でファイル検索をトグルします

ノーマルモードで使用できます
開いている状態でもう一度押すと閉じます（Telescopeプラグイン）
]]

local keymap = vim.keymap.set

--[[
ノーマルモードで Ctrl+P を押すとTelescopeのファイル検索を開きます

telescope.builtin.find_files() であいまい検索によるファイル選択画面を表示します
]]
keymap("n", "<C-p>", function()
  require("telescope.builtin").find_files({
    prompt_title = "",
    results_title = "",
    preview_title = "",
  })
end, { noremap = true, desc = "ファイル検索" })
