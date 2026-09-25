# Waits for the v1.0.0 release APK and saves it into "install apk/".
#
# Deliberately does NOT touch api.github.com. Unauthenticated API calls are
# capped at 60/hour per IP and a polling loop burns that in minutes — which
# is exactly how the first version of this script died. Release asset URLs
# are predictable from the tag and filename, and downloading one is an
# ordinary file fetch with no such cap, so this just retries the URL until
# the release job publishes it.
param(
    [string]$Tag = "v1.0.0",
    [string]$Apk = "app-arm64-v8a-release.apk"
)

$ErrorActionPreference = "Stop"

$repo   = "dev-banik/VoiceCraft-AI"
$tag    = $Tag
$apk    = $Apk
$url    = "https://github.com/$repo/releases/download/$tag/$apk"
$outDir = Join-Path (Split-Path $PSCommandPath -Parent) "..\install apk"
$outDir = [System.IO.Path]::GetFullPath($outDir)
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$dest = Join-Path $outDir $apk

$deadline = (Get-Date).AddMinutes(40)
$attempt  = 0

while ((Get-Date) -lt $deadline) {
    $attempt++
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        $mb = (Get-Item $dest).Length / 1MB
        if ($mb -lt 10) { throw "downloaded file is only $([math]::Round($mb,1)) MB - not a real APK" }
        "SAVED: $dest ({0:n1} MB)" -f $mb
        "The APK is in the 'install apk' folder. Copy it to your phone and tap to install."
        exit 0
    } catch {
        if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
        "attempt $attempt at $((Get-Date).ToString('HH:mm:ss')): not published yet"
        Start-Sleep -Seconds 90
    }
}

"TIMED OUT. Check https://github.com/$repo/releases and https://github.com/$repo/actions"
exit 1
