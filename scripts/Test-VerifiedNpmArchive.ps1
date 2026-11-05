#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $PackageFile,
    [Parameter(Mandatory)][string] $WorkDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$work = [IO.Path]::GetFullPath($WorkDirectory)
if (-not [IO.Path]::IsPathFullyQualified($WorkDirectory)) { throw 'Use an absolute dedicated work directory' }
if ($IsWindows -and $work -inotmatch '^D:\\') { throw 'Use a dedicated D: work directory on Windows' }
$cursor = $work
while ($cursor) {
    if (Test-Path -LiteralPath $cursor) {
        $item = Get-Item -Force -LiteralPath $cursor
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point forbidden: $cursor" }
    }
    $cursor = Split-Path -Parent $cursor
}
if (Test-Path -LiteralPath $work) {
    if (@(Get-ChildItem -Force -LiteralPath $work).Count) { throw 'Work directory must be empty' }
} else { [IO.Directory]::CreateDirectory($work) | Out-Null }
$oldTemp = $env:TEMP
$oldTmp = $env:TMP
$oldTmpDir = $env:TMPDIR
try {
    $env:TEMP = $work
    $env:TMP = $work
    $env:TMPDIR = $work
    $verified = & (Join-Path $PSScriptRoot 'Verify-BunPackage.ps1') -PackageFile $PackageFile
    if ($verified.Files -ne 6) { throw 'Verifier did not validate all six archive entries' }
    Write-Output 'PASS production archive verifier: six entries and source bytes/manifest match'
    $manifest = Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'package.json') | ConvertFrom-Json
    Add-Type -Path (Join-Path $PSScriptRoot 'NpmPublisher.cs'), (Join-Path $PSScriptRoot 'NpmPublisher.ArchiveIntegration.Tests.cs')
    [Kagayoi.Npm.ArchiveIntegrationTests]::Run($verified.PackageFile, $verified.Integrity, $manifest.name, $manifest.version, $work)
} finally {
    $env:TEMP = $oldTemp
    $env:TMP = $oldTmp
    $env:TMPDIR = $oldTmpDir
}
