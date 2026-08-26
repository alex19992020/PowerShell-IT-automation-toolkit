# PowerShell-IT-automation-toolkit

Day 1: I will test all three scripts against DC01. I will try the full flow — provision a user, reset their password and unlock them, then I'll run the health check to confirm the changes actually landed.  I will then check that Logs/helpdesk-toolkit.log is capturing everything.

Ok, I want to show my my understanding of scripting because knowing how to automate some tasks will increase productivity in the company which is a very important. So I have some scripts that I will run, one being "new-helpdeskuser.ps1, reset-helpdeskpassword.ps1, get-helpdeskhealth.ps1", by the name you can see that each does a different task. Below are the scripts,
<img width="3182" height="1364" alt="image" src="https://github.com/user-attachments/assets/e48f867a-bc61-4c96-bdf6-d1447d6fd80b" />

I will now go into my VM and make sure that shared folders between machines is on,
<img width="776" height="507" alt="image" src="https://github.com/user-attachments/assets/78f17b1e-7791-4ac8-a286-b40cf4d3dae3" />

As you can see above, the toolkit folder is shared so I'll be able to see it in the DC01 machine.

My next step is to change the default path of my scripts to a specific OU unit like IT, HR, or Sales department. In order for me to get the right path I should run Get-ADOrganizationalUnit -Filter * in the powershell, it'll have the full distinguished name there. Below you can see me run the command,
<img width="975" height="843" alt="Screenshot 2026-08-25 194405" src="https://github.com/user-attachments/assets/55d8bbda-cf72-4dfc-ac07-715005be86af" />


