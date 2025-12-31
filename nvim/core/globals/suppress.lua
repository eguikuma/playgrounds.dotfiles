--[[
ランタイムプラグインの抑制設定です

https://neovim.io/doc/user/vim_diff.html
https://neovim.io/doc/user/filetype.html
]]

--[[
matchit.vim を無効化します

% キーの拡張マッチング機能を提供するプラグインです
独自のキーマッピング体系では不要です
]]
vim.g.loaded_matchit = 1

--[[
netrwPlugin.vim を無効化します

ファイラー機能を提供するプラグインです
]]
vim.g.loaded_netrwPlugin = 1

--[[
ftplugin のマッピングを無効化します

ファイルタイプごとのプラグインがキーマッピングを上書きするのを防ぎます
]]
vim.g.no_plugin_maps = 1
