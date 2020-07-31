# Process-Triage

Takes a directory containing DupTriage and/or KapeTriage packages and processes them with Kroll Artifact Parser and Extractor (KAPE) for streamlined analysis.

If multiple triage packages for a single host exist, Process-Triage will differentiate them by collection timestamp and process them all. Incomplete triage packages are skipped and a message is printed to screen. Process-Triage will detect if a triage package has already been processed and skip it by default. This encourages you to run Process-Triage throughout an engagement.

## Required Software

Process-Triage utilizes the following software:

|Name|URL|Expected Location|
|----|----|----|
|7-Zip|[Download Page](https://www.7-zip.org/download.html)|`C:\Program Files\7-Zip\7z.exe`|
|KAPE|[Download Page](https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape) (request form required)|`C:\tools\KAPE\kape.exe`|
|PowerShell*|[GitHub Releases](https://github.com/PowerShell/powershell/releases)||

If the software location differs on your system, modify the Process-Triage script to reflect the full path.

\* Version 7.x or above.

## Additional Notes

None. If you are having trouble you can email me at [marc@padil.la](mailto:marc@padil.la).
