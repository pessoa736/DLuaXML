--- esse aquivo server para definir a api paser()
--- MIT - Davi/Pessoa736 (2026)

---@version 5.5
---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param
---@diagnostic enable: spell-check


--#region lpeg definitions

---@class lpeg_C_object: userdata, table
---
--- @operator len():string|lpeg_C_object
--- @operator add(lpeg_C_object): lpeg_C_object
--- @operator sub(lpeg_C_object): lpeg_C_object
--- @operator unm(lpeg_C_object): lpeg_C_object
--- @operator mul(lpeg_C_object): lpeg_C_object
--- @operator div(lpeg_C_object): lpeg_C_object
--- @operator pow(lpeg_C_object|number): lpeg_C_object
--- @operator mod(lpeg_C_object): lpeg_C_object
---
--- @field match fun(self:any, code: string): any



---@class lpeg_rule_obj: table<number, string>,table<string, lpeg_C_object>
---@class lpeg_patern: string, lpeg_C_object



---@class lpeg: metatable, lpeg_C_object
---
--- @field match fun(self:any, code: string): any
---
--- @field P fun(value: lpeg_rule_obj|number|string): lpeg_C_object
--- @field S fun(string: string): lpeg_C_object
--- @field R fun(...: string): lpeg_C_object
--- @field utfR fun(code_point1:number|string, code_point2: number|string):lpeg_C_object
--- @field locate fun(l: table<any|unknown, table>):lpeg_C_object
--- @field B fun(Pattern: lpeg_patern): lpeg_C_object
--- @field C fun(Pattern: lpeg_patern): lpeg_C_object
--- @field Ct fun(Pattern: lpeg_patern): lpeg_C_object
--- @field Cf fun(Pattern: lpeg_patern, func: function): lpeg_C_object
--- @field Cg fun(Pattern: lpeg_patern, key?: number): lpeg_C_object
--- @field Cmt fun(Pattern: lpeg_patern, func: function): lpeg_C_object
--- @field V fun(v: string): lpeg_C_object
---
--#endregion lpeg definitions
local lpeg = require("lpeg")
local inspect = require "inspect"

local P = lpeg.P
local S = lpeg.S
local R = lpeg.R
local C = lpeg.C
local Cg = lpeg.Cg
local Ct = lpeg.Ct
local Cmt = lpeg.Cmt
local V = lpeg.V
local Cf = lpeg.Cf



---@alias DSLX_Parser_Know_Nodes
---| "lua"
---| "script"
---| "props"
---| "element_prop"
---| "full_element"
---| "element_self_close"
---| "file"
--- nome dos nodes conhecidos


---@alias DSLX_Parser_Know_Patterns
---| DSLX_Parser_Know_Nodes
---| "children"
---| "element_props"
---| "space"
---| "spaces"
---| "q_any"
---| "chars"
---| "str"
---| "block"
---| "element_name"
---| "prop_name"
---| "open_element"
---| "childrens"
---| "close_element"
---| "Element_parser"
---| "lua_code"
---| "File_parser"
--- nome dos padrões conhecidos


--- nodes AST de informação do codigo
---@class DSLX_AST_Node
---@field node_type DSLX_Parser_Know_Nodes tipo do node
---@field children table<string|number, DSLX_AST_Node|string|nil>|nil sua decendecia
---@field content string|nil conteudo
---@field element string|nil nome do elemento
---@field props   table<string, DSLX_AST_Node>|nil seus paramentros


