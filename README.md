# TechDocs

Base pública e sanitizada de conhecimento técnico, construída com Markdown e Material for MkDocs.

> **Segurança:** este repositório é público. Não publique dados reais do tenant, usuários, dispositivos, IDs, endereços internos, logs, evidências, segredos, tokens, certificados ou chaves.

## Executar localmente

```bash
python -m venv .venv
python -m pip install -r requirements.txt
mkdocs serve
```

Acesse `http://127.0.0.1:8000`.

## Publicação

O workflow em `.github/workflows/publicar.yml` publica automaticamente o portal no GitHub Pages após alterações aprovadas na branch `main`.

Consulte [CONTRIBUTING.md](CONTRIBUTING.md) antes de incluir ou alterar conteúdo.



Teste de publicação automática no Cloudflare Workers — 03/08/2026
