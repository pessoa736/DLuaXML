--- MIT - Davi/Pessoa736 (2026)




---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param




-- imports
local rt = require "dslx.runtime"
local parser = require "dslx.parser"
local readFile = require "dslx.readFile"
local inspect = require "inspect"





---@class DSLX_Compile_Config
---@field asfile boolean|nil
---@field tofile boolean|nil
---@field output_relative_actual_file boolean|nil
---@field run boolean|nil
---@field input string
---@field output_name "output"|"%s"|string|nil
---@field output_ext ".lua"|string|nil
---@field output_dir "."|string|nil
---@field relative_actual_file boolean|nil

---@alias DSLX_Compile_Function fun(self: DSLX_Compile_Module, config?: DSLX_Compile_Config, chunkname?: string):string|nil


---@class DSLX_Compile_Module
---@field show_compilation_info boolean
---@field compile DSLX_Compile_Function
---@field __call DSLX_Compile_Function
---@field _LICENSE "MIT License"
---@field _DESCRIPTION "DSLX (lua + xml) compiler to lua"
---@field _AUTOR "Davi/Pessoa736"



---@type DSLX_Compile_Module
local M <const> = {
    show_conpilation_info = false,
    __call = function (self, ...)
        return self:compile(...)
    end,

    _AUTOR = "Davi/Pessoa736",
    _DESCRIPTION = "DSLX (lua + xml) compiler to lua",
    _LICENSE = "MIT License"
}


M.__index = M
setmetatable(M,M)




---@generic Value
---@generic Default
---@type fun(v: Value, d:Default): Value|Default
local function default(v, d) if v == nil then return d end; return v end

---@type fun(base: string, path: string): string
local function join(base, path)
    if path:sub(1, 1) == "/" then return path end
    return base .. path
end






function M:compile(config, chunkname)
    local shoInfo = self.show_conpilation_info

    local caller = debug.getinfo(2, "S").source
    local caller_dir = (caller:match("^@(.*)[/\\][^/\\]*$") or ".") .. "/"
    if shoInfo then 
        print(("\ncaller: %s (%s)\n"):format(caller, caller_dir))
    end

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
    if shoInfo then
        print(("compilation_config: %s\n"):format(inspect(config)))
    end




    local input = config.input
    if config.asfile then
        if config.relative_actual_file then
            input = join(caller_dir, input)
            if shoInfo then print(("real_input_dir: %s\n"):format(input)) end
        end

        input = readFile(input)
    end

    local nodes = parser(input)
    local new_code = rt:make_new_code(nodes)

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
    if shoInfo then print("output_dir: ".. output_dir) end

    local file, err = io.open(output_dir, "w+")
    if not file then error(err, 0) end

    if file then
        file:write(new_code)
        file:close()
    end


    print("compilation sucessed")
end




local is_main =
    type(arg) == "table" and arg[0] ~= nil
    and debug.getinfo(1, "S").source == "@" .. arg[0]
    and not pcall(debug.getlocal, 4, 1)


if is_main then
    M.show_conpilation_info = true
    
    M:compile({
        output_name = "test",
        input = "test/1.dslx",
        output_dir = "test",
        run = false,
        relative_actual_file=true
    })

end


return M






