# DSLX - Davi System Lua-XML

<div style="display: flex; justify-content: center; justify-self: left;">
    <img src="doc/DSLX_icon.png" width="128px" />
    <p>Um interpretador JSX-like para Lua.</p>
    <a href="https://luarocks.org/modules/pessoa736/daviluaxml">
        <img src="https://img.shields.io/luarocks/v/pessoa736/daviluaxml" />
    </a>
</div>

> [!WARNING]
> Projeto experimental. APIs podem mudar sem aviso.

## sumário

- [DSLX - Davi System Lua-XML](#dslx---davi-system-lua-xml)
  - [sumário](#sumário)
  - [sobre o que se trata o DSLX?](#sobre-o-que-se-trata-o-dslx)
  - [instalação](#instalação)
  - [como funciona?](#como-funciona)
    - [sintaxe](#sintaxe)
    - [importação dos .dslx através do require](#importação-dos-dslx-através-do-require)
  - [API](#api)
    - [parser](#parser)
    - [runtime](#runtime)
    - [compile](#compile)
    - [import](#import)
    - [is\_element](#is_element)
  - [o que DSLX não é](#o-que-dslx-não-é)
  - [licença](#licença)

## sobre o que se trata o DSLX?

DSLX (ou Davi System: Lua XML) é um módulo que fornece ao Lua a capacidade de interpretar arquivos .dslx no qual permite ler código Lua e transformar o XML em Lua puro num mesmo arquivo e depois executa, parecido com o JSX.

A partir da versão 2.0 o módulo foi renomeado para `dslx` e reescrito sobre [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/): o parser transforma o código em uma lista de nodes e o runtime gera (e executa) código Lua puro a partir deles.

```mermaid
graph TD;
    A("código em DSLX") --> B("parser (LPeg)");
    B --> C("lista de nodes");
    C --> D("runtime: make_new_code");
    D --> E("código Lua puro");
    E --> F("executa");
```

## instalação

```bash
luarocks install daviluaxml
```

Requisitos: Lua 5.5 e [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/) (instalado automaticamente como dependência).

## como funciona?

No .dslx qualquer função definida no ambiente do Lua pode ser chamada no formato do XML. A tag vira uma chamada de função que recebe uma única tabela com o nome da tag, as props e os childrens:

```lua
soma{name = "soma", props = { t = 9 }, childrens = { 1, 2, 3 }}
```

Um exemplo completo, direto no Lua:

```lua
local dslx = require("dslx")
local parser, runtime = dslx.parser, dslx.runtime

local code = [[
local function soma(el)
    local total = el.props.t
    for _, v in ipairs(el.childrens) do total = total + v end
    return total
end

print(<soma t={9}>{1}{2}{3}</soma>)
]]

local nodes = parser(code)
print(runtime:make_new_code(nodes)) -- código Lua gerado
runtime:runtime(nodes)             -- executa: 15
```

O `parser` devolve a lista de nodes do código, `runtime:make_new_code` gera o código Lua equivalente e `runtime:runtime` compila e executa. O `print(<soma t={9}>{1}{2}{3}</soma>)` vira:

```lua
print(soma{name="soma", props={t=9}, childrens={1, 2, 3}})
```

As expressões `{...}` entram direto no código gerado, sem wrappers. Note que a função `soma` está dentro da string `code`: ela vira parte do código Lua gerado, então locais do script externo não são visíveis pra ela.

### sintaxe

Props e childrens podem ser strings, expressões Lua, booleans ou elementos aninhados (conteúdo de um arquivo `.dslx`):

```dslx
local function card(el)
    -- props
    el.props.titulo   -- "olá"    (string)
    el.props.largura  -- 10       (expressão Lua)
    el.props.destaque -- true     (boolean, só o nome da prop)

    -- childrens
    el.childrens[1]    -- "texto " (texto literal)
    el.childrens[2]    -- 42       (expressão Lua)
    el.childrens[3]    -- tabela   (elemento aninhado)
end

-- tag completa
local c1 = <card titulo="olá" largura={10} destaque>texto {40 + 2} <card/></card>

-- tag self-close
local c2 = <card titulo="tchau"/>
```

Um elemento aninhado vira uma chamada ao componente dentro da tabela de childrens: o valor retornado por ele é o que aparece em `el.childrens`. Se o componente retornar `nil`, o children simplesmente não existe. E como em Lua os valores são avaliados antes do constructor da tabela, o elemento aninhado roda antes do pai.

### importação dos .dslx através do require

Quando seu projeto importa o módulo do DSLX ele carrega o loader do DSLX, sobrepondo o require no ambiente no qual foi importado, permitindo importar o .dslx da mesma forma do .lua:

```lua
package.path = package.path .. ";./dslx/test/?.dslx"
local dslx = require("dslx") -- instala o searcher automaticamente
local ok = require("1")     -- carrega e executa 1.dslx
print("import ok:", ok)     -- true
```

## API

### parser

```lua
local nodes = parser(code)
```

Transforma o código em uma lista de nodes. Cada node tem um `node_type`: `lua`, `script`, `string`, `children`, `props`, `element`, `full_element`, `element_self_close` ou `element_prop`. Em falha, devolve uma tabela vazia.

### runtime

- `runtime:addHandler(name, func)` — registra um handler customizado por `node_type` (`name` pode ser uma string ou uma tabela de nomes)
- `runtime:expr(node, handlers)` — devolve o código Lua de um node
- `runtime:make_new_code(nodes, handlers)` — devolve o código Lua completo
- `runtime:runtime(nodes, handlers)` — compila e executa o código

### compile

```lua
compile({
    input = "arquivo.dslx",       -- arquivo .dslx de entrada (ou código, com asfile = false)
    asfile = true,                -- lê input como arquivo
    tofile = true,                -- escreve a saída em arquivo (false: devolve o código)
    run = false,                  -- executa o resultado
    output_name = nil,            -- nome do arquivo de saída (default: nome do input)
    output_ext = ".lua",          -- extensão da saída
    output_dir = ".",            -- diretório da saída
    relative_actual_file = false, -- resolve caminhos relativos ao arquivo que chamou
})
```

Com `tofile = false` e `run = false` o `compile` devolve o código gerado; com `run = true` executa o resultado.

### import

- `import.install()` / `import.uninstall()` — adiciona/remove o searcher de .dslx do `require()`
- `import.loadfile(filename, opts)` — carrega um .dslx direto
- `import.reload(name)` — recarrega um módulo já importado
- `import.clear()` — limpa os módulos .dslx carregados e o cache
- `import.path` — o `package.path` usado pelo searcher
- `import.use_cache` — cache de compilação (default: true)

### is_element

```lua
local ok, err, nparams = is_element(minha_funcao)
```

Global instalada pelo `require("dslx")`. Valida se uma função serve como elemento DSLX: precisa ser uma função que recebe exatamente 1 argumento (a tabela do elemento).

Retorna `true` se serve; senão `false`, a mensagem de erro e o número de parâmetros da função.

## o que DSLX não é

- **não é html**, html é uma linguagem web para criação de páginas, o DSLX é um Lua+XML. e XML é uma linguagem de estruturação rígida para sistemas.

- **não é um substituto do Lua**, o DSLX é para funcionar em conjunto ao Lua


## licença

Esse módulo é MIT. Sinta-se livre para brincar e fazer o que quiser a sua fork desse projeto, mantendo os créditos :)


