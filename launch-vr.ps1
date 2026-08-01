# One-click launcher for the optional SteamVR/OpenXR build.
#
# This script prepares the local checkout when necessary, finds SteamVR even
# when Steam is installed outside its default folder, selects SteamVR as the
# active OpenXR runtime, and launches the game with the native bridge.

[CmdletBinding()]
param(
    [string]$XrBridge = $env:POKEPORT_XRBRIDGE,
    [string]$RomPath,
    [switch]$SkipSetup,
    [switch]$SkipSteamVR,
    [switch]$NoRuntimeSwitch,
    [switch]$CheckOnly,
    [switch]$DesktopPreview
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Game = Join-Path $Root 'gen1recomp'
$SetupScript = Join-Path $Root 'setup-vr.ps1'
$PlayScript = Join-Path $Root 'play-vr.ps1'
$RomInfoScript = Join-Path $Root 'rom-info.ps1'

function Stop-Launcher([string]$Message) {
    Write-Host ''
    Write-Host "VR launcher stopped: $Message" -ForegroundColor Red
    exit 1
}

function Invoke-ProjectScript([string]$Script, [object[]]$Arguments) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script @Arguments
    if ($LASTEXITCODE -ne 0) {
        Stop-Launcher "'$Script' exited with code $LASTEXITCODE."
    }
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
        $resolvedMod = (Resolve-Path -LiteralPath (Join-Path $Root 'DramaticShapeVoxelMod')).Path
        return $resolvedLink.TrimEnd('\') -eq $resolvedMod.TrimEnd('\')
    } catch {
        return $false
    }
}

function Get-SteamRoots {
    $roots = @()
    $registryLocations = @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'
    )

    foreach ($location in $registryLocations) {
        try {
            $properties = Get-ItemProperty -LiteralPath $location -ErrorAction Stop
            foreach ($propertyName in 'InstallPath', 'SteamPath') {
                $installPath = $properties.$propertyName
                if ($installPath) { $roots += $installPath }
            }
        } catch {}
    }

    $roots += @(
        "${env:ProgramFiles(x86)}\Steam",
        "$env:ProgramFiles\Steam",
        "$env:LOCALAPPDATA\Steam"
    )

    return @($roots | Where-Object {
        $_ -and (Test-Path -LiteralPath (Join-Path $_ 'steam.exe') -PathType Leaf)
    } | Select-Object -Unique)
}

function Get-SteamLibraries([string[]]$SteamRoots) {
    $libraries = @($SteamRoots)
    foreach ($steamRoot in $SteamRoots) {
        $libraryFile = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $libraryFile -PathType Leaf)) { continue }

        $contents = Get-Content -LiteralPath $libraryFile -Raw
        foreach ($match in [regex]::Matches($contents, '"path"\s+"([^"]+)"')) {
            $library = $match.Groups[1].Value -replace '\\\\', '\'
            if ($library) { $libraries += $library }
        }
    }
    return @($libraries | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } | Select-Object -Unique)
}

function Get-ActiveOpenXRRuntime {
    foreach ($location in @(
        'HKLM:\SOFTWARE\Khronos\OpenXR\1',
        'HKLM:\SOFTWARE\WOW6432Node\Khronos\OpenXR\1',
        'HKCU:\Software\Khronos\OpenXR\1'
    )) {
        try {
            $value = (Get-ItemProperty -LiteralPath $location -Name ActiveRuntime -ErrorAction Stop).ActiveRuntime
            if ($value) { return $value }
        } catch {}
    }
    return $null
}

