--[[
エディタの設定です

Neovimのオプションを設定してエディタの動作をカスタマイズします
]]

local preferences = {
  "display",
  "cursor",
  "mouse",
  "selection",
  "editing",
  "indent",
  "search",
  "commandline",
  "window",
  "terminal",
}

for _, name in ipairs(preferences) do
  require("core.preferences." .. name)
end
