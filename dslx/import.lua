--- MIT - Davi/Pessoa736 (2026)


---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param

local on_test = false
if arg and arg[0] and arg[0]:match("import%.lua$") then
    on_test = true
end


local readFile = require("dslx.readFile")
local compile = require("dslx.compile")



--- @class DSLXImportLib
local M <const> = {
    path = package.path:gsub("?.lua", "?.dslx"):gsub("?/init.lua", "?/init.dslx"),
    use_cache = true,
    use_relative_file_path = true,
    loaded   = {},
    compiled = {}
}



--- @param filename any
--- @param opts any
--- @return any, string?
function M.loadfile(filename, opts)
  local use_cache = M.use_cache
  if opts and opts.cache ~= nil then use_cache = opts.cache end

  local src, err = M.read_file(filename)
  if not src then return nil, err end

  if use_cache then
    local hit = M.compiled[filename]
    if hit and hit.src == src then return hit.chunk end
  end

  local chunk, cerr = M.compile(src, "@" .. filename)
  if not chunk then return nil, cerr end

  if use_cache then M.compiled[filename] = { src = src, chunk = chunk } end
  return chunk
end


--- @param name string
--- @return string?, string?
function M.searcher(name)
  local filename, why = package.searchpath(name, M.path)
  if not filename then return why end

  local chunk, err = M.loadfile(filename)
  if not chunk then
    error(("erro ao carregar o módulo '%s' (%s):\n%s"):format(name, filename, err), 0)
  end

  M.loaded[name] = filename
  return chunk, filename
end


--- @param list table
--- @param fn function
--- @return integer?
local function index_of(list, fn)
  for i, v in ipairs(list) do
    if v == fn then return i end
  end
end


---@param pos number?
---@return DSLXImportLib
function M.install(pos)
  if not index_of(package.searchers, M.searcher) then
    table.insert(package.searchers, pos or 2, M.searcher)
  end
  return M
end


--- @return DSLXImportLib
function M.uninstall()
  local i = index_of(package.searchers, M.searcher)
  if i then table.remove(package.searchers, i) end
  return M
end

function M.clear()
  for name in pairs(M.loaded) do package.loaded[name] = nil end
  M.compiled, M.loaded = {}, {}
end


--- @param path string
--- @return string?, string?
M.read_file = function(path)
  local ok, res = pcall(readFile, path)
  if ok then return res end
  return nil, res
end


--- @param src string
--- @param chunkname string
--- @return any?, string?
M.compile = function(src, chunkname)
  local ok, code = pcall(compile, { input = src, asfile = false, tofile = false }, chunkname)
  if not ok or not code then return nil, code end
  return load(code, chunkname, "t")
end


--- @param name string
--- @return any, any
function M.reload(name)
  package.loaded[name] = nil
  local filename = M.loaded[name]
  if filename then M.compiled[filename] = nil end
  return require(name)
end

if on_test then
    M.install()
    local here = (debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or ".")
    M.path = M.path .. ";" .. here .. "/test/?.dslx;" .. here .. "/test/?/init.dslx;"
    require("1")
end

return M