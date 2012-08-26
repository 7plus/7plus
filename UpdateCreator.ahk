;If program is run without admin privileges, try to run it again as admin, and exit this instance when the user confirms it
if(!A_IsAdmin)
{
	If(A_IsCompiled)
		uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_ScriptFullPath, str, "/r", str, A_WorkingDir, int, 1)
	else
		uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, "/r """ A_ScriptFullPath """", str, A_WorkingDir, int, 1)
	ExitApp
}
;Close running 7plus instance
if(running := FileExist(A_Temp "\7plus\hwnd.txt"))
{
	DetectHiddenWindows, On
	FileRead, hwnd, %A_Temp%\7plus\hwnd.txt
	if(WinExist("ahk_id " hwnd))
	{
		WinGet, pid, pid, ahk_id %hwnd%
		Process, Close, %pid%
	}
}
SetWorkingDir %a_scriptdir%
;Read current version from 7plus.ahk
Loop, Read, 7plus.ahk
{
	if(InStr(A_LoopReadLine, "MajorVersion := "))
		MajorVersion := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, " := ") + 4)
	else if(InStr(A_LoopReadLine, "MinorVersion := "))
		MinorVersion := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, " := ") + 4)
	else if(InStr(A_LoopReadLine, "BugfixVersion := "))
		BugfixVersion := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, " := ") + 4)
	else if(InStr(A_LoopReadLine, "BuildVersion := "))
	{
		BuildVersion := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, " := ") + 4)
		VersionString := A_LoopReadLine
	}
}

;Now show a GUI with publishing options
Gui, Add, Button, gBuild, Build Only
Gui, Add, Button, gPublish, Publish
Gui, Add, Button, gPublishAsBeta, Publish as Beta
Gui, Show
return


Build:
Publish:
PublishAsBeta:

if(VersionString)
{
	BuildVersion := A_ThisLabel = "Publish" ? 0 : BuildVersion + 1
	FileRead, code, 7plus.ahk
	StringReplace, code, %VersionString%, BuildVersion := %BuildVersion%
}
7plusVersion := MajorVersion "." MinorVersion "." BugfixVersion "." BuildVersion

;The Autoupdater uses a file called NewVersion.ini hosted on a server that contains information about the newest available (beta)version
;This file is updated here.
FilesURL := "http://7plus.googlecode.com/files/"
if(A_ThisLabel = "Publish")
{
	IniWrite, %MajorVersion%, NewVersion.ini, Version, MajorVersion
	IniWrite, %MinorVersion%, NewVersion.ini, Version, MinorVersion
	IniWrite, %BugfixVersion%, NewVersion.ini, Version, BugfixVersion
	IniWrite, %BuildVersion%, NewVersion.ini, Version, BuildVersion
	InputBox, Message, Enter Update Message, A new update is available. Download now?
	IniWrite, %Message%, NewVersion.ini, Version, UpdateMessage
	IniWrite, %FilesURL%UpdaterX86Binary.exe, NewVersion.ini, Version, LinkX86
	IniWrite, %FilesURL%UpdaterX86Source.exe, NewVersion.ini, Version, LinkX86Source
	IniWrite, %FilesURL%UpdaterX64Binary.exe, NewVersion.ini, Version, LinkX64
	IniWrite, %FilesURL%UpdaterX64Source.exe, NewVersion.ini, Version, LinkX64Source
}
else if(A_ThisLabel = "PublishAsBeta")
{
	IniWrite, %BuildVersion%, NewVersion.ini, Version, BuildVersion
	InputBox, Message, Enter Update Message, A new beta update is available. Download now?
	IniWrite, %Message%, NewVersion.ini, Version, BetaUpdateMessage
	IniWrite, %FilesURL%BetaUpdaterX86Binary.exe, NewVersion.ini, Version, BetaLinkX86
	IniWrite, %FilesURL%BetaUpdaterX86Source.exe, NewVersion.ini, Version, BetaLinkX86Source
	IniWrite, %FilesURL%BetaUpdaterX64Binary.exe, NewVersion.ini, Version, BetaLinkX64
	IniWrite, %FilesURL%BetaUpdaterX64Source.exe, NewVersion.ini, Version, BetaLinkX64Source
}


if(A_ThisLabel != "Build")
{
	;Create the event patch file required for the autoupdater.
	;The user of this script needs to select the event file version this patch should use as a base.
	fd := new CFileDialog("Open")
	fd.Filter := "*.xml"
	fd.InitialDirectory := A_ScriptDir "\Events"
	fd.Title := "Select old ""All Events.xml"" file to generate the events patch file."
	if(!fd.Show())
		return
	run % """" A_AhkPath """ """   A_ScriptDir "\CreateEventPatch.ahk"" """ fd.Filename  """ """ A_ScriptDir "\Events\All Events.xml"""
}

;Create updates for all configurations
CreateUpdate("X86", "Source")
CreateUpdate("X86", "Binary")
CreateUpdate("X64", "Source")
CreateUpdate("X64", "Binary")

;And start 7plus again if it was running before
if(running)
	run, %A_ScriptDir%\7plus.ahk
ExitApp