function Normalize-Path([string]$Path) {
    if (-not $Path) { return '' }
    try { return [IO.Path]::GetFullPath($Path).TrimEnd('\').ToLowerInvariant() }
    catch { return $Path.TrimEnd('\').ToLowerInvariant() }
}

function Test-SteamRuntime([string]$Path, [string]$ExpectedPath) {
    return [bool]($Path -and $ExpectedPath -and
        ((Normalize-Path $Path) -eq (Normalize-Path $ExpectedPath)))
}

if (-not (Test-Path -LiteralPath $Game -PathType Container)) {
    Stop-Launcher "the gen1recomp folder is missing from $Root."
}
if (-not (Test-Path -LiteralPath $SetupScript -PathType Leaf)) {
    Stop-Launcher 'setup-vr.ps1 is missing.'
}
if (-not (Test-Path -LiteralPath $PlayScript -PathType Leaf)) {
    Stop-Launcher 'play-vr.ps1 is missing.'
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
if ((-not $SkipSetup) -and $needsSetup) {
    Write-Host 'Preparing LOVE 11.5 and the voxel mod...' -ForegroundColor Cyan
    Invoke-ProjectScript $SetupScript @('-RomPath', $RomPath)
    $LoveBin = Find-Love
}

if (-not $LoveBin) {
    Stop-Launcher 'LOVE 11.5 was not found. Run setup-vr.ps1 or install LOVE 11.5.'
}
if (-not (Test-VoxelModLink)) {
    Stop-Launcher 'the voxel mod junction is missing or points at the wrong folder. Run setup-vr.ps1.'
}
$loveVersion = Get-LoveVersion $LoveBin
if ($loveVersion -notmatch '11\.5') {
    Stop-Launcher "LOVE 11.5 is required; found '$loveVersion' at $LoveBin."
}

$bridgeCandidates = @()
if ($XrBridge) { $bridgeCandidates += $XrBridge }
$bridgeCandidates += @(
    (Join-Path $Root 'xrbridge.dll'),
    (Join-Path $Game 'vrbridge\xrbridge.dll'),
    (Join-Path $Game 'vrbridge\build\Release\xrbridge.dll'),
    (Join-Path $Game 'vrbridge\build\xrbridge.dll')
)
$BridgePath = @($bridgeCandidates | Where-Object {
    $_ -and (Test-Path -LiteralPath $_ -PathType Leaf)
} | Select-Object -First 1)
if ($BridgePath) { $BridgePath = (Resolve-Path -LiteralPath $BridgePath).Path }
if ($DesktopPreview) { $BridgePath = $null }

if (-not $DesktopPreview -and -not $BridgePath -and -not $CheckOnly) {
    Stop-Launcher "xrbridge.dll was not found. Build it using gen1recomp\vrbridge\README.md, or run with -DesktopPreview."
}

$SteamRoot = $null
$SteamExe = $null
$VrMonitor = $null
$SteamVrBin = $null
$SteamVrRoot = $null
$SteamXrJson = $null
$RuntimeSetter = Join-Path $Root 'set-steamvr-openxr.ps1'

if (-not $DesktopPreview) {
    $steamRoots = Get-SteamRoots
    if (-not $steamRoots) {
        Stop-Launcher 'Steam was not found. Install Steam before launching the headset build.'
    }
    $SteamRoot = $steamRoots[0]
    $SteamExe = Join-Path $SteamRoot 'steam.exe'

    $libraries = Get-SteamLibraries $steamRoots
    foreach ($library in $libraries) {
        $candidate = Join-Path $library 'steamapps\common\SteamVR\bin\win64\vrmonitor.exe'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $VrMonitor = $candidate
            break
        }
    }
    if (-not $VrMonitor) {
        Stop-Launcher 'SteamVR was not found in the Steam libraries. Install SteamVR from Steam first.'
    }

    $SteamVrBin = Split-Path -Parent $VrMonitor
    $SteamVrRoot = Split-Path -Parent (Split-Path -Parent $SteamVrBin)
    $SteamXrJson = Join-Path $SteamVrRoot 'steamxr_win64.json'
    $OpenXrLoader = Join-Path $SteamVrBin 'openxr_loader.dll'
    if (-not (Test-Path -LiteralPath $SteamXrJson -PathType Leaf)) {
        Stop-Launcher "SteamVR's OpenXR runtime profile was not found: $SteamXrJson"
    }
    if (-not (Test-Path -LiteralPath $OpenXrLoader -PathType Leaf)) {
        Stop-Launcher "SteamVR's OpenXR loader was not found: $OpenXrLoader. Verify the SteamVR installation."
    }

    $activeRuntime = Get-ActiveOpenXRRuntime
    if ($CheckOnly) {
        Write-Host "LOVE:       $LoveBin ($loveVersion)" -ForegroundColor Green
        Write-Host "ROM:        $RomPath ($($RomInfo.DisplayName), canonical)" -ForegroundColor Green
        Write-Host "Bridge:     $(if ($BridgePath) { $BridgePath } else { '<missing>' })" -ForegroundColor $(if ($BridgePath) { 'Green' } else { 'Yellow' })
        Write-Host "SteamVR:    $VrMonitor" -ForegroundColor Green
        $runtimeReady = Test-SteamRuntime $activeRuntime $SteamXrJson
        Write-Host "OpenXR now: $(if ($activeRuntime) { $activeRuntime } else { '<not set>' })" -ForegroundColor $(if ($runtimeReady) { 'Green' } else { 'Yellow' })
        if (-not $runtimeReady) {
            Write-Host "OpenXR next: SteamVR will be selected when launched." -ForegroundColor Yellow
        }
        if (-not $BridgePath -or -not $runtimeReady) { exit 1 }
        exit 0
    }

    if (-not (Test-SteamRuntime $activeRuntime $SteamXrJson)) {
        if ($NoRuntimeSwitch) {
            Stop-Launcher "SteamVR is not the active OpenXR runtime (current: $activeRuntime). Enable it in SteamVR settings or omit -NoRuntimeSwitch."
        }
        if (-not (Test-Path -LiteralPath $RuntimeSetter -PathType Leaf)) {
            Stop-Launcher 'The OpenXR runtime helper is missing; set SteamVR as the active OpenXR runtime in SteamVR settings.'
        }
        Write-Host 'Selecting SteamVR as the active Windows OpenXR runtime (UAC may appear)...' -ForegroundColor Cyan
        $setterArguments = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
            ('"{0}"' -f $RuntimeSetter), '-RuntimePath',
            ('"{0}"' -f $SteamXrJson)
        )
        $setter = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList $setterArguments
        if ($setter.ExitCode -ne 0) {
            Stop-Launcher 'SteamVR could not be selected as the active OpenXR runtime. Approve the UAC prompt or set it manually in SteamVR settings.'
        }
        $activeRuntime = Get-ActiveOpenXRRuntime
        if (-not (Test-SteamRuntime $activeRuntime $SteamXrJson)) {
            Stop-Launcher 'SteamVR did not become the active OpenXR runtime. Set it manually in SteamVR settings.'
        }
    }
} elseif ($CheckOnly) {
    Write-Host "LOVE:       $LoveBin ($loveVersion)" -ForegroundColor Green
    Write-Host "ROM:        $RomPath ($($RomInfo.DisplayName), canonical)" -ForegroundColor Green
    Write-Host 'Mode:       desktop preview' -ForegroundColor Green
    Write-Host "Bridge:     $(if ($BridgePath) { $BridgePath } else { '<not used>' })" -ForegroundColor Green
    exit 0
}

if ($CheckOnly) {
    Write-Host "LOVE:       $LoveBin ($loveVersion)" -ForegroundColor Green
    Write-Host "ROM:        $RomPath ($($RomInfo.DisplayName), canonical)" -ForegroundColor Green
    Write-Host "Bridge:     $BridgePath" -ForegroundColor Green
    exit 0
}

if (-not $DesktopPreview) {
    if (-not (Get-Process -Name steam -ErrorAction SilentlyContinue)) {
        Write-Host 'Starting Steam...' -ForegroundColor Cyan
        Start-Process -FilePath $SteamExe -WorkingDirectory $SteamRoot | Out-Null
        Start-Sleep -Seconds 3
    }

    if (-not $SkipSteamVR -and -not (Get-Process -Name vrmonitor -ErrorAction SilentlyContinue)) {
        Write-Host 'Starting SteamVR...' -ForegroundColor Cyan
        Start-Process -FilePath $VrMonitor -WorkingDirectory $SteamVrBin | Out-Null
        Start-Sleep -Seconds 5
    }

    if (-not $SkipSteamVR) {
        $vrReady = $false
        for ($attempt = 0; $attempt -lt 15; $attempt++) {
            if (Get-Process -Name vrmonitor, vrserver, vrcompositor -ErrorAction SilentlyContinue) {
                $vrReady = $true
                break
            }
            Start-Sleep -Seconds 1
        }
        if (-not $vrReady) {
            Stop-Launcher 'SteamVR did not start. Open SteamVR manually, wait until the headset is ready, then run launch-vr.bat again.'
        }
    }

    # The bridge loads openxr_loader.dll dynamically. Add SteamVR's native
    # directory so that Windows can resolve it when LOVE loads the bridge.
    $env:Path = "$SteamVrBin;$(Split-Path -Parent $LoveBin);$env:Path"
}

$env:POKEPORT_VR = '1'
$env:POKEPORT_VR_REQUIRED = if ($DesktopPreview) { '0' } else { '1' }
$env:POKEPORT_VR_DIAGNOSTIC = if ($DesktopPreview) { '0' } else { '1' }
$env:POKEPORT_VERSION = $RomInfo.Id
$env:POKEPORT_IMPORT_ROM = $RomPath
if ($BridgePath) { $env:POKEPORT_XRBRIDGE = $BridgePath }

$playArguments = @('-RomPath', $RomPath)
if ($BridgePath) { $playArguments += @('-XrBridge', $BridgePath) }
Write-Host "Launching the $($RomInfo.DisplayName) voxel build..." -ForegroundColor Green
Invoke-ProjectScript $PlayScript $playArguments
