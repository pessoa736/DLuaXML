--- esse aquivo server para definir a api paser()
--- MIT - Davi/Pessoa736 (2026)

---@version 5.5
---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param

---@class lpeg_C_object: userdata, table
---@operator len():string|lpeg_C_object
---@operator add(lpeg_C_object): lpeg_C_object
---@operator sub(lpeg_C_object): lpeg_C_object
---@operator unm(lpeg_C_object): lpeg_C_object
---@operator mul(lpeg_C_object): lpeg_C_object
---@operator div(lpeg_C_object): lpeg_C_object
---@operator pow(lpeg_C_object|number): lpeg_C_object
---@operator mod(lpeg_C_object): lpeg_C_object
---@field match function

---@class lpeg_rule_obj: table<number, string>,table<string, lpeg_C_object>

---@class lpeg_patern: string, lpeg_C_object

---@class lpeg: metatable, lpeg_C_object
---@field match function
---@field P fun(value: lpeg_rule_obj|number|string): lpeg_C_object
---@field S fun(string: string): lpeg_C_object
---@field R fun(...: string): lpeg_C_object
---@field utfR fun(code_point1:number|string, code_point2: number|string):lpeg_C_object
---@field locate fun(l: table<any|unknown, table>):lpeg_C_object
---@field B fun(Pattern: lpeg_patern): lpeg_C_object
---@field C fun(Pattern: lpeg_patern): lpeg_C_object
---@field Ct fun(Pattern: lpeg_patern): lpeg_C_object
---@field Cf fun(Pattern: lpeg_patern, func: function): lpeg_C_object
---@field Cg fun(Pattern: lpeg_patern, key?: number): lpeg_C_object
---@field Cmt fun(Pattern: lpeg_patern, func: function): lpeg_C_object
---@field V fun(v: string): lpeg_C_object
local lpeg = require("lpeg")

local P = lpeg.P
local S = lpeg.S
local R = lpeg.R
local C = lpeg.C
local Cg = lpeg.Cg
local Ct = lpeg.Ct
local Cmt = lpeg.Cmt
local V = lpeg.V
local Cf = lpeg.Cf

local inspect = require "inspect"



---@class DSLX_AST_Node
---@field node_type "element"|"full_element"|"element_self_close"|"element_prop"|"lua"|"script"
---@field children table<string|number, DSLX_AST_Node|string|nil>|nil
---@field content string|nil
---@field element string|nil
---@field props   table<string, DSLX_AST_Node>|nil

---@class DSLX_Parser_Module
---@field parser fun(self:DSLX_Parser_Module, code: string):DSLX_AST_Node
---@operator call(string):DSLX_AST_Node
---@field SetPattern fun(self:DSLX_Parser_Module, name: string, pattern: lpeg_C_object)
local M <const> = {
    patterns = {},
    lpeg = lpeg
}
M.__index = M
function M:__call(code) self:parser(code) end

setmetatable(M, M)


function M:SetPattern(name, pattern) self.patterns[name] = pattern end

function M:GetPattern(name) return self.patterns[name] end

M:SetPattern(
    "chars",
    (R("az", "AZ", "09") + S("_-."))
)

M:SetPattern(
    "spaces",
    S(" \t\r\n") ^ 0
)

M:SetPattern(
    "space",
    S(" \t\r\n") ^ 1
)

M:SetPattern(
    "q_any",
    P(1)
)

M:SetPattern(
    "element_name",
    C(M:GetPattern("chars") ^ 1)
)

M:SetPattern(
    "prop_name",
    C(M:GetPattern("chars") ^ 1)
)

M:SetPattern(
    "block",
    P({
        "B",
        B = P("{") * C(V("Inner") ^ 0) * P("}"),
        Inner = (1 - S("{}")) + P("{") * V("Inner") ^ 0 * P("}"),
    }) /
    function(content)
        return { node_type = "script", content = content }
    end
)

M:SetPattern(
    "str",
    P("'") *
    C((M:GetPattern("q_any") - P("'")) ^ 0) *
    P("'") + P('"') *
    C((M:GetPattern("q_any") - P('"')) ^ 0) *
    P('"')
)

M:SetPattern(
    "element_prop",
    Cg(M:GetPattern("prop_name") *
        M:GetPattern("spaces") *
        P("=") *
        M:GetPattern("spaces") *
        (
            M:GetPattern("block")
            +
            M:GetPattern("str")
        )
    )
)

local element_props = Cf(Ct("") * (element_prop * espacos + prop_name) ^ 0, function(acc, name, value)
    acc.node_type = "element_prop"
    return rawset(acc, name, value == nil and true or value)
end)

local open_element = P("<") * espacos * element_name * espaco ^ 0 * element_props * espacos * P(">")
local childrens = Ct((V("Element") + block + C((q_qualquer - P("<") - block) ^ 1)) ^ 0)
local close_element = P("</") * espacos * element_name * espacos * P(">")

local element_completa = Cmt(
    open_element * childrens * close_element,
    function(s, i, open_name, props, children, close_name)
        if open_name ~= close_name then
            return nil
        end
        return i, { node_type = "full_element", element = open_name, props = props, children = children }
    end
)

local element_self_close = (P("<") * espacos * element_name * espaco ^ 0 * element_props * espacos * P("/>"))
    / function(name, props)
        return { node_type = "element_self_close", element = name, props = props }
    end

local Element_parser = P({
    "Element",
    Element = espacos * (element_self_close + element_completa),
})

local lua_code = C((1 - P("<")) ^ 1 + P("<")) / function(s)
    return { node_type = "lua", content = s }
end

local File_parser = Ct((Element_parser + lua_code) ^ 0)




---@class DSLX_AST_Node
---@field node_type "element"|"full_element"|"element_self_close"|"element_prop"|"lua"|"script"
---@field children table<string|number, DSLX_AST_Node|string|nil>|nil
---@field content string|nil
---@field element string|nil
---@field props   table<string, Node>|nil


function M:parser(code)
    local obj = File_parser:match(code)
    if not obj then
        return setmetatable({}, {
            __tostring = function()
                return "nil (Falha no Parser)"
            end,
        })
    end
    return setmetatable(obj,
        {
            __tostring = function(_self)
                return inspect(_self)
            end
        }
    )
end

---- test
local is_main =
    type(arg) == "table" and arg[0] ~= nil
    and debug.getinfo(1, "S").source == "@" .. arg[0]
    and not pcall(debug.getlocal, 4, 1)


if is_main then
    local function test(script)
        script = script or "print('sem script')"
        local obj = M(script)
        print("codigo de entrada:", script)
        print("objeto de saida: \n" .. tostring(obj) .. "\n\n")
    end

    test("local a = <element prop1='' prop2={'2'} prop3> txt aleatorio {local a = 9} <test/> </element> \n print(a)")
    test("local a<const> = 2")
end



return M
