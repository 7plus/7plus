;This fix was required for the 2.3.0 -> 2.4.0 autoupdate because of an error in 2.2.0 autoupdate that didn't fetch the correct link.
;A similar error was already present in the previous version which wasn't fixed completely unfortunately.
;7plus 2.3.0 downloads UpdaterFix.exe to %A_Temp%\7plus\Update.exe. This script then downloads the correct update to %A_Temp%\7plus\Updater.exe
;which is later checked in 2.4.0 for post-update detection.
random, rand
IsCompiled := false ;Set for source/binary version separately
IniRead, ScriptDir, %A_Temp%\7plus\Update.ini, Update, ScriptDir
link := "Link" (!IsCompiled ? "Source" : "") (A_PtrSize = 8 ? "x64" : "x86")
IniRead, Link, %A_Temp%\7plus\Version.ini, Version, %Link%
if(Link != "" && Link != "ERROR")
{
	Progress zh0 fs18,Downloading Update, please wait.
	URLDownloadToFile, %link%?x=%rand%,%A_Temp%\7plus\Updater.exe
	if(!Errorlevel)
	{
		Run %A_Temp%\7plus\Updater.exe,,UseErrorlevel
		ExitApp
	}
	else
	{
		MsgBox Error while updating. Make sure http://7plus.googlecode.com is reachable.
		Progress, Off
	}
}
else
{
	MsgBox Error while updating. Config file not found.
	Progress, Off
}