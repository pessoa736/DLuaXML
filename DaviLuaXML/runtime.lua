
local on_test = false
if arg and arg[0] and arg[0]:match("runtime%.lua$") then
    on_test = true
end


local function props_to_lua(props)
    local parts = {}
    for k, v in pairs(props or {}) do
        local val
        if type(v) == "table" and v.node_type == "script" then
            val = "((function() return " .. v.content .. " end)())"
        elseif type(v) == "string" then
            val = string.format("%q", v)
        else
            val = tostring(v) -- true
        end
        parts[#parts + 1] = string.format("[%q] = %s", k, val)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end


local expr

local function children_to_lua(children, handlers)
    local parts = {}
    for _, child in ipairs(children or {}) do
        parts[#parts + 1] = expr(child, handlers)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function script_to_lua(content)
    content = content or ""
    if load("return " .. content) then
        return "((function() return " .. content .. " end)())"
    end
    return "((function() " .. content .. " end)())"
end


expr = function(node, handlers)
    handlers = handlers or {}
    if type(node) == "string" then
        return string.format("%q", node)
    
    elseif node.node_type == "script" then
        return script_to_lua(node.content)
    
    elseif node.node_type == "full_element" or node.node_type == "element_self_close" then
        if handlers.element then return handlers.element(node) end
        return string.format(
            "%s({name = %q, props = %s, childrens = %s})",
            node.element, node.element,
            props_to_lua(node.props),
            children_to_lua(node.children, handlers)
        )
    
    elseif type(node) == "table" and node.node_type == "script" then
        for k, v in pairs(node) do print("campo:", k, v) end
        error("script sem content", 0)
    else

        return "nil"
    end
end

local function make_new_code(nodes, handlers)
    local out = {}
    for _, node in ipairs(nodes) do
        if node.node_type == "lua" then
            out[#out + 1] = node.content
        else
            out[#out + 1] = expr(node, handlers)
        end
    end
    return table.concat(out)
end


---@param nodes table
---@param handlers table<string, function>?
---@return any filereturn
local function runtime(nodes, handlers)
    local new_code_string = make_new_code(nodes, handlers)

    -- retorno implícito: se o último nó é um elemento e não há "return" logo antes
    local last = nodes[#nodes]
    if last and last.node_type ~= "lua" and last.node_type ~= "script" then
        local prev = nodes[#nodes - 1]
        local ja_tem_return = prev and prev.node_type == "lua" and prev.content:match("return%s*$")
        if not ja_tem_return then
            local init = make_new_code({table.unpack(nodes, 1, #nodes - 1)}, handlers)
            new_code_string = init .. "\nreturn " .. expr(last, handlers)
        end
    end

    local func, err = load("return function()\n" .. new_code_string .. "\nend", "=xml-lua", "bt")
    if not func then error(err, 0) end
    return func()()
end

if on_test then
    local parser = require "DaviLuaXML.parser" 
    if type(parser)~="function" then
        parser = function (_) 
            return {{node_type="lua", content="print(\"erro em importar o parser\")"}} 
        end
    end
    local code = "local a = function(element) print(element.name, element.props, element.childrens) end\n <a prop='1' ok>txt</a>"
    local nodes = parser(code) or {{node_type="lua", content="print(\"erro na execução do parser\")"}}
    runtime(nodes)
end


return {runtime = runtime, make_new_code = make_new_code}