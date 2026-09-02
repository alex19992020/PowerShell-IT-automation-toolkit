<#
.SYNOPSIS
    Provisions a new AD user account for a new hire - the most common Tier 1
    onboarding task.

.DESCRIPTION
    Creates the account, generates a temporary password, forces a password
    change at first logon, and (optionally) adds the user to department
    groups. Every step is logged via Write-HelpDeskLog.

    EDIT ME: $DefaultOUPath below should point at the OU in your lab where
    new user accounts should land (e.g. "OU=Employees,DC=corp,DC=local").
    I don't have your exact OU structure, so this is a placeholder - swap it
    for whatever OU you created in corp.local, or pass -OUPath at runtime.

.PARAMETER FirstName
    New user's first name.

.PARAMETER LastName
    New user's last name.

.PARAMETER Department
    Optional. Used only to log which department the account is for.

.PARAMETER Groups
    Optional. Array of AD group names to add the new user to.

.PARAMETER OUPath
    Optional. Overrides $DefaultOUPath below for this run.

.EXAMPLE
    .\New-HelpDeskUser.ps1 -FirstName "Jordan" -LastName "Rivera" -Department "Sales" -Groups "Sales-Team","VPN-Users"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $false)]
    [string]$Department = 'Unassigned',

    [Parameter(Mandatory = $false)]
    [string[]]$Groups = @(),

    [Parameter(Mandatory = $false)]
    [string]$OUPath
)

Import-Module ActiveDirectory
Import-Module "$PSScriptRoot\Modules\HelpDeskLogging.psm1" -Force

# --- EDIT THIS to match your lab's actual OU structure ---
$DefaultOUPath = 'OU=Employees,DC=corp,DC=local'
if (-not $OUPath) { $OUPath = $DefaultOUPath }

function New-TempPassword {
    # Builds a random password that satisfies typical AD complexity rules:
    # upper, lower, number, symbol, 12+ chars. Real orgs usually generate
    # these programmatically rather than hand-picking "Welcome1!" for every
    # new hire, which is worth calling out in an interview.
    $upper   = 65..90  | Get-Random -Count 3 | ForEach-Object { [char]$_ }
    $lower   = 97..122 | Get-Random -Count 4 | ForEach-Object { [char]$_ }
    $number  = 48..57  | Get-Random -Count 2 | ForEach-Object { [char]$_ }
    $symbol  = '!@#$%^&*'.ToCharArray() | Get-Random -Count 2
    $all     = ($upper + $lower + $number + $symbol) | Sort-Object { Get-Random }
    return -join $all
}

$username = ("{0}{1}" -f $FirstName.Substring(0,1), $LastName).ToLower() -replace '[^a-z0-9]', ''

try {
    if (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue) {
        Write-HelpDeskLog -Level ERROR -Message "Provisioning failed: username '$username' already exists."
        throw "User '$username' already exists in AD. Choose a different naming scheme or check for a duplicate hire."
    }

    $tempPassword = New-TempPassword
    $securePwd    = ConvertTo-SecureString $tempPassword -AsPlainText -Force

    New-ADUser `
        -Name "$FirstName $LastName" `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $username `
        -UserPrincipalName "$username@corp.local" `
        -Path $OUPath `
        -AccountPassword $securePwd `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -Department $Department

    Write-HelpDeskLog -Level SUCCESS -Message "Created account '$username' ($FirstName $LastName, $Department) in $OUPath."

    foreach ($group in $Groups) {
        try {
            Add-ADGroupMember -Identity $group -Members $username
            Write-HelpDeskLog -Level SUCCESS -Message "Added '$username' to group '$group'."
        } catch {
            Write-HelpDeskLog -Level WARNING -Message "Could not add '$username' to group '$group': $($_.Exception.Message)"
        }
    }

    # NOTE: printing the temp password to console is fine for a home lab
    # demo. In a real environment you would NOT log a plaintext password to
    # a file - hand it off via a secure channel instead. Worth mentioning
    # this distinction if asked about it in an interview.
    Write-Host "`nAccount created for $FirstName $LastName" -ForegroundColor Cyan
    Write-Host "Username: $username"
    Write-Host "Temporary password: $tempPassword"
    Write-Host "User must change password at next logon.`n"

} catch {
    Write-HelpDeskLog -Level ERROR -Message "Provisioning failed for '$FirstName $LastName': $($_.Exception.Message)"
    Write-Error $_.Exception.Message
}
