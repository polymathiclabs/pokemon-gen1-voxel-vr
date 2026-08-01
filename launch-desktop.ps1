# Production desktop launcher for the voxel build.
#
# This prepares the sibling voxel mod, selects Red/Blue/Yellow from the ROM,
# and explicitly disables the optional VR bridge.

[CmdletBinding()]
param(
    [string]$RomPath,
    [switch]$SkipSetup,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Game = Join-Path $Root 'gen1recomp'
$Mod = Join-Path $Root 'DramaticShapeVoxelMod'
$SetupScript = Join-Path $Root 'setup-vr.ps1'
$RunScript = Join-Path $Game 'scripts\run.ps1'
$RomInfoScript = Join-Path $Root 'rom-info.ps1'

function Stop-Launcher([string]$Message) {
    Write-Host ''
    Write-Host "Desktop launcher stopped: $Message" -ForegroundColor Red
    exit 1
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

function Test-VoxelModLink {
    $linkPath = Join-Path $Game 'mods\DramaticShapeVoxelMod'
    if (-not (Test-Path -LiteralPath $linkPath)) { return $false }
    try {
        $item = Get-Item -LiteralPath $linkPath -Force
        if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            return $false
        }
        $linkTarget = @($item.Target) | Select-Object -First 1
        if (-not $linkTarget) { return $false }
        $resolvedLink = (Resolve-Path -LiteralPath $linkTarget).Path
        $resolvedMod = (Resolve-Path -LiteralPath $Mod).Path
        return $resolvedLink.TrimEnd('\') -eq $resolvedMod.TrimEnd('\')
    } catch {
        return $false
    }
}

if (-not (Test-Path -LiteralPath $Game -PathType Container)) {
    Stop-Launcher "the gen1recomp folder is missing from $Root."
}
if (-not (Test-Path -LiteralPath $Mod -PathType Container)) {
    Stop-Launcher "the DramaticShapeVoxelMod folder is missing from $Root."
}
if (-not (Test-Path -LiteralPath $SetupScript -PathType Leaf)) {
    Stop-Launcher 'setup-vr.ps1 is missing.'
}
if (-not (Test-Path -LiteralPath $RunScript -PathType Leaf)) {
    Stop-Launcher 'gen1recomp/scripts/run.ps1 is missing.'
}
if (-not (Test-Path -LiteralPath $RomInfoScript -PathType Leaf)) {
    Stop-Launcher 'rom-info.ps1 is missing.'
}

. $RomInfoScript
try { $RomInfo = Get-PokemonRomInfo -Path $RomPath -SearchRoot $Root }
catch { Stop-Launcher $_.Exception.Message }
$RomPath = $RomInfo.Path

$LoveBin = Find-Love
$needsSetup = (-not $LoveBin) -or (-not (Test-VoxelModLink))

if (-not $SkipSetup -and $needsSetup) {
    Write-Host 'Preparing LOVE 11.5 and the voxel mod...' -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SetupScript -RomPath $RomPath
    if ($LASTEXITCODE -ne 0) {
        Stop-Launcher "setup-vr.ps1 exited with code $LASTEXITCODE."
    }
    $LoveBin = Find-Love
}

if (-not (Test-VoxelModLink)) {
    Stop-Launcher 'the voxel mod junction is missing or points at the wrong folder. Run setup-vr.ps1.'
}
if (-not $LoveBin) {
    Stop-Launcher 'LOVE 11.5 was not found. Run setup-vr.ps1 or install LOVE 11.5.'
}
$loveVersion = Get-LoveVersion $LoveBin
if ($loveVersion -notmatch '11\.5') {
    Stop-Launcher "LOVE 11.5 is required; found '$loveVersion' at $LoveBin."
}

if ($CheckOnly) {
    Write-Host "LOVE:       $LoveBin ($loveVersion)" -ForegroundColor Green
    Write-Host "ROM:        $RomPath ($($RomInfo.DisplayName), canonical)" -ForegroundColor Green
    Write-Host "Voxel mod:  $Mod" -ForegroundColor Green
    Write-Host 'Mode:       desktop first-/third-person voxel build' -ForegroundColor Green
    Write-Host 'Launcher:   versioned ROM importer and voxel build' -ForegroundColor Green
    exit 0
}

# Do not let a previous VR shell environment turn this desktop entrypoint into
# a headset launch, or force the in-game launcher to auto-import a ROM.
$env:POKEPORT_VR = '0'
$env:POKEPORT_VR_REQUIRED = '0'
$env:POKEPORT_VR_DIAGNOSTIC = '0'
$env:POKEPORT_VERSION = $RomInfo.Id
$env:POKEPORT_IMPORT_ROM = $RomPath
Remove-Item Env:POKEPORT_XRBRIDGE -ErrorAction SilentlyContinue

Write-Host "Launching the desktop $($RomInfo.DisplayName) voxel build..." -ForegroundColor Green
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $RunScript
exit $LASTEXITCODE
