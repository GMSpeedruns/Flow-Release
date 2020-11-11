This is a pretty complex-to-setup system, so I'll try to guide you through it.
I've completely set this up myself so it probably makes more sense to me than it does to you.

This script HAS to run on a Windows box unless you know your way around with C#, Mono and Java so you can edit all my project files. (If you want to edit graavy.jar, for Java source, use a Java Decompiler)
The Windows server has to run a Java instance, as well as a SOUND system (if you run Windows Server, you might have to install this: https://technet.microsoft.com/en-us/library/cc772567.aspx)
The source is available in the /Application/SurflineTicketManager_src.zip folder. It's compiled against the .NET Framework 4.5. Your server must also have the client redistributable installed.

To obtain the full repository you need for this, check Downloads/Downloads.txt for the download URLs.

The most important file in this is the SurflineTicketManager.exe itself. This makes sure the tickets actually get processed.
Let's have a look at the config file! It's at /Application/config.ini

You'll have to change several paths to get this thing to work.
LOCAL_PATH
	- Description: The path to the folder where your files are going to be (ALL FILES WILL BE SAVED TO THIS FOLDER \data\), followed with a backslash
	- Default (example): C:\Surfline\Web\htdocs\radio\

GROOVE_PATH
	- Description: This is the path to LOCAL_PATH\graavy.jar - The Grooveshark processing unit.
	- Default (example): C:\Surfline\Web\htdocs\radio\graavy.jar

JAVA_PATH
	- Description: The path to your Java VM. This should be JRE 1.8, but I believe it will also work with 1.7
	- Default (example): C:\Program Files (x86)\Java\jre1.8.0_25\bin\java.exe

TICKET_PREFIX
	- Description: The ticket prefix. If you are not changing the post.php script, use ticket_
	- Default (example): ticket_

REPORT_URL
	- Description: The URL the application calls to mark a song as downloaded. This is the same path as the one you're using in post.php
	- Default (example): http://www.google.com/on_mysql_server_radio.php?type=add&params=

REPORT_URL_FAIL
	- Description: The URL the application calls to mark a song as failed. This is the same path as the one you're using in post.php
	- Default (example): http://www.google.com/on_mysql_server_radio.php?type=fail&params=

[[[ SERVER CONTROL ]]]
These are only useful for when you're running your server on the same box as the radio server will be running on.
It's of course best to have it all on one server, so there's no latency.

If you already have a server restart script (other than SRCDS Watchdog - it sucks...), there's no need to look into this.
If you have your server running on another box, there's also no need for this so just leave it on "No"

SERVER_CONTROL
	- Description: Determines whether it's on or not. Will take anything as a value, but only for setting it to Yes you'll enable it.
	- Default (example): No

SERVER_DIRECTORY
	- Description: The location of your /garrysmod/ folder and of course the srcds.exe file
	- Default (example): C:\Surfline\Steam\steamapps\common\GarrysModDS

SERVER_SRCDSBOOT
	- Description: The path to your server start batch script. You should be able to link this to .exe's as well, but you can't pass arguments or parameters
	- Default (example): C:\Surfline\Steam\steamapps\common\GarrysModDS\start.bat

SERVER_DUMPS
	- Description: The location where the ticket manager will save your crash dumps when it auto restarted the server. MAKE SURE THIS FOLDER EXISTS
	- Default (example): C:\Surfline\Steam\steamapps\common\GarrysModDS\dumps\restart\


Now that the config file is ready, try launching SurflineTicketManager from inside of LOCAL_PATH and it should say the program has been started.
To try it out, create a file called: ticket_123456.txt (or whatever your TICKET_PREFIX is set to) and put this inside it: 1;dQw4w9WgXcQ
If the program picks it up and starts downloading something, you're all set! Be sure to check the /data folder for the MP3 output after it's done to validate that it's working.

To actually be able to handle input from the game itself, you'll have to set the PHP files up (check them and replace and paths that are marked to be replaced!)
Once everything is done, go to your gamemode and fill in the missing fields in modules/sv_radio.lua

Checklist for getting this to work:
- Make sure the post.php script has write permissions for the folder it's in.
- Make sure that youtube-dl.exe and graavy.jar are in the same folder
- Make sure to have Java installed on the target box
- Make sure to keep YouTube-DL up-to-date for it to work with the latest YouTube versions
- Make sure you have the ffmpeg library as well as ffplay and ffprobe (they're required for conversion)
- Make sure you have the .dll files from NAudio and Newtonsoft.Json in the same folder as the .exe
- Doublecheck all file paths
- Make sure you have downloaded the WebRepository.zip file from the Downloads.txt file because this contains essential files like ffmpeg


Credits for this system:
- YouTube-DL (http://rg3.github.io/youtube-dl/) for making the tool
- Groovesquid (http://groovesquid.com/) for the Grooveshark downloading
- Me for making the connecting services (PHP scripts, gamemode and C# ticket manager)


Thank you very much for trying this!
Gravious