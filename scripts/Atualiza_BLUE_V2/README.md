# Script operacional

Arquivo:

```text
Atualiza_BLUE_V2.ps1
```

Local recomendado no servidor:

```text
D:\PERFIL\TEMP\Automacao\Atualiza_BLUE_V2.ps1
```

Execução:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "D:\PERFIL\TEMP\Automacao\Atualiza_BLUE_V2.ps1"
```

O script pergunta a origem e se a execução deve ocorrer imediatamente ou ser agendada. Não mova o arquivo depois de criar a tarefa.

A pasta `Logs` deste repositório possui bloqueio para `.log`, `.csv` e `.txt` reais. Preserve evidências originais em armazenamento restrito.

