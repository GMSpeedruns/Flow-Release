The gamemode files are in the /Gamemode folder.

This gamemode requires quite some setting up.

General settings:
- core.lua - Change of name of the gamemode AND some other IMPORTANT settings (lines 17 until 21)
- core_data.lua - Change the MySQL Server credentials AND FastDL files (Core:AddResources())
- core_lang.lua - Change URLs and Servers and maybe even text if you want

API Keys:
- sv_admin.lua - Steam API Key
- sv_radio.lua - Lots of keys, check the file for instructions


I think that's about it. Make sure the sv.db database is prepared with the content in the /Database folder included in this release
You can also use the provided sv.db (rename it, though). There is a clean version and a populated one, but this already has around 9k saved times. It doesn't have the bot files of those times, since they're pretty big.

There are a lot more things to customize, but please respect the gamemode in this state and refrain from altering it too much.


NOTE:
If you don't own a MySQL database and just want a single server with local bans etc, go to core_data.lua and set SQL.Use on line 2 to false
To edit this local database, you have to edit the tables prefixed with 'gmod_' in your sv.db - Alternatively, if you don't know how to do that, go to core_data.lua on line 378 and put your Steam ID in.
Oh! In order to use the VIP feature, you'll have to be able to edit the sv.db file MANUALLY. There is no in-built functionality to set people to VIP as this usually happens via my webserver. With MySQL, you'll have to write your own backend, or take the released one from my thread.


Thank you and enjoy it!
Gravious