--- Modulo que analiza e transforma codigo dslx em Nodes AST
---@class (exact) DSLX_Parser_Module
---
--- @operator call(string):DSLX_AST_Node ja faz a chamada da função parser
--- @field parser_principal string? qual regra/padrão (pattern) é o parser principal
--- @field patterns table<DSLX_Parser_Know_Patterns|string, lpeg_C_object> banco de paterns
--- @field lpeg lpeg lpeg ja importado para modificações nos patterns caso necessario
---
--- @field parser 
--- | fun(self:DSLX_Parser_Module, code: string):DSLX_AST_Node 
--- 
--- 
--- @field SetPattern 
--- | fun(self:DSLX_Parser_Module, name: DSLX_Parser_Know_Patterns|string, pattern: lpeg_C_object)
--- 
--- @field GetPattern 
--- | fun(self:DSLX_Parser_Module, name: DSLX_Parser_Know_Patterns|string):lpeg_C_object
--- 
--- @field SetParserPrincipal 
--- | fun(self: DSLX_Parser_Module, name: DSLX_Parser_Know_Patterns|string)
--- 
--- @field match 
--- | fun(self: DSLX_Parser_Module, code: string): any?
---
--- @field _LICENSE "MIT License" licensa: MIT License
--- @field _DESCRIPTION "parser of DSLX" descrição: parser do DSLX
--- @field _AUTOR "Davi/Pessoa736" autor: Davi/Pessoa736
---
local M <const> = {
    patterns = {},
    parser_principal = nil;
    lpeg = lpeg,


    _LICENSE = "MIT License",
    _AUTOR  = "Davi/Pessoa736",
    _DESCRIPTION = "parser of DSLX"
}



setmetatable(M,{
    __call=function(self, code) return self:parser(code) end
})


function M:SetPattern(name, pattern) self.patterns[name] = pattern end
function M:GetPattern(name) return self.patterns[name] or error("não existe pattern: ".. name) end
function M:SetParserPrincipal(name) self.parser_principal = name end
function M:match(code)
    return (self:GetPattern(self.parser_principal)):match(code)
end


--#region making patterns
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


M:SetPattern(
    "element_props",
    Cf(
        Ct("") *
            (
                M:GetPattern("element_prop")*
                M:GetPattern("spaces") +
                M:GetPattern("prop_name")
            ) ^ 0,
        function(acc, name, value)
            acc.node_type = "element_prop"
            return rawset(acc, name, value == nil and true or value)
        end
    )
)

M:SetPattern(
    "open_element",
    P("<")*
        M:GetPattern("spaces")*
        M:GetPattern("element_name")*
        M:GetPattern("space")^0 *
        M:GetPattern("element_props")*
        M:GetPattern("spaces")*
    P(">")
)

M:SetPattern(
    "childrens",
    Ct((
        V("Element")+
        M:GetPattern("block")+
        C((
            M:GetPattern("q_any")-
            P("<")-
            M:GetPattern("block")
        ) ^ 1)
    ) ^ 0)
)


M:SetPattern(
    "close_element",
     P("</")*
        M:GetPattern("spaces")*
        M:GetPattern("element_name")*
        M:GetPattern("spaces")*
    P(">")
)

M:SetPattern(
    "full_element",
     Cmt(
        M:GetPattern("open_element") * M:GetPattern("childrens") * M:GetPattern("close_element"),
        
        function(s, i, open_name, props, children, close_name)
            if open_name ~= close_name then return nil end

            return i, { node_type = "full_element", element = open_name, props = props, children = children }
        end
    )
)

M:SetPattern(
    "element_self_close",
    (P("<")*
        M:GetPattern("spaces")*
        M:GetPattern("element_name")*
        M:GetPattern("space") ^ 0 *
        M:GetPattern("element_props")*
        M:GetPattern("spaces")*
    P("/>"))/
    function(name, props)
        return { node_type = "element_self_close", element = name, props = props }
    end
)

M:SetPattern(
    "Element_parser",
    P{
        "Element",
        Element = M:GetPattern("spaces")*
        (
            M:GetPattern("element_self_close")+
            M:GetPattern('full_element')
        ),
    }
)

M:SetPattern(
    "lua_code",
    C((1 - P("<")) ^ 1 + P("<"))/ 
    function(s)
        return { node_type = "lua", content = s }
    end
)

M:SetPattern(
    "File_parser",
    Ct((
        M:GetPattern("Element_parser")+
        M:GetPattern("lua_code")
    ) ^ 0)/
    function (s)
        return {node_type = "file", children = s}
    end
)
--#endregion


M:SetParserPrincipal("File_parser")


function M:parser(code)
    local obj = self:match(code)
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




------------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------------


return M
