# Publicar o KB no GitHub

## Primeira publicação pelo navegador

1. Extraia o pacote `KB-AxiaAgro-v1.0.zip` no computador. Não envie o arquivo ZIP diretamente.
2. Abra o repositório `flaviofrancozo/KB-AxiaAgro`.
3. Clique em **Add file → Upload files**.
4. Abra a pasta extraída e arraste **o conteúdo interno**, inclusive `.github`, para a área de upload. Se o GitHub solicitar confirmação para substituir o `README.md` existente, confirme.
5. Confirme que `mkdocs.yml`, `docs`, `templates`, `.github` e os arquivos institucionais aparecem na raiz.
6. Em **Commit changes**, informe `docs: cria estrutura inicial do AxiaAgro TechDocs`.
7. Se disponível, escolha criar uma nova branch e abrir um Pull Request; caso contrário, confirme o commit na `main`.

!!! warning "Não envie a pasta externa"
    A raiz do repositório deve conter diretamente o arquivo `mkdocs.yml`. Não deixe os arquivos aninhados em outra pasta chamada `KB-AxiaAgro`.

## Ativar o GitHub Pages

1. Abra **Settings → Pages**.
2. Em **Build and deployment → Source**, selecione **GitHub Actions**.
3. Abra a aba **Actions** e acompanhe o workflow **Publicar AxiaAgro TechDocs**.
4. Após a conclusão, acesse `https://flaviofrancozo.github.io/KB-AxiaAgro/`.

## Atualizações futuras

Crie uma branch, altere os arquivos Markdown, abra um Pull Request e publique somente após revisão técnica e de sanitização.
