$DataDirectory = $msource
$ExtrasDest = $mdest + "\Extras\"
#$DataDirectory = "F:\F\Windows\system32\winevt\logs"
#$ExtrasDest = "E:\onpoint\Extras\"

New-Item -Path $ExtrasDest -ItemType Directory 2>&1 | Out-Null

$CreatedServices = Get-ChildItem -Recurse -Path $DataDirectory -Filter "System.evtx" | ForEach-Object {
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
            EventAddedBy = $using:Name ;
            DateAdded = Get-Date -Format yyyy-MM-dd
            Column1 = ""
            Column2 = ""
            Column3 = ""
            Column4 = ""
        }
    }
}

$LogonTypes = [ordered]@{ # https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/basic-audit-logon-events
    "2" = "Interactive" ;
    "3" = "Network" ;
    "4" = "Batch" ;
    "5" = "Service" ;
    "7" = "System Unlock" ;
    "8" = "NetworkCleartext" ;
    "9" = "NewCredentials" ;
    "10" = "RemoteInteractive" ;
    "11" = "CachedInteractive"
}

$SuccessfulLogons = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Security.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 4624 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(18) | Select -ExpandProperty "#text"
        $LogonType = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(8) | Select -ExpandProperty "#text"
        $LogonId = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(7) | Select -ExpandProperty "#text"
        $WorkstationName = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(11) | Select -ExpandProperty "#text"
        $Domain = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(6) | Select -ExpandProperty "#text"
        $User = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(5) | Select -ExpandProperty "#text"
        if ($Domain) {
            $UserId = $Domain + "\" + $User
        }
        else {
            $UserId = $User
        }
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "Security:4624" ;
            Hostname = $HostName ;
            HostIpAddress = $HostIpAddress ;
            UserId = $UserId ;
            Assessment = "Context" ;
            SourceRelevance = "Successful Logon" ;
            EventDetails = $LogonTypes.$LogonType + " Logon" ;
            SourceIpAddress = $SourceIpAddress ;
            Comments = "" ;
            Hash = "" ;
            EventAddedBy = "Padilla" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
            Column1 = $LogonType
            Column2 = $LogonId
            Column3 = $WorkstationName
            Column4 = ""
        }
    }
}

$FailedLogons = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Security.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 4625 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0) # working
        $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(19) | Select -ExpandProperty "#text"
        $LogonType = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(10) | Select -ExpandProperty "#text" #working
        $FailureReason = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(8) | Select -ExpandProperty "#text" #working
        $WorkstationName = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(13) | Select -ExpandProperty "#text" #working
        $Domain = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(6) | Select -ExpandProperty "#text"
        $User = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(5) | Select -ExpandProperty "#text" #testing
        if ($Domain) {
            $UserId = $Domain + "\" + $User
        }
        else {
            $UserId = $User
        }
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "Security:4625" ;
            Hostname = $HostName ;
            HostIpAddress = $HostIpAddress ;
            UserId = $UserId ;
            Assessment = "Context" ;
            SourceRelevance = "Failed Logon" ;
            EventDetails = $LogonTypes.$LogonType ;
            SourceIpAddress = $SourceIpAddress ;
            Comments = "" ;
            Hash = "" ;
            EventAddedBy = "Padilla" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
            Column1 = $LogonType
            Column2 = $FailureReason
            Column3 = $WorkstationName
            Column4 = ""
        }
    }
}

$Application = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Application.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 11724 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0) # working
        $UserId = ([xml]$_.ToXml()).GetElementsByTagName("System") | Select -ExpandProperty "Security" | Select -ExpandProperty "UserId"
        $EventDetails = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(0) | Select -ExpandProperty "#text"
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "Application:11724" ;
            Hostname = "" ;
            HostIpAddress = "" ;
            UserId = $UserId ;
            Assessment = "Context" ;
            SourceRelevance = "Product Removal" ;
            EventDetails = $EventDetails ;
            SourceIpAddress = "" ;
            Comments = "" ;
            Hash = "" ;
            EventAddedBy = "Padilla" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
            Column1 = ""
            Column2 = ""
            Column3 = ""
            Column4 = ""
        }  
    }
}

