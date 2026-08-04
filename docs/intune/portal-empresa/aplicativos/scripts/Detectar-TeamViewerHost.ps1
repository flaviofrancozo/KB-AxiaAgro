# Detectar-TeamViewerHost.ps1
$VersaoMinima = [version]"15.79.4"
$Caminhos = @(
    "$env:ProgramFiles\TeamViewer\TeamViewer.exe",
    "${env:ProgramFiles(x86)}\TeamViewer\TeamViewer.exe"
)
foreach ($Caminho in $Caminhos) {
    if ($Caminho -and (Test-Path -LiteralPath $Caminho)) {
        try {
            $Texto = (Get-Item -LiteralPath $Caminho).VersionInfo.ProductVersion
            $Limpa = $Texto -replace '[^\d\.].*$', ''
            if ([version]$Limpa -ge $VersaoMinima) {
                Write-Output "TeamViewer detectado. Versão: $Limpa"
                exit 0
            }
        } catch {}
    }
}
exit 1
