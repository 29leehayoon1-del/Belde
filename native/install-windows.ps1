[CmdletBinding()]
param(
    [ValidatePattern('^[a-p]{32}$')]
    [string]$ExtensionId = 'ngolglhaedkpheljgabbfafifbimmlle',
    [string]$HostPath = (Join-Path $PSScriptRoot 'bin\belde_host.exe')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $HostPath -PathType Leaf)) {
    throw "Native host executable not found: $HostPath. Use the complete Windows download."
}
$installDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Belde\NativeMessaging'
New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null
$installedHost = Join-Path $installDirectory 'belde_host.exe'
Copy-Item -LiteralPath $HostPath -Destination $installedHost -Force
$manifestPath = Join-Path $installDirectory 'com.belde.editor.json'
$manifest = [ordered]@{
    name = 'com.belde.editor'
    description = 'Belde connected map editor'
    path = $installedHost
    type = 'stdio'
    allowed_origins = @("chrome-extension://$ExtensionId/")
}
$json = $manifest | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText($manifestPath, $json, [Text.UTF8Encoding]::new($false))
foreach ($browser in @('Google\Chrome', 'Chromium')) {
    $keyPath = "HKCU:\Software\$browser\NativeMessagingHosts\com.belde.editor"
    New-Item -Path $keyPath -Force | Out-Null
    (Get-Item -LiteralPath $keyPath).SetValue('', $manifestPath, [Microsoft.Win32.RegistryValueKind]::String)
}
Write-Host 'Belde native messaging host installed for this Windows user.'
Write-Host "Authorized extension: $ExtensionId"
Write-Host 'Start Belde, open the extension, and enter the pairing code shown in the game.'
