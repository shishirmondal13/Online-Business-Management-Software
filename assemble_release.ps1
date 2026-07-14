$ErrorActionPreference = "Stop"

$projectDir = "d:\web app\I-buzz bd mangement"
$sourceDir = "$projectDir\build\windows\x64\runner\Release"
$releaseDir = "$projectDir\ReleaseBundle"

# Create ReleaseBundle directory
if (Test-Path $releaseDir) {
    Remove-Item -Path $releaseDir -Recurse -Force
}

Write-Host "Copying entire Release folder..."
Copy-Item -Path $sourceDir -Destination $releaseDir -Recurse

Write-Host "Bundle created successfully at $releaseDir"
Get-ChildItem $releaseDir
