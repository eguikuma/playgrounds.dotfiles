--[[
あいまい検索でファイルを探すプラグインです

https://github.com/nvim-telescope/telescope.nvim
]]
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",

  --[[
  依存プラグインです
  ]]
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },

  --[[
  起動時にプラグインを読み込みます
  ]]
  lazy = false,

  --[[
  プラグインの設定です
  ]]
  config = function()
    local actions = require("telescope.actions")

    require("telescope").setup({
      defaults = {
        --[[
        ウィンドウサイズを最大化します（画面の95%）
        ]]
        layout_config = {
          width = 0.95,
          height = 0.95,
        },

        --[[
        デフォルトのキーマッピングを無効化します
        ]]
        mappings = {
          --[[
          インサートモード（検索入力中）のキーマッピングです
          ]]
          i = {
            --[[
            デフォルトキーを無効化します
            ]]
            ["<C-n>"] = false,

            --[[
            Ctrl+P で閉じます
            ]]
            ["<C-p>"] = actions.close,
            ["<C-c>"] = false,
            ["<C-x>"] = false,
            ["<C-v>"] = false,
            ["<C-t>"] = false,
            ["<C-u>"] = false,
            ["<C-d>"] = false,
            ["<C-f>"] = false,
            ["<C-k>"] = false,
            ["<C-q>"] = false,
            ["<C-l>"] = false,
            ["<C-/>"] = false,
            ["<C-w>"] = false,
            ["<C-r>"] = false,
            ["<C-j>"] = false,
            ["<Tab>"] = false,
            ["<S-Tab>"] = false,
            ["<PageUp>"] = false,
            ["<PageDown>"] = false,
            ["<M-f>"] = false,
            ["<M-k>"] = false,
            ["<M-q>"] = false,

            --[[
            矢印キーで選択を移動します
            ]]
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,

            --[[
            Enter で選択したファイルを開きます
            ]]
            ["<CR>"] = actions.select_default,

            --[[
            Esc で閉じます
            ]]
            ["<Esc>"] = actions.close,
          },
        },
      },
    })
  end,
}
