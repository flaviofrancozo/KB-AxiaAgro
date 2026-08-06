# Atualiza BLUE V2 — distribuição automatizada

## Objetivo

Distribuir um ou mais arquivos e subpastas de uma origem informada pelo operador para todas as pastas de perfil que seguem o padrão:

```text
D:\PERFIL\<hash>\Blue
```

A automação substitui o arquivo existente somente quando a origem é mais nova. Se o destino estiver em uso, o hash permanece pendente e é processado novamente em ciclos até a conclusão.

## Arquivo da automação

```text
scripts/Atualiza_BLUE_V2/Atualiza_BLUE_V2.ps1
```

[Baixar o script PowerShell](../../../assets/scripts/atualiza-blue-v2/Atualiza_BLUE_V2.ps1)

Local operacional recomendado:

```text
D:\PERFIL\TEMP\Automacao\Atualiza_BLUE_V2.ps1
```

Não mova ou renomeie o script depois de criar uma tarefa agendada, pois o Agendador guarda o caminho completo do arquivo.

## Requisitos

- Windows PowerShell 5.1 ou PowerShell 7;
- Robocopy disponível no Windows;
- permissão de leitura na origem;
- permissão de gravação em `D:\PERFIL`;
- execução como administrador para criar tarefa agendada como `SYSTEM`;
- volume `D:` disponível no horário da execução.

## Funcionamento

1. O operador informa a pasta de origem.
2. A ferramenta pergunta se deve executar agora ou agendar.
3. No início da execução efetiva, o script inventaria as pastas-hash diretamente abaixo de `D:\PERFIL`.
4. Um `hash.txt` limpo é criado ao lado do `.ps1`.
5. O primeiro ciclo processa todos os hashes.
6. Códigos Robocopy de `0` a `7` encerram aquele hash como sucesso.
7. Código `8` ou superior mantém o hash para o ciclo seguinte.
8. O próximo ciclo processa somente os pendentes.
9. Ao concluir, os logs temporários são consolidados e removidos.

## Regras de cópia

| Situação | Ação |
|---|---|
| Arquivo não existe no destino | Copiar |
| Origem mais nova | Substituir |
| Origem e destino equivalentes | Ignorar |
| Destino mais novo | Preservar |
| Arquivo em uso | Registrar e tentar no próximo ciclo |
| Arquivo extra no destino | Preservar |
| Subpasta na origem | Copiar recursivamente |

A automação não usa `/MIR` nem `/PURGE`; portanto, não exclui arquivos extras do destino.

## Execução imediata

Abra o PowerShell como administrador:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "D:\PERFIL\TEMP\Automacao\Atualiza_BLUE_V2.ps1"
```

Informe a origem, por exemplo:

```text
D:\PERFIL\TEMP\Update060826
```

Responda `N` quando aparecer:

```text
Deseja AGENDAR esta execução? Digite S para SIM ou N para executar AGORA
```

## Execução agendada

1. Execute o `.ps1` como administrador.
2. Informe a origem.
3. Responda `S`.
4. Informe a data no formato `dd/MM/yyyy`.
5. Informe o horário no formato `HH:mm`.
6. Confirme a mensagem de criação.

A tarefa será registrada com nome semelhante a:

```text
PERFIL - Atualiza BLUE V2 - 20260807-2330
```

Características:

- execução única;
- identidade `SYSTEM`;
- privilégios elevados;
- não exige usuário conectado;
- executa assim que possível se o computador estiver indisponível no horário;
- não possui limite de duração para os ciclos.

Para conferir:

```powershell
Get-ScheduledTask -TaskName "PERFIL - Atualiza BLUE V2 -*" |
    Select-Object TaskName, State
```

Para consultar o resultado:

```powershell
Get-ScheduledTaskInfo -TaskName "NOME EXATO DA TAREFA" |
    Format-List LastRunTime, LastTaskResult, NextRunTime
