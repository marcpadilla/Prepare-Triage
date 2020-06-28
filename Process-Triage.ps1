<#
.SYNOPSIS
Takes a directory containing triage packages and processes them with KAPE.
.EXAMPLE
.\Process-Triage.ps1 -Source S:\matter\DupTriage\ -TriageType DupTriage -Destination C:\mpwd\kape\
.NOTES
Author: Marc Padilla
E-Mail: marc@padil.la
Website: https://padil.la
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,
    [Parameter(Mandatory)]
    [string]$TriageType,
    [Parameter(Mandatory)]
    [string]$Destination
    )

function Extract-DupTriage {
    Get-ChildItem -Path $Source -Filter "*.7z" -Recurse | ForEach-Object -Parallel {
        $CurrentHost = $using:TempDest + $_.BaseName
        Write-Host "Current Host is" $_.BaseName
        # decompress, decompres... and decompress
        & $using:SevenZip x $_.FullName "-o$CurrentHost" 2>&1 | Out-Null
        & $using:SevenZip x "$CurrentHost\*.tar.gz" "-o$CurrentHost" 2>&1 | Out-Null
        Remove-Item $CurrentHost\*.tar.gz -Force
        & $using:SevenZip x "$CurrentHost\*.tar" "-o$CurrentHost" 2>&1 | Out-Null
        Remove-Item $CurrentHost\*.tar -Force
        $mdest = $using:Destination + $_.BaseName
        # run kape against decompressed data
        & $using:Kape --msource $CurrentHost --mdest $mdest --mflush --module !EZParser --mef csv  2>&1 | Out-Null
        Remove-Item $CurrentHost -Recurse -Force
    } -ThrottleLimit $cores
    # clean-up
    Get-ChildItem -Path $Destination | Rename-Item -NewName {$_.FullName -replace '_DupTriage',''}
    Get-ChildItem -Path $Destination | Rename-Item -NewName {$_.FullName -replace '\d{2}_',''}
}

function Extract-KapeTriage {
    Get-ChildItem -Path $Source -Filter '*.zip' -Recurse | ForEach-Object -Parallel {
        Expand-Archive -Path $_ -DestinationPath $using:TempDest -Force
        $vhdx = $using:TempDest + $_.BaseName + '.vhdx'
        $msource = Mount-VHD -Path $vhdx -Passthru | Get-Disk | Get-Partition | Get-Volume
        $msource = $msource.DriveLetter + ":"
        $mdest = $using:Destination + $_.BaseName
        & $using:Kape --msource $msource --mdest $mdest --mflush --module !EZParser --mef csv
        Dismount-VHD -Path $vhdx
        Remove-Item -Path $vhdx
    } -ThrottleLimit $cores
}

# main ====
Write-Host "`nProcess-Triage by Marc Padilla`n"

# adjust these as necessary
$TempDest = 'C:\Windows\Temp\crm114\'
$SevenZip = 'C:\Program Files\7-Zip\7z.exe'
$Kape = 'C:\tools\kape\kape.exe'

# get core count
$cores = Get-CimInstance -Class CIM_Processor | Select -ExpandProperty NumberOfCores
$cores = [int]$cores

# check for lol slow lab vm
if ((Get-CimInstance -Class Win32_ComputerSystem | Select -ExpandProperty Domain) -eq 'cyber.local') {
    Write-Host `n'This is a Cyber Lab VM. Reducing -Parallel to 2.'`n
    $cores = 2
}

# add trailing \ due to my ignorance
if ($Destination[-1] -ne '\') {
    $Destination += '\'
}

if ($TriageType.ToLower() -eq 'duptriage') {
    Extract-DupTriage -Source $Source -Destination $Destination
    } ElseIf ($type.ToLower() -eq 'kapetriage') {
    Extract-KapeTriage -Source $Source -Destination $Destination
}

Remove-Item $TempDest -Recurse -Force

pause