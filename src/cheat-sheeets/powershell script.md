running scripts is disabled on this system:

The error message "PowerShell module cannot be loaded using import command because running scripts is disabled on this system" indicates that the PowerShell execution policy is preventing the loading of the module. This policy is a security feature that controls which scripts can be run on your system.
Here's how to resolve this issue:
1. Understand Execution Policies
Restricted: The default policy, which doesn't allow any scripts to run.
AllSigned: Allows running scripts signed by a trusted publisher.
RemoteSigned: Allows running local scripts and scripts downloaded from the internet if they are signed by a trusted publisher.
Unrestricted: Allows all scripts to run, which poses a security risk.
Bypass: Allows all scripts to run, bypassing security warnings.
2. Check the Current Execution Policy
Open PowerShell as an administrator.
Run the command: Get-ExecutionPolicy -List
This will display the current execution policy for different scopes (e.g., LocalMachine, CurrentUser, Process).
3. Change the Execution Policy
To temporarily allow scripts to run for the current PowerShell session, use: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
To permanently change the execution policy for the current user, use: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned (or another suitable policy).
To permanently change the execution policy for all users on the system, use: Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned (or another suitable policy).
You may be prompted to confirm the change; type A and press Enter to accept.
4. Import the Module
After changing the execution policy, try importing the module again using the Import-Module command.
5. Revert the Execution Policy (Optional)
If you only needed to run the script temporarily, you can revert the execution policy to Restricted after you're done using: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Restricted
Important Notes:
Be cautious when changing the execution policy. Avoid using Unrestricted unless absolutely necessary, as it can pose a security risk.
RemoteSigned is often a good compromise, allowing you to run your own scripts and scripts from trusted sources.
Always run PowerShell as an administrator when making changes to the execution policy.