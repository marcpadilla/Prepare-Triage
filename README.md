# Process-Triage

Takes a directory containing DupTriage and/or KapeTriage packages and processes them with Kroll Artifact Parser and Extractor (KAPE) for streamlined analysis.

If multiple triage packages for a single host exist, Process-Triage will differentiate them by collection timestamp and process them all. Incomplete triage packages are skipped and a message is printed to screen. Process-Triage will detect if a triage package has already been processed and skip it by default. This encourages you to run Process-Triage throughout an engagement.

## Required Software

Process-Triage utilizes the following software:

|Name|Links|Note|
|----|----|----|
|7-Zip|[Download](https://www.7-zip.org/download.html)|Expected Location: `C:\Program Files\7-Zip\7z.exe`|
|KAPE|[Download](https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape) - request form required :(|Expected Location: `C:\tools\KAPE\kape.exe`|
|PowerShell|[GitHub Releases](https://github.com/PowerShell/powershell/releases)|Version 7 or above is required.|

If the software location differs on your system, modify the Process-Triage script to reflect the full path.

## Example

`C:\tools\Process-Triage.ps1 -Source d:\example\ -Destination c:\mpwd\example\kape\`

## Additional Notes

None. If you are having trouble you can email me at [marc@padil.la](mailto:marc@padil.la).
