--[[
グローバル変数の設定です

Neovimのグローバル変数を設定してエディタの動作をカスタマイズします

https://neovim.io/doc/user/lua-guide.html
]]

local globals = {
  "suppress",
  "mapping",
  "clipboard",
}

for _, name in ipairs(globals) do
  require("core.globals." .. name)
end
