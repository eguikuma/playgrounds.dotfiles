--[[
ファイルツリーを表示するプラグインです

https://github.com/nvim-neo-tree/neo-tree.nvim
]]
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",

  --[[
  依存プラグインです
  ]]
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },

  --[[
  起動時に読み込みます
  ]]
  lazy = false,

  --[[
  プラグインの設定です
  ]]
  config = function()
    require("neo-tree").setup({
      --[[
      git 状態アイコンを非表示にします
      ]]
      default_component_configs = {
        git_status = {
          symbols = {
            added = "",
            modified = "",
            deleted = "",
            renamed = "",
            untracked = "",
            ignored = "",
            unstaged = "",
            staged = "",
            conflict = "",
          },
        },
      },

      --[[
      ウィンドウ設定です
      ]]
      window = {
        position = "float",

        --[[
        フローティングウィンドウの設定です
        ]]
        popup = {
          --[[
          サイズを最大化します（画面の90%）
          ]]
          size = {
            width = "90%",
            height = "90%",
          },

          --[[
          タイトルを非表示にします
          ]]
          border = {
            style = "rounded",
            text = {
              top = "",
            },
          },
        },

        --[[
        キーマッピングを全て無効化し、必要なものだけ定義します
        ]]
        mappings = {
          --[[
          デフォルトキーを無効化します
          ]]
          ["<space>"] = "none",
          ["<2-LeftMouse>"] = "none",
          ["<cr>"] = "none",
          ["P"] = "none",
          ["l"] = "none",
          ["h"] = "none",
          ["S"] = "none",
          ["s"] = "none",
          ["t"] = "none",
          ["w"] = "none",
          ["C"] = "none",
          ["z"] = "none",
          ["A"] = "none",
          ["a"] = "none",
          ["d"] = "none",
          ["r"] = "none",
          ["y"] = "none",
          ["x"] = "none",
          ["p"] = "none",
          ["c"] = "none",
          ["m"] = "none",
          ["q"] = "none",
          ["R"] = "none",
          ["?"] = "none",
          [">"] = "none",
          ["<"] = "none",
          ["i"] = "none",
          ["o"] = "none",
          ["oc"] = "none",
          ["od"] = "none",
          ["og"] = "none",
          ["om"] = "none",
          ["on"] = "none",
          ["os"] = "none",
          ["ot"] = "none",
          ["/"] = "none",
          ["f"] = "none",
          ["<C-x>"] = "none",
          ["<C-f>"] = "none",
          ["<C-b>"] = "none",
          ["<C-r>"] = "none",
          ["e"] = "none",
          ["[g"] = "none",
          ["]g"] = "none",
          ["#"] = "none",
          ["."] = "none",
          ["D"] = "none",
          ["<bs>"] = "none",

          --[[
          ユーザー定義のキーマッピングです
          ]]
          ["<CR>"] = "open",
          ["<Esc>"] = "close_window",
          ["<C-n>"] = "add",
          ["<F2>"] = "rename",
          ["<BS>"] = "delete",
          ["<C-c>"] = "copy_to_clipboard",
          ["<C-v>"] = "paste_from_clipboard",
        },
      },

      --[[
      ファイルシステム設定です
      ]]
      filesystem = {
        --[[
        隠しファイルを表示します
        ]]
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    })
  end,
}
