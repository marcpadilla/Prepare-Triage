# Example of extra preparation that can be performed as part of the Prepare-Triage process.

Write-Output "Starting Extras"

$DataDirectory = $msource
$ExtrasDest = $mdest + "\Extras\"

New-Item -Path $ExtrasDest -ItemType Directory 2>&1 | Out-Null

# Service Creation
$ServiceCreation = Get-ChildItem -Recurse -Path $DataDirectory -Filter "System.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 7045 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $ServiceName = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(0) | Select -ExpandProperty "#text"
        $ServicePath = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(1) | Select -ExpandProperty "#text"
        $EventDetails =  $ServiceName + ", " + $ServicePath
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "System:7045" ;
            Hostname = $HostName ;
            HostIpAddress = $HostIpAddress ;
            UserId = "" ;
            Assessment = "Context" ;
            SourceRelevance = "Service Creation" ;
            EventDetails = $EventDetails ;
            SourceIpAddress = "" ;
            Comments = "Service Created" ;
            Hash = "" ;
            EventAddedBy = "Process-Triage" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
        }
    }
}
$ServiceCreation | Export-Csv -Path $ExtrasDest"service_creation.csv" -Encoding ascii

# Successful Remote Logins
$SuccessfulRemoteLogins = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Security.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 4624 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(18) | Select -ExpandProperty "#text"
        $Domain = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(6) | Select -ExpandProperty "#text"
        $User = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(5) | Select -ExpandProperty "#text"
        if ((([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(8) | Select -ExpandProperty "#text") -eq "10") {
            [PsCustomObject][ordered]@{
                Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
                Source = "Security:4624" ;
                Hostname = $HostName ;
                HostIpAddress = $HostIpAddress ;
                UserId = [string]$Domain + "\" + [string]$User ;
                Assessment = "Context" ;
                SourceRelevance = "Successful Type 10 Logon (RDP)" ;
                EventDetails = "Successful RDP login from " + $SourceIpAddress +  " as " + [string]$Domain + "\" + [string]$User ;
                SourceIpAddress = $SourceIpAddress ;
                Comments = "" ;
                Hash = "" ;
                EventAddedBy = "Process-Triage" ;
                DateAdded = Get-Date -Format yyyy-MM-dd
            }
        }
    }
}
$SuccessfulRemoteLogins += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 1149 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param3"
        $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param1"
        if ($User -eq "") { 
            $Comments = "Blank user name may indicate use of Sticky Keys."
            #$User = "????"
        }
        else {
            $Comments = ""
        }
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "TS-RCM:1149" ;
            Hostname = $HostName ;
            HostIpAddress = $HostIpAddress ;
            UserId = $User;
            Assessment = "Context" ;
            SourceRelevance = "User Authentication Succeeded" ;
            EventDetails = "Authenticated login from " + $SourceIpAddress +  " as " + $User ;
            SourceIpAddress = $SourceIpAddress ;
            Comments = $Comments ;
            Hash = "" ;
            EventAddedBy = "Process-Triage" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
        }
    }
}
$SuccessfulRemoteLogins += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" | ForEach-Object {
    foreach ($EventId in 21, 22, 25) {
        Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = $EventId } | ForEach-Object {
            $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
            $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
            $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User"
            [PsCustomObject][ordered]@{
                Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
                Source = "TS-LSM:" + [string]$EventId ;
                Hostname = $HostName ;
                HostIpAddress = $HostIpAddress ;
                UserId = $User;
                Assessment = "Context" ;
                SourceRelevance = "User Authentication Succeeded" ;
                EventDetails = "Authenticated login from " + $SourceIpAddress +  " as " + $User ;
                SourceIpAddress = $SourceIpAddress ;
                Comments = "" ;
                Hash = "" ;
                EventAddedBy = "Process-Triage" ;
                DateAdded = Get-Date -Format yyyy-MM-dd
            }
        }
    }
}
if ($SuccessfulRemoteLogins) { $SuccessfulRemoteLogins | Export-Csv -Path $ExtrasDest"successul_remote_logins.csv" -Encoding ascii }

<#
#if ($SuccessfulRemoteLogins) { $SuccessfulRemoteLogins | Export-Csv -Path $ExtrasDest"successul_remote_logins.csv" -Encoding ascii }

Get-WinEvent -FilterHashtable @{ Path = "C:\Windows\System32\winevt\Logs\Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" ; Id = 21 } | ForEach-Object { ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User" }

$DataDirectory = "C:\Windows\System32\winevt\Logs\"
$HostName = "ExampleHost"
#>