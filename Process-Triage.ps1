<#
.SYNOPSIS
Takes a directory containing triage packages and processes them with KAPE.
.EXAMPLE
.\Process-Triage.ps1 -Source S:\matter\ -Destination C:\mpwd\kape\
.NOTES
Author: Marc Padilla (marc@padil.la)
GitHub: https://github.com/marcpadilla/Process-Triage
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,
    [Parameter(Mandatory)]
    [string]$Destination
    )

Write-Host "`nProcess-Triage by Marc Padilla (marc@padil.la)`n"

# modify if necessary
$TempDest = 'C:\Windows\Temp\angrydome\'
$SevenZip = 'C:\Program Files\7-Zip\7z.exe'
$Kape = 'C:\tools\kape\kape.exe'
$Location = Get-Location

# check for specified location of required programs
foreach ($item in $SevenZip, $Kape) {
    if (!(Test-Path -Path $item)) {
        Write-Output "$item does not exist. Modify the Process-Triage script to set a custom location. Exiting.`n"
        Exit
    }
}

# concatenate a trailing \ if necessary
if ($Destination[-1] -ne '\') {
    $Destination += '\'
}

# create array with useful members
Set-Location -Path $Source
$TriageDirectories = "DupTriage\", "KapeTriage\"
$TriagePackages = Get-ChildItem -Path $TriageDirectories -Recurse | Where-Object -FilterScript {$_.FullName -match ".7z|.zip"} | Select FullName,BaseName,LastWriteTime
foreach ($file in $TriagePackages) {
    $UnderscoreCount = ($file.BaseName.Split('_DupTriage.7z')[0].Split('.zip')[0].ToCharArray() -eq "_").count # some windows hostnames contain "_" due to bootcamp and its obnoxious
    if ($UnderscoreCount -gt 2) {
        $file | Add-Member -MemberType NoteProperty -Name "HostName" -Value ($file.BaseName.Split('_DupTriage')[0].Split('.zip')[0].Split('_')[1..$UnderscoreCount] -join "_")
    }
    else {
        $file | Add-Member -MemberType NoteProperty -Name "HostName" -Value $file.BaseName.Split('_DupTriage')[0].Split('.zip')[0].Split('_')[-1]
    }
    $file | Add-Member -MemberType NoteProperty -Name "TriageType" -Value $file.FullName.Split('\')[2]
    $file | Add-Member -MemberType NoteProperty -Name "Incomplete" -Value ($file.FullName.Split('_')[-1] -eq 'INCOMPLETE.zip')
    $file | Add-Member -MemberType NoteProperty -Name "Processed" -Value (Test-Path -Path ($Destination + $file.HostName + "_" + $file.LastWriteTime.ToString("yyyy-MM-ddTHHmmss")))
}
$TriagePackages = $TriagePackages | Sort-Object LastWriteTime -Descending

# no triage packages found
$TriagePackageCount = ($TriagePackages | Measure-Object).Count
if ($TriagePackageCount -eq 0) {
    Write-Output "Good news, everyone! Bad news. No triage packages found. Are you looking in the right place?`n"
    Set-Location $Location
    Exit
}

# check for incomplete triage packages
$TriagePackages = $TriagePackages | Where-Object -FilterScript {$_.Incomplete -eq $False}
$IncompleteTriagePackageCount = $TriagePackageCount - ($TriagePackages | Measure-Object).Count
if ($IncompleteTriagePackageCount -ne 0) {
    Write-Output "$IncompleteTriagePackageCount triage packages are marked as INCOMPLETE. They will be skipped.`n"
    $TriagePackageCount = ($TriagePackages | Measure-Object).Count
}

# get totals and convey what will be processed to user
$TriagePackages = $TriagePackages | Where-Object -FilterScript {$_.Processed -eq $False}
$NewTriagePackageCount = ($TriagePackages | Measure-Object).Count
if ($TriagePackageCount -eq $NewTriagePackageCount) {
    Write-Output "Located $Total triage packages -- all of which will be processed.`n"
}
elseif ($NewTriagePackageCount -eq 0) {
    Write-Output "No new triage packages for processing. Exiting.`n"
    Set-Location $Location
    Exit
}
else {
    Write-Output "$NewTriagePackageCount new triage package(s) have been located for processing.`n"
}

# check for lol slow cyberlab vm
if ((Get-CimInstance -Class Win32_ComputerSystem | Select -ExpandProperty Domain) -eq 'cyber.local') {
    $Cores = 2
}
else {
    $Cores = Get-CimInstance -Class CIM_Processor | Select -ExpandProperty NumberOfCores
    $Cores = [int]$Cores
}

# processing
$TriagePackages | ForEach-Object -Parallel {
    $mdest = $using:Destination + $_.HostName + "_" + $_.LastWriteTime.ToString("yyyy-MM-ddTHHmmss")
    Write-Host "Processing" $_.FullName
    # decompress/unarchive, mount, etc.
    if ($_.TriageType -eq 'DupTriage') {
        $msource = $using:TempDest + $_.HostName
        # decompress, decompress... and decompress
        & $using:SevenZip x $_.FullName "-o$msource" 2>&1 | Out-Null
        & $using:SevenZip x "$msource\*.tar.gz" "-o$msource" 2>&1 | Out-Null
        Remove-Item $msource\*.tar.gz -Force
        & $using:SevenZip x "$msource\*.tar" "-o$msource" 2>&1 | Out-Null
        Remove-Item $msource\*.tar -Force
    }
    if ($_.TriageType -eq 'KapeTriage') {
        Expand-Archive -Path $_.FullName -DestinationPath $using:TempDest -Force
        $vhdx = $using:TempDest + $_.BaseName + '.vhdx'
        $msource = Mount-VHD -Path $vhdx -Passthru | Get-Disk | Get-Partition | Get-Volume
        $msource = $msource.DriveLetter + ":"
    }
    # run kape, adjust modules as necessary
    & $using:Kape --msource $msource --mdest $mdest --mflush --module !EZParser --mef csv 2>&1 | Out-Null
    # clean-up
    if ($_.TriageType -eq 'DupTriage') {
        Remove-Item $msource -Recurse -Force
    }
    if ($_.TriageType -eq 'KapeTriage') {
        Dismount-VHD -Path $vhdx
        Remove-Item -Path $vhdx
    }
} -ThrottleLimit $Cores

# remove temporary directory if it even exists
if (Test-Path -Path $TempDest) {
    Remove-Item $TempDest -Recurse -Force
}

Set-Location $Location
Write-Host "`nProcess-Triage Complete. Exiting.`n"

Exit