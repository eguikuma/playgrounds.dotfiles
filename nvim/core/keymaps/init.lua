--[[
キーバインドの設定です

Neovimのキーマッピングをカスタマイズします
各キーマップは個別のファイルに分割されています

https://neovim.io/doc/user/lua-guide.html
https://neovim.io/doc/user/map.html
https://neovim.io/doc/user/motion.html
https://neovim.io/doc/user/change.html
]]

--[[
デフォルトキーバインドをリセットします
]]
vim.cmd("mapclear")
vim.cmd("mapclear!")

--[[
無効化するデフォルトキーのリストです
]]
local disabled_keys = {
  --[[
  移動系
  ]]
  "h",
  "j",
  "k",
  "l",
  "w",
  "b",
  "e",
  "W",
  "B",
  "E",
  "ge",
  "gE",
  "0",
  "$",
  "^",
  "G",
  "gg",
  "f",
  "F",
  "t",
  "T",
  ";",
  ",",
  "{",
  "}",
  "(",
  ")",
  "[[",
  "]]",
  "%",
  "H",
  "M",
  "L",
  "+",
  "-",

  --[[
  カウント数値
  ]]
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",

  --[[
  編集系
  ]]
  "d",
  "dd",
  "D",
  "y",
  "yy",
  "Y",
  "c",
  "cc",
  "C",
  "p",
  "P",
  "x",
  "X",
  "r",
  "R",
  "s",
  "S",
  "~",
  ">>",
  "<<",
  ">",
  "<",
  "=",
  "!",
  "U",

  --[[
  挿入系
  ]]
  "a",
  "A",
  "o",
  "O",
  "I",

  --[[
  検索系
  ]]
  "/",
  "?",
  "n",
  "N",
  "*",
  "#",

  --[[
  ビジュアルモード系
  ]]
  "v",
  "V",

  --[[
  その他
  ]]
  "u",
  ".",
  "q",
  "Q",
  "gq",
  "gw",
  "J",
  "K",
  "m",
  "'",
  "`",
  "z",
  "g",
  "[",
  "]",
  "@",
  "@@",
  "&",
  "ZZ",
  "ZQ",
  "gv",

  --[[
  特殊キー
  ]]
  "<Tab>",
  "<S-Tab>",
  "<Space>",

  --[[
  Ctrl キー
  ]]
  "<C-b>",
  "<C-d>",
  "<C-g>",
  "<C-h>",
  "<C-i>",
  "<C-j>",
  "<C-k>",
  "<C-l>",
  "<C-n>",
  "<C-o>",
  "<C-r>",
  "<C-u>",
  "<C-w>",
  "<C-x>",
}

--[[
全てのキーを無効化します
]]
for _, key in ipairs(disabled_keys) do
  vim.keymap.set({ "n", "v", "o" }, key, "<Nop>", { noremap = true, silent = true })
end

--[[
カスタムキーマップを読み込みます
]]
local keymaps = {
  --[[
  保存
  ]]
  "ctrl-s",

  --[[
  編集履歴
  ]]
  "ctrl-z",
  "ctrl-y",

  --[[
  クリップボード
  ]]
  "ctrl-c",
  "ctrl-v",

  --[[
  テキスト選択
  ]]
  "ctrl-a",
  "ctrl-q",

  --[[
  検索
  ]]
  "ctrl-f",
  "enter",

  --[[
  ファイル操作
  ]]
  "ctrl-e",
  "ctrl-p",

  --[[
  単語と段落移動
  ]]
  "ctrl-left",
  "ctrl-right",
  "ctrl-up",
  "ctrl-down",
  "ctrl-alt-left",
  "ctrl-alt-right",
  "ctrl-alt-up",
  "ctrl-alt-down",

  --[[
  選択拡張
  ]]
  "shift-left",
  "shift-right",
  "shift-up",
  "shift-down",

  --[[
  単語と行選択
  ]]
  "ctrl-shift-left",
  "ctrl-shift-right",
  "ctrl-shift-up",
  "ctrl-shift-down",

  --[[
  ウィンドウ操作
  ]]
  "leader-left",
  "leader-right",
  "leader-up",
  "leader-down",
  "leader-r",
  "alt-bracketleft",
  "alt-slash",
  "alt-semicolon",
  "alt-apostrophe",

  --[[
  ペイン移動
  ]]
  "alt-left",
  "alt-right",
  "alt-up",
  "alt-down",

  --[[
  バッファ操作
  ]]
  "leader-d",
  "leader-enter",
  "leader-backspace",

  --[[
  Claude Code
  ]]
  "ctrl-shift-c",

  --[[
  モード切替
  ]]
  "i",
  "escape",

  --[[
  削除
  ]]
  "backspace",

  --[[
  ターミナル
  ]]
  "ctrl-shift-grave",
}

for _, name in ipairs(keymaps) do
  require("core.keymaps." .. name)
end

--[[
FileTypeイベントで無効化キーを再適用します

ファイルタイプごとのプラグイン（ftplugin）がバッファローカルなキーマッピングを設定する場合があるため、FileType イベント発生時に無効化キーを再適用します
buffer = true を指定することで、グローバルな設定を上書きするバッファローカルなマッピングとして設定されます
]]
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    for _, key in ipairs(disabled_keys) do
      vim.keymap.set({ "n", "v", "o" }, key, "<Nop>", {
        buffer = true,
        noremap = true,
        silent = true,
      })
    end
  end,
})
