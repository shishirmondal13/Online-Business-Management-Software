$ErrorActionPreference = "Stop"

# Get the user's Desktop path
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

if (-not $DesktopPath) {
    Write-Error "Could not locate the Desktop folder automatically."
    exit 1
}

# Paths to executable and working directory
$targetPath = "d:\web app\I-buzz bd mangement\ReleaseBundle\ibuzz_bd_management.exe"
$workingDir = "d:\web app\I-buzz bd mangement\ReleaseBundle"

if (-not (Test-Path $targetPath)) {
    Write-Error "Executable not found at $targetPath. Please run build or assemble_release.ps1 first."
    exit 1
}

Write-Host "Creating Desktop shortcut..."

# Create WScript Shell COM Object
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\I-Buzz BD Management.lnk")
$Shortcut.TargetPath = $targetPath
$Shortcut.WorkingDirectory = $workingDir
$Shortcut.Description = "I-Buzz BD Management System"
$Shortcut.IconLocation = "$targetPath,0"
$Shortcut.Save()

Write-Host "✅ Shortcut created successfully on your Desktop as 'I-Buzz BD Management'!"
Write-Host "Path: $DesktopPath\I-Buzz BD Management.lnk"
