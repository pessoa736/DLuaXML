# perguntas.md

Dúvidas levantadas durante a análise do projeto. Responda quando puder.

---

**1. `loglua` no rockspec**
A dependência `loglua` ainda aparece no rockspec mas o código não usa mais. Pode remover na próxima versão, ou tem algum plano de reintroduzir?

**2. URL antiga no rockspec 2.0-1**
O rockspec 2.0-1 aponta para `pessoa736/DaviLuaXML` (nome antigo). O GitHub redireciona, mas vale corrigir? Ou deixa pra próxima versão e ignora os anteriores?

**3. Pasta `.github` removida**
O `copilot-instructions.md` foi removido e a pasta `.github` junto. Tem intenção de usar GitHub Actions, templates de issue/PR ou qualquer outro recurso que precise da pasta `.github` futuramente?

**4. Extensão VS Code**
O changelog 1.3-1 menciona uma extensão VS Code atualizada para reconhecer `.dslx`. Essa extensão ainda existe? Está publicada? Vale linkar no README?

**5. Namespace em tags**
Suporte a `<html.div/>` ou `<ns:tag/>` aparece como candidato no roadmap. É algo que você quer no futuro, ou coloquei lá por completude e pode remover?

**6. `dslxc` CLI**
A versão 1.x tinha um CLI. Tem interesse em trazer de volta como script standalone, ou a API `compile` já resolve tudo que você precisa?

**7. Formato de commit**
O padrão atual é português informal (`feat: adicionei...`). Quer manter assim ou tem preferência diferente?
