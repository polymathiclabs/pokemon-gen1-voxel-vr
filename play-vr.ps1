# Launch the local Gen1Recomp + voxel build with the optional VR path enabled.

param(
    [string]$XrBridge = $env:POKEPORT_XRBRIDGE,
    [string]$RomPath,
    [switch]$Diagnostic
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Game = Join-Path $Root 'gen1recomp'
$RomInfoScript = Join-Path $Root 'rom-info.ps1'

if (-not (Test-Path -LiteralPath $RomInfoScript -PathType Leaf)) {
    throw 'rom-info.ps1 is missing.'
}
. $RomInfoScript
$RomInfo = Get-PokemonRomInfo -Path $RomPath -SearchRoot $Root
$RomPath = $RomInfo.Path

$env:POKEPORT_VR = '1'
$env:POKEPORT_VR_DIAGNOSTIC = if ($Diagnostic) { '1' } else { '0' }
$env:POKEPORT_VERSION = $RomInfo.Id
$env:POKEPORT_IMPORT_ROM = $RomPath

if ($XrBridge) {
    if (-not (Test-Path -LiteralPath $XrBridge -PathType Leaf)) {
        throw "OpenXR bridge DLL not found: $XrBridge"
    }
    $env:POKEPORT_XRBRIDGE = (Resolve-Path -LiteralPath $XrBridge).Path
}

$runScript = Join-Path $Game 'scripts\run.ps1'
if (-not (Test-Path -LiteralPath $runScript -PathType Leaf)) {
    throw 'gen1recomp/scripts/run.ps1 is missing.'
}

$runArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $runScript
)
& powershell @runArgs
if ($LASTEXITCODE -ne 0) { throw "The game exited with code $LASTEXITCODE." }
