<#
.SYNOPSIS
    Shared logging function for the Help Desk Automation Toolkit.

.DESCRIPTION
    Every script in this toolkit calls Write-HelpDeskLog instead of writing
    its own log lines. That means one consistent log format across the whole
    toolkit, and if the log format ever needs to change, it changes in one
    place instead of three.

    Why this matters for a help desk tool specifically: every action here
    (account created, password reset, account unlocked) is something an
    auditor or a manager might ask about later ("who reset this password and
    when?"). A consistent, timestamped log is what makes that answerable.
#>

function Write-HelpDeskLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$PSScriptRoot\..\Logs\helpdesk-toolkit.log"
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    # Record who ran the action, not just what happened - important for an
    # audit trail on anything touching user accounts or passwords.
    $runningAs = "$env:USERDOMAIN\$env:USERNAME"
    $logLine   = "[$timestamp] [$Level] [Run by: $runningAs] $Message"

    # Make sure the Logs folder exists even on a fresh clone of the toolkit.
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    Add-Content -Path $LogPath -Value $logLine

    # Mirror to the console too, color-coded, so you get immediate feedback
    # when running scripts interactively - not just a silent log write.
    switch ($Level) {
        'ERROR'   { Write-Host $logLine -ForegroundColor Red }
        'WARNING' { Write-Host $logLine -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $logLine -ForegroundColor Green }
        default   { Write-Host $logLine }
    }
}

Export-ModuleMember -Function Write-HelpDeskLog
