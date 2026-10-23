--- MIT - Davi/Pessoa736 (2026)

---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param







---@class DSLX_Main_Module
---
--- @field parser DSLX_Parser_Module
--- @field runtime DSLX_Runtime_Module
--- @field import DSLX_Import_Module
--- @field compile DSLX_Compile_Module
---
--- @field _LICENSE "MIT License"
--- @field _DESCRIPTION "Main DSLX"
--- @field _AUTOR "Davi/Pessoa736"
--- 
--- 
local dslx <const> = {
    parser = require("dslx.parser"),
    compile = require("dslx.compile"),
    import = require("dslx.import"),
    runtime = require("dslx.runtime"),

    _AUTOR = "Davi/Pessoa736",
    _DESCRIPTION = "Main DSLX",
    _LICENSE = "MIT License"
}



--- @param element_func fun(element_data: DSLX_AST_Node):any
--- @return boolean, string?, number?
_G.is_element = function (element_func)
    if type(element_func) ~= "function" then return false, "o elemento precisa ser uma função." end

    local info = debug.getinfo(element_func, "u")
    local nparan = info.nparams

    if nparan < 1 then return false, "função do elemento precisa receber o element_data.", nparan end
    if nparan > 1 then return false, "elemento so recebe 1 argumento.", nparan end

    return true
end


------------------------------------------------------------------------------------------
--#region test ---------------------------------------------------------------------------

local is_main =
    type(arg) == "table" and arg[0] ~= nil
    and debug.getinfo(1, "S").source == "@" .. arg[0]
    and not pcall(debug.getlocal, 4, 1)


if is_main then
    local element1 = function (element_data) return "aaa" end
    local element2 = function () return "aaa" end
    local element3 = function (_, _, _) return "" end
    print(is_element(element1))
    print(is_element(element2))
    print(is_element(element3))
    print(is_element(42)) ---@diagnostic disable-line: param-type-mismatch
end

--#endregion test ------------------------------------------------------------------------
------------------------------------------------------------------------------------------




dslx.import.install()
return dslx