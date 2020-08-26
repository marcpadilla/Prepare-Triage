<#
.SYNOPSIS
Takes a directory containing DupTriage and/or KapeTriage packages and processes them.
.EXAMPLE
C:\tools\Prepare-Triage.ps1 -Source D:\TriageSourceDir\ -Destination C:\OutputDir\ -Scans Loki,DeepBlueCLI
.NOTES
Author: Marc Padilla (marc@padil.la)
GitHub: https://github.com/marcpadilla/Prepare-Triage
#>

#Requires -RunAsAdministrator
#Requires -Version 7

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,
    [Parameter(Mandatory)]
    [string]$Destination,
    [array]$Scans,
    [switch]$NoKape,
    [switch]$Extras,
    [switch]$BlackBlox
    )

Write-Host "`nPrepare-Triage by Marc Padilla (marc@padil.la)`n"

# Initial variable assignments.
$TempDest = "C:\Windows\Temp\angrydome\"
$Location = Get-Location
# Core executables.
$SevenZip = "C:\Program Files\7-Zip\7z.exe" # https://www.7-zip.org/
$Kape = "C:\tools\kape\kape.exe"
# Scanner variables.
$DeepBlueCli = "C:\tools\DeepBlueCLI\DeepBlue.ps1" # https://github.com/sans-blue-team/DeepBlueCLI
$DeepBlueCliEventLogs = "Application", "Security", "System", "Microsoft-Windows-PowerShell%4Operational", "Microsoft-Windows-Sysmon%4Operational"
$Loki = "C:\tools\Loki\loki.exe" # https://github.com/Neo23x0/Loki, https://github.com/Neo23x0/signature-base
$Yara = "C:\tools\yara\yara64.exe" # https://github.com/virustotal/yara
$SupportedScans = "deepbluecli", "loki", "yara"

if (!$Scans) { # Check for -Scans parameter.
    Write-Host "No -Scan specified. Only processing triage packages with KAPE.`n"
}
else {
    $Scans = $Scans.ToLower()
    if ((($Scans | Where-Object { $_ -notin $SupportedScans}).Count) -ne 0) { # Inform user of an invalid -Scan parameter.
        Write-Host "> Unsupported -Scan parameter. Please review and try again. Exiting.`n" -ForegroundColor Red
        Exit
    }
}

foreach ($item in $SevenZip, $Kape, $Source) {
    if (!(Test-Path -Path $item)) { # Check data source and required programs.
        Write-Host "$item does not exis. Exiting.`n" -ForegroundColor Red
        Exit
    }
}

if ($Destination[-1] -ne "\") {
    $Destination += "\"
}

