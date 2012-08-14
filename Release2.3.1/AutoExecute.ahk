;Groups for explorer classes
GroupAdd, ExplorerGroup, ahk_class ExploreWClass
GroupAdd, ExplorerGroup, ahk_class CabinetWClass
GroupAdd, DesktopGroup, ahk_class WorkerW
GroupAdd, DesktopGroup, ahk_class Progman ;Progman for older windows versions <Vista
GroupAdd, TaskbarGroup, ahk_class Shell_TrayWnd
GroupAdd, TaskbarGroup, ahk_class BaseBar
GroupAdd, TaskbarGroup, ahk_class DV2ControlHost
GroupAdd, TaskbarDesktopGroup, ahk_group DesktopGroup
GroupAdd, TaskbarDesktopGroup, ahk_group TaskbarGroup

;Check for proper AHK version (Unicode and bitness)
if(!A_IsUnicode)
{
	Msgbox Not running on Unicode build of Autohotkey_L. Please use a unicode version!
	ExitApp ;Too many incompatibilities here
}

;initialize settings, application state and Languages classes
global ApplicationState := new CApplicationState()

;Depending on the command line parameters supplied, this instance might send event triggers to another instance which is already running.
;In addition, IsPortable is possibly set here
ProcessCommandLineParameters() ;Possible exit point


