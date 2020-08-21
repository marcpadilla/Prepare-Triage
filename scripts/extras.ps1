# Example of extra preparation that can be performed as part of the Prepare-Triage process.

#Write-Output "Starting Extras"

$DataDirectory = $msource
$ExtrasDest = $mdest + "\Extras\"

New-Item -Path $ExtrasDest -ItemType Directory 2>&1 | Out-Null

$Result = Get-ChildItem -Recurse -Path $DataDirectory -Filter "System.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 7045 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $ServiceName = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(0) | Select -ExpandProperty "#text"
        $ServicePath = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(1) | Select -ExpandProperty "#text"
        $EventDetails =  "Name: " + $ServiceName + ", Location: " + $ServicePath
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
            Column1 = ""
            Column2 = ""
            Column3 = ""
            Column4 = ""
        }
    }
}
$Result = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Security.evtx" | ForEach-Object {
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
                Column1 = ""
                Column2 = ""
                Column3 = ""
                Column4 = ""
            }
        }
    }
}
$Result += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx" | ForEach-Object {
    foreach ($EventId in 98, 131) {
        Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = $EventId } | ForEach-Object {
            $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
            #$User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User"
            if ($EventId -eq 98) {
                $EventDetails = ""
                $SourceIpAddress = ""
                $SourceRelevance = "RDS: A TCP connection has been successfully established."
            }
            if ($EventId -eq 131) {
                $EventDetails = ""
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(1) | Select-Object -ExpandProperty "#text"
                $SourceIpAddress = $SourceIpAddress.Replace("[","").Replace("]","").Split(":")[0]
                $SourceRelevance = "The server accepted a new TCP connection from " + $SourceIpAddress
            }
            [PsCustomObject][ordered]@{
                Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
                Source = "TS-LSM:" + [string]$EventId ;
                Hostname = $HostName ;
                HostIpAddress = $HostIpAddress ;
                UserId = "";
                Assessment = "Context" ;
                SourceRelevance = $SourceRelevance ;
                EventDetails = $EventDetails ;
                SourceIpAddress = $SourceIpAddress ;
                Comments = "" ;
                Hash = "" ;
                EventAddedBy = "Process-Triage" ;
                DateAdded = Get-Date -Format yyyy-MM-dd ;
                Column1 = ""
                Column2 = ""
                Column3 = ""
                Column4 = ""
            }
        }
    }
}
$Result += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 1149 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param3"
        $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param1"
        if ($User -eq "") {
            $Column1 = "Blank user name may indicate use of Sticky Keys."
        }
        else {
            $Column1 = ""
        }
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "TS-RCM:1149" ;
            Hostname = $HostName ;
            HostIpAddress = $HostIpAddress ;
            UserId = $User;
            Assessment = "Context" ;
            SourceRelevance = "RDS: User authentication succeeded." ;
            EventDetails = "Authenticated login from " + $SourceIpAddress +  " as " + $User ;
            SourceIpAddress = $SourceIpAddress ;
            Comments = "" ;
            Hash = "" ;
            EventAddedBy = "Process-Triage" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
            Column1 = $Column1
            Column2 = ""
            Column3 = ""
            Column4 = ""
        }
    }
}
$Result += Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" | ForEach-Object {
    foreach ($EventId in 21, 22, 23, 24, 25) {
        Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = $EventId } | ForEach-Object {
            $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
            $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User"
            if ($EventId -eq 21) {
                $EventDetails = "RDP login from " + $SourceIpAddress +  " as " + $User
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $SourceRelevance = "RDS: Session logon succeeded."
                $Column1 = ""
            }
            if ($EventId -eq 22) {
                $EventDetails = ""
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $SourceRelevance = "RDS: Shell start notification received."
                $Column1 = ""
            }
            if ($EventId -eq 23) {
                $EventDetails = $User + " logged off."
                $SourceIpAddress = ""
                $SourceRelevance = "RDS: Session logoff succeeded."
                $Column1 = "Example: User went to the Start Menu and logged off. Did not simlply exit out of RDP."
            }
            if ($EventId -eq 24) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $EventDetails = $User + " from " + $SourceIpAddress + " disconnected."
                $SourceRelevance = "RDS: Session has been disconnected."
                $Column1 = "Example: User closed RDP by clicking 'X'. No logoff occured."
            }
            if ($EventId -eq 25) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $EventDetails = $User + " reconnected from " + $SourceIpAddress
                $SourceRelevance = "RDS: Session reconnection succeeded."
                $Column1 = "Example: Reconnecting after closing RDP by clicking 'X'."
            }
            if ($EventId -eq 41) {
                $EventDetails = ""
                $SourceRelevance = "Begin session arbitration."
                $Column1 = ""
            }
            [PsCustomObject][ordered]@{
                Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
                Source = "TS-LSM:" + [string]$EventId ;
                Hostname = $HostName ;
                HostIpAddress = $HostIpAddress ;
                UserId = $User;
                Assessment = "Context" ;
                SourceRelevance = $SourceRelevance ;
                EventDetails = $EventDetails ;
                SourceIpAddress = $SourceIpAddress ;
                Comments = "" ;
                Hash = "" ;
                EventAddedBy = "Process-Triage" ;
                DateAdded = Get-Date -Format yyyy-MM-dd ;
                Column1 = $Column1
                Column2 = ""
                Column3 = ""
                Column4 = ""
            }
        }
    }
}
if ($Result) { $Result | Export-Csv -Path $ExtrasDest"the_whole_chimichanga.csv" -Encoding ascii }
#if ($Result) { $Result | Export-Csv -Path "the_whole_chimichanga.csv" -Encoding ascii } # testing

<#
#if ($SuccessfulRemoteLogins) { $SuccessfulRemoteLogins | Export-Csv -Path $ExtrasDest"successul_remote_logins.csv" -Encoding ascii }

Get-WinEvent -FilterHashtable @{ Path = "C:\Windows\System32\winevt\Logs\Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" ; Id = 21 } | ForEach-Object { ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User" }

$DataDirectory = "C:\Windows\System32\winevt\Logs\"
$HostName = "ExampleHost"

Get-WinEvent -FilterHashtable @{ Path = "C:\Windows\System32\winevt\Logs\Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx" ; Id = 131 } | ForEach-Object { ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User" }
#>