# Expected Triage Naming Scheme: Share\KapeTriage\SensorId_HOSTNAME\DateTime_KapeTriage_HOSTNAME.zip
Set-Location -Path $Source
$TriageDirectories = "DupTriage\", "KapeTriage\"
$TriagePackages = Get-ChildItem -Path $TriageDirectories -Recurse | Where-Object -FilterScript { $_.FullName -match ".7z|.zip" } | Select FullName,BaseName,LastWriteTime
foreach ($file in $TriagePackages) {
    Write-Output $file is found
    $SensorId = $file.FullName.Split("\")[3].Split("_")[0]
    $UnderscoreCount = ($file.BaseName.Split("_DupTriage.7z")[0].Split(".zip")[0].ToCharArray() -eq "_").Count # Account for "_" in hostnames.
    if ($UnderscoreCount -gt 2) {
        $file | Add-Member -MemberType NoteProperty -Name "HostName" -Value ($file.BaseName.Split("_DupTriage")[0].Split(".zip")[0].Split("_")[1..$UnderscoreCount] -join "_")
    }
    else {
        $file | Add-Member -MemberType NoteProperty -Name "HostName" -Value $file.BaseName.Split("_DupTriage")[0].Split(".zip")[0].Split("_")[-1]
    }
    $file | Add-Member -MemberType NoteProperty -Name "TriageType" -Value $file.FullName.Split("\")[-3]
    $file | Add-Member -MemberType NoteProperty -Name "Incomplete" -Value ($file.FullName.Split("_")[-1] -eq "INCOMPLETE.zip")
    $file | Add-Member -MemberType NoteProperty -Name "Processed" -Value (Test-Path -Path ($Destination + $SensorId + "_" + $file.HostName + "_" + $file.LastWriteTime.ToString("yyyy-MM-ddTHHmmss")))
    $file | Add-Member -MemberType NoteProperty -Name "SensorId" -Value $SensorId
    Write-Output $file
}

$TriagePackages = $TriagePackages | Sort-Object LastWriteTime -Descending

Write-Output $TriagePackages

$TriagePackageCount = ($TriagePackages | Measure-Object).Count
if ($TriagePackageCount -eq 0) { # Check for zero triage packages.
    Write-Host "Good news, everyone! Bad news. No triage packages found. Are you looking in the right place?`n"
    Set-Location $Location
    Exit
}

$TriagePackages = $TriagePackages | Where-Object -FilterScript { $_.Incomplete -eq $False } # Filter out incomplete triage packages.
$IncompleteTriagePackageCount = $TriagePackageCount - ($TriagePackages | Measure-Object).Count
if ($IncompleteTriagePackageCount -ne 0) {
    Write-Host "$IncompleteTriagePackageCount INCOMPLETE triage package(s) have been located and will be skipped.`n" -ForegroundColor Yellow
    $TriagePackageCount = ($TriagePackages | Measure-Object).Count
}

$TriagePackages = $TriagePackages | Where-Object -FilterScript { $_.Processed -eq $False } # Filter out previously processed triage packages.
$NewTriagePackageCount = ($TriagePackages | Measure-Object).Count
if ($TriagePackageCount -eq $NewTriagePackageCount) {
    Write-Host "$NewTriagePackageCount triage package(s) have been located and will be processed.`n" -ForegroundColor Green
}
elseif ($NewTriagePackageCount -eq 0) {
    Write-Host "No new triage packages located for processing. Exiting.`n"
    Set-Location $Location
    Exit
}
else {
    Write-Host "$NewTriagePackageCount new triage package(s) have been located for processing.`n" -ForegroundColor Green
}

if ((Get-CimInstance -Class Win32_ComputerSystem | Select -ExpandProperty Model).Split(" ")[0] -eq "VMware") {
    $Cores = 2 # Some tools shred VMware guests.  Limiting -Parallel to 2.
}
else {
    $Cores = Get-CimInstance -Class CIM_Processor | Select -ExpandProperty NumberOfCores
    $Cores = [int]$Cores`
}

$TriagePackages | ForEach-Object -Parallel {
    $mdest = $using:Destination + $_.SensorId + "_" + $_.HostName + "_" + $_.LastWriteTime.ToString("yyyy-MM-ddTHHmmss")
    Write-Output "mdest is: " $mdest
    $HostName = $_.HostName
    Write-Host "Processing" $_.FullName
    if ($_.TriageType -eq "DupTriage") {
        $msource = $using:TempDest + $_.HostName
        & $using:SevenZip x $_.FullName "-o$msource" 2>&1 | Out-Null
        & $using:SevenZip x "$msource\*.tar.gz" "-o$msource" 2>&1 | Out-Null
        Remove-Item $msource\*.tar.gz -Force
        & $using:SevenZip x "$msource\*.tar" "-o$msource" 2>&1 | Out-Null
        Remove-Item $msource\*.tar -Force
    }
    if ($_.TriageType -eq "KapeTriage") {
        Write-Host "KapeTriage detected!"
        Expand-Archive -Path $_.FullName -DestinationPath $using:TempDest -Force
        $vhdx = $using:TempDest + $_.BaseName + ".vhdx"
        $msource = Mount-VHD -Path $vhdx -Passthru | Get-Disk | Get-Partition | Get-Volume
        $msource = $msource.DriveLetter + ":"
    }
    if (!$using:NoKape) { & $using:Kape --msource $msource --mdest $mdest --mflush --module !EZParser --mef csv 2>&1 | Out-Null } # Run KAPE.
    if ("loki" -in $using:Scans) { # Run LOKI Scan
        $LokiDest = $mdest + "\Scans\LOKI\"
        New-Item -Path $LokiDest -ItemType Directory 2>&1 | Out-Null
        & $using:Loki --noprocscan -p $msource --csv --logfolder $LokiDest --dontwait 2>&1 | Out-Null
    }
    if ("deepbluecli" -in $using:Scans) { # Run DeepBlueCLI Scan
        $DeepBlueCliDest = $mdest + "\Scans\DeepBlueCLI\"
        New-Item -Path $DeepBlueCliDest -ItemType Directory 2>&1 | Out-Null
        Set-Location -Path "C:\tools\DeepBlueCLI\" # DeepBlueCLI needs to be ran from its location.
        foreach ($EventLog in $using:DeepBlueCliEventLogs) {
            $Count += 1 # Count exists to be prepended to output file.
            Get-ChildItem -Path $msource -Recurse -Filter $EventLog".evtx" | ForEach-Object {
                & $using:DeepBlueCli $_.FullName | ConvertTo-Csv | Out-File -FilePath $DeepBlueCliDest$Count"_"$EventLog".csv" 2>&1 | Out-Null
            }
        }
    }
    if ("yara" -in $using:Scans) { # Run YARA Scan
        $YaraDest = $mdest + "\Scans\YARA\"
        New-Item -Path $YaraDest -ItemType Directory 2>&1 | Out-Null
    }
    if ($using:Extras) { # Consider the three supported scan options to be public demos.
        #Write-Host "-Extras switch detected. Executing foreign script(s)."
        & $using:Location"\scripts\MiniChimi.ps1"
    }
    Set-Location $Location
    if ($_.TriageType -eq "DupTriage") {
        Remove-Item $msource -Recurse -Force
    }
    if ($_.TriageType -eq "KapeTriage") {
        Dismount-VHD -Path $vhdx
        Remove-Item -Path $vhdx
    }
} -ThrottleLimit $Cores

if (Test-Path -Path $TempDest) { # Remove temporary directory if it even exists.
    Remove-Item $TempDest -Recurse -Force
}

Set-Location $Location
Write-Host "`nPrepare-Triage Complete. Exiting.`n"

Exit