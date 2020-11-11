@echo off
REM Simple script made by me that launches the game, killing any previous instances
cls
taskkill /f /im srcds.exe
start srcds.exe -console -game garrysmod +gamemode bhop +map bhop_autobadges +maxplayers 8 -tickrate 100 -condebug -disableluarefresh
exit