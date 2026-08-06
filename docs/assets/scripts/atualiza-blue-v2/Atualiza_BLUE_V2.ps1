<#
.SYNOPSIS
    Atualiza arquivos de uma pasta de origem em D:\PERFIL\<hash>\Blue.

.DESCRIPTION
    - Solicita interativamente somente a pasta de origem.
    - Pergunta se a execução deve ocorrer agora ou ser agendada para data/hora futura.
    - No modo agendado, registra uma tarefa única como SYSTEM e executa sem
      interação do usuário no horário programado.
    - Gera automaticamente hash.txt ao lado do próprio script, usando somente
      as pastas-hash diretamente abaixo de D:\PERFIL.
    - Copia arquivos novos e substitui somente quando a origem for mais nova.
    - Se um arquivo estiver em uso/bloqueado, registra a falha e mantém o hash
      pendente para o próximo ciclo.
    - Repete somente os hashes pendentes até que todos concluam com sucesso.
    - Não encerra processos e não apaga arquivos extras existentes no destino.
    - Mantém um relatório CSV e consolida toda a execução em um único log principal.
    - Logs temporários de ciclo são removidos ao final.

    Compatível com Windows PowerShell 5.1 e PowerShell 7+.
#>

param(
    # Usado internamente pelo Agendador de Tarefas. Na execução manual, deixe vazio.
    [string]$OrigemAgendada = "",

    # Indica que a chamada veio do Agendador e impede perguntas interativas.
    [switch]$ExecucaoAgendada
)

Clear-Host

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURAÇÕES REUTILIZÁVEIS
# ============================================================

$PastaRaizDestino = "D:\PERFIL"
$SubpastaDestino  = "Blue"
$IntervaloCiclos  = 15
$PadraoHash       = "(?i)(?<Hash>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4})"

# ============================================================
# FUNÇÕES
# ============================================================

function Ler-PastaOrigem {
    while ($true) {
        $Valor = (Read-Host "Informe a PASTA DE ORIGEM dos arquivos").Trim().Trim('"')

        if (Test-Path -LiteralPath $Valor -PathType Container) {
            return (Resolve-Path -LiteralPath $Valor).Path
        }

        Write-Host "Pasta não encontrada: $Valor" -ForegroundColor Red
    }
}

