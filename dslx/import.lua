---@meta DSLX.Import
--- MIT - Davi/Pessoa736 (2026)
---@module "dslx.import"


---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param


local readFile = require("dslx.readFile")
local compile = require("dslx.compile")
local inspect = require "inspect"


---@class DSLX_importer_hit
---@field src string
---@field chunk string

---@class DSLX_option_loader_file
---@field use_cache boolean|nil
---@field use_relative_file_path boolean|nil
---@field show_debug boolean|nil

---@class DSLX_Import_Module:DSLX_option_loader_file
---@field _LICENSE "MIT License"
---@field _DESCRIPTION "DSLX (lua + xml) importer"
---@field _AUTOR "Davi/Pessoa736"
---@field path string
---@field loaded table<string, string>
---@field compiled table<string, DSLX_importer_hit>
---@field loadfile (fun(filename: string, opts?: DSLX_option_loader_file|nil):string|nil, string|nil)?
---@field searcher (fun(name: string, opts?: DSLX_option_loader_file|nil):string|nil, string|nil)?
---@field install (fun(pos: integer?, opts?: DSLX_option_loader_file|nil):DSLX_Import_Module)?
---@field uninstall (fun(opts?: DSLX_option_loader_file|nil):DSLX_Import_Module)?
---@field clear fun(opts?: DSLX_option_loader_file|nil)?
---@field read_file (fun(path: string, opts?: DSLX_option_loader_file|nil):string|nil, string|nil)?
---@field compile (fun(src: string, chunkname: string, opts?: DSLX_option_loader_file|nil):any|nil, string|nil)?
---@field reload (fun(name: string, opts?: DSLX_option_loader_file|nil): unknown|nil, unknown|nil)?
---@field syncPath (fun(self: DSLX_Import_Module, opts?: DSLX_option_loader_file|nil))?



---@type DSLX_Import_Module
local M <const> = {
    _AUTOR = "Davi/Pessoa736",
    _DESCRIPTION = "DSLX (lua + xml) importer",
    _LICENSE = "MIT License",

    show_debug = false,
    path = package.path:gsub("?.lua", "?.dslx"):gsub("?/init.lua", "?/init.dslx"),
    use_cache = true,
    use_relative_file_path = true,
    loaded   = {},
    compiled = {},
}



function M.loadfile(filename, opts)
  local use_cache = M.use_cache
  if opts and opts.use_cache ~= nil then use_cache = opts.use_cache end

  local src, err = M.read_file(filename, opts)
  if not src then return nil, err end

  if use_cache then
    local hit = M.compiled[filename]
    if hit and hit.src == src then return hit.chunk end
  end

  local chunk, cerr = M.compile(src, "@" .. filename, opts)
  if not chunk then return nil, cerr end

  if use_cache then M.compiled[filename] = { src = src, chunk = chunk } end
  return chunk
end


function M.searcher(name, opts)
  local filename, why = package.searchpath(name, M.path)
  if not filename then 
    return why 
  end

  local chunk, err = M.loadfile(filename, opts)
  if not chunk then
    error(("erro ao carregar o módulo '%s' (%s):\n%s"):format(name, filename, err), 0)
  end

  M.loaded[name] = filename
  if (opts and opts.show_debug) or M.show_debug then
    print(("\n%s carregado\n"):format(filename))
  end
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


function M.install(pos, opts)
  if not index_of(package.searchers, M.searcher) then
    pos = pos or 2
    table.insert(package.searchers, pos, M.searcher)
    if (opts and opts.show_debug) or M.show_debug  then
      print("\n\nimporter DSLX instalado em package.searcher na posição "..pos)
      print(inspect(package.searchers), "\n\n")
    end
  end
  return M
end



function M.uninstall(opts)
  local i = index_of(package.searchers, M.searcher)
  if i then table.remove(package.searchers, i) end
  if (opts and opts.show_debug) or M.show_debug  then
    print("\n\nimporter DSLX desinstalado em package.searcher")
    print(inspect(package.searchers), "\n\n")
  end
  return M
end

function M.clear(opts)
  for name in pairs(M.loaded) do package.loaded[name] = nil end
  M.compiled, M.loaded = {}, {}
  if (opts and opts.show_debug) or M.show_debug  then
    print("\n\n limpando modulos importados")
    print("compilados: " .. inspect(M.compiled))
    print("carregados: " .. inspect(M.loaded), "\n\n")
  end
end


M.read_file = function(path, opts)
  local ok, res = pcall(readFile, path)
  if ok then return res end
  return nil, res
end


M.compile = function(src, chunkname, opts)
  local ok, code = pcall(compile, { input = src, asfile = false, tofile = false }, chunkname)
  if not ok or not code then return nil, code end
  if (opts and opts.show_debug) or M.show_debug then
    print(("(%s): \n '%s'"):format(chunkname, code))
  end
  return load(code, chunkname, "t")
end


function M.reload(name, opts)
  package.loaded[name] = nil
  local filename = M.loaded[name]
  if filename then M.compiled[filename] = nil end
  return require(name)
end

function M:syncPath(opts)
  self.path = package.path:gsub("?.lua", "?.dslx")
end



---- test
local is_main =
    type(arg) == "table" and arg[0] ~= nil
    and debug.getinfo(1, "S").source == "@" .. arg[0]
    and not pcall(debug.getlocal, 4, 1)


if is_main then
    M.show_debug = true
    M.install(nil, M)
    local here = (debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or ".")
    M.path = M.path .. ";" .. here .. "/test/?.dslx;" .. here .. "/test/?/init.dslx;"
    require("1")

    M.clear(M)
    M.uninstall(M)
end

return M