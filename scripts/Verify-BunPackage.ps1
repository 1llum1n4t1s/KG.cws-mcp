#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string] $PackageFile)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$archive = (Resolve-Path -LiteralPath $PackageFile).ProviderPath
$manifestJson = Get-Content -Raw -LiteralPath (Join-Path $root 'package.json')
$manifest = $manifestJson | ConvertFrom-Json -AsHashtable
$server = Get-Content -Raw -LiteralPath (Join-Path $root 'server.json') | ConvertFrom-Json -AsHashtable
if ($manifest.name -cne '@kagayoi/cws-mcp' -or $manifest.version -cnotmatch '^\d+\.\d+\.\d+$' -or
    $server.version -cne $manifest.version -or $server.packages[0].version -cne $manifest.version -or
    $server.packages[0].identifier -cne $manifest.name) { throw 'Package metadata differs' }
if ($manifest.main -cne 'dist/index.js' -or $manifest.bin.Count -ne 1 -or $manifest.bin['cws-mcp'] -cne 'dist/index.js' -or
    $manifest.files.Count -ne 3 -or $manifest.files[0] -cne 'dist/**/*' -or $manifest.files[1] -cne 'LICENSE' -or $manifest.files[2] -cne 'README.md') { throw 'Package entry point or files contract differs' }
$expected = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
foreach ($file in @('LICENSE', 'README.ko.md', 'README.md', 'dist/index.d.ts', 'dist/index.js', 'package.json')) {
    $expected.Add('package/' + $file, (Join-Path $root $file))
}
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
# The archive is read once: inspection and integrity both consume these bytes.
$archiveBytes = [IO.File]::ReadAllBytes($archive)
$stream = [IO.MemoryStream]::new($archiveBytes, $false)
try {
    $gzip = [IO.Compression.GZipStream]::new($stream, [IO.Compression.CompressionMode]::Decompress)
    try {
        $reader = [System.Formats.Tar.TarReader]::new($gzip)
        try {
            while ($entry = $reader.GetNextEntry()) {
                if ($entry.EntryType -notin @([System.Formats.Tar.TarEntryType]::RegularFile, [System.Formats.Tar.TarEntryType]::V7RegularFile)) { throw "Unexpected archive entry type: $($entry.Name)" }
                if (-not $expected.ContainsKey($entry.Name) -or -not $seen.Add($entry.Name)) { throw "Unexpected or duplicate archive entry: $($entry.Name)" }
                $buffer = [IO.MemoryStream]::new()
                try { $entry.DataStream.CopyTo($buffer); $bytes = $buffer.ToArray() } finally { $buffer.Dispose() }
                if ($entry.Name -ceq 'package/package.json') {
                    # Bun may reformat JSON; preserve every value while ignoring formatting and key order.
                    $packed = [System.Text.Json.Nodes.JsonNode]::Parse([Text.Encoding]::UTF8.GetString($bytes))
                    $source = [System.Text.Json.Nodes.JsonNode]::Parse($manifestJson)
                    if (-not [System.Text.Json.Nodes.JsonNode]::DeepEquals($packed, $source)) { throw 'Archive manifest differs from package.json' }
                } elseif (-not [Linq.Enumerable]::SequenceEqual[byte]($bytes, [IO.File]::ReadAllBytes($expected[$entry.Name]))) { throw "Archive contents differ: $($entry.Name)" }
                if ($entry.Name -ceq 'package/dist/index.js' -and (([int]$entry.Mode -band 73) -ne 73)) { throw 'Archive CLI is not executable' }
            }
        } finally { $reader.Dispose() }
    } finally { $gzip.Dispose() }
} finally { $stream.Dispose() }
if ($seen.Count -ne $expected.Count) { throw 'Archive is missing expected files' }
$integrity = 'sha512-' + [Convert]::ToBase64String([Security.Cryptography.SHA512]::HashData($archiveBytes))
[pscustomobject]@{ PackageFile = $archive; Integrity = $integrity; Files = $seen.Count }
