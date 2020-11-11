@echo off
if [%1]==[] goto usage

for /f %%i in ("%1") do (
	echo %%~di
	echo %%~pi
	echo %%~xi
	set rootpath="%%~di%%~pi*%%~xi"
)

for %%f in (%rootpath%) do (
	"D:\Program Files\7-Zip\7z.exe" a -tbzip2 "%%f.bz2" "%%f" -mx9
)

echo Finished operations!
goto exit

:usage
echo You have to drag and drop a file on this batch script!
echo Sorry for the poor documentation, but if you'll want to use it, you have to edit the .bat file
echo The only thing you really need is to change the path to your 7-Zip installation
echo Then simply drag and drop a file in a folder you want to BZip2, and it'll do the rest automatically

:exit
pause
