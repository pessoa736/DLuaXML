--- test de compilação de dslx para lua




local function soma(element)
    local soma = 0 
    for _, valor in ipairs(element.childrens) do
        soma = soma + valor
    end

    return soma + element.props.t
end

local pt = function(element) print(table.unpack(element.childrens)) end


pt({name = "pt", props = {}, childrens = {soma({name = "soma", props = {["t"] = ((function() return 9 end)()), ["node_type"] = "element_prop"}, childrens = {((function() return 1 end)()), ((function() return 2 end)()), ((function() return 3 end)())}})}})

print("final do test")