$TerminalServicesLSM = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" | ForEach-Object {
    foreach ($EventId in 21, 22, 23, 24, 25) {
        Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = $EventId } | ForEach-Object {
            $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
            $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User"
            if ($EventId -eq 21) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $EventDetails = "RDP login from " + $SourceIpAddress +  " as " + $User
                $SourceRelevance = "Session logon succeeded."
                $Column1 = ""
            }
            if ($EventId -eq 22) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $EventDetails = ""
                $SourceRelevance = "Shell start notification received."
                $Column1 = ""
            }
            if ($EventId -eq 23) {
                $SourceIpAddress = ""
                $EventDetails = $User + " logged off."
                $SourceRelevance = "Session logoff succeeded."
                $Column1 = "Example: User went to the Start Menu and logged off. Did not simlply exit out of RDP."
            }
            if ($EventId -eq 24) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $EventDetails = $User + " from " + $SourceIpAddress + " disconnected."
                $SourceRelevance = "Session has been disconnected."
                $Column1 = "Example: User closed RDP by clicking 'X'. No logoff occured."
            }
            if ($EventId -eq 25) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Address"
                $EventDetails = $User + " reconnected from " + $SourceIpAddress
                $SourceRelevance = "Session reconnection succeeded."
                $Column1 = "Example: Reconnecting after closing RDP by clicking 'X'."
            }
            if ($EventId -eq 41) {
                $SourceIpAddress = ""
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
                EventAddedBy = "Padilla" ;
                DateAdded = Get-Date -Format yyyy-MM-dd ;
                Column1 = $Column1
                Column2 = ""
                Column3 = ""
                Column4 = ""
            }
        }
    }
}

$TerminalServicesRCM = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx" | ForEach-Object {
    Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = 1149 } | ForEach-Object {
        $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
        $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param3"
        $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "Param1"
        if ($User -eq "") {
            $Column1 = "Blank user name may indicate use of Sticky Keys."
            $EventDetails = "Authenticated login from " + $SourceIpAddress
        }
        else {
            $Column1 = ""
            $EventDetails = "Authenticated login from " + $SourceIpAddress +  " as " + $User
        }
        [PsCustomObject][ordered]@{
            Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
            Source = "TS-RCM:1149" ;
            Hostname = $HostName ;
            HostIpAddress = $HostIpAddress ;
            UserId = $User;
            Assessment = "Context" ;
            SourceRelevance = "User authentication succeeded." ;
            EventDetails = $EventDetails ;
            SourceIpAddress = $SourceIpAddress ;
            Comments = "" ;
            Hash = "" ;
            EventAddedBy = "Padilla" ;
            DateAdded = Get-Date -Format yyyy-MM-dd
            Column1 = $Column1
            Column2 = ""
            Column3 = ""
            Column4 = ""
        }
    }
}

$RemoteDesktopServicesRCTS = Get-ChildItem -Recurse -Path $DataDirectory -Filter "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx" | ForEach-Object {
    foreach ($EventId in 98, 131) {
        Get-WinEvent -FilterHashtable @{ Path = $_.FullName ; Id = $EventId } | ForEach-Object {
            $Time = ([xml]$_.ToXml()).GetElementsByTagName("TimeCreated").itemOf(0)
            $User = ([xml]$_.ToXml()).GetElementsByTagName("EventXML").itemOf(0) | Select -ExpandProperty "User"
            if ($EventId -eq 98) {
                $SourceIpAddress = ""
            }
            if ($EventId -eq 131) {
                $SourceIpAddress = ([xml]$_.ToXml()).GetElementsByTagName("Data").itemOf(1) | Select-Object -ExpandProperty "#text"
                $SourceIpAddress = $SourceIpAddress.Replace("[","").Replace("]","").Split(":")[0]
            }
            [PsCustomObject][ordered]@{
                Time = [string]$Time.SystemTime.Replace("T", " ").Split(".")[0] ;
                Source = "RdpCoreTS:" + [string]$EventId ;
                Hostname = $HostName ;
                HostIpAddress = $HostIpAddress ;
                UserId = "";
                Assessment = "Context" ;
                SourceRelevance = "A TCP connection has been successfully established." ;
                EventDetails = "" ;
                SourceIpAddress = $SourceIpAddress ;
                Comments = "" ;
                Hash = "" ;
                EventAddedBy = "Padilla" ;
                DateAdded = Get-Date -Format yyyy-MM-dd ;
                Column1 = ""
                Column2 = ""
                Column3 = ""
                Column4 = ""
            }
        }
    }
}

$MiniChimi = $CreatedServices + $SuccessfulLogons + $FailedLogons + $TerminalServicesLSM + $TerminalServicesRCM + $RemoteDesktopServicesRCTS + $Application
$MiniChimi | Export-Csv $ExtrasDest"\MiniChimi.csv" && Start-Process $ExtrasDest"\MiniChimi.csv"