```

## Progresso exibido

Durante a execução manual:

```text
[CICLO 2] 60,0% | PENDENTE | 0b1e5e5c-ef36-42d8 | Robocopy 8
```

Ao final de cada ciclo:

```text
FIM DO CICLO 2
Processados no ciclo : 5
Concluídos no ciclo  : 3
Pendentes no ciclo   : 2
Pendentes restantes  : 2
Conclusão geral      : 99,8%
```

## Logs

Local:

```text
D:\PERFIL\TEMP\Logs
```

Arquivos preservados após a conclusão:

```text
Atualiza_BLUE_V2_Principal_YYYYMMDD_HHMMSS.log
Atualiza_BLUE_V2_Resultado_YYYYMMDD_HHMMSS.csv
```

O CSV registra data/hora, ciclo, percentual, hash, destino, status, código Robocopy e contagens. O log principal contém a transcrição e a saída detalhada do Robocopy.

## Códigos Robocopy

| Código | Interpretação operacional |
|---:|---|
| 0 | Nenhuma cópia necessária |
| 1 | Arquivos copiados |
| 2–7 | Diferenças ou extras, sem falha fatal |
| 8–15 | Uma ou mais falhas; permanece pendente |
| 16 | Erro grave de caminho, acesso, parâmetro ou ambiente |

## Interrupção

Para interromper uma execução manual:

```text
Ctrl+C
```

Os arquivos temporários são consolidados pelo bloco de encerramento. Se houver interrupção forçada do processo ou desligamento, valide `TEMP_Pendentes_*.txt` e os arquivos `TEMP_*` eventualmente remanescentes.

## Validação pós-execução

```powershell
$Origem = "D:\PERFIL\TEMP\Update060826"
$Destino = "D:\PERFIL\HASH-DE-TESTE\Blue"

Get-ChildItem -LiteralPath $Origem -File -Recurse |
    Select-Object FullName, Length, LastWriteTime

Get-ChildItem -LiteralPath $Destino -File -Recurse |
    Select-Object FullName, Length, LastWriteTime
```

Para arquivos críticos, compare SHA-256:

```powershell
Get-FileHash "D:\PERFIL\TEMP\Update060826\blue.exe" -Algorithm SHA256
Get-FileHash "D:\PERFIL\HASH-DE-TESTE\Blue\blue.exe" -Algorithm SHA256
```

## Solução de problemas

### Código 8

Normalmente representa arquivo em uso, acesso negado ou falha parcial. O script tentará novamente. Consulte o log principal.

### Código 16

Valide:

```powershell
Test-Path "D:\PERFIL\TEMP\Update060826"
Test-Path "D:\PERFIL\HASH-DE-TESTE\Blue"
```

Teste gravação:

```powershell
$Teste = "D:\PERFIL\HASH-DE-TESTE\Blue\teste_permissao.txt"
"Teste" | Out-File -LiteralPath $Teste -Force
Test-Path -LiteralPath $Teste
Remove-Item -LiteralPath $Teste -Force
```

### A tarefa não iniciou

- confirme que o servidor estava ligado;
- confira `LastTaskResult`;
- confirme que o `.ps1` não foi movido;
- confirme que a origem ainda existe;
- valide se `SYSTEM` acessa a origem;
- unidades de rede mapeadas no perfil do usuário não ficam disponíveis para `SYSTEM`; prefira caminho UNC com permissões específicas.

## Rollback

A automação substitui arquivos e não mantém automaticamente a versão anterior. O rollback depende de backup ou cópia anterior aprovada.

Procedimento:

1. Interrompa a execução.
2. Identifique a versão distribuída pelo log e pelo hash SHA-256.
3. Coloque a versão anterior aprovada em uma pasta de origem separada.
4. Execute a mesma ferramenta usando essa origem.
5. Valide uma pasta piloto.
6. Preserve os logs do rollback junto à mudança original.

Não execute rollback sem confirmar compatibilidade da aplicação com a versão anterior.
