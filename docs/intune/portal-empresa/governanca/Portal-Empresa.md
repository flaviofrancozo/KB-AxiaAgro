# Governança do Portal da Empresa

## Objetivo

Controlar o ciclo de vida dos aplicativos publicados no Microsoft Intune, da solicitação à retirada.

## Controles obrigatórios

1. Registrar dono, finalidade, público, licença e origem.
2. Validar assinatura, comandos silenciosos, requisitos e reinício.
3. Definir detecção que evite reinstalação e downgrade.
4. Homologar em piloto e registrar evidências.
5. Aprovar a atribuição definitiva.
6. Monitorar instalado, falha, pendente e não aplicável.
7. Retirar atribuições antes de excluir pacotes antigos.

## Segredos

Tokens, chaves e IDs privados não podem aparecer em GitHub, logs, screenshots ou scripts versionados.

## Estado registrado em 28/07/2026

- Portal da Empresa: implantado e validado.
- TeamViewer Host 15.79.4 Win32: piloto aprovado e produção atribuída a Todos os dispositivos.
- TeamViewer 15.43.7: sem atribuições e sem desinstalação forçada.
- Pendências: monitoramento final, rotação do token exposto e decisão de exclusão do pacote antigo.
