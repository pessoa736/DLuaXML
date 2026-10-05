# Copilot Instructions - DaviLuaXML (dslx)

## Sobre o Projeto

DaviLuaXML é uma biblioteca Lua que permite usar sintaxe XML diretamente no código Lua, similar ao JSX no JavaScript. A partir da versão 2.0-1 o módulo foi renomeado para `dslx` e reescrito sobre LPeg: `<tag prop="x">texto</tag>` vira uma chamada `tag({name = "tag", props = {prop = "x"}, childrens = {"texto"}})`.

- **Linguagem:** Lua 5.5 (use `<const>`, `<close>` quando apropriado)
- **Gerenciador de pacotes:** LuaRocks (wrappers locais `./lua` e `./luarocks` na raiz do repo)
- **Parser:** LPeg (gramática PEG definida em `dslx/parser.lua`)
- **Repositório:** https://github.com/pessoa736/DLuaXML (renomeado; URLs antigas redirecionam)
- **LuaRocks:** https://luarocks.org/modules/pessoa736/daviluaxml

## Estrutura do Projeto

```
dslx/
├── init.lua      # Exporta a API completa e instala o searcher no require()
├── parser.lua    # Parser LPeg: código com XML -> lista de nodes
├── runtime.lua   # Handlers por node_type, gera e executa o código Lua
├── compile.lua   # Compila arquivos .dslx (tofile, output_dir, run, etc)
├── import.lua    # require() de .dslx (install/uninstall/loadfile/reload/clear)
├── readFile.lua  # Leitura de arquivos
└── test/dslx/    # Fixtures de teste (1.dslx, test.lua gerado)
rockspecs/        # Rockspecs de cada release (daviluaxml-X.Y-Z.rockspec)
doc/              # Copiado pelo rockspec
```

## Wrappers locais (use sempre)

- `./lua <arquivo>` — roda Lua 5.5 com o `package.path` apontando pra `lua_modules/` (onde o lpeg tá instalado). Sem argumentos abre o REPL interativo.
- `./luarocks <cmd>` — LuaRocks com `--project-tree lua_modules`.
- O `lua` do sistema não encontra o lpeg; sempre use o wrapper.

## API principal

- `parser(code)` — retorna a lista de nodes (`node_type`: `lua`, `script`, `string`, `children`, `props`, `element`, `full_element`, `element_self_close`).
- `runtime` — `addHandler(name, func)` registra handlers customizados por node_type; `expr(node)`, `make_new_code(nodes)` e `runtime(nodes)` geram/executam o código.
- `compile(config)` — compila `.dslx`; config: `input`, `asfile`, `tofile`, `run`, `output_name`, `output_ext`, `output_dir`, `relative_actual_file`.
- `import` — `install()`/`uninstall()` adiciona/remove o searcher do `require()` pra `.dslx`; `loadfile`, `reload(name)`, `clear()`, `path`, `use_cache`.

## Ao Implementar uma Nova Feature

### Antes de começar:
1. Verificar a versão atual no rockspec mais recente em `rockspecs/`
2. Verificar se o código está atualizado com o repositório remoto
3. Entender o padrão de código existente (documentação com `---@param`, `---@return`)

### Durante o desenvolvimento:
1. Seguir o padrão de documentação existente com comentários `--[[]]` e annotations
2. Novos tipos de node ou comportamentos de geração entram como handlers no `runtime.lua` (`addHandler`)

### Depois de implementar:
1. Atualizar/adicionar o bloco `on_test` no final do módulo afetado
2. Rodar os testes de todos os módulos (ver seção Testes)
3. Se tudo passar, seguir para o release

## Processo de Upload/Release

### Commits:
- Commits separados por mudança lógica
- Prefixo convencional conforme o tipo: `feat:`, `fix:`, `chore:` ou `remove:`
- Mensagem informal em português, em um parágrafo só
- Exemplo: `feat: adicionei suporte pra tags com namespace tipo html.div, agora funciona certinho`

### Versionamento (padrão `x.y-z`):
- **Feature adicionada:** incrementar `y` → `x.(y+1)-1`
- **Bug corrigido:** incrementar `z` → `x.y-(z+1)`
- **Breaking change:** incrementar `x` → `(x+1).0-1`

### Passos do release:
1. Copiar o rockspec dev mais recente pra `rockspecs/daviluaxml-X.Y-Z.rockspec`, atualizando versão, tag e o `detailed` com as principais mudanças
2. Validar com `./luarocks lint rockspecs/daviluaxml-X.Y-Z.rockspec`
3. Commit das mudanças
4. Criar tag git: `git tag X.Y-Z`
5. Push com tags: `git push && git push --tags` (se o push HTTPS falhar por credenciais, use a URL SSH direta: `git push git@github.com:pessoa736/DLuaXML.git <branch> --tags`)
6. Criar release no GitHub com as principais mudanças
7. Upload no LuaRocks: `./luarocks upload rockspecs/daviluaxml-X.Y-Z.rockspec --api-key=CHAVE`

## Padrões de Código

### Documentação de funções:
```lua
--- Descrição breve da função.
--- Descrição mais detalhada se necessário.
---
--- @param nome tipo Descrição do parâmetro
--- @return tipo Descrição do retorno
local function minhaFuncao(nome)
    -- implementação
end
```

### Tratamento de erros:
- Erros de compilação/execução: `error(msg, 0)` pra não poluir o traceback
- O import devolve `nil, err` em falhas de leitura/compilação

## Testes

Não tem `run_all.lua`; cada módulo tem um bloco `on_test` no final que roda quando o arquivo é executado diretamente:

```bash
./lua dslx/parser.lua    # Testes do parser
./lua dslx/runtime.lua    # Testes do runtime
./lua dslx/compile.lua    # Compila test/dslx/1.dslx -> test/dslx/test.lua
./lua dslx/import.lua     # require() de test/dslx/1.dslx
```

Padrão de teste (dentro do `if on_test then ... end`):
```lua
local function test_nome_do_teste()
    -- arrange
    local input = "..."
    
    -- act
    local result = funcao(input)
    
    -- assert
    assert(result == esperado, "mensagem de erro")
end
```

## Comandos Úteis

```bash
# Rodar os testes de um módulo
./lua dslx/parser.lua

# Testar o parser manualmente
./lua -e 'local p = require("dslx.parser") print(p("<div/>"))'

# Compilar um arquivo .dslx pra Lua
./lua -e 'require("dslx.compile"){input = "arquivo.dslx", tofile = true}'

# Instalar localmente para teste
./luarocks make daviluaxml-dev-1.rockspec

# Upload para LuaRocks
./luarocks upload rockspecs/daviluaxml-X.Y-Z.rockspec --api-key=CHAVE
```

## Observações

- `loglua` ainda tá listado como dependência no rockspec, mas o código `dslx/` não usa mais. Vale remover a dep no próximo rockspec.
- O rockspec 2.0-1 aponta pra URL antiga do repo (`pessoa736/DaviLuaXML`); o GitHub redireciona, mas vale atualizar pro novo nome na próxima versão.