return
GuiEscape:
GuiClose:
ExitApp

;Called to create .zip and Autoupdate executable files for a build configuration
;Everything is temporarily copied to %A_TEMP%\7plusUpdateCreator
CreateUpdate(Platform, Version)
{
	global 7plusVersion

	;Clean up first
	FileRemoveDir, %A_TEMP%\7plusUpdateCreator, 1
	FileCreateDir, %A_TEMP%\7plusUpdateCreator
	FileDelete, Updater.exe
	FileDelete, Update.zip

	;Copy binary image of AHK_L for the compiler
	if(Platform = "X86")
		FileCopy, %A_ProgramFiles%\Autohotkey\Compiler\AutoHotkeySC_UNICODE_32.bin, %A_ProgramFiles%\Autohotkey\Compiler\AutoHotkeySC.bin, 1		
	else
		FileCopy, %A_ProgramFiles%\Autohotkey\Compiler\AutoHotkeySC_UNICODE_64.bin, %A_ProgramFiles%\Autohotkey\Compiler\AutoHotkeySC.bin, 1
	
	;Compile 7plus and Uninstaller
	if(Version = "Binary")
	{
		RunWait, %A_ProgramFiles%\Autohotkey\Compiler\Compile_AHK.exe /nogui "%A_ScriptDir%\7plus.ahk"
		Sleep 1500
	}

	;Uninstaller is always compiled
	RunWait, %A_ProgramFiles%\Autohotkey\Compiler\Compile_AHK.exe /nogui "%A_ScriptDir%\Uninstall.ahk"
	Sleep 1500

	;Copy all other files
	FolderLoop(Platform, Version)

	;Zip them
	RunWait, 7za.exe a -y "%a_scriptdir%\update.zip" "%A_TEMP%\7plusUpdateCreator\*", %a_scriptdir%,Hide

	;Generate update script
	WriteUpdater()
	
	if(!FileExist(A_Scriptdir "\update.zip"))
		MsgBox, update.zip doesn't exist!
	
	;Compile updater
	RunWait, %A_ProgramFiles%\Autohotkey\Compiler\Compile_AHK.exe /nogui "%A_ScriptDir%\Updater.ahk"
	Sleep 2000
	if(!FileExist(A_Scriptdir "\updater.exe"))
		MsgBox updater.exe doesn't exist!
	;Cleanup and move resulting files
	FileRemoveDir, %A_TEMP%\7plusUpdateCreator,1
	FileMove, %a_scriptdir%\update.zip, %A_ScriptDir%\7plus V.%7plusVersion% %Platform% %Version%.zip, 1
	FileMove, %A_ScriptDir%\Updater.exe, %A_ScriptDir%\Updater%Platform%%Version%.exe, 1
}

