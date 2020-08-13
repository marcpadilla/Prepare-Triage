<#
.SYNOPSIS
Takes a directory containing DupTriage and/or KapeTriage packages and processes them.
.EXAMPLE
C:\tools\Prepare-Triage.ps1 -Source D:\ClientName\ -Destination C:\WorkingDir\ClientName\Prepared\
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
    [string]$Destination
    )

Write-Host "`nPrepare-Triage by Marc Padilla (marc@padil.la)`n"

$TempDest = "C:\Windows\Temp\angrydome\"
$SevenZip = "C:\Program Files\7-Zip\7z.exe" # https://www.7-zip.org/
$DeepBlueCli = "C:\tools\DeepBlueCLI\DeepBlue.ps1"
$Kape = "C:\tools\kape\kape.exe"
$Location = Get-Location
$Loki = "C:\tools\Loki\loki.exe" # https://github.com/Neo23x0/Loki, https://github.com/Neo23x0/signature-base

foreach ($item in $SevenZip, $Kape, $Source) {
    if (!(Test-Path -Path $item)) { # Check data source and required programs.
        Write-Output "$item does not exist. Exiting.`n"
        Exit
    }
}

if ($Destination[-1] -ne "\") {
    $Destination += "\"
}

Set-Location -Path $Source
$TriageDirectories = "DupTriage\", "KapeTriage\"
$TriagePackages = Get-ChildItem -Path $TriageDirectories -Recurse | Where-Object -FilterScript { $_.FullName -match ".7z|.zip" } | Select FullName,BaseName,LastWriteTime
foreach ($file in $TriagePackages) {
    $SensorId = $file.FullName.Split("\")[3].Split("_")[0]
    $UnderscoreCount = ($file.BaseName.Split("_DupTriage.7z")[0].Split(".zip")[0].ToCharArray() -eq "_").count # Account for "_" in hostnames.
    if ($UnderscoreCount -gt 2) {
        $file | Add-Member -MemberType NoteProperty -Name "HostName" -Value ($file.BaseName.Split("_DupTriage")[0].Split(".zip")[0].Split("_")[1..$UnderscoreCount] -join "_")
    }
    else {
        $file | Add-Member -MemberType NoteProperty -Name "HostName" -Value $file.BaseName.Split("_DupTriage")[0].Split(".zip")[0].Split("_")[-1]
    }
    $file | Add-Member -MemberType NoteProperty -Name "TriageType" -Value $file.FullName.Split("\")[2]
    $file | Add-Member -MemberType NoteProperty -Name "Incomplete" -Value ($file.FullName.Split("_")[-1] -eq "INCOMPLETE.zip")
    $file | Add-Member -MemberType NoteProperty -Name "Processed" -Value (Test-Path -Path ($Destination + $SensorId + "_" + $file.HostName + "_" + $file.LastWriteTime.ToString("yyyy-MM-ddTHHmmss")))
    $file | Add-Member -MemberType NoteProperty -Name "SensorId" -Value $SensorId
}

$TriagePackages = $TriagePackages | Sort-Object LastWriteTime -Descending

$TriagePackageCount = ($TriagePackages | Measure-Object).Count
if ($TriagePackageCount -eq 0) { # Check for zero triage packages.
    Write-Output "Good news, everyone! Bad news. No triage packages found. Are you looking in the right place?`n"
    Set-Location $Location
    Exit
}

$TriagePackages = $TriagePackages | Where-Object -FilterScript { $_.Incomplete -eq $False } # Filter out incomplete triage packages.
$IncompleteTriagePackageCount = $TriagePackageCount - ($TriagePackages | Measure-Object).Count
if ($IncompleteTriagePackageCount -ne 0) {
    Write-Output "$IncompleteTriagePackageCount INCOMPLETE triage package(s) have been located and will be skipped.`n"
    $TriagePackageCount = ($TriagePackages | Measure-Object).Count
}

$TriagePackages = $TriagePackages | Where-Object -FilterScript { $_.Processed -eq $False } # Filter out previously processed triage packages.
$NewTriagePackageCount = ($TriagePackages | Measure-Object).Count
if ($TriagePackageCount -eq $NewTriagePackageCount) {
    Write-Output "$NewTriagePackageCount triage package(s) have been located and will be processed.`n"
}
elseif ($NewTriagePackageCount -eq 0) {
    Write-Output "No new triage packages located for processing. Exiting.`n"
    Set-Location $Location
    Exit
}
else {
    Write-Output "$NewTriagePackageCount new triage package(s) have been located for processing.`n"
}

if ((Get-CimInstance -Class Win32_ComputerSystem | Select -ExpandProperty Model).Split(" ")[0] -eq "VMware") {
    $Cores = 2 # Some tools shred VMware guests.  Limiting -Parallel to 2.
}
else {
    $Cores = Get-CimInstance -Class CIM_Processor | Select -ExpandProperty NumberOfCores
    $Cores = [int]$Cores
}

$TriagePackages | ForEach-Object -Parallel {
    $mdest = $using:Destination + $_.SensorId + "_" + $_.HostName + "_" + $_.LastWriteTime.ToString("yyyy-MM-ddTHHmmss")
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
        Expand-Archive -Path $_.FullName -DestinationPath $using:TempDest -Force
        $vhdx = $using:TempDest + $_.BaseName + ".vhdx"
        $msource = Mount-VHD -Path $vhdx -Passthru | Get-Disk | Get-Partition | Get-Volume
        $msource = $msource.DriveLetter + ":"
    }
    & $using:Kape --msource $msource --mdest $mdest --mflush --module !EZParser --mef csv 2>&1 | Out-Null # Run KAPE.
    New-Item -Path $mdest"\Scans" -ItemType Directory 2>&1 | Out-Null
    $LokiDest = $mdest + "\Scans\" + $_.HostName + "_LOKI.csv"
    & $using:Loki --noprocscan -p $msource --csv -l $LokiDest --dontwait 2>&1 | Out-Null
    $DeepBlueCliDest = $mdest + "\Scans\" + $_.HostName + "_"
    Set-Location -Path "C:\tools\DeepBlueCLI\" # DeepBlueCLI needs to be ran from its location.
    foreach ($EventLog in "Application.evtx", "Security.evtx", "System.evtx", "Windows PowerShell.evtx") {
        Get-ChildItem -Path $msource -Recurse -Filter $EventLog | ForEach-Object {
            & $using:DeepBlueCli $_.FullName | ConvertTo-Csv | Out-File -FilePath $DeepBlueCliDest$EventLog"_DeepBlueCLI.csv" 2>&1 | Out-Null
            }
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