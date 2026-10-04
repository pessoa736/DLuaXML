
--- Lê o conteúdo completo de um arquivo.
--- @param pathFile string Caminho do arquivo
--- @return string Conteúdo do arquivo
--- @error Se o arquivo não puder ser aberto
return function (pathFile)
    local file <close> = io.open(pathFile, "r+")
    if not file then
        error("não foi possivel abrir o arquivo: ".. pathFile)
    end

    local content = file:read("a")
    return content
end