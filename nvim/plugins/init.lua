--[[
プラグインの設定です

lazy.nvim を初期化してプラグインを読み込みます

https://github.com/folke/lazy.nvim
]]

--[[
lazy.nvim のブートストラップを実行します
]]
require("plugins.lazy")

--[[
lazy.nvim を初期化してプラグインを読み込みます
]]
---@diagnostic disable-next-line: different-requires
require("lazy").setup({
  require("plugins.kanagawa"),
  require("plugins.lualine"),
  require("plugins.neo-tree"),
  require("plugins.telescope"),
  require("plugins.snacks"),
  require("plugins.claudecode"),
}, {
  --[[
  luarocks サポートを無効化します
  ]]
  rocks = {
    enabled = false,
  },
})
