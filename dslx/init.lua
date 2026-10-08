
local on_test = false
if arg and arg[0] and arg[0]:match("init%.lua$") then
    on_test = true
end


local dslx = {
    parser = require("dslx.parser"),
    compile = require("dslx.compile"),
    import = require("dslx.import"),
    runtime = require("dslx.runtime"),
}



--- @param element_func fun(element_data: Node):any
--- @return boolean, string?, number?
_G.is_element = function (element_func)
    local info = debug.getinfo(element_func, "u")
    local nparan = info.nparams
    
    if type(element_func) ~= "function" then return false, "o elemento precisa ser uma função." end
    if nparan < 1 then return false, "função do elemento precisa receber o element_data.", nparan end
    if nparan > 1 then return false, "elemento so recebe 1 argumento.", nparan end

    return true
end


if on_test then 
    local element1 = function (element_data) return "aaa" end
    local element2 = function () return "aaa" end
    local element3 = function (_, _, _) return "" end
    print(is_element(element1))
    print(is_element(element2))
    print(is_element(element3))
end

dslx.import.install()
return dslx