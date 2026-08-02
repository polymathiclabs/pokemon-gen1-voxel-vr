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
$packageName = "pokemon-gen1-voxel-$($Mode.ToLowerInvariant())-$Version"
$package = Join-Path $OutputDirectory $packageName
$archive = Join-Path $OutputDirectory "$packageName.zip"

function Stop-Package([string]$Message) {
    throw "Release packaging stopped: $Message"
}

function Copy-File([string]$Source, [string]$Destination) {
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Stop-Package "Required source file is missing: $Source"
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Copy-TrackedFiles([string]$Repository, [string[]]$Paths, [string]$Destination) {
    $files = @(& git -C $Repository ls-files -- $Paths)
    if ($LASTEXITCODE -ne 0) {
        Stop-Package "Could not enumerate tracked files in $Repository."
    }

    foreach ($relative in $files) {
        if (-not $relative) { continue }
        $source = Join-Path $Repository $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            Stop-Package "Tracked file is missing from $Repository`: $relative"
        }
        $target = Join-Path $Destination $relative
        $parent = Split-Path -Parent $target
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
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
        'README.md', 'rom-info.ps1', 'Play-Windows.bat', 'Play-VR.bat',
        'launch-desktop.ps1', 'launch-vr.ps1', 'play-vr.ps1',
        'setup-vr.ps1', 'set-steamvr-openxr.ps1', 'build-vrbridge.ps1',
        'LICENSE', 'THIRD-PARTY-NOTICES.md', 'RELEASE-CHECKLIST.md'
    )) {
        Copy-Item -LiteralPath (Join-Path $Root $file) -Destination $package
    }

    $packagedGame = Join-Path $package 'gen1recomp'
    New-Item -ItemType Directory -Path $packagedGame -Force | Out-Null
    Copy-TrackedFiles $Game @('conf.lua', 'main.lua', 'assets', 'data', 'scripts', 'src', 'tools') $packagedGame

    $packagedMod = Join-Path $package 'DramaticShapeVoxelMod'
    New-Item -ItemType Directory -Path $packagedMod -Force | Out-Null
    Copy-TrackedFiles $Mod @('LICENSE-POLYMATIC-LABS.md', 'manifest.json', 'mod.card', 'main.lua', 'assets', 'data', 'lib') $packagedMod

    $licenseDirectory = Join-Path $package 'LICENSES'
    New-Item -ItemType Directory -Path $licenseDirectory -Force | Out-Null
    Copy-File (Join-Path $Game 'LICENSE.MD') (Join-Path $licenseDirectory 'GEN1RECOMP-LICENSE.MD')
    Copy-File (Join-Path $Mod 'LICENSE-POLYMATIC-LABS.md') (Join-Path $licenseDirectory 'DRAMATICSHAPE-POLYMATIC-LABS-LICENSE.md')

    if ($Mode -eq 'VR') {
        if (-not $BridgePath) {
            $BridgePath = Join-Path $Root 'xrbridge.dll'
        }
        if (-not (Test-Path -LiteralPath $BridgePath -PathType Leaf)) {
            Stop-Package 'VR packages require a matching x64 xrbridge.dll. Pass -BridgePath or place it at the workspace root.'
        }
        Copy-Item -LiteralPath $BridgePath -Destination (Join-Path $package 'xrbridge.dll')
    }

    $forbidden = @(Get-ChildItem -LiteralPath $package -Recurse -File | Where-Object {
        $relative = $_.FullName.Substring($package.Length + 1)
        $_.Extension.ToLowerInvariant() -in @('.gb', '.gbc', '.sav') -or
        $relative -match '(^|[\\/])(data|assets)[\\/]generated([\\/]|$)'
    })
    if ($forbidden.Count -gt 0) {
        $names = ($forbidden | ForEach-Object { $_.FullName }) -join '; '
        Stop-Package "Forbidden ROM, save, or generated data entered the package: $names"
    }

    Compress-Archive -Path (Join-Path $package '*') -DestinationPath $archive -CompressionLevel Optimal
    Write-Host "Created $archive" -ForegroundColor Green
    Write-Host 'The archive contains tracked source and launcher files only; ROM and generated ROM-derived files are excluded.' -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $package) {
        Remove-Item -LiteralPath $package -Recurse -Force
    }
}
