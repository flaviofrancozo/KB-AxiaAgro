# Pacote de publicação — Atualiza BLUE V2

Este pacote adiciona ao TechDocs/KB-AxiaAgro a documentação operacional, a documentação de governança, o procedimento de evidências e o script PowerShell da automação de distribuição para `D:\PERFIL\<hash>\Blue`.

## Estrutura

```text
KB-AxiaAgro_Atualiza_BLUE_V2/
├── docs/
│   ├── processos/automacoes/atualiza-blue-v2/index.md
│   ├── governanca/automacoes/atualiza-blue-v2/index.md
│   ├── assets/scripts/atualiza-blue-v2/
│   │   └── Atualiza_BLUE_V2.ps1
│   └── evidencias/atualiza-blue-v2/
│       ├── index.md
│       └── logs-publicaveis/
│           ├── README.md
│           ├── EXEMPLO_Atualiza_BLUE_V2_Principal.log
│           └── EXEMPLO_Atualiza_BLUE_V2_Resultado.csv
├── scripts/Atualiza_BLUE_V2/
│   ├── Atualiza_BLUE_V2.ps1
│   ├── README.md
│   └── Logs/.gitignore
├── GUIA_UPLOAD_DIRETO_GITHUB.md
└── mkdocs-nav-snippet.yml
```

## Como publicar

Extraia o ZIP e siga `GUIA_UPLOAD_DIRETO_GITHUB.md`. O envio será realizado pelo botão **Add file > Upload files**, diretamente na raiz do repositório.

Não envie o ZIP e não arraste a pasta externa `KB-AxiaAgro_Atualiza_BLUE_V2`. Envie somente as pastas `docs` e `scripts`, para que sejam mescladas às pastas já existentes.

## Aviso sobre os logs

O repositório GitHub `KB-AxiaAgro` é público. Mesmo que o site esteja protegido por autenticação Entra, os arquivos presentes no repositório podem ser acessíveis diretamente pelo GitHub.

Por isso:

- logs originais devem permanecer em repositório restrito de evidências;
- o site deve receber somente logs sanitizados;
- o `.gitignore` incluído bloqueia logs reais na pasta operacional;
- os arquivos `EXEMPLO_*` usam dados fictícios e podem ser publicados.
