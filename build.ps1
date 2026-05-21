Remove-Module explr -ErrorAction SilentlyContinue
Import-Module .\explr.psd1 -Force
Invoke-Pester -Path .\tests -Output Detailed