function Testar-Administrador {
    try {
        $Identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal  = New-Object Security.Principal.WindowsPrincipal($Identidade)

        return $Principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    catch {
        return $false
    }
}

function Ler-DataHoraAgendamento {
    while ($true) {
        Write-Host ""
        $DataInformada = (Read-Host "Informe a DATA da execução (dd/MM/yyyy)").Trim()
        $HoraInformada = (Read-Host "Informe o HORÁRIO da execução (HH:mm)").Trim()

        $TextoDataHora = "$DataInformada $HoraInformada"
        $DataHora      = [datetime]::MinValue
        $Cultura       = [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")
        $Estilo        = [System.Globalization.DateTimeStyles]::None

        $Valida = [datetime]::TryParseExact(
            $TextoDataHora,
            "dd/MM/yyyy HH:mm",
            $Cultura,
            $Estilo,
            [ref]$DataHora
        )

        if (-not $Valida) {
            Write-Host "Data ou horário inválido. Exemplo: 07/08/2026 23:30" -ForegroundColor Red
            continue
        }

        if ($DataHora -le (Get-Date)) {
            Write-Host "O agendamento precisa estar no futuro." -ForegroundColor Red
            continue
        }

        return $DataHora
    }
}

function Criar-AgendamentoDistribuicao {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Origem,

        [Parameter(Mandatory = $true)]
        [datetime]$DataHora,

        [Parameter(Mandatory = $true)]
        [string]$CaminhoScript
    )

    if (-not (Testar-Administrador)) {
        throw "Para criar a tarefa como SYSTEM, abra o PowerShell como Administrador e execute o script novamente."
    }

    if ([string]::IsNullOrWhiteSpace($CaminhoScript) -or -not (Test-Path -LiteralPath $CaminhoScript -PathType Leaf)) {
        throw "Não foi possível determinar o caminho do próprio script. Salve o .ps1 em um local permanente antes de agendar."
    }

    $NomeTarefa = "PERFIL - Atualiza BLUE V2 - {0}" -f $DataHora.ToString("yyyyMMdd-HHmm")
    $PowerShellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

    # Escapa aspas caso algum caminho contenha caracteres especiais.
    $ScriptSeguro = $CaminhoScript.Replace('"', '\"')
    $OrigemSegura = $Origem.Replace('"', '\"')

    $Argumentos = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -ExecucaoAgendada -OrigemAgendada "{1}"' -f `
        $ScriptSeguro,
        $OrigemSegura

    $DiretorioTrabalho = Split-Path -Parent $CaminhoScript

    $Acao = New-ScheduledTaskAction `
        -Execute $PowerShellExe `
        -Argument $Argumentos `
        -WorkingDirectory $DiretorioTrabalho

    $Gatilho = New-ScheduledTaskTrigger `
        -Once `
        -At $DataHora

    # SYSTEM permite executar sem usuário conectado e sem armazenar senha.
    $PrincipalTarefa = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest

    # StartWhenAvailable executa assim que possível caso o computador esteja
    # desligado exatamente no horário. ExecutionTimeLimit zero = sem limite,
    # preservando a lógica de ciclos até todos os hashes concluírem.
    $Configuracoes = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit ([TimeSpan]::Zero)

    Register-ScheduledTask `
        -TaskName $NomeTarefa `
        -Action $Acao `
        -Trigger $Gatilho `
        -Principal $PrincipalTarefa `
        -Settings $Configuracoes `
        -Description "Atualiza BLUE V2: distribuição automática para D:\PERFIL\<hash>\Blue. Origem: $Origem" `
        -Force |
        Out-Null

    return $NomeTarefa
}

function Gravar-ResultadoCsv {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Registro,

        [Parameter(Mandatory = $true)]
        [string]$CaminhoCsv
    )

    if (Test-Path -LiteralPath $CaminhoCsv) {
        $Registro | Export-Csv -LiteralPath $CaminhoCsv -Delimiter ";" -NoTypeInformation -Encoding UTF8 -Append
    }
    else {
        $Registro | Export-Csv -LiteralPath $CaminhoCsv -Delimiter ";" -NoTypeInformation -Encoding UTF8
    }
}

function Obter-ResumoRobocopy {
    param(
        [object[]]$Saida
    )

    $Resumo = [ordered]@{
        TotalArquivos    = ""
        ArquivosCopiados = ""
        ArquivosIgnorados = ""
        ArquivosFalha    = ""
    }

    $LinhaArquivos = $Saida |
        ForEach-Object { [string]$_ } |
        Where-Object { $_ -match '^\s*(Files|Arquivos)\s*:' } |
        Select-Object -Last 1

    if ($LinhaArquivos -and $LinhaArquivos -match ':\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?') {
        $Resumo.TotalArquivos     = $Matches[1]
        $Resumo.ArquivosCopiados  = $Matches[2]
        $Resumo.ArquivosIgnorados = $Matches[3]
        $Resumo.ArquivosFalha     = $Matches[5]
    }

    return [PSCustomObject]$Resumo
}

# ============================================================
# ENTRADAS
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " ATUALIZA BLUE V2 - EXECUÇÃO EM CICLOS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Destino padrão: D:\PERFIL\<hash>\Blue"
Write-Host "O hash.txt será gerado automaticamente ao lado deste script."
Write-Host "Arquivos bloqueados serão tentados novamente no próximo ciclo." -ForegroundColor Yellow
Write-Host "O script não encerra aplicações/processos." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# MODO MANUAL OU AGENDADO
# ============================================================

