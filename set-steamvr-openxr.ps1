# Set the 64-bit Windows OpenXR runtime used by the VR launcher.
# This file is normally started elevated by launch-vr.ps1.

param(
    [Parameter(Mandatory = $true)]
    [string]$RuntimePath
)

$ErrorActionPreference = 'Stop'
$key = 'HKLM:\SOFTWARE\Khronos\OpenXR\1'
if (-not (Test-Path -LiteralPath $RuntimePath -PathType Leaf)) {
    throw "OpenXR runtime profile not found: $RuntimePath"
}
if (-not (Test-Path -LiteralPath $key)) {
    New-Item -Path $key -Force | Out-Null
}
Set-ItemProperty -LiteralPath $key -Name ActiveRuntime -Value ((Resolve-Path -LiteralPath $RuntimePath).Path)
$actual = (Get-ItemProperty -LiteralPath $key -Name ActiveRuntime).ActiveRuntime
if ([IO.Path]::GetFullPath($actual).TrimEnd('\').ToLowerInvariant() -ne
    [IO.Path]::GetFullPath($RuntimePath).TrimEnd('\').ToLowerInvariant()) {
    throw "Windows did not accept the requested OpenXR runtime: $actual"
}
Write-Host "Active OpenXR runtime set to $actual"
