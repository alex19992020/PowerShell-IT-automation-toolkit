<#
.SYNOPSIS
    Pulls a quick account "health check" for a user - the info you'd want on
    screen before you even start troubleshooting a ticket.

.DESCRIPTION
    Instead of manually clicking through ADUC to find last logon time, group
    memberships, and lockout status, this pulls it all in one command. This
    is exactly the kind of "before I touch anything, what's actually going
    on with this account" step a Tier 1 tech does on nearly every ticket -
    account issues, access issues, "why can't I log in" reports.

.PARAMETER Username
    SamAccountName of the account to check.

.EXAMPLE
    .\Get-HelpDeskUserHealth.ps1 -Username "jrivera"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Username
)

Import-Module ActiveDirectory
Import-Module "$PSScriptRoot\Modules\HelpDeskLogging.psm1" -Force

try {
    $props = 'LastLogonDate','LockedOut','PasswordLastSet','PasswordExpired',
              'PasswordNeverExpires','AccountExpirationDate','Enabled','MemberOf'

    $user = Get-ADUser -Identity $Username -Properties $props -ErrorAction Stop

    $groupNames = $user.MemberOf | ForEach-Object {
        (Get-ADGroup -Identity $_).Name
    }

    $result = [PSCustomObject]@{
        Username             = $user.SamAccountName
        FullName             = $user.Name
        Enabled              = $user.Enabled
        LockedOut            = $user.LockedOut
        LastLogonDate        = $user.LastLogonDate
        PasswordLastSet      = $user.PasswordLastSet
        PasswordExpired      = $user.PasswordExpired
        PasswordNeverExpires = $user.PasswordNeverExpires
        AccountExpires       = $user.AccountExpirationDate
        GroupMemberships     = ($groupNames -join ', ')
    }

    Write-HelpDeskLog -Level INFO -Message "Health check run for '$Username'."

    $result | Format-List

} catch {
    Write-HelpDeskLog -Level ERROR -Message "Health check failed for '$Username': $($_.Exception.Message)"
    Write-Error $_.Exception.Message
}
