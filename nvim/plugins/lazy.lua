--[[
プラグインを管理するプラグインです

https://github.com/folke/lazy.nvim
]]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

--[[
lazy.nvim がインストールされていない場合は GitHub からクローンします

lazy-lock.json が存在する場合はロックされたコミットを使用します
存在しない場合は stable にフォールバックします
]]
if not vim.uv.fs_stat(lazypath) then
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local lazy_commit = nil

  if vim.uv.fs_stat(lockfile) then
    local file = io.open(lockfile, "r")
    if file then
      local content = file:read("*all")
      file:close()
      --[[
      コミットハッシュを抽出します
      ]]
      lazy_commit = content:match('"lazy%.nvim"%s*:%s*{[^}]*"commit"%s*:%s*"([^"]+)"')
    end
  end

  if lazy_commit then
    --[[
    ロックファイルのコミットでチェックアウトします
    ]]
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
    vim.fn.system({
      "git",
      "-C",
      lazypath,
      "checkout",
      lazy_commit,
    })
  else
    --[[
    lazy-lock.json が存在しないか読み取れない場合は stable を使用します
    ]]
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
end

--[[
lazy.nvim をランタイムパスに追加します
]]
vim.opt.rtp:prepend(lazypath)
