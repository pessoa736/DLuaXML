# Roadmap — DSLX

Este documento registra o que está planejado, o que está em aberto e o que está fora do escopo do projeto. Não é um compromisso de prazo — é um registro de intenções.

## Em aberto (curto prazo)

Itens conhecidos que precisam de atenção:

- **Remover `loglua` do rockspec** — a dependência ainda aparece no rockspec mas o código `dslx/` não usa mais. Deve ser removida na próxima versão.
- **Atualizar URL do rockspec 2.0-1** — aponta para o repositório antigo (`pessoa736/DaviLuaXML`). O GitHub redireciona, mas vale corrigir.
- **Adicionar `run_all.lua`** — hoje os testes precisam ser rodados módulo a módulo (`./lua dslx/parser.lua`, etc.). Um script único que rode todos facilitaria a verificação antes de um release.

## Melhorias (médio prazo)

Itens que agregam qualidade sem mudar a API pública:

- **Mensagens de erro do parser com posição** — hoje o parser retorna uma tabela vazia em falha. Incluir linha e coluna onde a parse falhou tornaria erros de sintaxe muito mais fáceis de depurar.
- **Campo `source` nos nodes** — adicionar informação de posição (linha/coluna) em cada node da AST. Permite que ferramentas externas construam sourcemaps ou apontem erros para o `.dslx` original.
- **Atualizar a extensão VS Code** — a extensão foi mencionada no changelog 1.3-1 quando a extensão foi renomeada de `.lx` para `.dslx`. Vale verificar se está atualizada para a sintaxe 2.x.

## Features (longo prazo)

Itens que adicionam funcionalidade nova. Nenhum desses está confirmado — são candidatos:

- **Suporte a namespaces** — `<html.div/>` ou `<ns:tag/>`. Foi mencionado informalmente como possibilidade. Requer mudança no grammar do parser e no runtime.
- **CLI `dslxc` como script standalone** — a versão 1.x tinha um CLI para compilar arquivos e diretórios inteiros. A versão 2.x tem a API `compile` mas não tem um CLI pronto. Poderia ser um script separado, sem ser parte do módulo em si.
- **Sourcemap na geração de código** — a versão 1.x tinha suporte básico a sourcemap. Com o campo `source` nos nodes (ver médio prazo), seria possível re-implementar isso de forma mais robusta em cima do novo runtime.

## Fora do escopo

Coisas que não serão implementadas neste projeto:

- **Renderização HTML** — DSLX não é um template engine. Não vai gerar HTML.
- **Conformidade com a spec XML** — DSLX usa uma sintaxe inspirada em XML mas não tenta ser um parser XML completo. Namespaces, DTDs, entidades HTML e processamento de XML não fazem parte do objetivo.
- **Substituir o Lua** — DSLX é uma extensão de sintaxe. Todo `.dslx` vira Lua puro.
- **Suporte a Lua < 5.5** — o código usa `<const>` e outras features de Lua 5.5. Backports não estão planejados.
