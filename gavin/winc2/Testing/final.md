# Offensive Security Engineering (CSEC 559/659)

### Final Project

# Tests

## Overview

The goal of these tests is to ensure that the Client is working as expected, and is able to correctly fetch, run, and return all of its new (and old) tasking, as well as smoothly handle any errors. This test document will demonstrate the resolution of all warnings at the `W4` level, the successful implementation of the new `mimikatz` task, the use of encryption between the Client and the Server, the removal of a visible console window when the client is run, and any other miscellaneous improvements.

## Screenshots and Descriptions

### Resolution of Warnings

![Figure 1: Warning Level 4](final-images/warning-level.png)

**Figure 1: Warning Level 4** The first screenshot shows that the Client's warning level is set to `Level4 (/W4)`, and that it will halt the build process if any warnings are issued, treating them as if they were errors.

![Figure 2: No Warnings](final-images/build-output.png)

**Figure 2: No Warnings** The second screenshot depicts a full rebuild completing successfully (and not being interrupted, as it would if there were a warning or error), as well as the Error List window, which shows the warning and error count both equal to `0`.

### Mimikatz Task

![Figure 3: Mimikatz Commands](final-images/mimikatz.png)

**Figure 3: Mimikatz Commands**

![Figure 4: Mimikatz Tasks](final-images/mimikatz-tasks.png)

**Figure 4: Mimikatz Tasks**

![Figure 5: Mimikatz Standard Result](final-images/mimikatz-1.png)

**Figure 5: Mimikatz Standard Result**

![Figure 6: Mimikatz Logonpasswords Result](final-images/mimikatz-2.png)

**Figure 6: Mimikatz Logonpasswords Result**

***The first screenshot shows a mimikatz sequence of commands being issued, followed by the logonpasswords alias. Then, the task ID's and statuses are shown, followed by the result of each task.***

### Encryption Between Client and Server

![CLI Commands](final-images/random-CLI.png)

![Encrypted Registration](final-images/random-registration.png)

![Encrypted listprivs Task Result](final-images/random-listprivs.png)

***The first screenshot shows the CLI selecting an agent and then sending it the `listprivs` task (specifically chosen because of the large amount of data it causes the client to send back to the server).***

***The second screenshot displays a Wireshark packet capture that was running during the Client, Server, CLI interaction shown in the first screenshot. As you can see, the very first HTTP packet (the Client registering with the Server) contains only high entropy (encrypted) bytes in its data field. Only the HTTP headers and encapsulating structures are left unencrypted. Because the server was able to successfully register the Client, in order for it to be able to be selected in the CLI, it must have been able to successfully decrypt the encrypted registration data.***

***Similar to the second screenshot, the third screenshot highlights the data field in an HTTP packet only containing encrypted data. This time, however, the packet is delivering the results of the `listprivs` command, demonstrating that all types of requests are encrypted, not just registration requests. In addition, the HTTP stream is followed in the center window, showing successful communication between the Client and the Server, both encrypting their communication data before sending it.***

### Removal of Visible Console

![Windows Subsystem Configuration](final-images/windows-subsystem-configuration.png)

***This screenshot shows the correct configuration for removing the visible console window for Release builds***

![Windows Subsystem Configuration](final-images/conditional-debug-macros.png)
![Running Without Window](final-images/running-without-window.PNG)

***Here, VisualStudio is shown to be actively running a Release build of the Client, and no corresponding console window is to be found.***

### Help Information

![help](final-images/help.png)

***In this screenshot, the improved `help` command's output is shown. Although all of the help messages and specific command examples couldn't be shown in this screenshot, they can easily be referenced [here](../Server/cli/README.md), in the CLI documentation.***

### EXTERNAL / INTERNAL IP

![Sysinfo - showing Internal IP](final-images/internal-ip.png)

![Sysinfo - showing External IP](final-images/external-ip.png)

![Server Parsing External IP from Registration](final-images/external-ip2.PNG)

### MISC Feature1

![autofill](final-images/autofill.png)
Worked on by Will Faber

### MISC Feature2

![alias](final-images/alias.png)

Worked on by all of us, we could not get alias-list done in time. 

### ADDITIONAL FEATURES

Add additional functionality to the Client/Server. Your goal is to make it awesome!

You **MUST** note in the final.md **AND** in the AAR who worked on each additional feature.

We did not finish this in time. 

### Documented Re-Tests

![terminate](final-images/terminate.PNG)

***This screenshot shows the terminate functionality***

![history](final-images/history.PNG)

***This screenshot shows the history functionality***

![pwd](final-images/pwd.png)

***This screenshot shows the pwd functionality***

![cd](final-images/cd.png)

***This screenshot shows the cd functionality***

![whoami](final-images/whoami.PNG)

***This screenshot shows the whoami functionality***

![ps](final-images/ps.png)

![ps2](final-images/pscont.png)

***These screenshots show the ps functionality***

![Shell](final-images/shell.PNG)
***This screenshot shows the shell functionality***

![setpriv](final-images/setpriv.PNG)

***This screenshot shows the functionality of the setpriv command***

![listprivs](final-images/listprivs.PNG)

***This screenshot shows the functionality of the listprivs command, where you can see the priv that was set using the setpriv command above.***

![tasks](final-images/tasks.PNG)

![task](final-images/task.PNG)

***These screenshots show the functionality of the task command.***

![bypassuac](final-images/bypassuac.PNG)

***This screenshot shows the functionality of the bypassuac command***

![getsystem](final-images/getsystem.PNG)

***This screenshot shows the functionality of the getsystem command***

![sysinfo](final-images/sysinfo.PNG)

***This screenshot shows the functionality of the sysinfo command***

![Screenshot](final-images/screenshot.PNG)

***This screenshot shows the functionality of the screenshot command.***

![the screenshot that was taken](final-images/AGENT-TASK.png)

***This is the screenshot taken using the above command***

![Sleep](final-images/sleep.PNG)

***This screenshot shows the functionality of the sleep command***

# AAR

Date: 05/05/2025

Attendees: Gavin McConnell, William Faber, Lance Cordova

* what went well?
  * We got a lot of screenshots done early. Communicated well. 
* what didnt go well?
  * We were all super busy, could not finish everything in time, Insanely huge final project, homeworks were not fully finished, made the final near impossible during finals week for our team. 
* what should we change?
  * Honestly wish we could have changed much but we did all we good. I am proud of where we got. 

Additional Notes (optional):

* In the future, implementing every previous homework in a C2 is a AWESOME final project, just really hard during finals wwek. 

