<#
.SYNOPSIS
  Drops the latest built APK into "install apk/" so you don't have to go
  digging through the GitHub UI for it.

.DESCRIPTION
  Two ways to get a build out of GitHub, and they differ in one way that
  matters here: release assets are public, workflow artifacts are not.

    1. Release assets  - plain HTTPS download, no credentials. Produced by
                         the create-release-on-tag job in build_apk.yml,
                         which fires on any tag matching v*.
    2. Run artifacts   - require a token with actions:read, even though the
                         repo is public. This is why downloading by hand
                         means being signed in to github.com.

  This script prefers (1) and falls back to (2) when a token is available,
  so once you've tagged a release it works with no setup at all.

.PARAMETER Token
  GitHub token with actions:read. Only needed for the artifact fallback.
  Defaults to $env:GITHUB_TOKEN. Never write a token into this file.

.PARAMETER Abi
  Which split APK to keep. arm64-v8a is what a normal modern phone wants.

.EXAMPLE
  pwsh tools/fetch-apk.ps1
#>
[CmdletBinding()]
param(
    [string]$Repo   = "dev-banik/VoiceCraft-AI",
    [string]$Abi    = "arm64-v8a",
    [string]$OutDir,
    [string]$Token  = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"
$headers = @{ "User-Agent" = "fetch-apk" }
if ($Token) { $headers["Authorization"] = "Bearer $Token" }

# $PSScriptRoot isn't populated yet while parameter defaults are bound in
# Windows PowerShell 5.1, so the repo-relative default is resolved here.
if (-not $OutDir) {
    $OutDir = Join-Path (Split-Path $PSCommandPath -Parent) "..\install apk"
}
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function Save-File($Url, $Path) {
    Write-Host "  downloading $(Split-Path $Path -Leaf) ..."
    Invoke-WebRequest -Uri $Url -Headers $headers -OutFile $Path
    "  saved {0} ({1:n1} MB)" -f $Path, ((Get-Item $Path).Length / 1MB) | Write-Host
}

# --- 1. Release assets (public, no token) --------------------------------
$release = $null
try {
    $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers $headers
} catch {
    Write-Host "No published release yet."
}

if ($release) {
    $asset = $release.assets | Where-Object { $_.name -like "*$Abi*release*.apk" } | Select-Object -First 1
    if (-not $asset) { $asset = $release.assets | Where-Object { $_.name -like "*.apk" } | Select-Object -First 1 }
    if ($asset) {
        Write-Host "Release $($release.tag_name), published $($release.published_at):"
        Save-File $asset.browser_download_url (Join-Path $OutDir $asset.name)
        Write-Host "`nDone. Copy it to your phone and tap to install."
        return
    }
    Write-Host "Release $($release.tag_name) has no APK attached; trying artifacts."
}

# --- 2. Workflow artifacts (needs a token) -------------------------------
if (-not $Token) {
    Write-Host ""
    Write-Host "Can't fall back to workflow artifacts without a token."
    Write-Host "Either tag a release:"
    Write-Host "    git tag v1.0.0 && git push origin v1.0.0"
    Write-Host "or set one for this shell:"
    Write-Host "    `$env:GITHUB_TOKEN = '<token with actions:read>'"
    exit 1
}

$runs = Invoke-RestMethod "https://api.github.com/repos/$Repo/actions/runs?branch=main&status=success&per_page=1" -Headers $headers
if ($runs.workflow_runs.Count -eq 0) { throw "No successful workflow run on main." }
$run = $runs.workflow_runs[0]
Write-Host "Run $($run.head_sha.Substring(0,7)) ($($run.created_at)):"

$artifacts = Invoke-RestMethod $run.artifacts_url -Headers $headers
$artifact = $artifacts.artifacts | Where-Object { $_.name -like "*release*" } | Select-Object -First 1
if (-not $artifact) { throw "No release-APK artifact on that run." }
if ($artifact.expired) { throw "Artifact '$($artifact.name)' has expired; re-run the workflow or tag a release." }

$zip = Join-Path ([System.IO.Path]::GetTempPath()) "$($artifact.name).zip"
Save-File $artifact.archive_download_url $zip

$staging = Join-Path ([System.IO.Path]::GetTempPath()) "apk-$(Get-Random)"
Expand-Archive -Path $zip -DestinationPath $staging -Force
Get-ChildItem $staging -Filter "*$Abi*.apk" -Recurse | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $OutDir $_.Name) -Force
    "  saved {0} ({1:n1} MB)" -f (Join-Path $OutDir $_.Name), ($_.Length / 1MB) | Write-Host
}
Remove-Item $zip, $staging -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nDone. Copy it to your phone and tap to install."
