# Clone the privately owned engine/mod copies into this integration checkout,
# prepare the ROM-derived cache, and optionally launch one of the two modes.

[CmdletBinding()]
param(
    [ValidateSet('Desktop', 'VR')]
    [string]$Mode = 'Desktop',
    [Parameter(Mandatory = $true)]
    [string]$RomPath,
    [string]$Owner = 'polymathiclabs',
    [string]$EngineRepo = 'gen1recomp',
    [string]$VoxelRepo = 'DramaticShapeVoxelMod',
    [string]$EngineUrl,
    [string]$VoxelUrl,
    [switch]$SkipSetup,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Game = Join-Path $Root 'gen1recomp'
$Mod = Join-Path $Root 'DramaticShapeVoxelMod'

function Stop-Install([string]$Message) {
    Write-Host ''
    Write-Host "Installation stopped: $Message" -ForegroundColor Red
    exit 1
}

function Invoke-Git([string[]]$Arguments) {
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        Stop-Install "git $($Arguments -join ' ') failed with code $LASTEXITCODE."
    }
}

function Ensure-Repo([string]$Name, [string]$Url, [string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Container) {
        if (Test-Path -LiteralPath (Join-Path $Path '.git')) {
            Write-Host "$Name is already present: $Path" -ForegroundColor Green
            return
        }
        Stop-Install "$Path already exists but is not a Git repository. Move it aside or pass a clean checkout."
    }

    Write-Host "Cloning $Name from $Url..." -ForegroundColor Cyan
    Invoke-Git @('clone', '--origin', 'origin', $Url, $Path)
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Stop-Install 'Git is required. Install Git for Windows and run this again.'
}
if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    Stop-Install "ROM not found: $RomPath"
}

$RomPath = (Resolve-Path -LiteralPath $RomPath).Path
if (-not $EngineUrl) { $EngineUrl = "https://github.com/$Owner/$EngineRepo.git" }
if (-not $VoxelUrl) { $VoxelUrl = "https://github.com/$Owner/$VoxelRepo.git" }

Ensure-Repo 'Gen1Recomp' $EngineUrl $Game
Ensure-Repo 'Dramatic Shape Voxel Mod' $VoxelUrl $Mod

if (-not $SkipSetup) {
    $setup = Join-Path $Root 'setup-vr.ps1'
    Write-Host 'Preparing LOVE, generated data, and the voxel-mod link...' -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -RomPath $RomPath
    if ($LASTEXITCODE -ne 0) {
        Stop-Install "setup-vr.ps1 failed with code $LASTEXITCODE."
    }
}

$launcher = if ($Mode -eq 'VR') {
    Join-Path $Root 'Play-VR.bat'
} else {
    Join-Path $Root 'Play-Windows.bat'
}

if ($Mode -eq 'VR') {
    $bridgeCandidates = @(
        (Join-Path $Root 'xrbridge.dll'),
        (Join-Path $Game 'vrbridge\build\Release\xrbridge.dll'),
        (Join-Path $Game 'vrbridge\build\xrbridge.dll')
    )
    $bridge = @($bridgeCandidates | Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
    } | Select-Object -First 1)
    if (-not $bridge) {
        Write-Host ''
        Write-Host 'VR files are installed, but xrbridge.dll is not present.' -ForegroundColor Yellow
        Write-Host 'Build it with .\build-vrbridge.ps1, or place a matching x64 bridge beside this script.' -ForegroundColor Yellow
        Write-Host 'The desktop mode is ready; VR launch will remain unavailable until the bridge is added.' -ForegroundColor Yellow
        if ($Launch) { exit 1 }
    }
}

Write-Host ''
Write-Host "Install complete for $Mode mode." -ForegroundColor Green
Write-Host "Launcher: $launcher" -ForegroundColor Green

if ($Launch) {
    & $launcher
    exit $LASTEXITCODE
}
