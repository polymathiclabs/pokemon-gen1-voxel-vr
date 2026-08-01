# Production desktop launcher for the voxel build.
#
# This follows the upstream game's Windows bootstrap pattern, but prepares the
# sibling voxel mod first and explicitly disables the optional VR bridge. The
# game itself still opens its normal ROM/save/mod launcher.

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
if (-not $RomPath) { $RomPath = Join-Path $Root 'Pokemon Red.gb' }

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
if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    Stop-Launcher "ROM not found: $RomPath"
}

$RomPath = (Resolve-Path -LiteralPath $RomPath).Path
$romHash = (Get-FileHash -Algorithm SHA1 -LiteralPath $RomPath).Hash.ToLowerInvariant()
if ($romHash -ne 'ea9bcae617fdf159b045185467ae58b2e4a48b9a') {
    Stop-Launcher "unsupported ROM SHA-1: $romHash. Supply the canonical US Pokemon Red 1.0 ROM."
}

$maps = Join-Path $Game 'data\generated\maps.lua'
$LoveBin = Find-Love
$needsSetup = (-not (Test-Path -LiteralPath $maps -PathType Leaf)) -or `
              (-not $LoveBin) -or `
              (-not (Test-VoxelModLink))

if (-not $SkipSetup -and $needsSetup) {
    Write-Host 'Preparing generated game data, LOVE 11.5, and the voxel mod...' -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SetupScript -RomPath $RomPath
    if ($LASTEXITCODE -ne 0) {
        Stop-Launcher "setup-vr.ps1 exited with code $LASTEXITCODE."
    }
    $LoveBin = Find-Love
}

if (-not (Test-Path -LiteralPath $maps -PathType Leaf)) {
    Stop-Launcher 'generated game data is missing. Run setup-vr.ps1 or remove -SkipSetup.'
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
    Write-Host "ROM:        $RomPath (canonical)" -ForegroundColor Green
    Write-Host "Voxel mod:  $Mod" -ForegroundColor Green
    Write-Host 'Mode:       desktop first-/third-person voxel build' -ForegroundColor Green
    Write-Host 'Launcher:   upstream in-game ROM/save/mod launcher' -ForegroundColor Green
    exit 0
}

# Do not let a previous VR shell environment turn this desktop entrypoint into
# a headset launch, or force the in-game launcher to auto-import a ROM.
$env:POKEPORT_VR = '0'
$env:POKEPORT_VR_REQUIRED = '0'
$env:POKEPORT_VR_DIAGNOSTIC = '0'
Remove-Item Env:POKEPORT_XRBRIDGE -ErrorAction SilentlyContinue
Remove-Item Env:POKEPORT_IMPORT_ROM -ErrorAction SilentlyContinue

$upstreamLauncher = Join-Path $Game 'Play-Windows.bat'
if (-not (Test-Path -LiteralPath $upstreamLauncher -PathType Leaf)) {
    Stop-Launcher 'gen1recomp/Play-Windows.bat is missing.'
}

Write-Host 'Launching the desktop Pokemon Red voxel build...' -ForegroundColor Green
$env:ROM_PATH = $RomPath
& $upstreamLauncher
exit $LASTEXITCODE
