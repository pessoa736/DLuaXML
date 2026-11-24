# AGENT.md — Uso de IA neste projeto

Este arquivo define o que um agente de IA (GitHub Copilot, Claude, ChatGPT, etc.) pode e não pode fazer neste repositório.

## Regra geral

IA serve para **tirar dúvidas** e **documentar**. Nada além disso.

## O que IA pode fazer

### Tirar dúvidas
- Explicar como uma parte do código funciona
- Responder perguntas sobre a API (`parser`, `runtime`, `compile`, `import`)
- Ajudar a entender o comportamento do parser LPeg ou do sistema de handlers
- Sugerir como usar uma feature existente

### Documentar
- Atualizar ou escrever comentários no código
- Adicionar anotações LSP (`---@param`, `---@return`) em código já existente
- Melhorar READMEs, CHANGELOG, ROADMAP e guias
- Descrever o comportamento de uma função para fins de documentação

### Executar testes (somente para verificar o estado do código)
```bash
./lua dslx/parser.lua    # verifica o parser
./lua dslx/runtime.lua   # verifica o runtime
./lua dslx/compile.lua   # verifica a compilação
./lua dslx/import.lua    # verifica o import
```

Rodar os testes é permitido **somente para verificar se o código está funcionando**. O resultado dos testes é informação — não é ponto de partida para uma refatoração ou correção.

## O que IA não pode fazer

- Implementar features novas
- Refatorar ou reorganizar código existente
- Corrigir bugs (mesmo que óbvios)
- Adicionar, remover ou alterar dependências
- Criar ou modificar rockspecs
- Fazer commits, push ou releases
- Propor mudanças de arquitetura
- Alterar a lógica de qualquer módulo (`parser.lua`, `runtime.lua`, `compile.lua`, `import.lua`, `init.lua`, `readFile.lua`)
- Abrir ou fechar issues e pull requests

## Por que essa restrição?

DSLX é um projeto pessoal com escolhas de design intencionais. IA pode ser muito útil para entender e documentar o código, mas as decisões de implementação — o que mudar, o que não mudar e o porquê — pertencem ao autor.

Código gerado por IA tende a introduzir padrões externos ao estilo do projeto, criar abstrações desnecessárias ou resolver problemas de formas que o autor não reconheceria como suas. Isso prejudica a coerência do projeto a longo prazo.

## Se você encontrou um problema

Se usou IA para explorar o código e identificou um bug ou inconsistência, abra uma issue descrevendo o problema com clareza. Não envie PRs com código gerado por IA.
