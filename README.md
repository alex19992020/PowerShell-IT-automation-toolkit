# PowerShell Help Desk Automation Toolkit

PowerShell scripts that automate the three most common Tier 1 help desk tickets: **new-hire account setup**, **password reset / account unlock**, and **"what's wrong with this user's account?"** checks. Built and tested against my own Active Directory home lab (`corp.local`), with shared logging and deliberate failure testing.

> **30-second summary:** I built three Active Directory scripts plus a shared logging module using an AI-assisted workflow (Claude), then deployed them to my own Windows Server 2022 domain controller. I tested them end-to-end and tried to break them on purpose (duplicate accounts, mistyped usernames, bad OU paths) to confirm they fail cleanly and leave an audit trail. AI sped up the first draft; I owned the deployment, testing, verification, and review. Below I explain why each design choice was made, how I used AI (and where I didn't trust it), what went wrong while testing, and what I'd change next.

---

## Table of Contents
- [Why I Built This](#why-i-built-this)
- [What's in the Toolkit](#whats-in-the-toolkit)
- [Lab Environment](#lab-environment)
- [Design Decisions (and Why)](#design-decisions-and-why)
- [How I Used AI in This Project](#how-i-used-ai-in-this-project)
- [How to Use It](#how-to-use-it)
- [Testing: Happy Path](#testing-happy-path)
- [Testing: Trying to Break It](#testing-trying-to-break-it)
- [Troubleshooting Log](#troubleshooting-log)
- [What I'd Do Differently](#what-id-do-differently)
- [Skills Demonstrated](#skills-demonstrated)
- [Repo Structure](#repo-structure)

---

## Why I Built This

On a help desk, a large share of tickets are the same few requests over and over: set up the new hire, reset a forgotten password, figure out why someone can't log in. Doing these by clicking through Active Directory Users and Computers works, but it's slow and easy to get slightly wrong (wrong OU, forgot to force a password change, no record of who did what).

I wanted to show that I can:
1. **Automate repetitive work** so it's faster and done the same way every time
2. **Handle bad input safely**, because real tickets contain typos and duplicates
3. **Leave an audit trail**, so any action can be traced back later

---

## What's in the Toolkit

| Script | Ticket it handles | What it does |
|---|---|---|
| `New-HelpDeskUser.ps1` | "We have a new hire starting Monday" | Creates the AD account in the right OU, generates a temporary password, forces a password change at first logon, refuses to create duplicates |
| `Reset-HelpDeskPassword.ps1` | "I forgot my password" / "I'm locked out" | Resets the password to a new temporary one, optionally unlocks the account (`-Unlock`), forces a change at next logon |
| `Get-HelpDeskUserHealth.ps1` | "User can't log in, what's going on?" | Pulls a quick account snapshot: enabled, locked out, password expired, last logon, password last set, group memberships |
| `Modules/HelpDeskLogging.psm1` | (shared) | One logging function all three scripts import, writing timestamped `[SUCCESS]` / `[INFO]` / `[ERROR]` lines to `Logs/helpdesk-toolkit.log` |

<img width="3182" height="1364" alt="The three toolkit scripts and logging module" src="https://github.com/user-attachments/assets/e48f867a-bc61-4c96-bdf6-d1447d6fd80b" />

---

## Lab Environment

This runs against the Active Directory lab I built from scratch ([AD lab repo](https://github.com/alex19992020/AD)):

- **Hypervisor:** VirtualBox 7.2
- **DC01:** Windows Server 2022, domain controller for `corp.local` (10.0.0.10)
- **Client01:** Windows 11 Enterprise, domain-joined (10.0.0.20)
- **OUs:** HR, IT, Sales
- Scripts were run on **DC01**, which already has the ActiveDirectory PowerShell module. Running from Client01 would require installing RSAT first.

To get the scripts from my host machine into the VM, I set up a VirtualBox shared folder:

<img width="776" height="507" alt="VirtualBox shared folder setup" src="https://github.com/user-attachments/assets/78f17b1e-7791-4ac8-a286-b40cf4d3dae3" />

---

## Design Decisions (and Why)

**One shared logging module instead of logging code in every script.**
If I copy-paste the same logging code into three files, a future change has to be made three times and they'll drift apart. A single module means one place to fix, and every script writes to the same log in the same format.

**The log records actions, not data.**
The log says *"password reset for tuser"*, not the account's full details or the new password. The log is an audit trail (who did what, when). The account details print to the console for the tech running the script, and the log never stores passwords.

**Force a password change at first logon.**
The temporary password is known to the help desk tech. Forcing the user to change it means only the user ends up knowing their real password, which is standard practice.

**Check for duplicates before creating an account.**
`New-ADUser` will fail on an exact duplicate anyway, but checking first lets the script give a clear, human-readable message instead of a raw exception, and log it.

**Wrap the work in `try/catch` and fail loudly.**
A script that silently does the wrong thing is worse than one that errors. Every failure prints a clear red message and writes an `[ERROR]` line to the log.

**Configurable OU path.**
The target OU can be set with `-OUPath` per run, with a default at the top of the script so the common case needs no extra typing.

---

## How I Used AI in This Project

I used Claude (Anthropic's AI assistant) as a pair-programmer and tutor throughout this project. IT teams are adopting AI tools quickly, and the skill that matters isn't just *using* AI. It's knowing what to hand off, what to verify, and when the output is wrong.

### Where AI helped

| Task | How I used AI | What I did myself |
|---|---|---|
| **Scaffolding the scripts** | Generated the first draft of the three scripts and the logging module from my requirements (the tickets to cover, logging, error handling) | Deployed them into my lab, set the real OU paths, and ran them against live AD |
| **Planning the tests** | Brainstormed realistic failure cases (duplicates, typos, bad OU paths) | Wrote pass criteria *before* each test, ran them, and judged the results |
| **Explaining AD behavior** | Asked why `PasswordLastSet` was blank after a reset | Confirmed the explanation against the actual account state in AD instead of taking it on faith |
| **Debugging** | Pasted errors and screenshots to narrow down causes (e.g. the missing log file) | Ran the diagnostic commands (`pwd`, `dir`, `git status`, `git log`) and applied the fixes |
| **Documentation** | Helped restructure this README for readability | Supplied every screenshot, test result, and finding |

### Where I didn't just trust the AI

- **I verified results in the lab, not in the chat.** An AI saying "this should work" isn't evidence. The proof is the account showing up in the right OU, the health check reflecting the reset, and `Get-ADUser` returning nothing after the bad-OU test.
- **I reviewed the generated code and found a flaw.** The double `[ERROR]` logging ([Troubleshooting #3](#3-two-error-lines-for-one-failed-run)) came from the AI-generated draft: it logged inside the duplicate check *and* in the `catch` block. Tracing the logic myself is how I found it.
- **I tested against a lab, never production.** AI-generated scripts that touch Active Directory should always run in a safe environment first. That's exactly what the home lab is for.
- **I made sure I understand every line.** If I can't explain what a line does and why it's there, it doesn't belong in a script I'm putting my name on.

### Takeaway

AI cut the time to a working first draft from days to hours. That freed me to spend my effort where it matters most on a help desk: testing edge cases, verifying outcomes, and documenting the reasoning. I took this further in my next project, [AI IT Ticket Triage](https://github.com/alex19992020/AI-IT-Ticket-Triage). There I built a tool on the Anthropic API that classifies and prioritizes tickets, with a human-in-the-loop design so a technician always makes the final call.

---

## How to Use It

**1. Allow local scripts to run** (once per machine, as Administrator):
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
*Why:* Windows blocks unsigned scripts by default. `RemoteSigned` allows scripts written locally while still blocking unsigned scripts downloaded from the internet.

**2. Find your OU's distinguished name:**
```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
```
*Why:* AD needs the full path (e.g. `OU=IT,DC=corp,DC=local`), not just "IT". I ran this to get the exact value instead of guessing.

<img width="975" height="843" alt="Get-ADOrganizationalUnit output" src="https://github.com/user-attachments/assets/55d8bbda-cf72-4dfc-ac07-715005be86af" />

**3. Run the scripts from inside the toolkit folder:**
```powershell
# Create a new user in the IT OU
.\New-HelpDeskUser.ps1 -FirstName "Test" -LastName "User" -Department "IT"

# Reset a password and unlock the account
.\Reset-HelpDeskPassword.ps1 -Username "tuser" -Unlock

# Check the account's status
.\Get-HelpDeskUserHealth.ps1 -Username "tuser"

# Read the audit log
notepad .\Logs\helpdesk-toolkit.log
```

---

## Testing: Happy Path

I tested the full lifecycle of a ticket: **create → check → reset/unlock → check again**. The second health check matters: it confirms the change actually landed in AD, not just that the script said it worked.

**Create user:** `Test User` (`tuser`) created in the IT OU.

<img width="752" height="303" alt="Test User created in the IT OU" src="https://github.com/user-attachments/assets/65214942-1485-4841-94da-a780221f397f" />

**Health check after reset and unlock:**

<img width="981" height="529" alt="Health check output" src="https://github.com/user-attachments/assets/09e8cffa-5f09-4fdd-bb5d-f43031800743" />

How I read this output:

| Field | Value | Why it's correct |
|---|---|---|
| `LockedOut` | False | The `-Unlock` switch worked |
| `PasswordExpired` | True | Expected: "must change password at next logon" is stored by AD as an expired password |
| `PasswordLastSet` | (blank) | Expected for the same reason: AD doesn't count the password as "set" until the user changes it. A date here would mean the force-change flag *didn't* apply |
| `LastLogonDate` | (blank) | Nobody has logged in as this user yet |
| `GroupMemberships` | (blank) | No `-Groups` were passed in this test |

<!-- TODO: add screenshot of Reset-HelpDeskPassword.ps1 success output -->

---

## Testing: Trying to Break It

Getting the happy path working is only half the job. I deliberately fed the scripts the kind of bad input that shows up in real tickets, and wrote down what a **pass** looks like *before* running each test so I wasn't just accepting whatever happened.

| # | Test | Real-world cause | Pass criteria | Result |
|---|---|---|---|---|
| 1 | Create the same user twice | Duplicate onboarding request from HR | Clear error, `[ERROR]` in log, no second account | ✅ Pass |
| 2 | Reset password for `nobodyhere` | Tech mistypes a username from a ticket | Readable "cannot find" error, `[ERROR]` in log | ✅ Pass |
| 3 | Create user in `OU=DoesNotExist` | Typo in the OU path | Error, `[ERROR]` in log, **no account created anywhere** | ✅ Pass |

**Test 1: Duplicate account**
```powershell
.\New-HelpDeskUser.ps1 -FirstName "Test" -LastName "User" -Department "IT"
```
<img width="1144" height="510" alt="Duplicate account test" src="https://github.com/user-attachments/assets/67daac92-80d9-4fae-af06-c7078a9ff9eb" />

No duplicate was created. I noticed the log shows **two** `[ERROR]` lines for one run; see the [troubleshooting log](#troubleshooting-log) for why.

**Test 2: Nonexistent user**
```powershell
.\Reset-HelpDeskPassword.ps1 -Username "nobodyhere"
```
<img width="1191" height="239" alt="Nonexistent user test" src="https://github.com/user-attachments/assets/7316b43a-c336-492f-8802-0dc1d9a2fca6" />

The error names the exact username it couldn't find, so a tech can act on it immediately instead of digging.

**Test 3: Bad OU path**
```powershell
.\New-HelpDeskUser.ps1 -FirstName "Bad" -LastName "Path" -OUPath "OU=DoesNotExist,DC=corp,DC=local"
```
<img width="1214" height="191" alt="Bad OU path test" src="https://github.com/user-attachments/assets/9f3beb50-e642-4308-badb-ec23de169329" />

An error message alone doesn't prove nothing was created, so I verified it separately:
```powershell
Get-ADUser -Filter "Surname -eq 'Path'"
```
<img width="772" height="192" alt="Get-ADUser returns nothing" src="https://github.com/user-attachments/assets/35c7e08e-bde2-4342-9a41-43d0a16ae937" />

Empty result: no account landed anywhere unexpected.

---

## Troubleshooting Log

Real issues I hit while building and testing, and how I worked through each one.

### 1. "Cannot find path" when opening the log file
- **Symptom:** The user was created successfully, but `notepad .\Logs\helpdesk-toolkit.log` said the file didn't exist.
- **What I checked:** Ran `pwd` to see where PowerShell actually was, then `dir` to list the folder.
- **Cause:** I had reopened PowerShell, so I was back in my home directory. `.\Logs\...` is a *relative* path, so it only works from inside the toolkit folder.
- **Fix:** `cd` back into the toolkit folder; the log was there with the expected `[SUCCESS]` entry.
- **Takeaway:** When something "doesn't exist," confirm where you are before assuming it was never created.

### 2. `PasswordLastSet` was blank after a password reset
- **Symptom:** After resetting the password, the health check showed `PasswordLastSet` empty and `PasswordExpired: True`. It looked like the reset failed.
- **What I checked:** Compared the result to what the script does: it sets "change password at next logon."
- **Cause:** That's how AD represents a forced change. The password isn't considered "set" until the user sets it themselves.
- **Takeaway:** This was the opposite of a bug: it proved the force-change flag applied. Understanding *why* a field looks odd matters more than whether it looks normal.

### 3. Two `[ERROR]` lines for one failed run
- **Symptom:** Test 1 (duplicate account) produced two identical `[ERROR]` lines.
- **What I checked:** Traced the script logic from the duplicate check down to the `catch` block.
- **Cause:** The duplicate check logs an error *and then* throws an exception. The outer `catch` block catches that exception and logs it again.
- **Fix:** Not a functional bug (no extra attempt happens), but it's redundant. Removing the `Write-HelpDeskLog` call inside the duplicate check and letting only the `catch` block log would give one clean line per failure.

### 4. Log showed `Department: Unassigned` instead of `IT`
- **Symptom:** The first successful creation logged `(Test User, Unassigned)`.
- **Cause:** That run didn't include `-Department "IT"`, and the script defaults to "Unassigned" when it's missing.
- **Takeaway:** Silent defaults can hide mistakes. See [What I'd Do Differently](#what-id-do-differently).

### 5. Setup issues before the scripts would run
- **Scripts blocked:** Fixed with `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
- **Files not visible in the VM:** Downloading to my host doesn't put files in the VM. Set up a VirtualBox shared folder.
- **Module import failing:** The scripts expect `Modules\HelpDeskLogging.psm1` next to them. Keeping the folder structure intact fixed it.
- **Scripts missing from GitHub after pushing:** Only the README had been committed. Used `git status` and `git log` to confirm what was actually staged and committed, then added and pushed the rest.

---

## What I'd Do Differently

| Change | Why |
|---|---|
| Log each failure once (only in the `catch` block) | Cleaner audit trail, easier to read during an incident |
| Make `-Department` required or validated with `[ValidateSet()]` | A silent "Unassigned" default lets a mistake through unnoticed |
| Derive the OU from the department instead of editing `$DefaultOUPath` in the script | Editing code to change a setting is error-prone; a config file or a department→OU mapping is safer |
| Add `-WhatIf` support (`SupportsShouldProcess`) | Lets a tech preview what would change before touching AD |
| Deliver temp passwords through a secure channel instead of printing to screen | Anything on screen can end up in a screenshot or screen share |
| Run from Client01 with RSAT under a delegated help desk account, not on the DC as a Domain Admin | Least privilege: help desk staff shouldn't need Domain Admin to reset passwords |
| Add automated tests with Pester | The three failure tests I ran by hand could run automatically after every change |
| Add an offboarding script (disable account, remove groups, move to a Disabled OU) | Completes the employee lifecycle |

---

## Skills Demonstrated

- **Active Directory:** user provisioning, OUs and distinguished names, password resets, account unlocks, reading account status
- **PowerShell:** parameters, `try/catch` error handling, reusable modules, file logging, the ActiveDirectory module
- **Troubleshooting:** defining pass criteria before testing, verifying results independently, reading error output, tracing script logic
- **Security habits:** forced password change, no passwords in logs, audit trail, awareness of least privilege
- **AI-assisted development:** using AI for scaffolding, test planning, and debugging, while independently verifying and reviewing its output
- **Documentation:** explaining the *why* behind each step for whoever maintains it next
- **Tools:** VirtualBox, Windows Server 2022, Windows 11 Enterprise, Git/GitHub, Claude (AI assistant)

---

## Repo Structure

```
HelpDeskToolkit/
├── New-HelpDeskUser.ps1
├── Reset-HelpDeskPassword.ps1
├── Get-HelpDeskUserHealth.ps1
├── Modules/
│   └── HelpDeskLogging.psm1
├── Logs/
│   └── helpdesk-toolkit.log   # created on first run
└── README.md
```

---

## Related Projects
- [Active Directory Home Lab](https://github.com/alex19992020/AD): the environment this toolkit runs against
- [AI IT Ticket Triage](https://github.com/alex19992020/AI-IT-Ticket-Triage): follow-up project using the Anthropic API to classify and prioritize help desk tickets, with a human-in-the-loop design

**Connect with me:** [LinkedIn](https://www.linkedin.com/in/alejandro007)
