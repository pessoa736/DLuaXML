--- MIT - Davi/Pessoa736 (2026)

---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param




---@alias DSLX_Runtime_handle_type 
---| fun(node: DSLX_AST_Node|string, Runtime_Handlers?: DSLX_Runtime_Handlers):string


---@alias DSLX_Runtime_Know_Handlers DSLX_Parser_Know_Nodes


---@alias DSLX_Runtime_Handlers 
---| table<DSLX_Runtime_Know_Handlers|string, DSLX_Runtime_handle_type>



---@class DSLX_Runtime_Module
--- @field Runtime_Handlers DSLX_Runtime_Handlers
--- 
--- @field SetHandler 
--- | fun(self: DSLX_Runtime_Module,name: string[]|string , Runtime_handler: DSLX_Runtime_handle_type)
--- 
--- @field expr
--- | fun(self: DSLX_Runtime_Module, node: DSLX_AST_Node|string, Runtime_Handlers: DSLX_Runtime_Handlers):string
--- 
--- @field make_new_code 
--- | fun(self: DSLX_Runtime_Module, node: DSLX_AST_Node, Runtime_Handlers?: DSLX_Runtime_Handlers):string
--- 
--- 
local M<const> = {
    Runtime_Handlers = {},
}



function M:SetHandler(name, func)
    if type(name) == "string" then self.Runtime_Handlers[name] = func end
    if type(name) == "table" then
        for _, n in ipairs(name) do
            self.Runtime_Handlers[n] = func
        end
    end
end



--#region Runtime_Handlers definitions
M:SetHandler("lua", function(node) return node.content end)
M:SetHandler("string", function(str) return string.format("%q", str) end)
M:SetHandler(
    "script",
    function (node)
        return node.content
    end
)
M:SetHandler(
    "children",
    function (node, Runtime_Handlers)
        if type(node) == "string" then error("o children não pode ser string") end
        
        local parts = {}
        for _, child in ipairs(node.children or {}) do
            local so_indentacao = type(child) == "string" and child:find("\n") and child:match("^%s*$")
            if not so_indentacao then
                parts[#parts + 1] = M:expr(child, Runtime_Handlers)
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
)
M:SetHandler(
    {"element", "full_element", "element_self_close"},
    function(node, Runtime_Handlers)
        return string.format(
            "%s{name=%q, props=%s, childrens=%s}",
            node.element, node.element,
            Runtime_Handlers["props"](node, Runtime_Handlers),
            Runtime_Handlers["children"](node, Runtime_Handlers)
        )
    end
)
M:SetHandler(
    "props",
    function (node, Runtime_Handlers)
        if type(node) == "string" then error("o props não pode ser string") end

        local parts = {}
        for k, v in pairs(node.props or {}) do
            
            if k ~= "node_type" then
                local val
                if type(v) == "table" and v.node_type == "script" then
                    val = Runtime_Handlers["script"](v)
                elseif type(v) == "string" then
                    val = Runtime_Handlers["string"](v)
                else
                    val = tostring(v) -- true
                end
                parts[#parts + 1] = string.format("%s=%s", k, val)
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
)
M:SetHandler(
    "file",
    function(node, Runtime_Handlers)
        return M:make_new_code(node.children or {}, Runtime_Handlers)
    end
)
--#endregion Runtime_Handlers definitions



--- @param self DSLX_Runtime_Module
--- @param Runtime_Handlers DSLX_Runtime_Handlers
--- @return DSLX_Runtime_Handlers
local function with_defaults(self, Runtime_Handlers)
    if not Runtime_Handlers or Runtime_Handlers == self.Runtime_Handlers then return self.Runtime_Handlers end
    return setmetatable({}, {__index = function(_, k)
        local h = Runtime_Handlers[k]
        if h ~= nil then return h end
        return self.Runtime_Handlers[k]
    end})
end


function M:expr(node, Runtime_Handlers)
    Runtime_Handlers = with_defaults(self, Runtime_Handlers)

    if type(node) == "string" then
        local strHand = Runtime_Handlers.string or self.Runtime_Handlers.string
        return strHand(node, Runtime_Handlers)
    end
    
    local hand = Runtime_Handlers[node.node_type] or self.Runtime_Handlers[node.node_type]
    if  type(hand)=="function" then
        return hand(node, Runtime_Handlers)
    end

    if type(node) == "table" and node.node_type == "script" then
        for k, v in pairs(node) do print("campo:", k, v) end
        error("script sem content", 0)
    end

    return "nil"
end



function M:make_new_code(nodes, Runtime_Handlers)
    Runtime_Handlers = with_defaults(self, Runtime_Handlers)
    local out = {}
    for _, node in ipairs(nodes) do
        if node.node_type == "lua" then
            out[#out + 1] = node.content
        else
            out[#out + 1] = M:expr(node, Runtime_Handlers)
        end
    end
    return table.concat(out)
end


function M:runtime(file, Runtime_Handlers)
    local H = with_defaults(self, Runtime_Handlers)
    local nodes = (file.children or file)
    local last = nodes[#nodes]
    local code

    if last and last.node_type ~= "lua" and last.node_type ~= "script" then
        local prev = nodes[#nodes - 1]
        local ja_tem_return = prev and prev.node_type == "lua" and prev.content:match("return%s*$")
        if ja_tem_return then
            code = self:make_new_code(nodes, H)
        else
            --[[@diagnostic disable-next-line: missing-fields]]
            local init = self:make_new_code({table.unpack(nodes, 1, #nodes - 1)}, H)
            code = init .. "\nreturn " .. self:expr(last, H)
        end
    else
        code = self:make_new_code(nodes, H)
    end

    local func, err = load(code, "=xml-lua", "t")
    if not func then error(err, 0) end
    return func()
end



------------------------------------------------------------------------------------------
--#region test ---------------------------------------------------------------------------

local is_main =
    type(arg) == "table" and arg[0] ~= nil
    and debug.getinfo(1, "S").source == "@" .. arg[0]
    and not pcall(debug.getlocal, 4, 1)


if is_main then
    local parser = require "dslx.parser"

    local function test(script)
        if parser and type(parser.parser)~="function" then
            ---@diagnostic disable-next-line: cast-local-type
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

--#endregion test ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

return M