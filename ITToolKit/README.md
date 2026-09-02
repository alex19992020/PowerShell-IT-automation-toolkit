# Help Desk Automation Toolkit

PowerShell scripts automating the three most common Tier 1 help desk tasks,
built and tested against a home Active Directory lab (`corp.local`).

## Scripts

| Script | What it does |
|---|---|
| `New-HelpDeskUser.ps1` | Provisions a new-hire AD account: creates the user, generates a temp password, forces a password change at first logon, optionally adds them to groups. |
| `Reset-HelpDeskPassword.ps1` | Resets a user's password and optionally unlocks their account in one run. |
| `Get-HelpDeskUserHealth.ps1` | Pulls last logon, lockout status, password age, and group memberships for a given account - the "what's going on with this account" check before troubleshooting. |
| `Modules/HelpDeskLogging.psm1` | Shared logging function all three scripts use, so every action is timestamped and attributed to whoever ran it. |

## Setup (before running against your lab)

1. Open `New-HelpDeskUser.ps1` and update `$DefaultOUPath` to match the OU
   you actually created in `corp.local` (e.g. `OU=Employees,DC=corp,DC=local`).
2. Run these from **Client01** (or DC01) with an account that has rights to
   create/modify AD users - i.e. RSAT / ActiveDirectory module installed and
   permissions in that OU.
3. Logs land in `Logs/helpdesk-toolkit.log`.

## Example usage

```powershell
# Provision a new hire
.\New-HelpDeskUser.ps1 -FirstName "Jordan" -LastName "Rivera" -Department "Sales" -Groups "Sales-Team"

# Reset a password and unlock the account
.\Reset-HelpDeskPassword.ps1 -Username "jrivera" -Unlock

# Check account status before troubleshooting a ticket
.\Get-HelpDeskUserHealth.ps1 -Username "jrivera"
```

## Why this exists

Manually clicking through Active Directory Users and Computers for routine
tasks - onboarding, password resets, account checks - doesn't scale, and
it's the first thing that gets automated on a real help desk team. This
toolkit demonstrates that automation directly against a lab environment
built to mirror a real corporate domain.

*(Screenshots of each script running against the lab go here.)*
