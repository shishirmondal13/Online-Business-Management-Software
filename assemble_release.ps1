$ErrorActionPreference = "Stop"

# Stop any active app processes so files are not locked
Get-Process -Name "ibuzz_bd_management" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$projectDir = "d:\web app\I-buzz bd mangement"
$sourceDir = "$projectDir\build\windows\x64\runner\Release"
$releaseDir = "$projectDir\ReleaseBundle"

if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir -Force
} else {
    Remove-Item -Path "$releaseDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $sourceDir)) {
    throw "Release source directory not found: $sourceDir"
}

Write-Host "Copying fresh Release files into ReleaseBundle..."
Copy-Item -Path "$sourceDir\*" -Destination $releaseDir -Recurse -Force

if (-not (Test-Path (Join-Path $releaseDir 'ibuzz_bd_management.exe'))) {
    throw "Release copy did not produce ibuzz_bd_management.exe"
}

Write-Host "Bundle updated successfully at $releaseDir"
Get-ChildItem $releaseDir
