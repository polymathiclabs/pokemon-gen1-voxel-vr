# Canonical Pokemon Red/Blue/Yellow ROM identification shared by the launchers.

$PokemonRomDefinitions = @(
    [PSCustomObject]@{
        Id = 'red'
        DisplayName = 'Pokemon Red'
        Sha1 = 'ea9bcae617fdf159b045185467ae58b2e4a48b9a'
    }
    [PSCustomObject]@{
        Id = 'blue'
        DisplayName = 'Pokemon Blue'
        Sha1 = 'd7037c83e1ae5b39bde3c30787637ba1d4c48ce2'
    }
    [PSCustomObject]@{
        Id = 'yellow'
        DisplayName = 'Pokemon Yellow'
        Sha1 = 'cc7d03262ebfaf2f06772c1a480c7d9d5f4a38e1'
    }
)

function Get-PokemonRomInfo {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$SearchRoot = $PSScriptRoot
    )

    if (-not $Path) {
        $defaultPath = Join-Path $SearchRoot 'Pokemon Red.gb'
        if (Test-Path -LiteralPath $defaultPath -PathType Leaf) {
            $Path = $defaultPath
        } else {
            $matches = @()
            foreach ($candidate in Get-ChildItem -LiteralPath $SearchRoot -File |
                Where-Object { $_.Extension.ToLowerInvariant() -in @('.gb', '.gbc') }) {
                try {
                    $candidateHash = (Get-FileHash -Algorithm SHA1 -LiteralPath $candidate.FullName).Hash.ToLowerInvariant()
                    if ($PokemonRomDefinitions.Sha1 -contains $candidateHash) {
                        $matches += $candidate
                    }
                } catch {}
            }
            if ($matches.Count -eq 0) {
                throw "No supported Pokemon Red, Blue, or Yellow ROM was found in $SearchRoot."
            }
            if ($matches.Count -gt 1) {
                $names = ($matches | ForEach-Object { $_.Name }) -join ', '
                throw "Multiple supported ROMs were found: $names. Pass -RomPath to choose one."
            }
            $Path = $matches[0].FullName
        }
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "ROM not found: $Path"
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $sha1 = (Get-FileHash -Algorithm SHA1 -LiteralPath $resolved).Hash.ToLowerInvariant()
    $match = $PokemonRomDefinitions | Where-Object { $_.Sha1 -eq $sha1 } |
        Select-Object -First 1
    if (-not $match) {
        $supported = ($PokemonRomDefinitions | ForEach-Object {
            "$($_.DisplayName) ($($_.Sha1))"
        }) -join '; '
        throw "Unsupported ROM SHA-1: $sha1. Supported canonical US ROMs: $supported"
    }

    return [PSCustomObject]@{
        Id = $match.Id
        DisplayName = $match.DisplayName
        Sha1 = $sha1
        Path = $resolved
    }
}
