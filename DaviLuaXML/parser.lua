--- esse aquivo server para definir a api paser()
--- MIT - Davi/Pessoa736 (2026)



local on_test = false
if arg and arg[0] and arg[0]:match("parser%.lua$") then
    on_test = true
end



---@alias lpeg_element any

---@class lpeg: metatable
---@field P fun(v: string|number|table): lpeg_element
---@field S fun(v: string): lpeg_element
---@field R fun(...: string): lpeg_element
---@field B fun(v: lpeg_element): lpeg_element
---@field C fun(v: lpeg_element): lpeg_element
---@field Ct fun(v: lpeg_element): lpeg_element
---@field Cf fun(v: lpeg_element, _: function): lpeg_element
---@field Cg fun(v: lpeg_element): lpeg_element
---@field Cmt fun(v: lpeg_element, _: function): lpeg_element
---@field V fun(v: string): lpeg_element
local lpeg = require("lpeg")

local P = lpeg.P
local S = lpeg.S
local R = lpeg.R
local B = lpeg.B
local C = lpeg.C
local Cg = lpeg.Cg
local Ct = lpeg.Ct
local Cmt = lpeg.Cmt
local V = lpeg.V
local Cf = lpeg.Cf


local caractere   = (R("az", "AZ", "09") + S"_-.")
local espacos     = S" \t\r\n"^0
local espaco      = S" \t\r\n"^1
local q_qualquer  = P(1)

local element_name    = C(caractere^1)
local prop_name   = C(caractere^1)


local block = 
    P{
        "B",
        B = P"{" * C(V"Inner"^0) * P"}",
        Inner = (1 - S"{}") + P"{" * V"Inner"^0 * P"}"
    } / function (content)
        return {node_type="script", content = content}
    end

local str =
    P"'"
        * C((q_qualquer - P"'")^0) *
    P"'"
    +
    P'"'
        * C((q_qualquer - P'"')^0) *
    P'"'


local element_prop  = Cg(prop_name * espacos * P"=" * espacos * (block + str))
local element_props = Cf(Ct("") * (element_prop * espacos + prop_name)^0, 
    function(acc, name, value)
        acc.node_type = "element_prop"
        return rawset(acc, name, value == nil and true or value)
    end
)


local open_element = P"<" * espacos * element_name * espaco^0 * element_props * espacos * P">"
local childrens = Ct((V"Element" + block + C((q_qualquer - P"<" - block)^1) )^0)
local close_element = P"</" * espacos * element_name * espacos * P">"


local element_completa = Cmt(
    open_element * childrens * close_element,
    function(s, i, open_name, props, children, close_name)
        if open_name ~= close_name then return nil end
        return i, { node_type="full_element", element = open_name, props = props, children = children }
    end
)

local element_self_close =
    (P"<" * espacos * element_name * espaco^0 * element_props * espacos * P"/>")
    / function(name, props)
        return { node_type="element_self_close", element = name, props = props }
    end




local Element_parser = P{
    "Element",
    Element = espacos * (element_self_close + element_completa)
}

local lua_code = C((1 - P"<")^1 + P"<")
    / function(s) return { node_type = "lua", content = s } end

local File_parser = Ct((Element_parser + lua_code)^0)

local function repeatTab(n)
    local str = ""
    for i=1, n do
        str = str .. "\t"
    end
    return str
end

local function serializer (tabl, t)
    t = t or 0
    local str = "{"
    local i = 0

    for k, v in pairs(tabl) do
        str = str .. "\n" .. repeatTab(t+1)
        i = i + 1

        if type(v)=="table" then 
            str = str .. k .. ": " .. tostring(serializer(v, t+1))
        elseif type(v)=="string" then 
            str = str .. k .. ": " ..'"' ..  v .. '"'
        else
            str = str .. k .. ": " .. tostring(v)
        end
        str = str .. ","
    end

    if not (i==0) then str = str:sub(0, #str - 1) .. "\n" .. repeatTab(t) end
    return str .. "}"
end

---@class Node
---@field node_type "element"|"full_element"|"element_self_close"|"element_prop"|"lua"
---@field children table<string|number, Node|string>|nil
---@field content string|nil
---@field element string|nil
---@field props   table<string, Node>

---@type fun(code: string): Node
local function parser(code)
    local obj = File_parser:match(code)
    if not obj then return setmetatable({}, {__tostring = function() return "nil (Falha no Parser)" end}) end
    return setmetatable(obj, {__tostring = serializer})
end





---- test
if on_test then
    local code_test = "local a = <element prop1='' prop2={'2'} prop3> txt aleatorio {local a = 9} <test/> </element> \n print(a)"
    local obj = parser(code_test)

    print("codigo de entrada:", code_test)
    print("objeto de saida: \n" .. tostring(obj))
end

return parser