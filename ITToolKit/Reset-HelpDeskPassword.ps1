<#
.SYNOPSIS
    Resets a user's password and/or unlocks their account - the single most
    common help desk ticket type.

.DESCRIPTION
    Verifies the account exists, resets the password to a new randomly
    generated temp password (forcing a change at next logon), and optionally
    unlocks the account in the same run since "reset my password" and
    "I'm locked out" very often arrive as the same ticket.

.PARAMETER Username
    SamAccountName of the account to reset.

.PARAMETER Unlock
    Switch. If present, also clears the account lockout.

.EXAMPLE
    .\Reset-HelpDeskPassword.ps1 -Username "jrivera" -Unlock
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $false)]
    [switch]$Unlock
)

Import-Module ActiveDirectory
Import-Module "$PSScriptRoot\Modules\HelpDeskLogging.psm1" -Force

function New-TempPassword {
    $upper   = 65..90  | Get-Random -Count 3 | ForEach-Object { [char]$_ }
    $lower   = 97..122 | Get-Random -Count 4 | ForEach-Object { [char]$_ }
    $number  = 48..57  | Get-Random -Count 2 | ForEach-Object { [char]$_ }
    $symbol  = '!@#$%^&*'.ToCharArray() | Get-Random -Count 2
    $all     = ($upper + $lower + $number + $symbol) | Sort-Object { Get-Random }
    return -join $all
}

try {
    $user = Get-ADUser -Identity $Username -Properties LockedOut -ErrorAction Stop

    $tempPassword = New-TempPassword
    $securePwd    = ConvertTo-SecureString $tempPassword -AsPlainText -Force

    Set-ADAccountPassword -Identity $Username -NewPassword $securePwd -Reset
    Set-ADUser -Identity $Username -ChangePasswordAtLogon $true

    Write-HelpDeskLog -Level SUCCESS -Message "Password reset for '$Username'. Change-at-next-logon flag set."

    if ($Unlock -or $user.LockedOut) {
        Unlock-ADAccount -Identity $Username
        Write-HelpDeskLog -Level SUCCESS -Message "Account '$Username' unlocked."
    }

    Write-Host "`nPassword reset for $Username" -ForegroundColor Cyan
    Write-Host "Temporary password: $tempPassword"
    Write-Host "User must change password at next logon.`n"

} catch {
    Write-HelpDeskLog -Level ERROR -Message "Password reset failed for '$Username': $($_.Exception.Message)"
    Write-Error $_.Exception.Message
}
