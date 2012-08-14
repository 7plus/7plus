;This fix was required for the 2.2.0 -> 2.3.0 autoupdate because of an error in 2.2.0 autoupdate that didn't fetch the correct link.
random, rand
ScriptDir := A_WorkingDir
if(FileExist(A_WorkingDir "\7plus.exe"))
	IsCompiled := true
else if(FileExist(A_WorkingDir "\7plus.ahk"))
	IsCompiled := false	
else
{
	FileSelectFile, ScriptDir, 1, , 7plus not found, please select 7plus.exe/7plus.ahk,7plus(7plus.ahk; 7plus.exe)
	if(Errorlevel)
		ExitApp
}
IniWrite, %A_Appdata%\7plus, %A_Temp%\7plus\Update.ini, Update, ConfigPath
IniWrite, %ScriptDir%, %A_Temp%\7plus\Update.ini, Update, ScriptDir
link := "Link" (!IsCompiled ? "Source" : "") (A_PtrSize = 8 ? "x64" : "x86")
IniRead, Link, %A_Temp%\7plus\Version.ini, Version,%Link%
if(Link != "")
{
	Progress zh0 fs18,Downloading Update, please wait.
	URLDownloadToFile, %link%?x=%rand%,%A_Temp%\7plus\Update.exe
	if(!Errorlevel)
	{
		Run %A_Temp%\7plus\Update.exe,,UseErrorlevel
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