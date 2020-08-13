# Prepare-Triage

Takes a directory containing DupTriage and/or KapeTriage packages and processes them with Kroll Artifact Parser and Extractor (KAPE) and other tools for streamlined analysis.

If multiple triage packages for a single host exist Prepare-Triage will differentiate them by collection timestamp and process them all. Triage packages marked as INCOMPLETE are skipped and a message is printed to screen. If a triage package has already been processed it will be skipped when Prepare-Triage is re-run. This encourages you to run Prepare-Triage throughout an engagement.

## Required Software

Prepare-Triage utilizes the following software:

|Name|Links|Note|
|----|----|----|
|7-Zip|[Download](https://www.7-zip.org/download.html)|Expected Location: `C:\Program Files\7-Zip\7z.exe`|
|KAPE|[Download](https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape) - request form required :(|Expected Location: `C:\tools\KAPE\kape.exe`|
|LOKI|[GitHub Releases](https://github.com/Neo23x0/Loki/releases), [Signature Base](https://github.com/Neo23x0/signature-base)|Expected Location: `C:\tools\loki\loki.exe`
|PowerShell|[GitHub Releases](https://github.com/PowerShell/powershell/releases)|Version 7 or above is required.|

## Example

```PowerShell
C:\tools\Prepare-Triage.ps1 -Source D:\ClientName\ -Destination C:\WorkingDir\ClientName\KAPE\
```

## To-Do

Add reference to external PowerShell script for additional processing while data sources are available. For example: Running DeepBlueCLI against event logs before a VHDX container is dismounted.

## Additional Notes

None. If you are having trouble you can email me at [marc@padil.la](mailto:marc@padil.la).
