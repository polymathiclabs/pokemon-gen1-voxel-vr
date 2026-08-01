# Launch the local Gen1Recomp + voxel build with the optional VR path enabled.

param(
    [string]$XrBridge = $env:POKEPORT_XRBRIDGE,
    [string]$RomPath = (Join-Path $PSScriptRoot 'Pokemon Red.gb')
)

$ErrorActionPreference = 'Stop'
$Game = Join-Path $PSScriptRoot 'gen1recomp'

if (-not (Test-Path -LiteralPath (Join-Path $Game 'data\generated\maps.lua'))) {
    throw 'Generated data is missing. Run .\setup-vr.ps1 first.'
}
if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "ROM not found: $RomPath"
}

$env:POKEPORT_VR = '1'
$env:POKEPORT_VR_DIAGNOSTIC = '1'
$RomPath = (Resolve-Path -LiteralPath $RomPath).Path
$sha1 = (Get-FileHash -Algorithm SHA1 -LiteralPath $RomPath).Hash.ToLowerInvariant()
if ($sha1 -ne 'ea9bcae617fdf159b045185467ae58b2e4a48b9a') {
    throw "Unsupported ROM SHA-1: $sha1. Supply the canonical US Pokémon Red 1.0 ROM."
}

# The fast source-tree builder intentionally omits the full audio program
# pack. On the first launch, hand the same validated ROM to the upstream
# importer so it can complete the cache and boot automatically instead of
# stopping at the interactive ROM selector.
if (-not (Test-Path -LiteralPath (Join-Path $Game 'assets\generated\audio\programs.bin'))) {
    $env:POKEPORT_IMPORT_ROM = $RomPath
}
if ($XrBridge) {
    if (-not (Test-Path -LiteralPath $XrBridge -PathType Leaf)) {
        throw "OpenXR bridge DLL not found: $XrBridge"
    }
    $env:POKEPORT_XRBRIDGE = (Resolve-Path -LiteralPath $XrBridge).Path
}

$runArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    (Join-Path $Game 'scripts\run.ps1')
)
& powershell @runArgs
if ($LASTEXITCODE -ne 0) { throw "The game exited with code $LASTEXITCODE." }
