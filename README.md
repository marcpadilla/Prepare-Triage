# Process-Triage

Takes a matter share containing DupTriage and/or KapeTriage packages and processes them with Kroll Artifact Parser and Extractor (KAPE) for streamlined analysis.

If multiple triage packages for a single host exist Process-Triage will process them all. Incomplete triage packages are skipped and a message is printed to screen. Process-Triage will detect if a triage package has already been processed and skip it by default. This encourages you to run Process-Triage throughout an engagement.

## Required Software

Process-Triage utilizes the following software:

|Name|URL|Expected Location|Note|
|----|----|----|----|
|7-Zip|[https://www.7-zip.org/download.html](https://www.7-zip.org/download.html)|`C:\Program Files\7-Zip\7z.exe`||
|DeepBlueCLI|[https://github.com/sans-blue-team/DeepBlueCLI](https://github.com/sans-blue-team/DeepBlueCLI)|`C:\tools\DeepBlueCLI\DeepBlue.ps1`||
|LOKI|[https://github.com/Neo23x0/Loki/releases](https://github.com/Neo23x0/Loki/releases)|`C:\tools\KAPE\kape.exe`|
|KAPE|[https://s3.amazonaws.com/cyb-us-prd-kape/kape.zip](https://s3.amazonaws.com/cyb-us-prd-kape/kape.zip)|`C:\tools\KAPE\kape.exe`||
|PowerShell|[https://github.com/PowerShell/powershell/releases](https://github.com/PowerShell/powershell/releases)||Version 7.x or above.|

If the software location differs on your system, modify the Process-Triage script to reflect the full path.

## Additional Notes

None. If you are having trouble you can email me at [marc@padil.la](mailto:marc@padil.la).
