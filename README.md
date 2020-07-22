# Process-Triage

Takes a matter Splunk share containing DupTriage and/or KapeTriage packages and processes them with KAPE.

If multiple triage packages for a single host exist Process-Triage will process them all. This behavior can be modified to meet your needs. Process-Triage will detect if a triage package has already been processed and skip it by default. This encourages you to run Process-Triage throughout an engagement.

## Required Software

Process-Triage utilizes the following software:

- **7-Zip** [https://www.7-zip.org/](https://www.7-zip.org/)
- **KAPE** [https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape](https://www.kroll.com/en/services/cyber-risk/investigate-and-respond/kroll-artifact-parser-extractor-kape)
- **PowerShell** [https://github.com/PowerShell/powershell/releases](https://github.com/PowerShell/powershell/releases) *\* Version 7+ required*

Process-Triage expects the full path of 7-Zip to be C:\Program Files\7-Zip\7z.exe and the full path of KAPE to be C:\tools\kape\kape.exe. Modify the Process-Triage script if either location is different on your system.

## Additional Notes

None. If you are having trouble you can email me at [marc@padil.la](mailto:marc@padil.la).
