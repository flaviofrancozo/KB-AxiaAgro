# Adicionar aplicativos ao Portal da Empresa

## Escolha do tipo

| Tipo | Uso |
|---|---|
| Microsoft Store app (new) | Aplicativos mantidos pela Store |
| Windows app (Win32) | Comandos, detecção e atualização controlados |
| Line-of-business MSI | MSI simples, com menos flexibilidade |
| Web link | Atalho; não instala software |

## Fluxo

1. Obter instalador oficial e documentação.
2. Testar instalação/desinstalação silenciosas.
3. Empacotar como `.intunewin`, quando Win32.
4. Configurar metadados, comandos, requisitos e detecção.
5. Publicar em piloto.
6. Aprovar e expandir.
7. Monitorar e documentar.

**Disponível** permite escolha pelo usuário. **Obrigatório** instala automaticamente. **Desinstalar** remove do público atribuído e exige mudança aprovada.
