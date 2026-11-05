$ErrorActionPreference = "Stop"

$projectDir = "d:\web app\I-buzz bd mangement"
$releaseBundle = "$projectDir\ReleaseBundle"
$installerDir = "$projectDir\windows_installer"
$outputMsi = "$installerDir\Smart_Buy_Online_Setup.msi"
$releasesDir = "$projectDir\Releases"

if (-not (Test-Path $releaseBundle)) {
    throw "ReleaseBundle folder not found at $releaseBundle"
}

if (-not (Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
}

if (-not (Test-Path $releasesDir)) {
    New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null
}

Write-Host "Scanning ReleaseBundle for files..."
$files = Get-ChildItem -Path $releaseBundle -Recurse -File

$dirMap = @{}
$dirCounter = 1
$componentCounter = 1

# Generate relative directory structure
$xmlDirs = [System.Text.StringBuilder]::new()
$xmlComponents = [System.Text.StringBuilder]::new()
$componentRefs = [System.Text.StringBuilder]::new()

# Root directory is INSTALLFOLDER
$dirMap[""] = "INSTALLFOLDER"

# Collect all unique relative directory paths
$relDirs = Get-ChildItem -Path $releaseBundle -Recurse -Directory | ForEach-Object {
    $_.FullName.Substring($releaseBundle.Length).TrimStart("\")
} | Sort-Object Length

foreach ($relDir in $relDirs) {
    $parentRel = [System.IO.Path]::GetDirectoryName($relDir)
    $dirName = [System.IO.Path]::GetFileName($relDir)
    $parentId = $dirMap[$parentRel]
    $dirId = "DIR_$dirCounter"
    $dirCounter++
    $dirMap[$relDir] = $dirId
}

# Generate Components
foreach ($file in $files) {
    $relFile = $file.FullName.Substring($releaseBundle.Length).TrimStart("\")
    $parentRel = [System.IO.Path]::GetDirectoryName($relFile)
    $dirId = $dirMap[$parentRel]
    $compId = "cmp_$componentCounter"
    $fileId = "fil_$componentCounter"
    $componentCounter++

    $fullSourcePath = $file.FullName

    [void]$xmlComponents.AppendLine("      <Component Id=`"$compId`" Directory=`"$dirId`" Guid=`"$([System.Guid]::NewGuid().ToString().ToUpper())`">")
    [void]$xmlComponents.AppendLine("        <File Id=`"$fileId`" Source=`"$fullSourcePath`" KeyPath=`"yes`" />")
    [void]$xmlComponents.AppendLine("      </Component>")

    [void]$componentRefs.AppendLine("      <ComponentRef Id=`"$compId`" />")
}

# Build Directory Tree XML
function Build-DirXml($parentRel, $indent) {
    $sb = [System.Text.StringBuilder]::new()
    $childDirs = $relDirs | Where-Object { [System.IO.Path]::GetDirectoryName($_) -eq $parentRel }
    foreach ($cDir in $childDirs) {
        $dirName = [System.IO.Path]::GetFileName($cDir)
        $dirId = $dirMap[$cDir]
        $pad = " " * $indent
        [void]$sb.AppendLine("$pad<Directory Id=`"$dirId`" Name=`"$dirName`">")
        [void]$sb.Append((Build-DirXml $cDir ($indent + 2)))
        [void]$sb.AppendLine("$pad</Directory>")
    }
    return $sb.ToString()
}

$nestedDirsXml = Build-DirXml "" 12

$wxsContent = @"
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
     xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui">
  <Package Name="Smart Buy Online"
           Manufacturer="Smart Buy Online"
           Version="1.0.0.0"
           UpgradeCode="4F58B12A-1748-4DF3-9E49-8D19A82D16C4"
           Scope="perMachine">
    
    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." />
    
    <MediaTemplate EmbedCab="yes" />

    <Icon Id="AppIcon" SourceFile="windows\runner\resources\app_icon.ico" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon" />
    <Property Id="ARPHELPLINK" Value="https://smart-buy-online.web.app" />

    <ui:WixUI Id="WixUI_Minimal" />

    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory Id="ManufacturerFolder" Name="Smart Buy Online">
        <Directory Id="INSTALLFOLDER" Name="Smart Buy Online">
$nestedDirsXml        </Directory>
      </Directory>
    </StandardDirectory>

    <StandardDirectory Id="ProgramMenuFolder">
      <Directory Id="ApplicationProgramsFolder" Name="Smart Buy Online">
        <Component Id="ApplicationShortcut" Directory="ApplicationProgramsFolder" Guid="B6E2C7E5-18A1-42FE-9092-26EC9A5B7F83">
          <Shortcut Id="ApplicationStartMenuShortcut"
                    Name="Smart Buy Online"
                    Description="Smart Buy Online - Mobile &amp; Gadget Management System"
                    Target="[INSTALLFOLDER]ibuzz_bd_management.exe"
                    WorkingDirectory="INSTALLFOLDER"
                    Icon="AppIcon" />
          <RemoveFolder Id="CleanUpShortCut" Directory="ApplicationProgramsFolder" On="uninstall" />
          <RegistryValue Root="HKCU" Key="Software\SmartBuyOnline\SmartBuyOnline" Name="installed" Type="integer" Value="1" KeyPath="yes" />
        </Component>
      </Directory>
    </StandardDirectory>

    <StandardDirectory Id="DesktopFolder">
      <Component Id="DesktopShortcutComponent" Directory="DesktopFolder" Guid="E32D96C1-2856-42AB-963F-A9F71B043B4E">
        <Shortcut Id="DesktopShortcut"
                  Name="Smart Buy Online"
                  Description="Smart Buy Online - Mobile &amp; Gadget Management System"
                  Target="[INSTALLFOLDER]ibuzz_bd_management.exe"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="AppIcon" />
        <RegistryValue Root="HKCU" Key="Software\SmartBuyOnline\SmartBuyOnline" Name="desktop_shortcut" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </StandardDirectory>

    <ComponentGroup Id="ProductComponents">
$($xmlComponents.ToString())    </ComponentGroup>

    <Feature Id="MainFeature" Title="Smart Buy Online" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
      <ComponentRef Id="ApplicationShortcut" />
      <ComponentRef Id="DesktopShortcutComponent" />
    </Feature>
  </Package>
</Wix>
"@

$wxsPath = "$installerDir\Package.wxs"
Set-Content -Path $wxsPath -Value $wxsContent -Encoding utf8

Write-Host "Compiling MSI using WiX..."
wix build "$wxsPath" -ext WixToolset.UI.wixext -o "$outputMsi" -arch x64

if (-not (Test-Path $outputMsi)) {
    throw "MSI build failed: $outputMsi not found."
}

$destMsi = "$releasesDir\Smart_Buy_Online_Setup_v1.0.0.msi"
Copy-Item -Path $outputMsi -Destination $destMsi -Force

$fileInfo = Get-Item $destMsi
Write-Host "✅ MSI Installer created successfully!"
Write-Host "File: $($fileInfo.FullName)"
Write-Host "Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"
