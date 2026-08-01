# Prepare the local Gen1Recomp + Dramatic Shape workspace.

param(
    [string]$RomPath = (Join-Path $PSScriptRoot 'Pokemon Red.gb')
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Game = Join-Path $Root 'gen1recomp'
$Mod = Join-Path $Root 'DramaticShapeVoxelMod'
$ModLink = Join-Path $Game 'mods\DramaticShapeVoxelMod'

if (-not (Test-Path -LiteralPath $Game -PathType Container)) {
    throw "gen1recomp is missing from $Root"
}
if (-not (Test-Path -LiteralPath $Mod -PathType Container)) {
    throw "DramaticShapeVoxelMod is missing from $Root"
}
if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "ROM not found: $RomPath"
}

$RomPath = (Resolve-Path -LiteralPath $RomPath).Path
$sha1 = (Get-FileHash -Algorithm SHA1 -LiteralPath $RomPath).Hash.ToLowerInvariant()
if ($sha1 -ne 'ea9bcae617fdf159b045185467ae58b2e4a48b9a') {
    throw "Unsupported ROM SHA-1: $sha1. Supply the canonical US Pokémon Red 1.0 ROM."
}

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

$setupArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    (Join-Path $Game 'scripts\setup.ps1'), '-Rom', $RomPath
)
& powershell @setupArgs
if ($LASTEXITCODE -ne 0) { throw "The upstream setup failed with code $LASTEXITCODE." }

Write-Host ''
Write-Host 'Setup complete.' -ForegroundColor Green
Write-Host 'Run .\play-vr.ps1 to start the VR-capable build.'
