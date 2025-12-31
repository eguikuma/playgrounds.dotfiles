--[[
コマンドラインに関する設定です
]]

--[[
:find コマンドの検索パスにサブディレクトリを追加します
]]
vim.opt.path:append("**")

--[[
コマンドライン補完時にメニューを表示します
]]
vim.opt.wildmenu = true

--[[
検索から除外するパターンを指定します
]]
vim.opt.wildignore:append("node_modules/*,.git/*")