;NOTE: If 7plus would be translated, this will not get trasnlated because languages and settings are loaded later on. It might be beneficial to use
;	   lazy language loading or something similar.
if(A_PtrSize = 4 && IsWow64Process())
	Msgbox 32bit version of 7plus is running on an x64 operating system.`nSome features are not going to work. Please use an x64 version of 7plus!

global Settings := new CSettings()

Settings.SetupConfigurationPath()
Settings.Load()
Languages := new CLanguages()

;Create temp directory in which temporary files will be stored.
;hwnd.txt is stored in temp dir for finding the main 7plus window to allow sending messages to it. 
;This mechanism is used by the ShellExtension and by the updater.
FileCreateDir %A_Temp%\7plus


;If program is run without admin privileges, try to run it again as admin, and exit this instance when the user confirms it
if(!A_IsAdmin && Settings.Misc.RunAsAdmin = "Always/Ask")
	Run7plusAsAdmin()

;Start debugger
if(Settings.General.DebugEnabled)
	DebuggingStart()
outputdebug 7plus Starting...

;If the current config path is set to the program directory but there is no write access because UAC is activated and 7plus is running as user,
;7plus cannot store its settings and warns the user about it
if((ApplicationState.IsPortable && !WriteAccess(Settings.ConfigPath "\Accessor.xml")))
{
	MsgBox % "No file access to settings files in 7plus directory """ Settings.ConfigPath "\Accessor.xml"". 7plus will not be able to store its settings. Please move 7plus to a folder with write permissions, run it as administrator, or grant write permissions to this directory."
	ExitApp
}
;Fresh install, copy default events file into config directory
if(!FileExist(Settings.ConfigPath "\Settings.ini")) 
{
	FileCreateDir % Settings.ConfigPath
	FileCopy, %A_ScriptDir%\Events\All Events.xml, % Settings.ConfigPath "\Events.xml"
	ApplyFreshInstallSteps()
}

;initialize gdi+
outputdebug starting gdip
ApplicationState.pToken := Gdip_Startup()

;Exit Routine
OnExit, ExitSub



;This needs to be executed before EventSystem_Startup() because NewFile/Folder action relies on it
global shell32MUIpath := LocateShell32MUI()
;Keep a list of windows and their required info stored. This allows to identify windows which were closed recently.
if(!WindowList)
	WindowList := Object()

;Init event system
outputdebug starting event system
global EventSystem := new CEventSystem()
EventSystem.Startup()

;Make sure tray menu is built (even if there are no triggers that add items to it, because there are some special entries)
BuildMenu("Tray")

;Update checker
if(Settings.General.AutoUpdate)
{
	AutoUpdate()
	AutoUpdate_CheckPatches()
}

PostUpdate()

;Check if the user did a manual upgrade by extracting an archive over the previous 7plus installation
if(CompareVersion(XMLMajorVersion, MajorVersion, XMLMinorVersion, MinorVersion, XMLBugfixVersion, BugfixVersion) = -1)
	ApplyUpdateFixes()

if(Settings.GamepadRemoteControl)
	JoystickStart()
CAccessor.Instance := new CAccessor()

;Hwnd.txt is written to allow other processes to find the main window of 7plus
FileDelete, %A_Temp%\7plus\hwnd.txt
FileAppend, %A_ScriptHwnd%, %A_Temp%\7plus\hwnd.txt

;Register a shell hook to get messages when windows get activated, closed etc
outputdebug % "7plus window handle: " A_ScriptHwnd
DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd) 
ApplicationState.ShellHookMessage := DllCall("RegisterWindowMessage", Str, "SHELLHOOK") 
OnMessage(ApplicationState.ShellHookMessage, "ShellMessage") 

;Close windows autoupdate on wakeup
OnMessage(0x218, "WM_POWERBROADCAST")
;Register an event hook to catch move and dialog creation messages
ApplicationState.HookProcAdr := RegisterCallback("HookProc", "F" ) 
ApplicationState.WinEventHook1 := API_SetWinEventHook(0x8001,0x800B,0,ApplicationState.HookProcAdr,0,0,0) ;Make sure not to register unneccessary messages, as this causes cpu load
ApplicationState.WinEventHook2 := API_SetWinEventHook(0x0016,0x0016,0,ApplicationState.HookProcAdr,0,0,0) ;EVENT_SYSTEM_MINIMIZESTART
; API_SetWinEventHook(0x000E,0x000E,0,HookProcAdr,0,0,0)
ApplicationState.WinEventHook3 := API_SetWinEventHook(0x000A,0x000B,0,ApplicationState.HookProcAdr,0,0,0) ;EVENT_SYSTEM_MOVESIZESTART
if(WinVer >= WIN_Vista && (ApplicationState.ClipboardListenerRegistered := DllCall("AddClipboardFormatListener", "PTR", A_ScriptHwnd)))
	OnMessage(0x031D, "OnClipboardChange")

outputdebug Creating Slide Windows
SlideWindows := new CSlideWindows()

SetTimer, MouseMovePolling, 50

outputdebug Creating ClipboardList
ClipboardList := new CClipboardList()

outputdebug Initializing Explorer Windows
InitExplorerWindows()

outputdebug Loading HotStrings
LoadHotstrings()

;Try closing the windows update window if needed on startup since it might already be there.
AutoCloseWindowsUpdate(WinExist("Windows Update ahk_class #32770"))

ThemedWindows := DllCall("uxtheme.dll\IsThemeActive") ; On non-themed environments, standard icon is used
; if(A_IsCompiled)
; {
	; if(result)
		; Menu, tray, Icon, %A_ScriptFullPath%, 8,1
	; else
		; Menu, tray, Icon, %A_ScriptFullPath%, 8,1
; }	
; else
; {
	if(ThemedWindows)
		Menu, tray, Icon, %A_ScriptDir%\7+-w2.ico,,1
	else
		Menu, tray, Icon, %A_ScriptDir%\7+-w.ico,,1
; }

CGUI.WindowIcon := ExtractIcon(A_ScriptDir "\7+-w.ico")

Menu, tray, Tip, % "7plus " VersionString(1)

;Show tray icon when loading is complete
if(!Settings.Misc.HidetrayIcon)
	menu, tray, Icon

;possibly start wizard
if (Settings.General.Firstrun)
{
	outputdebug Registering Shell Extension
	RegisterShellExtension(1)
	GoSub, wizardry
}

;Set this so that config files aren't saved with empty values when there was a problem with the startup procedure
ApplicationState.ProgramStartupFinished := true

Suspend, Off
;Create settings window in advance to save some time when it is first shown.
outputdebug Creating Settings Window
global SettingsWindow := new CSettingsWindow()

outputdebug 7plus startup procedure finished, entering event loop.
;Event loop
SetTimer, EventScheduler, 10
Return

Run7plusAsAdmin()
{
	global
	local params, uacrep
	Loop %0%
		params .= " " (InStr(%A_Index%, " ") ? """" %A_Index% """" : %A_Index%)
	If(A_IsCompiled)
		uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_ScriptFullPath, str, "/r" params, str, A_WorkingDir, int, 1)
	else
		uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, "/r """ A_ScriptFullPath """" params, str, A_WorkingDir, int, 1)
	If(uacrep = 42) ;UAC Prompt confirmed, application may run as admin
		ExitApp
	else
		MsgBox 7plus is running in non-admin mode. Some features will not be working.
}

ExitSub:
if(A_ExitReason = "Reload")
{
	SetTimer, ReloadSub, -0
	return
}
OnExit(0)
ExitApp

ReloadSub:
OnExit(1)
OnExit
ExitApp

OnExit(reload=0)
{
	global
	outputdebug OnExit()
	if(ApplicationState.ProgramStartupFinished)
	{
		ClipboardList.Save()
		ExplorerHistory.Save()
		EventSystem.OnExit()
		CAccessor.Instance.OnExit()
		Gdip_Shutdown(ApplicationState.pToken)
		SlideWindows.OnExit()
		Settings.Save()
		CloseAllInactiveTabs()
		SaveHotstrings()
		OnMessage(0x218, "")
		OnMessage(0x031D, "")
		OnMessage(ApplicationState.ShellHookMessage, "")
		API_UnhookWinEvent(ApplicationState.WinEventHook1)
		API_UnhookWinEvent(ApplicationState.WinEventHook2)
		API_UnhookWinEvent(ApplicationState.WinEventHook3)
		DllCall("DeregisterShellHookWindow", "Ptr", A_ScriptHwnd)
		if(Settings.General.DebugEnabled)
			DebuggingEnd()
	}
	
	if(reload)
	{
		run % (A_IsCompiled ? A_ScriptFullPath : A_AhkPath) " /r" (A_IsCompiled ? "" : " """ A_ScriptFullPath """") (ApplicationState.IsPortable ? " -Portable" : ""), %A_WorkingDir%
	}
	FileRemoveDir, %A_Temp%\7plus, 1
}
;Some first run intro
wizardry:
MsgBox, 4,,Welcome to 7plus!`nBefore we begin, would you like to see a list of features?	
IfMsgBox Yes
	run http://code.google.com/p/7plus/wiki/Features,,UseErrorlevel
