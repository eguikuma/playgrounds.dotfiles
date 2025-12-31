--[[
選択に関する設定です
]]

--[[
システムクリップボードと連携します
]]
vim.opt.clipboard = "unnamedplus"

--[[
選択範囲の終端処理を変更します
]]
vim.opt.selection = "exclusive"

--[[
Shift+矢印キーで選択を開始・終了できるようにします
]]
vim.opt.keymodel = "startsel,stopsel"

--[[
Shift+矢印キーでSelectモードを使用します
]]
vim.opt.selectmode = "key"
