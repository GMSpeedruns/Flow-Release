@echo off
REM Simple script made by me that launches the game, killing any previous instances
cls
taskkill /f /im srcds.exe
start srcds.exe -console -game garrysmod +gamemode surf +map surf_adtr_njv +maxplayers 8 -condebug -disableluarefresh
exit