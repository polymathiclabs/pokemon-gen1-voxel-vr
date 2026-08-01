# Build a distributable source-based ZIP without ROMs or ROM-derived output.
# The maintainer runs this after the three local repositories are prepared.

[CmdletBinding()]
param(
    [ValidateSet('Desktop', 'VR')]
    [string]$Mode = 'Desktop',
    [string]$Version = 'dev',
    [string]$OutputDirectory,
    [string]$BridgePath
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$OutputDirectory = if ($OutputDirectory) {
    $OutputDirectory
} else {
    Join-Path $Root 'dist'
}
$Game = Join-Path $Root 'gen1recomp'
$Mod = Join-Path $Root 'DramaticShapeVoxelMod'
$packageName = "pokemon-red-voxel-$($Mode.ToLowerInvariant())-$Version"
$package = Join-Path $OutputDirectory $packageName
$archive = Join-Path $OutputDirectory "$packageName.zip"

function Stop-Package([string]$Message) {
    throw "Release packaging stopped: $Message"
}

function Copy-Directory([string]$Source, [string]$Destination) {
    if (Test-Path -LiteralPath $Source -PathType Container) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    } else {
        Stop-Package "Required source directory is missing: $Source"
    }
}

function Copy-File([string]$Source, [string]$Destination) {
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Stop-Package "Required source file is missing: $Source"
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Assert-CleanCheckout([string]$Repository) {
    if (-not (Test-Path -LiteralPath (Join-Path $Repository '.git'))) {
        Stop-Package "$Repository is not a Git checkout."
    }
    $dirty = & git -C $Repository status --porcelain
    if ($dirty) {
        Stop-Package "$Repository has uncommitted changes. Commit the release state first."
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Stop-Package 'Git is required by the maintainer packaging step.'
}
foreach ($required in @($Game, $Mod)) {
    if (-not (Test-Path -LiteralPath $required -PathType Container)) {
        Stop-Package "Required repository is missing: $required"
    }
    Assert-CleanCheckout $required
}
if (Test-Path -LiteralPath $package) {
    Stop-Package "$package already exists. Choose another -Version or remove the old staging folder."
}
if (Test-Path -LiteralPath $archive) {
    Stop-Package "$archive already exists. Choose another -Version or remove the old archive."
}

New-Item -ItemType Directory -Path $package -Force | Out-Null
try {
    foreach ($file in @(
        'README.md', 'Play-Windows.bat', 'Play-VR.bat',
        'launch-desktop.ps1', 'launch-vr.ps1', 'play-vr.ps1',
        'setup-vr.ps1', 'set-steamvr-openxr.ps1', 'build-vrbridge.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $Root $file) -Destination $package
    }

    $packagedGame = Join-Path $package 'gen1recomp'
    New-Item -ItemType Directory -Path $packagedGame -Force | Out-Null
    foreach ($file in @('conf.lua', 'main.lua')) {
        Copy-File (Join-Path $Game $file) (Join-Path $packagedGame $file)
    }
    foreach ($directory in @('assets', 'data', 'scripts', 'src', 'tools')) {
        Copy-Directory (Join-Path $Game $directory) (Join-Path $packagedGame $directory)
    }
    foreach ($generated in @(
        (Join-Path $packagedGame 'data\generated'),
        (Join-Path $packagedGame 'assets\generated')
    )) {
        if (Test-Path -LiteralPath $generated) {
            Remove-Item -LiteralPath $generated -Recurse -Force
        }
    }

    $packagedMod = Join-Path $package 'DramaticShapeVoxelMod'
    New-Item -ItemType Directory -Path $packagedMod -Force | Out-Null
    foreach ($file in @('manifest.json', 'mod.card', 'main.lua')) {
        Copy-File (Join-Path $Mod $file) (Join-Path $packagedMod $file)
    }
    foreach ($directory in @('assets', 'data', 'lib')) {
        Copy-Directory (Join-Path $Mod $directory) (Join-Path $packagedMod $directory)
    }

    if ($Mode -eq 'VR') {
        if (-not $BridgePath) {
            $BridgePath = Join-Path $Root 'xrbridge.dll'
        }
        if (-not (Test-Path -LiteralPath $BridgePath -PathType Leaf)) {
            Stop-Package 'VR packages require a matching x64 xrbridge.dll. Pass -BridgePath or place it at the workspace root.'
        }
        Copy-Item -LiteralPath $BridgePath -Destination (Join-Path $package 'xrbridge.dll')
    }

    Compress-Archive -Path (Join-Path $package '*') -DestinationPath $archive -CompressionLevel Optimal
    Write-Host "Created $archive" -ForegroundColor Green
    Write-Host 'The archive contains source and launcher files only; ROM and generated ROM-derived files are excluded.' -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $package) {
        Remove-Item -LiteralPath $package -Recurse -Force
    }
}
