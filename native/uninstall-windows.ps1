$ErrorActionPreference = 'Stop'
foreach ($browser in @('Google\Chrome', 'Chromium')) {
    $keyPath = "HKCU:\Software\$browser\NativeMessagingHosts\com.belde.editor"
    if (Test-Path -LiteralPath $keyPath) { Remove-Item -LiteralPath $keyPath -Recurse -Force }
}
$installDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Belde\NativeMessaging'
if (Test-Path -LiteralPath $installDirectory) { Remove-Item -LiteralPath $installDirectory -Recurse -Force }
Write-Host 'Belde native messaging host removed for this Windows user. Game saves were kept.'
