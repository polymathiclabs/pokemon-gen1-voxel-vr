# Build the optional x64 SteamVR/OpenXR bridge used by launch-vr.bat.
# The script uses the LuaJIT DLL shipped with the installed x64 LÖVE build and
# generates the matching import library from its exports.

[CmdletBinding()]
param(
    [string]$OpenXrSdk,
    [string]$LuaJitRoot,
    [string]$LoveDll,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$BridgeRoot = Join-Path $Root 'gen1recomp\vrbridge'
if (-not $OpenXrSdk) { $OpenXrSdk = Join-Path $Root '.vr-build\OpenXR-SDK' }
if (-not $LuaJitRoot) { $LuaJitRoot = Join-Path $Root '.vr-build\LuaJIT' }
if (-not $LoveDll) { $LoveDll = 'C:\Program Files\LOVE\lua51.dll' }

function Fail([string]$Message) {
    throw "VR bridge build failed: $Message"
}

function Find-CMake {
    $command = Get-Command cmake -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $packages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $candidate = Get-ChildItem -LiteralPath $packages -Recurse -Filter cmake.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1
    return $candidate.FullName
}

function Find-VsWhere {
    foreach ($candidate in @(
        'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe',
        'C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe'
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

function Find-VsInstall {
    $vswhere = Find-VsWhere
    if ($vswhere) {
        $path = (& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Out-String).Trim()
        if ($path -and (Test-Path -LiteralPath $path -PathType Container)) { return $path }
    }
    foreach ($candidate in @(
        'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools',
        'C:\Program Files\Microsoft Visual Studio\2022\BuildTools'
    )) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'VC\Auxiliary\Build\vcvars64.bat')) {
            return $candidate
        }
    }
    return $null
}

function Find-VcTool([string]$VsInstall, [string]$Name) {
    $tool = Get-ChildItem -LiteralPath (Join-Path $VsInstall 'VC\Tools\MSVC') -Recurse -Filter $Name -File |
        Where-Object { $_.FullName -match '\\bin\\Hostx64\\x64\\' } |
        Sort-Object FullName -Descending | Select-Object -First 1
    return $tool.FullName
}

$CMake = Find-CMake
if (-not $CMake -or -not (Test-Path -LiteralPath $CMake -PathType Leaf)) {
    Fail 'CMake was not found. Install CMake and run this script again.'
}
$VsInstall = Find-VsInstall
if (-not $VsInstall) {
    Fail 'Visual Studio 2022 C++ Build Tools were not found.'
}
$DumpBin = Find-VcTool $VsInstall 'dumpbin.exe'
$LibTool = Find-VcTool $VsInstall 'lib.exe'
if (-not $DumpBin -or -not $LibTool) {
    Fail 'MSVC dumpbin.exe/lib.exe were not found. Install the Desktop C++ workload.'
}

$OpenXrInclude = Join-Path $OpenXrSdk 'include'
$LuaJitInclude = Join-Path $LuaJitRoot 'src'
foreach ($required in @(
    (Join-Path $OpenXrInclude 'openxr\openxr.h'),
    (Join-Path $OpenXrInclude 'openxr\openxr_platform.h'),
    (Join-Path $LuaJitInclude 'lua.h'),
    (Join-Path $LuaJitInclude 'lauxlib.h'),
    $LoveDll
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        Fail "required dependency was not found: $required"
    }
}

$BuildRoot = Join-Path $Root '.vr-build'
$ImportDef = Join-Path $BuildRoot 'lua51-love.def'
$ImportLib = Join-Path $BuildRoot 'lua51-love.lib'
New-Item -ItemType Directory -Path $BuildRoot -Force | Out-Null

Write-Host 'Generating a LuaJIT import library from LOVE lua51.dll...' -ForegroundColor Cyan
$exports = @(& $DumpBin /exports $LoveDll | ForEach-Object {
    if ($_ -match '^\s+\d+\s+[0-9A-Fa-f]+\s+[0-9A-Fa-f]+\s+(\S+)\s*$') {
        $Matches[1]
    }
} | Sort-Object -Unique)
if ($exports.Count -lt 20) { Fail "no usable exports were found in $LoveDll" }

$defLines = @('LIBRARY lua51.dll', 'EXPORTS') + $exports
Set-Content -LiteralPath $ImportDef -Value $defLines -Encoding ascii
& $LibTool /def:$ImportDef /machine:X64 /out:$ImportLib | Out-Host
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ImportLib -PathType Leaf)) {
    Fail 'MSVC could not create the LuaJIT import library.'
}

$BuildDir = Join-Path $BridgeRoot 'build'
if ($Clean -and (Test-Path -LiteralPath $BuildDir -PathType Container)) {
    Remove-Item -LiteralPath $BuildDir -Recurse -Force
}

Write-Host 'Configuring the x64 bridge...' -ForegroundColor Cyan
$configureArgs = @(
    '-S', $BridgeRoot,
    '-B', $BuildDir,
    '-G', 'Visual Studio 17 2022',
    '-A', 'x64',
    "-DOPENXR_INCLUDE_DIR=$OpenXrInclude",
    "-DLUAJIT_INCLUDE_DIR=$LuaJitInclude",
    "-DLUAJIT_LIBRARY=$ImportLib"
)
& $CMake @configureArgs | Out-Host
if ($LASTEXITCODE -ne 0) { Fail 'CMake configuration failed.' }

Write-Host 'Compiling xrbridge.dll...' -ForegroundColor Cyan
& $CMake '--build', $BuildDir, '--config', 'Release' | Out-Host
if ($LASTEXITCODE -ne 0) { Fail 'CMake compilation failed.' }

$Output = Join-Path $BuildDir 'Release\xrbridge.dll'
if (-not (Test-Path -LiteralPath $Output -PathType Leaf)) {
    Fail "the build completed without producing $Output"
}
Write-Host "Bridge ready: $Output" -ForegroundColor Green
