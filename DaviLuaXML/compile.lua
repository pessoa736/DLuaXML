local on_test = false
if arg and arg[0] and arg[0]:match("compile%.lua$") then
    on_test = true
end

-- local readFile = require "readFile"
local rt = require "DaviLuaXML.runtime"
local parser = require "DaviLuaXML.parser"


---@class compile_config
---@field asfile boolean?
---@field run boolean?
---@field input string
---@field output_name string?
---@field output_ext string?


--- @param config compile_config
--- @return string
local function compile(config)
    config = {
        asfile = config.asfile or true,
        run = config.run or false,
        input = config.input,
        output_name = config.output,
        output_ext = config.output_ext or ".lua",
    }

    if config.asfile then
        local nodes = parser(config.input)
        if config.run then
            print(rt.runtime(nodes, {}))
            return ""
        end

        local new_code = rt.make_new_code(nodes)
        return new_code
    end
end


if on_test then
    local script = "local sum = function(element) return element.childrens[1]+element.childrens[2] end \n" ..
                   "<sum>{2}{3}</sum> \n" ..
                   "print('test')"

    local bin = compile({
        asfile = true,
        run = false,
        input = script
    })

    print("script: \n".. script)
    print("\nresponse:  \n" .. bin)
end


return compile






