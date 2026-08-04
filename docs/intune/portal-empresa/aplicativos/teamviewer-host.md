# TeamViewer Host 15.79.4 — exemplo realizado

## Contexto

Migração do MSI antigo 15.43.7 para Win32 15.79.4, com detecção compatível com instalações MSI e EXE.

## Instalação

```text
msiexec.exe /i "TeamViewer_Host.msi" /qn /norestart CUSTOMCONFIGID=SEU_CUSTOMCONFIGID ASSIGNMENTID="SEU_ASSIGNMENTID"
```

## Desinstalação

```text
msiexec.exe /x "{PRODUCT-CODE-DO-MSI-VALIDADO}" /qn /norestart
```

Não versione IDs reais, tokens ou chaves.

## Detecção

Use `scripts/Detectar-TeamViewerHost.ps1`. Ela reconhece a versão 15.79.4 ou superior e evita downgrade.

## Migração

1. Validar o Win32 no piloto.
2. Remover atribuições do pacote antigo; manter **Desinstalar** vazio.
3. Atribuir o novo pacote ao público aprovado.
4. Monitorar e manter o antigo sem atribuições até o encerramento.

## Fontes

- [TeamViewer — Win32 no Intune](https://www.teamviewer.com/en/global/support/knowledge-base/teamviewer-remote/deployment/mass-deployment-user-guide/create-a-package-in-microsoft-endpoint-manager-via-intune--win32/)
- [TeamViewer — implantação Host](https://www.teamviewer.com/en/global/support/knowledge-base/teamviewer-remote/deployment/mass-deployment-user-guide/deploy-teamviewer-host-or-full-client-9-10/)
