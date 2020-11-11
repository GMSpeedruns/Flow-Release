This anticheat consist of a server side and a client side.
It HAS to go in garrysmod/lua/autorun and not in the garrysmod/addons folder, otherwise people will get kicked.
Also, don't rename any of the clientside files unless you want trouble.
To use it with a different gamemode, call "imstnit( 1 )" on the client when the player resets and "imstnit( 2 )" when the player finishes.

There are also two different versions in here. The Bunny Hop version has specific measures for Bunny Hop cheats.
The main part of it is Movement Re-recorder detection. It is bypassable, but it works on a lot of cases. It could be done in a better way, but because of the limited Garry's Mod API I was unable to.

The generic anticheat blocks all types of Lua cheats. It doesn't go any further than that, but it's more than enough to keep the bad guys away from your server.

Made by George and Gravious