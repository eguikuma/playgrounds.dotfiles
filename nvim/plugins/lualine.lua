--[[
ステータスラインをカスタマイズするプラグインです

https://github.com/nvim-lualine/lualine.nvim
]]
return {
  "nvim-lualine/lualine.nvim",

  --[[
  依存プラグインです
  ]]
  dependencies = { "nvim-tree/nvim-web-devicons" },

  --[[
  起動時にステータスラインを表示します
  ]]
  lazy = false,

  --[[
  ステータスラインの設定です
  ]]
  opts = {
    options = {
      --[[
      アイコンを使用します
      ]]
      icons_enabled = true,

      --[[
      テーマに合わせた配色を使用します
      ]]
      theme = "auto",

      --[[
      セクション間の区切り文字です

      シンプルな外観にするため空文字を設定します
      ]]
      section_separators = "",
      component_separators = "",
    },
    sections = {
      --[[
      左側に表示する情報です
      ]]
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = { "filename" },

      --[[
      右側に表示する情報です
      ]]
      lualine_x = { "encoding", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },

    --[[
    タブラインの設定です

    画面上部にバッファとタブを表示します
    ]]
    tabline = {
      --[[
      左側に開いているバッファを表示します
      ]]
      lualine_a = {
        {
          "buffers",
          --[[
          テーマに合わせた色を設定します
          ]]
          buffers_color = {
            active = { fg = "#DCD7BA", bg = "#54546D" },
            inactive = { fg = "#727169", bg = "#1F1F28" },
          },
          --[[
          バッファの状態を示す記号です

          modified を空にして fmt 関数で制御します
          ]]
          symbols = {
            modified = "",
            alternate_file = "",
          },
          --[[
          バッファ名の表示をカスタマイズします

          プラグインバッファは「▸」で表示します
          それ以外は従来通りの表示で、変更時に「*」を追加します
          ]]
          fmt = function(name, buffer)
            local plugin_filetypes = {
              ["TelescopePrompt"] = true,
              ["neo-tree"] = true,
              ["neo-tree-popup"] = true,
              ["lazy"] = true,
              ["lazy_backdrop"] = true,
              ["checkhealth"] = true,
            }

            if plugin_filetypes[buffer.filetype] then
              return "▸"
            end

            if vim.bo[buffer.bufnr].modified then
              return name .. " *"
            end

            return name
          end,
        },
      },
    },
  },
}