;Copies all relevant files for the update to %A_Temp%\7plusUpdateCreator
FolderLoop(Platform, Version)
{
	global 7plusVersion
	;Copy matching autohotkey binary files and Dlls of the correct bitness
	DllTargetPath := Platform = "X86" ? A_TEMP "\7plusUpdateCreator\lib" : A_TEMP "\7plusUpdateCreator\lib\x64"
	DllSourcePath := Platform = "X86" ? A_ScriptDir "\lib" : A_ScriptDir "\lib\x64"
	FileCreateDir, %DllTargetPath%
	FileCopy, %DllSourcePath%\ShellExtension.dll,	%DllTargetPath%, 1
	FileCopy, %DllSourcePath%\sqlite3.dll, 			%DllTargetPath%, 1
	FileCopy, %DllSourcePath%\Explorer.dll, 		%DllTargetPath%, 1
	FileCopy, %DllSourcePath%\FileSearch.dll, 		%DllTargetPath%, 1
	FileCopy, %DllSourcePath%\SetACL.exe, 			%DllTargetPath%, 1


	;Now loop over the 7plus directory and copy all other needed files
	SkipNameList := ["7plusGApps.png", ".gitignore", "7za.exe", "Version.ini", "Autohotkey.exe", "Explorer.dll", "sqlite3.dll", "SetACL", "AU3_Spy.exe", "7+-128.ico", "Uninstall.ico", "Donate.ico", "Improvements.txt", "PatchInfo.xml"]
	SkipExtList := ["ini","bak","html","bin","zip","svg","log", "pdf", "md"]
	SkipPathList := [".git", "To be implemented\", "Old Versions", "Tools\", "Winspector", "DebugView", ".svn", "Compiler", "Explorer\Explorer", "x64\", "x86\", "Patches\", "DefaultConfig\", "ShellExtension", "tests\", "CreateEventPatch", "SubEventBackup", "NewSettings", "Kopie", "UpdateCreator"]
	Loop *.*, 0, 1 ;Find files which should be included
	{
		if(SkipNameList.IndexOf(A_LoopFileName))
			continue
		if(SkipExtList.IndexOf(A_LoopFileExt))
			continue
		index := ""
		for index, Path in SkipPathList
			if(InStr(A_LoopFileLongPath, Path))
				continue 2
		if(Version = "Binary" && A_LoopFileExt = "ahk")
			continue
		if(Version = "Source" && A_LoopFileName = "7plus.exe")
			continue
		
		if(InStr(A_LoopFileName, "Update") && !InStr(A_LoopFileName, "AutoUpdate"))
			continue
		if(InStr(A_LoopFileFullPath, "ReleasePatch\") && !InStr(A_LoopFileName, 7plusVersion)) ;Skip release patches for wrong 7plus version
			continue
		if(A_LoopFileExt = "xml") ;Remove german folder/file names
		{
			FileRead, content, %A_LoopFileFullPath%
			StringReplace, content, content,<Filename>Neues Textdokument.txt</Filename>`r`n
			StringReplace, content, content,<FolderName>Neuer Ordner</FolderName>`r`n
			FileDelete, %A_LoopFileFullPath%
			FileAppend, %content%, %A_LoopFileFullPath%
		}
		FileCreateDir %A_Temp%\7plusUpdateCreator\%A_LoopFileDir%
		FileCopy, %A_LoopFileLongPath%, %A_Temp%\7plusUpdateCreator\%A_LoopFileFullPath%, 1
	}
	FileCopy, %A_ScriptDir%\%Platform%\*, %A_Temp%\7plusUpdateCreator, 1
}

;Write the script which is executed on the client side
WriteUpdater()
{
	FileDelete %A_scriptdir%\Updater.ahk
	FileAppend, #NoTrayIcon`n,																						%A_scriptdir%\Updater.ahk
	FileAppend, if(!A_IsCompiled)`n,																				%A_scriptdir%\Updater.ahk	;Make sure that only the compiled version can be executed
	FileAppend, `tExitApp`n,																						%A_scriptdir%\Updater.ahk
	FileAppend, SetWorkingDir `%A_Temp`%\7plus`n,																	%A_scriptdir%\Updater.ahk
	FileAppend, IniRead`, ConfigPath`, `%A_Temp`%\7plus\Update.ini`, Update`, ConfigPath`, `%A_AppData`%\7plus`n, 	%A_scriptdir%\Updater.ahk
	FileAppend, IniRead`, ScriptDir`, `%A_Temp`%\7plus\Update.ini`, Update`, ScriptDir`, `%A_ProgramFiles`%\7plus`n,%A_scriptdir%\Updater.ahk
	FileAppend, Progress zh0 fs18`, Updating, please wait.`n,														%A_scriptdir%\Updater.ahk
	FileAppend, FileInstall`, %A_scriptdir%\Update.zip`, Update.zip`,1`n,											%A_scriptdir%\Updater.ahk	;%A_scriptdir% mustn't be dynamic for FileInstall -> no quotes
	FileAppend, FileInstall`, %A_scriptdir%\7za.exe`, 7za.exe`,1`n,													%A_scriptdir%\Updater.ahk	;%A_scriptdir% mustn't be dynamic for FileInstall -> no quotes
	FileAppend, run regsvr32 /s /u "`%ScriptDir`%\ShellExtension.dll"`n,											%A_scriptdir%\Updater.ahk	;Unregister context menu shell extension. It will get reregistered in PostUpdate()
	FileAppend, runwait 7za.exe x Update.zip -y -o`%A_Temp`%\7plus\Update`, `%A_Temp`%\7plus`, hide`n,				%A_scriptdir%\Updater.ahk	
	FileAppend, FileMoveDir`, `%A_Temp`%\7plus\Update\Patches`, `%ConfigPath`%\Patches`, 2`n, 						%A_scriptdir%\Updater.ahk	
    ; First move all the files (but not the folders):
    FileAppend, FileMove`, `%A_Temp`%\7plus\Update`, `%ScriptDir`%`, 1`n, 											%A_scriptdir%\Updater.ahk
    ; Now move all the folders:
    FileAppend, Loop`, `%A_Temp`%\7plus\Update\*.*`, 2`n,															%A_scriptdir%\Updater.ahk
    FileAppend, FileMoveDir`, `%A_LoopFileFullPath`%`, `%ScriptDir`%\`%A_LoopFileName`%`, 2`n,						%A_scriptdir%\Updater.ahk
	FileAppend, FileDelete 7za.exe`n,																				%A_scriptdir%\Updater.ahk
	FileAppend, FileDelete Update.zip`n,																			%A_scriptdir%\Updater.ahk
	FileAppend, FileMoveDir `%A_Temp`%\7plus\Update\ReleasePatch`,`%A_Temp`%\7plus\ReleasePatch`, 2`n,				%A_scriptdir%\Updater.ahk
	FileAppend, if(FileExist(ScriptDir "\7plus.ahk"))`n,																%A_scriptdir%\Updater.ahk
	FileAppend, `trun `%ScriptDir`%\7plus.ahk`n,																	%A_scriptdir%\Updater.ahk
	FileAppend, else if(FileExist(ScriptDir "\7plus.exe"))`n,														%A_scriptdir%\Updater.ahk
	FileAppend, `trun `%ScriptDir`%\7plus.exe`n,																	%A_scriptdir%\Updater.ahk
	FileAppend, ExitApp,																							%A_scriptdir%\Updater.ahk
}

#include <RichObject>
#include <CFileDialog>
#include <Array>