Notify("Open Settings?", "At the beginning you should take some minutes and check out the settings.`nDouble click on the tray icon or click here to open the settings window.", 10, NotifyIcons.Question, "ShowSettings")
return

ProcessCommandLineParameters()
{
	global
	local Count, hwnd, i, Parameter, Parameters
	InitWorkerThread() ;This processes all cases where 7plus acts as a worker thread for another 7plus instance
	FileRead, hwnd, %A_Temp%\7plus\hwnd.txt ;if existing, hwnd.txt contains the window handle of another running instance
	Parameters := []
	Loop %0%
		Parameters[A_Index] := %A_Index%
	
	;if a path is supplied as first parameter, set explorer directory to this path and exit
	if(InStr(FileExist(Parameters[1]), "D"))
	{
		Navigation.SetPath(Parameters[1])
		ExitApp
	}
	for i, Parameter in Parameters
	{
		;TODO: Change this format to "-id Number" for compatibility with Explorer Button trigger? (See EventSystem_Startup())
		;Generic event trigger, send to running instance
		if(InStr(Parameter, "-id") = 1)
		{
			if(WinExist("ahk_id " hwnd))
			{
				Parameter := SubStr(Parameter, 5) ;-ID:Value
				SendMessage, 55555, %Parameter%, 0, ,ahk_id %hwnd%
				ExitApp
			}
		}
		;Trigger from legacy context menu mechanism (used for My Computer menu), send to running instance
		else if(InStr(Parameter,"-ContextID") = 1)
		{
			if(WinExist("ahk_id " hwnd))
			{
				Parameter := SubStr(Parameter, 12) ; -ContextID:Value
				SendMessage, 55555, %Parameter%, 1, ,ahk_id %hwnd%
				ExitApp
			}
		}
		;Portable mode
		else if(Parameter = "-Portable" || Parameter = "/Portable") 
			ApplicationState.IsPortable := true
	}
	DetectHiddenWindows, On
	if(hwnd && WinGetClass("ahk_id " hwnd ) = "AutoHotkey")
		ExitApp
}