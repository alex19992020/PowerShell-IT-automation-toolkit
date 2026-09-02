# PowerShell-IT-automation-toolkit

Day 1: I will test all three scripts against DC01. I will try the full flow — provision a user, reset their password and unlock them, then I'll run the health check to confirm the changes actually landed.  I will then check that Logs/helpdesk-toolkit.log is capturing everything.

Ok, I want to show my my understanding of scripting because knowing how to automate some tasks will increase productivity in the company which is a very important. So I have some scripts that I will run, one being "new-helpdeskuser.ps1, reset-helpdeskpassword.ps1, get-helpdeskhealth.ps1", by the name you can see that each does a different task. Below are the scripts,
<img width="3182" height="1364" alt="image" src="https://github.com/user-attachments/assets/e48f867a-bc61-4c96-bdf6-d1447d6fd80b" />

I will now go into my VM and make sure that shared folders between machines is on,
<img width="776" height="507" alt="image" src="https://github.com/user-attachments/assets/78f17b1e-7791-4ac8-a286-b40cf4d3dae3" />

As you can see above, the toolkit folder is shared so I'll be able to see it in the DC01 machine.

My next step is to change the default path of my scripts to a specific OU unit like IT, HR, or Sales department. In order for me to get the right path I should run Get-ADOrganizationalUnit -Filter * in the powershell, it'll have the full distinguished name there. Below you can see me run the command,
<img width="975" height="843" alt="Screenshot 2026-08-25 194405" src="https://github.com/user-attachments/assets/55d8bbda-cf72-4dfc-ac07-715005be86af" />

First, I'm going to test the newHelpDeskUser script to make sure it'll run correctly, the script has a default path of $DefaultOUPath = 'OU=Employees,DC=corp,DC=local'. I want to test it by creating a new user for the IT OU so in order to do that I must change the path to $DefaultOUPath = 'OU=IT,DC=corp,DC=local'. Now I can run this file by running the script with .\New-HelpDeskUser.ps1 -FirstName "Test" -LastName "User" -Department "IT". As you can see below it worked because you can see test user in the IT OU.
<img width="752" height="303" alt="image" src="https://github.com/user-attachments/assets/65214942-1485-4841-94da-a780221f397f" />

Now I'm going to test the health script with the test user we created with the previous script, below is me running the health script and confirming that it all works
<img width="981" height="529" alt="image" src="https://github.com/user-attachments/assets/09e8cffa-5f09-4fdd-bb5d-f43031800743" />

I ran the password script as well and it worked as you can tell by the password expired being true, I just didn't get a screenshot of it but all 3 scripts worked.

The next step is for me to try and break the script, pass: duplicate account creation, resetting a username that doesn't exist, a bad OU path. I want to confirm the error handling actually catches it cleanly instead of throwing a raw PowerShell error. I am doing this to show how I would go about in fixing scripting errors if and when I come up on them at work.

Test 1: I will try to create the same user twice
I already have a 'Test User' in the IT OU. I will run the exact same command again: `.\New-HelpDeskUser.ps1 -FirstName "Test" -LastName "User" -Department "IT"` A PASS will look like this: red error text on screen saying the username already exists, and an [ERROR] line in the log - NOT a second account getting created, and NOT a raw ugly PowerShell exception. If it silently creates a duplicate or a weird username, that's a bug worth knowing about.

Here's what happens when I run this test below,
<img width="1144" height="510" alt="image" src="https://github.com/user-attachments/assets/67daac92-80d9-4fae-af06-c7078a9ff9eb" />

This shows that my script passed the test, no duplicate account was created, it failed loudly and clearly as seen in the log above. This shows that my script runs good and it has no bugs.
You'll notice two [ERROR] lines for one command. That is not two failed attempts, it's the same run logging twice because when looking at the script logic: when it detects the duplicate username, it logs an ERROR and then throws an exception with that same message. That exception gets caught by the outer catch block at the bottom of the script, which logs another ERROR with the same text. So one failure produces two log entries, that's not broken, but it does make it slightly redundant. We can make the log look more clear by removing the "Write-HelpDeskLog" from inside the duplicate check block. 

Now for test 2, I will reset a password for a username that doesn't exist:
I will Run: `.\Reset-HelpDeskPassword.ps1 -Username "nobodyhere"` A PASS will look like this: a clean red error message (something like "Cannot find an object with identity 'nobodyhere'") and an [ERROR] line in the log. This is a very realistic error that I will encounter working as an IT technician - a help desk tech mistyping a username in a ticket system happens constantly, so the script needs to fail politely instead of throwing a wall of unreadable red text.

Here is what happens when I run test 2,
<img width="1191" height="239" alt="Screenshot 2026-09-01 194318" src="https://github.com/user-attachments/assets/7316b43a-c336-492f-8802-0dc1d9a2fca6" />

Now for test 3, I will try to provision into an OU that doesn't exist:
Run: `.\New-HelpDeskUser.ps1 -FirstName "Bad" -LastName "Path" -OUPath "OU=DoesNotExist,DC=corp,DC=local"` A PASS will look like this: an error about the path/OU not being found, logged as [ERROR], and no account created anywhere (check with `Get-ADUser -Filter "Surname -eq 'Path'"` afterward to be sure it didn't land somewhere unexpected).

Here's is what happens when I run test 3,
<img width="1214" height="191" alt="Screenshot 2026-09-01 195428" src="https://github.com/user-attachments/assets/9f3beb50-e642-4308-badb-ec23de169329" />

Above shows that the script failed instead of silently creating the account somewhere unexpected, and it was logged correctly meaning that my script doesn't have any bugs.
In order to make sure nothing was created silently, we ran the command "Get-ADUser -Filter "Surname -eq 'Path'", its supposed to return nothing, if it did return something, that means that the script did create the account somewhere, but as you can see below, nothing was returned.

<img width="772" height="192" alt="Screenshot 2026-09-01 195930" src="https://github.com/user-attachments/assets/35c7e08e-bde2-4342-9a41-43d0a16ae937" />










