--[[
基本操作を集約するモジュールです
]]

---@class Primitives
---@field buffer PrimitivesBuffer
---@field cursor PrimitivesCursor
---@field mode PrimitivesMode
---@field search PrimitivesSearch
---@field window PrimitivesWindow
---@field word PrimitivesWord
return {
  buffer = require("core.primitives.buffer"),
  cursor = require("core.primitives.cursor"),
  mode = require("core.primitives.mode"),
  search = require("core.primitives.search"),
  window = require("core.primitives.window"),
  word = require("core.primitives.word"),
}
