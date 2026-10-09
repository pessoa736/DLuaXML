--- MIT - Davi/Pessoa736 (2026)

---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param

local on_test = false
if arg and arg[0] and arg[0]:match("compile%.lua$") then
    on_test = true
end

-- local readFile = require "readFile"
local rt = require "dslx.runtime"
local parser = require "dslx.parser"
local readFile = require "dslx.readFile"



local function default(v, d)
    if v == nil then return d end
    return v
end

local function join(base, path)
    if path:sub(1, 1) == "/" then return path end
    return base .. path
end



---@class compile_config
---@field asfile boolean?
---@field tofile boolean?
---@field output_relative_actual_file boolean?
---@field run boolean?
---@field input string
---@field output_name string?
---@field output_ext string??
---@field output_dir string?
---@field relative_actual_file boolean?

--- @param config compile_config
--- @return string?
local function compile(config, chunkname)
    local caller = debug.getinfo(2, "S").source
    local caller_dir = (caller:match("^@(.*)[/\\][^/\\]*$") or ".") .. "/"

    config = {
        tofile = default(config.tofile, true),
        asfile = default(config.asfile, true),
        run    = default(config.run,  false),
        input = config.input,
        output_name = config.output_name,
        output_ext = default(config.output_ext, ".lua"),
        output_dir = default(config.output_dir, "."),
        relative_actual_file = default(config.relative_actual_file, false)
    }

    local input = config.input
    if config.asfile then
        if config.relative_actual_file then
            input = join(caller_dir, input)
            print(input)
        end

        input = readFile(input)
        if on_test then print(input) end
    end

    local nodes = parser(input)
    local new_code = rt:make_new_code(nodes)
    if on_test then print(nodes) print(new_code) end

    if not config.tofile then
        if config.run then
            print(rt:runtime(nodes, {}))
            return ""
        end

        return new_code
    end
    
    if not config.output_name then
        config.output_name = 
            config.input:match("([^/\\]+)%.[^./\\]*$") or
            config.input:match("([^/\\]+)$")
    end

    local output_dir = join(config.output_dir .. "/", config.output_name .. config.output_ext)

    if config.output_relative_actual_file or config.relative_actual_file then
        
        output_dir = join(caller_dir, output_dir)
    end

    if on_test then print("output dir: "..output_dir) end
    
    local file, err = io.open(output_dir, "w+")
    if not file then error(err, 0) end

    if file then
        file:write(new_code)
        file:close()
    end
end


if on_test then

    compile({
        output_name = "test",
        input = "test/1.dslx",
        output_dir = "test",
        run = false,
        relative_actual_file=true
    })

    print("compilation sucessed")
end


return compile






