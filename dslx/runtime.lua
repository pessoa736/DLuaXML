--- MIT - Davi/Pessoa736 (2026)

---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param

local on_test = false
if arg and arg[0] and arg[0]:match("runtime%.lua$") then
    on_test = true
end



---@alias handle1 fun(node: string|Node):string
---@alias handle2 fun(node: Node|string, handlers?: __handlers):string
---@alias handleN handle1|handle2
---@class __handlers: table<string, handleN>
---@field lua handleN|nil
---@field script handleN|nil
---@field string handleN|nil
---@field children handleN|nil
---@field props handleN|nil
---@field element handleN|nil


---@class runtime_moduler
---@field __handlers __handlers
local M<const> = {
    __handlers = {},
}


--- @param name string|string[]
--- @param func handleN
function M:addHandler(name, func)
    if type(name) == "string" then self.__handlers[name] = func end
    if type(name) == "table" then
        for _, n in ipairs(name) do
            self.__handlers[n] = func
        end
    end
end




M:addHandler("lua", function(node) return node.content end)
M:addHandler("string", function(str) return string.format("%q", str) end)
M:addHandler(
    "script",
    function (node)
        return node.content
    end
)
M:addHandler(
    "children",
    function (node, handlers)
        if type(node) == "string" then error("o children não pode ser string") end
        
        local parts = {}
        for _, child in ipairs(node.children or {}) do
            local so_indentacao = type(child) == "string" and child:find("\n") and child:match("^%s*$")
            if not so_indentacao then
                parts[#parts + 1] = M:expr(child, handlers)
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
)
M:addHandler(
    {"element", "full_element", "element_self_close"},
    function(node, handlers)
        return string.format(
            "%s{name=%q, props=%s, childrens=%s}",
            node.element, node.element,
            handlers.props(node, handlers),
            handlers.children(node, handlers)
        )
    end
)
M:addHandler(
    "props",
    function (node, handlers)
        if type(node) == "string" then error("o props não pode ser string") end

        local parts = {}
        for k, v in pairs(node.props or {}) do
            
            if k ~= "node_type" then
                local val
                if type(v) == "table" and v.node_type == "script" then
                    val = handlers.script(v)
                elseif type(v) == "string" then
                    val = handlers.string(v)
                else
                    val = tostring(v) -- true
                end
                parts[#parts + 1] = string.format("%s=%s", k, val)
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
)



--- @param self runtime_moduler
--- @param handlers __handlers
--- @return __handlers
local function with_defaults(self, handlers)
    if not handlers or handlers == self.__handlers then return self.__handlers end
    return setmetatable({}, {__index = function(_, k)
        local h = handlers[k]
        if h ~= nil then return h end
        return self.__handlers[k]
    end})
end



---@type fun(self: table, node: Node|string, handlers: __handlers):string
function M:expr(node, handlers)
    handlers = with_defaults(self, handlers)

    if type(node) == "string" then
        local strHand = handlers.string or self.__handlers.string
        return strHand(node, handlers)
    end
    
    local hand = handlers[node.node_type] or self.__handlers[node.node_type]
    if  type(hand)=="function" then
        return hand(node, handlers)
    end

    if type(node) == "table" and node.node_type == "script" then
        for k, v in pairs(node) do print("campo:", k, v) end
        error("script sem content", 0)
    end

    return "nil"
end



---@param nodes table
---@param handlers table<string, function>?
---@return string new_code
function M:make_new_code(nodes, handlers)
    handlers = with_defaults(self, handlers)
    local out = {}
    for _, node in ipairs(nodes) do
        if node.node_type == "lua" then
            out[#out + 1] = node.content
        else
            out[#out + 1] = M:expr(node, handlers)
        end
    end
    return table.concat(out)
end


---@param nodes table
---@param handlers table<string, function>?
---@return any filereturn
function M:runtime(nodes, handlers)
    handlers = with_defaults(self, handlers)

    local new_code_string = M:make_new_code(nodes, handlers)

    local last = nodes[#nodes]
    if last and last.node_type ~= "lua" and last.node_type ~= "script" then
        local prev = nodes[#nodes - 1]
        local ja_tem_return = prev and prev.node_type == "lua" and prev.content:match("return%s*$")
        if not ja_tem_return then
            local init = M:make_new_code({table.unpack(nodes, 1, #nodes - 1)}, handlers)
            new_code_string = init .. "\nreturn " .. M:expr(last, handlers)
        end
    end

    local func, err = load("return function()\n" .. new_code_string .. "\nend", "=xml-lua", "bt")
    if not func then error(err, 0) end
    return func()()
end





if on_test then
    local parser = require "dslx.parser"

    local function test(script)
        if type(parser)~="function" then
            parser = function (_)
                return {{node_type="lua", content="print(\"erro em importar o parser\")"}} 
            end
        end

        script = script or "print('sem script')"
        local nodes = parser(script) or {{node_type="lua", content="print(\"erro na execução do parser\")"}}
        local _, res = pcall(function ()
            M:runtime(nodes)
        end)

        print(res)
    end
    
    
    test "local a = function(element) print(element.name, element.props, element.childrens) end\n <a prop='1' ok>txt</a>"
    test "local a <const> = 2; a=3"
end


return M