--[[
小規模な QoL プラグインのコレクションです

https://github.com/folke/snacks.nvim
]]
return {
  "folke/snacks.nvim",

  --[[
  起動時に読み込みます
  ]]
  lazy = false,

  --[[
  カラースキームの次に読み込みます
  ]]
  priority = 900,
}
