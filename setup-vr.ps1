# Prepare the local Gen1Recomp + Dramatic Shape workspace for Red, Blue, or Yellow.
#
# The game's own importer creates and versions the ROM-derived cache. This
# setup step only installs LÖVE and links the voxel mod, so every supported ROM
# follows the same safe path and no generated ROM data is committed or shipped.

param(
    [string]$RomPath
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Game = Join-Path $Root 'gen1recomp'
$Mod = Join-Path $Root 'DramaticShapeVoxelMod'
$ModLink = Join-Path $Game 'mods\DramaticShapeVoxelMod'
$RomInfoScript = Join-Path $Root 'rom-info.ps1'

if (-not (Test-Path -LiteralPath $Game -PathType Container)) {
    throw "gen1recomp is missing from $Root"
}
if (-not (Test-Path -LiteralPath $Mod -PathType Container)) {
    throw "DramaticShapeVoxelMod is missing from $Root"
}
if (-not (Test-Path -LiteralPath $RomInfoScript -PathType Leaf)) {
    throw 'rom-info.ps1 is missing.'
}

. $RomInfoScript
$RomInfo = Get-PokemonRomInfo -Path $RomPath -SearchRoot $Root
$RomPath = $RomInfo.Path

if (Test-Path -LiteralPath $ModLink) {
    $item = Get-Item -LiteralPath $ModLink -Force
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "$ModLink already exists and is not the local voxel-mod link. Remove it or choose a clean checkout."
    }
    $linkTarget = @($item.Target) | Select-Object -First 1
    if (-not $linkTarget) {
        throw "$ModLink is a reparse point without a readable target."
    }
    $resolvedLink = (Resolve-Path -LiteralPath $linkTarget).Path
    $resolvedMod = (Resolve-Path -LiteralPath $Mod).Path
    if ($resolvedLink.TrimEnd('\') -ne $resolvedMod.TrimEnd('\')) {
        throw "$ModLink is a reparse point, but it does not target $Mod."
    }
} else {
    New-Item -ItemType Junction -Path $ModLink -Target $Mod | Out-Null
}

function Find-Love {
    foreach ($name in 'lovec', 'love') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    foreach ($directory in @(
        "$env:ProgramFiles\LOVE",
        "${env:ProgramFiles(x86)}\LOVE",
        "$env:LOCALAPPDATA\Programs\LOVE"
    )) {
        if (-not $directory) { continue }
        foreach ($name in 'lovec.exe', 'love.exe') {
            $candidate = Join-Path $directory $name
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return $candidate
            }
        }
    }
    return $null
}

function Get-LoveVersion([string]$Path) {
    if (-not $Path) { return $null }
    $version = (& $Path --version 2>$null | Out-String).Trim()
    if (-not $version) {
        $version = (Get-Item -LiteralPath $Path).VersionInfo.ProductVersion
    }
    return $version
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

$LoveBin = Find-Love
if (-not $LoveBin) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'LÖVE 11.5 was not found and winget is unavailable. Install LÖVE 11.5 from https://love2d.org.'
    }
    Write-Host 'Installing LÖVE 11.5 via winget...' -ForegroundColor Cyan
    & winget install --exact --id Love2d.Love2d --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "LÖVE installation failed with code $LASTEXITCODE." }
    Refresh-Path
    $LoveBin = Find-Love
}
if (-not $LoveBin) {
    throw 'LÖVE 11.5 was not found after installation.'
}
$LoveVersion = Get-LoveVersion $LoveBin
if ($LoveVersion -notmatch '11\.5') {
    throw "LÖVE 11.5 is required; found '$LoveVersion' at $LoveBin."
}

Write-Host ''
Write-Host 'Setup complete.' -ForegroundColor Green
Write-Host "ROM: $($RomInfo.DisplayName) ($($RomInfo.Sha1))" -ForegroundColor Green
Write-Host "LÖVE: $LoveBin ($LoveVersion)" -ForegroundColor Green
Write-Host 'The game importer will create or reuse the matching Red/Blue/Yellow cache on launch.'
Write-Host 'Run .\Play-Windows.bat for desktop ABOVE / 3RD / POV play.'
Write-Host 'Run .\Play-VR.bat for the OpenXR / SteamVR headset build.'
