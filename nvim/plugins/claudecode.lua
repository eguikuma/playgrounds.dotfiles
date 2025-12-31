--[[
Claude Code を使用するプラグインです

https://github.com/coder/claudecode.nvim
]]
return {
  "coder/claudecode.nvim",

  --[[
  snacks.nvim をターミナルプロバイダーとして使用します
  ]]
  dependencies = { "folke/snacks.nvim" },

  --[[
  起動時に読み込みます
  ]]
  lazy = false,

  --[[
  デフォルト設定で初期化します
  ]]
  config = true,
}
