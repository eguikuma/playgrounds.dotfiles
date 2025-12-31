--[[
カラースキームをカスタマイズするプラグインです

https://github.com/rebelot/kanagawa.nvim
]]
return {
  "rebelot/kanagawa.nvim",

  --[[
  起動時に最優先で読み込みます
  ]]
  lazy = false,
  priority = 1000,

  --[[
  プラグイン読み込み後にカラースキームを適用します
  ]]
  config = function()
    require("kanagawa").setup({
      --[[
      ハイライトグループのカスタマイズです
      ]]
      overrides = function(colors)
        local theme = colors.theme
        return {
          --[[
          ビジュアルモードでの選択範囲のハイライトです
          ]]
          Visual = { bg = "#2d4f67" },

          --[[
          現在フォーカス中の検索結果のハイライトです
          ]]
          IncSearch = { bg = theme.diag.warning, fg = theme.ui.bg },
          CurSearch = { bg = theme.diag.warning, fg = theme.ui.bg },
        }
      end,
    })
    vim.cmd.colorscheme("kanagawa")
  end,
}
