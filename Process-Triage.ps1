<#
.SYNOPSIS
Takes a directory containing triage packages and processes them with KAPE.
.EXAMPLE
.\Process-Triage.ps1 -Source S:\matter\ -Destination C:\mpwd\kape\
.NOTES
Author: Marc Padilla
E-Mail: marc@padil.la
GitHub: https://github.com/marcpadilla
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,
    [Parameter(Mandatory)]
    [string]$Destination
    )

function Extract-DupTriage {
    Get-ChildItem -Path $DtSource -Filter "*.7z" -Recurse | ForEach-Object -Parallel {
        $mdest = $using:Destination + $_.BaseName.Split('_')[1]
        # skip previously processed triage
        if (Test-Path -Path $mdest) {
            Write-Host $mdest "already exists... skipping triage package."
        }
        else {
            Write-Host "Processing" $_.FullName
            $CurrentHost = $using:TempDest + $_.BaseName
            # decompress, decompress... and decompress
            & $using:SevenZip x $_.FullName "-o$CurrentHost" 2>&1 | Out-Null
            & $using:SevenZip x "$CurrentHost\*.tar.gz" "-o$CurrentHost" 2>&1 | Out-Null
            Remove-Item $CurrentHost\*.tar.gz -Force
            & $using:SevenZip x "$CurrentHost\*.tar" "-o$CurrentHost" 2>&1 | Out-Null
            Remove-Item $CurrentHost\*.tar -Force
            # adjust modules as needed
            & $using:Kape --msource $CurrentHost --mdest $mdest --mflush --module !EZParser --mef csv 2>&1 | Out-Null
            Remove-Item $CurrentHost -Recurse -Force
        }
    } -ThrottleLimit $cores
}

function Extract-KapeTriage {
    Get-ChildItem -Path $KtSource -Filter '*.zip' -Recurse | ForEach-Object -Parallel {
        $mdest = $using:Destination + $_.BaseName.Split('_')[-1]
        # skip previously processed triage
        if (Test-Path -Path $mdest) {
            Write-Host $mdest "already exists... skipping triage package."
        }
        else {
            Write-Host "Processing" $_.FullName
            Expand-Archive -Path $_ -DestinationPath $using:TempDest -Force
            $vhdx = $using:TempDest + $_.BaseName + '.vhdx'
            $msource = Mount-VHD -Path $vhdx -Passthru | Get-Disk | Get-Partition | Get-Volume
            $msource = $msource.DriveLetter + ":"
            # adjust modules as needed
            & $using:Kape --msource $msource --mdest $mdest --mflush --module !EZParser --mef csv 2>&1 | Out-Null
            Dismount-VHD -Path $vhdx
            Remove-Item -Path $vhdx
        }
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
    Write-Host 'This is a Cyber Lab VM. Reducing -Parallel to 2.'`n
    $cores = 2
}

# concatenate "\" due to my ignorance / forgetfulness
if ($Destination[-1] -ne '\') {
    $Destination += '\'
}

# processes kapetriage packages first -- adjust as needed
$KtSource = $Source + "\KapeTriage\"
Extract-KapeTriage
$DtSource = $Source + "\DupTriage\"
Extract-DupTriage

# remove temporary directory if it even exists
if (Test-Path -Path $TempDest) {
    Remove-Item $TempDest -Recurse -Force
}

Write-Host "`nProcess-Trigage Complete.`n"

pause