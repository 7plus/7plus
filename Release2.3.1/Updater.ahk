#NoTrayIcon
if(!A_IsCompiled)
	ExitApp
SetWorkingDir %A_Temp%\7plus
IniRead, ConfigPath, %A_Temp%\7plus\Update.ini, Update, ConfigPath, %A_AppData%\7plus
IniRead, ScriptDir, %A_Temp%\7plus\Update.ini, Update, ScriptDir, %A_ProgramFiles%\7plus
FileInstall, D:\Projekte\Autohotkey\7plus\Update.zip, Update.zip,1
FileInstall, D:\Projekte\Autohotkey\7plus\7za.exe, 7za.exe,1
run regsvr32 /s "%ScriptDir%\ShellExtension.dll"
runwait 7za.exe x Update.zip -y -o%A_Temp%\7plus\Update, %A_Temp%\7plus, hide
FileMoveDir, %A_Temp%\7plus\Update\Patches, %ConfigPath%\Patches, 2
FileMove, %A_Temp%\7plus\Update, %ScriptDir%, 1
Loop, %A_Temp%\7plus\Update\*.*, 2
FileMoveDir, %A_LoopFileFullPath%, %ScriptDir%\%A_LoopFileName%, 2
FileDelete 7za.exe
FileDelete Update.zip
FileMoveDir %A_Temp%\7plus\Update\ReleasePatch,%A_Temp%\7plus\ReleasePatch, 2
if(FileExist(ScriptDir "\7plus.ahk"))
	run %ScriptDir%\7plus.ahk
else if(FileExist(ScriptDir "\7plus.exe"))
	run %ScriptDir%\7plus.exe
ExitApp