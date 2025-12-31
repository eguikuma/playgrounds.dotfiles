--[[
Neovim設定のエントリーポイントです

このファイルはNeovim起動時に最初に読み込まれます

https://neovim.io/doc/user/starting.html
https://neovim.io/doc/user/lua-guide.html
]]

require("core.globals")
require("core.preferences")
require("plugins")
require("core.keymaps")
