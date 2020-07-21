# Process-Triage

Takes a directory containing DupTriage and/or KapeTriage packages and processes them with KAPE.

## Required Software

Process-Triage utilizes the following software:

- **7-Zip** [https://www.7-zip.org/](https://www.7-zip.org/)
- **KAPE** [https://www.kroll.com/en/insights/publications/cyber/kroll-artifact-parser-extractor-kape](https://www.kroll.com/en/insights/publications/cyber/kroll-artifact-parser-extractor-kape)
- **PowerShell** [https://github.com/PowerShell/powershell/releases](https://github.com/PowerShell/powershell/releases) *version 7+ required for use of -Parallel*

Process-Triage expects the full path of 7-Zip to be C:\Program Files\7-Zip\7z.exe and the full path of KAPE to be C:\tools\kape\kape.exe. Adjust the Process-Triage script if either location is different on your system.

## Additional Notes

By default Process-Triage processes KapeTriage packages before processing DupTriage packages. This is my personal preference. It is possible to swap the order or write a loop to use whichever was taken first, more recent, etc.
