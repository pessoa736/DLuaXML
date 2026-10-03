local on_test = false
if arg and arg[0] and arg[0]:match("compile%.lua$") then
    on_test = true
end

-- local readFile = require "readFile"
local rt = require "DaviLuaXML.runtime"
local parser = require "DaviLuaXML.parser"

local function compile(config)
    config = {
        asfile = config.asfile ~= false,
        run = config.run or false,
        input = config.input,
        input_ext = config.input_ext or ".dslx",
        output = config.output,
        output_ext = config.output_ext or ".lua",
    }

    if config.asfile==false then
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
    local bin = compile{
        asfile = false,
        run = true,
        input = "local sum = function(element) return element.childrens[1]+element.childrens[2] end \n" ..
                "<sum>{2}{3}</sum>"
    }
    print(bin)
end


return compile






