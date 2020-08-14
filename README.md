# Prepare-Triage

Takes a directory containing [DupTriage](https://tzworks.net/prototype_page.php?proto_id=37) and/or [KapeTriage](https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape) packages and processes them with Kroll Artifact Parser and Extractor (KAPE) and other tools for streamlined analysis.

If multiple triage packages for a single host exist Prepare-Triage will differentiate them by collection timestamp and process them all. Triage packages marked as INCOMPLETE are skipped and a message is printed to screen. If a triage package has already been processed it will be skipped when Prepare-Triage is re-run. This encourages you to run Prepare-Triage throughout an engagement.

## Required Software

Prepare-Triage utilizes the following software:

|Name|Links|Expected Location/Notes|
|----|----|----|
|7-Zip|[Download](https://www.7-zip.org/download.html)|`C:\Program Files\7-Zip\7z.exe`|
|DeepBlueCLI|[GitHub](https://github.com/sans-blue-team/DeepBlueCLI)|`C:\tools\DeepBlueCLI\DeepBlue.ps1`|
|KAPE|[Download Request Form](https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape)|`C:\tools\KAPE\kape.exe`|
|LOKI|[GitHub Releases](https://github.com/Neo23x0/Loki/releases), [Signature Base](https://github.com/Neo23x0/signature-base)|`C:\tools\loki\loki.exe`|
|PowerShell|[GitHub Releases](https://github.com/PowerShell/powershell/releases)|Version 7 or above is required.|

## Example

```PowerShell
C:\tools\Prepare-Triage.ps1 -Source D:\ClientName\ -Destination C:\WorkingDir\ClientName\Prepared\ -Scans Loki,DeepBlueCLI
```

## Additional Notes

None. If you are having trouble you can email me at [marc@padil.la](mailto:marc@padil.la).
