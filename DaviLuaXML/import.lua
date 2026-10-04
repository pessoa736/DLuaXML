local on_test = false
if arg and arg[0] and arg[0]:match("compile%.lua$") then
    on_test = true
end


local readFile = require("DaviLuaXML.readFile")
local compile = require("DaviLuaXML.compile")


--- @param pathfile string
--- @param config any
--- @return string
local function import(pathfile, config)
    local file = readFile(pathfile)
    local allow_cache = config and config._CACHE and config.use_cache

    if config._CACHE[file] and allow_cache then
       return config._CACHE[file]
    end

    local code = compile{
        input = file,
        run = false,
        asfile = false
    }

    if allow_cache then config._CACHE[file] = code end
    return code
end



if on_test then
    import("text.dslx.1")
end

return import