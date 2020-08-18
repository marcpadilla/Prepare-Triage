# Example of extra preparation that can be performed as part of the Prepare-Triage process.

Write-Output "Starting Extras"

$DataDirectory = $msource

$ExtrasDest = $mdest + "\Extras\"
# Services
$Services = Get-ChildItem -Recurse -Path $DataDirectory -Filter "System.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; ProviderName = "Service Control Manager" ; Id = 7045 }
}
$Services | Export-Csv -Path $ExtrasDest"services.csv" -Encoding ascii

# SUCCESSFULL RDP Information
$records = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Security.evtx" | ForEach-Object {
    $EventLog = $_.FullName
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 4624 } | ForEach-Object {
        $EventId = 4624
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $Ip = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(18) | Select -ExpandProperty "#text"
        if ((([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(8) | Select -ExpandProperty "#text") -eq "10") {
            New-Object PsObject -Property @{ Time = $Time.SystemTime; SourceIp = $Ip; EventLog = $EventLog; EventId = $EventId }
        }
    }
}
$records += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx" | ForEach-Object {
    $EventLog = $_.FullName
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 1149 } | ForEach-Object {
        $EventId = 1149
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $Ip = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param3"
        New-Object PsObject -Property @{ Time = $Time.SystemTime; SourceIp = $Ip; EventLog = $EventLog; EventId = $EventId }
    }
}
$records += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" | ForEach-Object {
    $EventLog = $_.FullName
    foreach ($EventId in 21, 22, 25) {
        Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = $EventId } | ForEach-Object {
            $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
            $Ip = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
            New-Object PsObject -Property @{ Time = $Time.SystemTime; SourceIp = $Ip; EventLog = $EventLog; EventId = $EventId }
        }
    }
}
$records | Export-Csv -Path $ExtrasDest"rdp_successful.csv" -Encoding ascii
$records | Select-Object -Property SourceIp | Sort-Object SourceIp -Unique | Export-Csv -Path $ExtrasDest"rdp_inbound_unique_ips.csv" -Encoding ascii

Write-Output "Extras complete.`n"