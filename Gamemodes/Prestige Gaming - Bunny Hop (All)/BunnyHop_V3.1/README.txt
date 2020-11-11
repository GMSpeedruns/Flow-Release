I said I wouldn't support this, and I don't, but I thought hey this only takes me 30 seconds effort so...

This gamemode runs SOLELY on MySQL. No SQLite required.
All you gotta do is change data.lua to point to a valid MySQL server and execute the database file (either SQL file) on the database and go play. Really easy!

Enjoy it.

Also, bots aren't broken, pG just messed them up. They only save via admin panel (force save on [Bot] Manage) or by changing maps (not changelevel, via RTV)

Oh, also, to add yourself as an admin, simply type addalladmins in your server console. You'll see something like: "Name has been added as Owner temporarily			Unique ID: NUMBERSSSS", copy that ID (where it says NUMBERSSSS) and go to admin.lua, add it at the top of Admin.List (copy another row)
NOTE: This does add ALL players currently in-game as an admin


As a final remark, it is HIGHLY recommended to use my Flow Network gamemode since it's got fixes and new features ALL over. Literally, there is more functionality in there than any other Bhop gamemode out there.
If you want to feel some nostalgia, feel free to use it though, ain't nobody stopping you.

- Grav