--- MIT - Davi/Pessoa736 (2026)

---@diagnostic disable: need-check-nil, duplicate-set-field, duplicate-doc-field, duplicate-doc-alias, duplicate-doc-param


--- Lê o conteúdo completo de um arquivo.
--- @param pathFile string Caminho do arquivo
--- @return string Conteúdo do arquivo
--- @error Se o arquivo não puder ser aberto
return function(pathFile)
  local file, err = io.open(pathFile, "rb")
  if not file then
    error("não foi possível abrir o arquivo: " .. tostring(err), 2)
  end
  local content = file:read("*a")
  file:close()
  if not content then error("não foi possível ler o arquivo: " .. pathFile, 2) end
  return content
end