if ($ExecucaoAgendada) {
    # Quando chamado pelo Agendador, não pode existir Read-Host.
    if ([string]::IsNullOrWhiteSpace($OrigemAgendada)) {
        throw "Execução agendada iniciada sem o parâmetro OrigemAgendada."
    }

    $OrigemAgendada = $OrigemAgendada.Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $OrigemAgendada -PathType Container)) {
        throw "A origem configurada no agendamento não está disponível: $OrigemAgendada"
    }

    $Origem = (Resolve-Path -LiteralPath $OrigemAgendada).Path

    Write-Host "MODO: EXECUÇÃO AGENDADA" -ForegroundColor Magenta
    Write-Host "Origem configurada: $Origem" -ForegroundColor Magenta
}
else {
    $Origem = Ler-PastaOrigem

    while ($true) {
        Write-Host ""
        $RespostaAgendamento = (Read-Host "Deseja AGENDAR esta execução? Digite S para SIM ou N para executar AGORA").Trim()

        if ($RespostaAgendamento -match '^(?i:S|SIM)$') {
            $DataHoraAgendada = Ler-DataHoraAgendamento

            # $PSCommandPath aponta para este próprio .ps1 quando executado como arquivo.
            if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
                throw "Para utilizar o agendamento, execute esta ferramenta a partir do arquivo .ps1 salvo em disco."
            }

            $NomeTarefaCriada = Criar-AgendamentoDistribuicao `
                -Origem $Origem `
                -DataHora $DataHoraAgendada `
                -CaminhoScript $PSCommandPath

            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host " AGENDAMENTO CRIADO COM SUCESSO" -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host "Tarefa : $NomeTarefaCriada"
            Write-Host "Data   : $($DataHoraAgendada.ToString('dd/MM/yyyy'))"
            Write-Host "Hora   : $($DataHoraAgendada.ToString('HH:mm'))"
            Write-Host "Origem : $Origem"
            Write-Host "Conta  : SYSTEM"
            Write-Host "Modo   : Executar mesmo sem usuário conectado"
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "A execução manual foi encerrada. No horário programado o próprio script será iniciado automaticamente." -ForegroundColor Cyan

            exit 0
        }
        elseif ($RespostaAgendamento -match '^(?i:N|NAO|NÃO)$') {
            Write-Host "Execução imediata selecionada." -ForegroundColor Green
            break
        }
        else {
            Write-Host "Resposta inválida. Digite S ou N." -ForegroundColor Red
        }
    }
}

# Pasta onde o próprio .ps1 está salvo. Se o host não preencher $PSScriptRoot,
# usa o diretório atual como fallback.
if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PastaExecucao = (Get-Location).Path
}
else {
    $PastaExecucao = $PSScriptRoot
}

$Lista = Join-Path $PastaExecucao "hash.txt"

# Em vez de "dir /ad /b /s", que também retornaria Blue e todas as demais
# subpastas internas, coleta apenas as pastas diretamente abaixo de D:\PERFIL
# cujo nome corresponde ao padrão real dos hashes.
$HashesGerados = @(
    Get-ChildItem -LiteralPath $PastaRaizDestino -Directory -Force -ErrorAction Stop |
        Where-Object { $_.Name -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}$' } |
        Select-Object -ExpandProperty Name |
        Sort-Object -Unique
)

if ($HashesGerados.Count -eq 0) {
    throw "Nenhuma pasta-hash foi localizada diretamente em $PastaRaizDestino"
}

$HashesGerados | Out-File -LiteralPath $Lista -Encoding UTF8 -Force

Write-Host ""
Write-Host "hash.txt gerado automaticamente: $Lista" -ForegroundColor Green
Write-Host "Hashes encontrados: $($HashesGerados.Count)" -ForegroundColor Green

# Confirma que existe pelo menos um arquivo na origem.
$ArquivosOrigem = @(Get-ChildItem -LiteralPath $Origem -File -Recurse -Force -ErrorAction Stop)

if ($ArquivosOrigem.Count -eq 0) {
    throw "A pasta de origem não contém arquivos: $Origem"
}

# ============================================================
# PREPARAR LOGS
# ============================================================

$PastaLogs = Join-Path $PastaRaizDestino "TEMP\Logs"
New-Item -Path $PastaLogs -ItemType Directory -Force | Out-Null

$DataExecucao = Get-Date -Format "yyyyMMdd_HHmmss"
$LogCsv       = Join-Path $PastaLogs "Atualiza_BLUE_V2_Resultado_$DataExecucao.csv"
$LogPrincipal = Join-Path $PastaLogs "Atualiza_BLUE_V2_Principal_$DataExecucao.log"

# Estes três arquivos existem somente enquanto a execução está em andamento.
# No final são consolidados/removidos, deixando apenas o log principal + CSV.
$LogDetalhadoTemporario = Join-Path $PastaLogs "TEMP_Atualiza_BLUE_V2_Robocopy_$DataExecucao.log"
$LogExecucaoTemporario  = Join-Path $PastaLogs "TEMP_Atualiza_BLUE_V2_Execucao_$DataExecucao.txt"
$LogPendentes           = Join-Path $PastaLogs "TEMP_Atualiza_BLUE_V2_Pendentes_$DataExecucao.txt"

Start-Transcript -Path $LogExecucaoTemporario -Force | Out-Null

try {
    # ========================================================
    # EXTRAIR HASHES
    # ========================================================

    # Funciona tanto com:
    #   004f8b19-9c51-47e7
    # quanto com uma saída do DIR:
    #   20/03/2026  02:01  <DIR>  004f8b19-9c51-47e7
    $Hashes = @(
        Get-Content -LiteralPath $Lista |
            ForEach-Object {
                if ($_ -match $PadraoHash) {
                    $Matches["Hash"].ToLowerInvariant()
                }
            } |
            Sort-Object -Unique
    )

    if ($Hashes.Count -eq 0) {
        throw "Nenhum hash válido foi localizado no arquivo: $Lista"
    }

    # ========================================================
    # RESUMO INICIAL
    # ========================================================

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " CONFIGURAÇÃO" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Origem               : $Origem"
    Write-Host "Arquivos na origem   : $($ArquivosOrigem.Count)"
    Write-Host "hash.txt automático  : $Lista"
    Write-Host "Hashes únicos        : $($Hashes.Count)"
    Write-Host "Destino              : D:\PERFIL\<hash>\Blue"
    Write-Host "Intervalo dos ciclos : $IntervaloCiclos segundos"
    Write-Host "Relatório CSV        : $LogCsv"
    Write-Host "Log principal        : $LogPrincipal"
    Write-Host "============================================================" -ForegroundColor Cyan

    $Pendentes    = @($Hashes)
    $Ciclo        = 0
    $TotalInicial = $Hashes.Count

    # ========================================================
    # CICLOS
    # ========================================================

    while ($Pendentes.Count -gt 0) {
        $Ciclo++
        $PendentesProximoCiclo = @()
        $TotalCiclo            = $Pendentes.Count
        $ConcluidosCiclo       = 0
        $FalhasCiclo           = 0
        $Contador              = 0

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " CICLO $Ciclo" -ForegroundColor Cyan
        Write-Host " Pendentes no início do ciclo: $TotalCiclo" -ForegroundColor Cyan
        Write-Host " Início: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan

        foreach ($Hash in $Pendentes) {
            $Contador++
            $Percentual = [math]::Round(($Contador / $TotalCiclo) * 100, 1)

            Write-Progress `
                -Activity "Ciclo $Ciclo - Distribuindo arquivos" `
                -Status "$Percentual% | $Contador de $TotalCiclo | $Hash" `
                -PercentComplete $Percentual

            $DestinoHash = Join-Path (Join-Path $PastaRaizDestino $Hash) $SubpastaDestino

            # Validação defensiva: o caminho deve continuar dentro da raiz esperada.
            $RaizCompleta    = [System.IO.Path]::GetFullPath($PastaRaizDestino).TrimEnd('\')
            $DestinoCompleto = [System.IO.Path]::GetFullPath($DestinoHash).TrimEnd('\')
            $PrefixoSeguro   = $RaizCompleta + "\"

            if (-not $DestinoCompleto.StartsWith($PrefixoSeguro, [System.StringComparison]::OrdinalIgnoreCase)) {
                $FalhasCiclo++
                $PendentesProximoCiclo += $Hash

                $Registro = [PSCustomObject]@{
                    DataHora         = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
                    Ciclo            = $Ciclo
                    PercentualCiclo  = "$Percentual%"
                    Hash             = $Hash
                    Destino          = $DestinoCompleto
                    Status           = "FALHA"
                    CodigoRobocopy   = ""
                    TotalArquivos    = ""
                    ArquivosCopiados = ""
                    ArquivosIgnorados = ""
                    ArquivosFalha    = ""
                    Detalhes         = "Destino fora da raiz permitida"
                }

                Gravar-ResultadoCsv -Registro $Registro -CaminhoCsv $LogCsv
                continue
            }

            try {
                New-Item -Path $DestinoCompleto -ItemType Directory -Force | Out-Null

                Add-Content -LiteralPath $LogDetalhadoTemporario -Encoding UTF8 -Value ""
                Add-Content -LiteralPath $LogDetalhadoTemporario -Encoding UTF8 -Value ("===== CICLO {0} | HASH {1} | {2} =====" -f $Ciclo, $Hash, (Get-Date -Format "dd/MM/yyyy HH:mm:ss"))

                # /E        : inclui subpastas, inclusive vazias
                # /XO       : não substitui destino por uma origem mais antiga
                #             (logo, substitui quando a origem é mais nova)
                # /COPY:DAT : dados, atributos e timestamps dos arquivos
                # /DCOPY:DAT: dados, atributos e timestamps das pastas
                # /R:0      : falha rapidamente se estiver bloqueado; o PRÓXIMO
                #             CICLO fará a nova tentativa
                # /Z        : modo reiniciável
                # /XJ       : evita seguir junction points
                # Importante: não usamos /MIR nem /PURGE. Nada extra é apagado.
                $Argumentos = @(
                    $Origem
                    $DestinoCompleto
                    "*.*"
                    "/E"
                    "/XO"
                    "/COPY:DAT"
                    "/DCOPY:DAT"
                    "/R:0"
                    "/W:0"
                    "/Z"
                    "/XJ"
                    "/NP"
                )

                $SaidaRobocopy = @(& robocopy.exe @Argumentos 2>&1)
                $CodigoRobocopy = $LASTEXITCODE

                # Guarda toda a saída nativa do Robocopy.
                $SaidaRobocopy | Out-File -LiteralPath $LogDetalhadoTemporario -Encoding UTF8 -Append

                $Resumo = Obter-ResumoRobocopy -Saida $SaidaRobocopy

                # Robocopy: 0 a 7 = sem falha fatal; >= 8 = houve falha de cópia.
                if ($CodigoRobocopy -le 7) {
                    $ConcluidosCiclo++
                    $Status   = "SUCESSO"
                    $Detalhes = "Destino concluído neste ciclo"

                    Write-Host ("[CICLO {0}] {1,6}% | SUCESSO | {2}" -f $Ciclo, $Percentual, $Hash) -ForegroundColor Green
                }
                else {
                    $FalhasCiclo++
                    $PendentesProximoCiclo += $Hash
                    $Status = "PENDENTE"

                    if ($CodigoRobocopy -eq 16) {
                        $Detalhes = "Erro grave do Robocopy. Verifique o log principal (caminho/permissão/uso do arquivo). Será tentado novamente."
                    }
                    else {
                        $Detalhes = "Uma ou mais cópias falharam, possivelmente por arquivo em uso. Será tentado novamente."
                    }

                    Write-Host ("[CICLO {0}] {1,6}% | PENDENTE | {2} | Robocopy {3}" -f $Ciclo, $Percentual, $Hash, $CodigoRobocopy) -ForegroundColor Yellow
                }

                $Registro = [PSCustomObject]@{
                    DataHora          = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
                    Ciclo             = $Ciclo
                    PercentualCiclo   = "$Percentual%"
                    Hash              = $Hash
                    Destino           = $DestinoCompleto
                    Status            = $Status
                    CodigoRobocopy    = $CodigoRobocopy
                    TotalArquivos     = $Resumo.TotalArquivos
                    ArquivosCopiados  = $Resumo.ArquivosCopiados
                    ArquivosIgnorados = $Resumo.ArquivosIgnorados
                    ArquivosFalha     = $Resumo.ArquivosFalha
                    Detalhes          = $Detalhes
                }

                Gravar-ResultadoCsv -Registro $Registro -CaminhoCsv $LogCsv
            }
            catch {
                $FalhasCiclo++
                $PendentesProximoCiclo += $Hash
                $Motivo = $_.Exception.Message -replace "[\r\n;]+", " "

                $Registro = [PSCustomObject]@{
                    DataHora          = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
                    Ciclo             = $Ciclo
                    PercentualCiclo   = "$Percentual%"
                    Hash              = $Hash
                    Destino           = $DestinoCompleto
                    Status            = "PENDENTE"
                    CodigoRobocopy    = ""
                    TotalArquivos     = ""
                    ArquivosCopiados  = ""
                    ArquivosIgnorados = ""
                    ArquivosFalha     = ""
                    Detalhes          = $Motivo
                }

                Gravar-ResultadoCsv -Registro $Registro -CaminhoCsv $LogCsv
                Write-Host ("[CICLO {0}] {1,6}% | PENDENTE | {2} | {3}" -f $Ciclo, $Percentual, $Hash, $Motivo) -ForegroundColor Yellow
            }
        }

        Write-Progress -Activity "Ciclo $Ciclo - Distribuindo arquivos" -Completed

        $Pendentes = @($PendentesProximoCiclo | Sort-Object -Unique)

        # Atualiza a lista de pendentes a cada ciclo. Se o operador interromper,
        # este TXT mostra exatamente o que ainda precisa ser processado.
        if ($Pendentes.Count -gt 0) {
            $Pendentes | Out-File -LiteralPath $LogPendentes -Encoding UTF8 -Force
        }
        elseif (Test-Path -LiteralPath $LogPendentes) {
            Remove-Item -LiteralPath $LogPendentes -Force -ErrorAction SilentlyContinue
        }

        $PercentualGlobal = [math]::Round((($TotalInicial - $Pendentes.Count) / $TotalInicial) * 100, 1)

        Write-Host ""
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "FIM DO CICLO $Ciclo" -ForegroundColor Cyan
        Write-Host "Processados no ciclo : $TotalCiclo"
        Write-Host "Concluídos no ciclo  : $ConcluidosCiclo" -ForegroundColor Green
        Write-Host "Pendentes no ciclo   : $FalhasCiclo" -ForegroundColor Yellow
        Write-Host "Pendentes restantes  : $($Pendentes.Count)" -ForegroundColor Yellow
        Write-Host "Conclusão geral      : $PercentualGlobal%" -ForegroundColor Cyan
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

        if ($Pendentes.Count -gt 0) {
            Write-Host "Novo ciclo em $IntervaloCiclos segundos. Pressione CTRL+C para interromper." -ForegroundColor Yellow
            Start-Sleep -Seconds $IntervaloCiclos
        }
    }

    # ========================================================
    # FINAL
    # ========================================================

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " ATUALIZA BLUE V2 CONCLUÍDO" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Todos os $TotalInicial hashes foram concluídos." -ForegroundColor Green
    Write-Host "Ciclos executados : $Ciclo"
    Write-Host "Relatório CSV     : $LogCsv"
    Write-Host "Log principal     : $LogPrincipal"
    Write-Host "============================================================" -ForegroundColor Green
}
finally {
    Write-Progress -Activity "Distribuindo arquivos" -Completed
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null

    # ========================================================
    # CONSOLIDAR LOGS TEMPORÁRIOS
    # ========================================================

    "============================================================" |
        Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Force
    " LOG PRINCIPAL - ATUALIZA BLUE V2" |
        Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
    (" Gerado em: {0}" -f (Get-Date -Format "dd/MM/yyyy HH:mm:ss")) |
        Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
    "============================================================" |
        Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append

    if (Test-Path -LiteralPath $LogExecucaoTemporario) {
        "" | Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
        "================ TRANSCRIÇÃO DA EXECUÇÃO ================" |
            Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
        Get-Content -LiteralPath $LogExecucaoTemporario |
            Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
    }

    if (Test-Path -LiteralPath $LogDetalhadoTemporario) {
        "" | Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
        "================ DETALHES DO ROBOCOPY ====================" |
            Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
        Get-Content -LiteralPath $LogDetalhadoTemporario |
            Out-File -LiteralPath $LogPrincipal -Encoding UTF8 -Append
    }

    # Remove os logs de trabalho/ciclo. O histórico completo já foi incorporado
    # ao LogPrincipal. O TXT de pendentes também é temporário.
    @(
        $LogExecucaoTemporario,
        $LogDetalhadoTemporario,
        $LogPendentes
    ) |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
        ForEach-Object {
            Remove-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue
        }
}
