# Correção visual final — Portal da Empresa dentro de Intune

Este pacote foi preparado para a estrutura atual do repositório `KB-AxiaAgro`.

## O que será adicionado

- Novo submenu **Portal da Empresa** dentro da aba **Intune**.
- Governança.
- Implantação e personalização.
- Aplicativos.
- Operação.
- Solução de problemas.
- Evidências.
- Templates.
- Página inicial visual com banner, botões e seis cards de acesso rápido.
- Menu lateral mais largo, com categorias destacadas e marcadores somente nos documentos.

## Como enviar

1. Extraia o ZIP.
2. Abra a raiz do repositório no GitHub.
3. Clique em **Add file > Upload files**.
4. Arraste a pasta `docs` e o arquivo `mkdocs.yml` deste pacote, preservando os caminhos.
5. Confirme especialmente a atualização destes arquivos:
   - `docs/intune/portal-empresa/index.md` — ativa o banner e os cards;
   - `docs/stylesheets/extra.css` — aplica o visual e corrige o menu;
   - `mkdocs.yml` — mantém Portal da Empresa dentro de Intune.
6. Use a mensagem de commit `Corrige visual do Portal da Empresa`.
7. Confirme o commit na branch `main`.
8. Aguarde o build da Cloudflare ficar **Success/Deployed**.
9. Atualize o portal com `Ctrl + F5`.

Não envie este arquivo `LEIA-ME-ANTES-DE-SUBIR.md` se não quiser exibi-lo no repositório; ele não participa do portal.

## Para adicionar novos artigos no futuro

1. Coloque o arquivo na subpasta correta de `docs/intune/portal-empresa`.
2. Use nome sem espaços e sem acentos, por exemplo `novo-aplicativo.md`.
3. Inclua a página na categoria correspondente do `nav:` em `mkdocs.yml`.
4. Preserve a indentação com espaços e nunca use tabulação.

## Resultado esperado no menu

```text
Intune
├── Visão geral
└── Portal da Empresa
    ├── Visão geral
    ├── Governança
    ├── Implantação e Personalização
    ├── Aplicativos
    ├── Operação
    ├── Solução de Problemas
    ├── Evidências
    └── Templates
```

Não envie a pasta `site`: ela é gerada automaticamente durante o build.

## Validação obrigatória

Ao abrir **Intune > Portal da Empresa > Visão geral**, a página correta deve mostrar:

- banner verde com o título **Portal da Empresa**;
- botões **Consultar implantação** e **Adicionar aplicativos**;
- seis cards: Governança, Implantação, Aplicativos, Operação, Solução de Problemas e Evidências e Modelos.

Se ainda aparecer uma tabela simples, o arquivo `docs/intune/portal-empresa/index.md` antigo não foi substituído.
