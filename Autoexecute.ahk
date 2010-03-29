;Start debugger
IniRead, DebugEnabled, %A_ScriptDir%\Settings.ini, General, DebugEnabled , 0
if(DebugEnabled)
	DebuggingStart()
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

;Get windows version
RegRead, vista7, HKLM, SOFTWARE\Microsoft\Windows NT\CurrentVersion, CurrentVersion
vista7 := vista7 >= 6 

;initialize gdi+
pToken := Gdip_Startup()

;Exit Routine
OnExit, ExitSub

;Disable COM error notifications that pop up sometimes when opening/closing explorer
COM_Error(0)

;On first run, wizard is used to setup values
IniRead, FirstRun, %A_ScriptDir%\Settings.ini, General, FirstRun , 1

IniRead, JoyControl, %A_ScriptDir%\Settings.ini, Misc, JoyControl , 1
if(JoyControl)
	JoystickStart()

;Explorer pasting as file
IniRead, ImgName, %A_ScriptDir%\Settings.ini, Explorer, Image, clip.png
IniRead, TxtName, %A_ScriptDir%\Settings.ini, Explorer, Text, clip.txt
;the path where the image file is saved for copying
temp_img := A_Temp . "\" . ImgName
temp_txt := A_Temp . "\" . TxtName

;some clipboard data type constants
CF_DIB = 8
CF_HDROP = 15 ;clipboard identifier of copied file from explorer
CF_BITMAP = 2
CF_TEXT = 1
;Used to temporarily suppress the surveillance of the clipboard
MuteClipboardSurveillance:=false

;Explorer command prompt
ExplorerCommandMode:=0

/*
;Replace Calendar
IniRead, ReplaceCalendar, %A_ScriptDir%\Settings.ini, Calendar, ReplaceCalendar , 1
IniRead, CalendarClass, %A_ScriptDir%\Settings.ini, Calendar, CalendarClass, Chrome_WindowImpl_0
IniRead, CalendarCommand, %A_ScriptDir%\Settings.ini, Calendar, CalendarCommand,  "%A_LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" --app="http://www.google.com/calendar"
*/
;Some explorer temporary variables
time1:=0
path1:=""
ExplorerSysListView32HWND:=""
ExplorerSysTreeView32HWND:=""
ExplorerEdit1HWND:=""
SetDefaultMouseSpeed, 0

;Register a shell hook to get messages when windows get activated, closed etc
Gui +LastFound 
hWnd := WinExist() 
DllCall( "RegisterShellHookWindow", UInt,hWnd ) 
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" ) 
OnMessage( MsgNum, "ShellMessage" ) 

;Tooltip messages
OnMessage(0x202,"WM_LBUTTONUP") ;Will make ToolTip Click possible 
OnMessage(0x4e,"WM_NOTIFY") ;Will make LinkClick and ToolTipClose possible
 
if(Vista7)
{
	;Register an event hook to catch move and dialog creation messages
	HookProcAdr := RegisterCallback("HookProc", "F" ) 
	API_SetWinEventHook(0x0,0x8002,0,HookProcAdr,0,0,0) 
}
DetectHiddenWindows, On
/*
;Install a CBT hook to catch and prevent minimize/maximize messages
pid:=DllCall("GetCurrentProcessId","Uint")

hwnd:=WinExist("ahk_pid " . pid)
hHookModule := DllCall("LoadLibrary", "str", "ahkhook.dll")
HookFuncHndl:=DllCall("ahkhook.dll\reghook", "UInt", 5, "UInt", hwnd, "UInt", 0x550, "UInt", (1<<1)+(1<<5))
OnMessage(0x551, "CBTHook")
OnMessage(0x555, "CBTHook2")
*/

;FTP Upload script
IniRead, FTP_Enabled, %A_ScriptDir%\Settings.ini, FTP, UseFTP , 1
IniRead, FTP_Username, %A_ScriptDir%\Settings.ini, FTP, Username , Username
IniRead, FTP_Password, %A_ScriptDir%\Settings.ini, FTP, Password , Password
IniRead, FTP_Host, %A_ScriptDir%\Settings.ini, FTP, Host , Host address
IniRead, FTP_PORT, %A_ScriptDir%\Settings.ini, FTP, Port , 21
IniRead, FTP_URL, %A_ScriptDir%\Settings.ini, FTP, URL , URL to webspace
IniRead, FTP_Path, %A_ScriptDir%\Settings.ini, FTP, Path, %A_Space%

;strip slashes
ValidateFTPVars()

;Texteditor for opening files per hotkey
IniRead, TextEditor, %A_ScriptDir%\Settings.ini, Explorer, TextEditor , `%windir`%\notepad.exe
IniRead, ImageEditor, %A_ScriptDir%\Settings.ini, Explorer, ImageEditor , `%windir`%\system32\mspaint.exe

IniRead, HKCreateNewFile, %A_ScriptDir%\Settings.ini, Explorer, HKCreateNewFile, 1
IniRead, HKCreateNewFolder, %A_ScriptDir%\Settings.ini, Explorer, HKCreateNewFolder, 1
IniRead, HKCopyFilenames, %A_ScriptDir%\Settings.ini, Explorer, HKCopyFilenames, 1
IniRead, HKCopyPaths, %A_ScriptDir%\Settings.ini, Explorer, HKCopyPaths, 1
IniRead, HKAppendClipboard, %A_ScriptDir%\Settings.ini, Explorer, HKAppendClipboard, 1

IniRead, HKFastFolders, %A_ScriptDir%\Settings.ini, Explorer, HKFastFolders, 1
IniRead, HKFFMenu, %A_ScriptDir%\Settings.ini, Explorer, HKFFMenu, 1
IniRead, HKPlacesBar, %A_ScriptDir%\Settings.ini, Explorer, HKPlacesBar, 0
IniRead, HKCleanFolderBand, %A_ScriptDir%\Settings.ini, Explorer, HKCleanFolderBand, 0
IniRead, HKFolderBand, %A_ScriptDir%\Settings.ini, Explorer, HKFolderBand, 0

IniRead, HKProperBackspace, %A_ScriptDir%\Settings.ini, Explorer, HKProperBackspace, 1
;IniRead, HKImprovedWinE, %A_ScriptDir%\Settings.ini, Explorer, HKImprovedWinE, 1
IniRead, HKSelectFirstFile, %A_ScriptDir%\Settings.ini, Explorer, HKSelectFirstFile, 1
IniRead, HKImproveEnter, %A_ScriptDir%\Settings.ini, Explorer, HKImproveEnter, 1
IniRead, HKDoubleClickUpwards, %A_ScriptDir%\Settings.ini, Explorer, HKDoubleClickUpwards, 1
IniRead, HKShowSpaceAndSize, %A_ScriptDir%\Settings.ini, Explorer, HKShowSpaceAndSize, 1
IniRead, HKMouseGestureBack, %A_ScriptDir%\Settings.ini, Explorer, HKMouseGestureBack, 1
IniRead, HKAutoCheck, %A_ScriptDir%\Settings.ini, Explorer, HKAutoCheck, 1
IniRead, ScrollUnderMouse, %A_ScriptDir%\Settings.ini, Explorer, ScrollUnderMouse, 1

IniRead, HKKillWindows, %A_ScriptDir%\Settings.ini, Windows, HKKillWindows, 1
IniRead, HKToggleWallpaper, %A_ScriptDir%\Settings.ini, Windows, HKToggleWallpaper, 1
IniRead, HKMiddleClose, %A_ScriptDir%\Settings.ini, Windows, HKMiddleClose, 1
IniRead, HKTitleClose, %A_ScriptDir%\Settings.ini, Windows, HKTitleClose, 1
IniRead, HKToggleAlwaysOnTop, %A_ScriptDir%\Settings.ini, Windows, HKToggleAlwaysOnTop, 1
IniRead, HKActivateBehavior, %A_ScriptDir%\Settings.ini, Windows, HKActivateBehavior, 1
IniRead, AeroFlipTime, %A_ScriptDir%\Settings.ini, Windows, AeroFlipTime, 0.2
IniRead, HKFlashWindow, %A_ScriptDir%\Settings.ini, Windows, HKFlashWindow, 1
IniRead, HKToggleWindows, %A_ScriptDir%\Settings.ini, Windows, HKToggleWindows, 1

if((AeroFlipTime>=0&&Vista7)||HKSlideWindows)
{
	SetTimer, hovercheck, 10
}
IniRead, HKHoverStart, %A_ScriptDir%\Settings.ini, Windows, HKHoverStart, 1
;program to launch on double click on taskbar
IniRead, TaskbarLaunchPath, %A_ScriptDir%\Settings.ini, Windows, TaskbarLaunchPath , %A_Windir%\system32\taskmgr.exe
stringreplace, TaskbarLaunchPath, TaskbarLaunchPath, `%A_ProgramFiles`%, %A_ProgramFiles% 
;Slide windows
IniRead, HKSlideWindows, %A_ScriptDir%\Settings.ini, Windows, HKSlideWindows , 1
SlideWindows_Startup()
IniRead, SlideWindowsBorder, %A_ScriptDir%\Settings.ini, Windows, SlideWindowsBorder , 30
IniRead, HKImproveConsole, %A_ScriptDir%\Settings.ini, Misc, HKImproveConsole, 1
IniRead, HKPhotoViewer, %A_ScriptDir%\Settings.ini, Misc, HKPhotoViewer, 1
IniRead, ImageExtensions, %A_ScriptDir%\Settings.ini, Misc, ImageExtensions, jpg,png,bmp,gif,tga,tif,ico,jpeg
IniRead, ClipboardManager, %A_ScriptDir%\Settings.ini, Misc, ClipboardManager, 1

;Fullscreen exclusion list
IniRead, FullscreenExclude, %A_ScriptDir%\Settings.ini, Misc, FullscreenExclude,VLC DirectX,OpWindow,CabinetWClass
IniRead, FullscreenInclude, %A_ScriptDir%\Settings.ini, Misc, FullscreenInclude,VLC DirectX,OpWindow,CabinetWClass
;Clipboard manager list (is some sort of fixed size stack which removes oldest entry on add/insert/push)
Stack := Object("len", "Array_Length", "indexOf", "Array_indexOf", "join", "Array_Join" 
      , "append", "Array_Append", "insert", "Array_Insert", "delete", "Array_Delete" 
      , "sort", "Array_sort", "reverse", "Array_Reverse", "unique", "Array_Unique" 
      , "extend", "Array_Extend", "copy", "Array_Copy", "pop", "Array_Pop", "swap", "Array_Swap", "Move", "Array_Move" , "push", "Stack_Push") 

ClipboardList := Object("base", Stack) 
Loop 10
{
	IniRead, x, %A_ScriptDir%\Settings.ini, Misc, Clipboard%A_Index%
	Transform, x, Deref, %x%
	if(x!="Error")
		ClipboardList.Append(x)
}

;FastFolders
Loop 10
{
    z:=A_Index-1
    IniRead, FF%z%, %A_ScriptDir%\Settings.ini, FastFolders, Folder%z%, `%systemdrive`%
    IniRead, FFTitle%z%, %A_ScriptDir%\Settings.ini, FastFolders, FolderTitle%z%, %A_Space%
}

;Explorer info stuff
if(Vista7)
{
	CreateInfoGui()
	AcquireExplorerConfirmationDialogStrings()
}

;Polling timer
;SetTimer, PollingTimer , 200

;Calendar
;RunCalendar()

;possibly start wizard
if (Firstrun=1)
	GoSub wizardry

;Show tray icon when loading is complete
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, Settings, SettingsHandler  ; Creates a new menu item.
if(A_IsCompiled)
	Menu, tray, Icon, %A_ScriptFullPath%, 2,1
else
	Menu, tray, Icon, %A_ScriptDir%\7+-w2.ico,,1
menu, tray, Icon
Return

ExitSub:
Gdip_Shutdown(pToken)
WriteIni()
;KillCalendar()
SlideWindows_Exit()
;DllCall("UnhookWindowsHookEx", "UInt", HookFuncHndl)
ExitApp

AcquireExplorerConfirmationDialogStrings()
{
	global shell32MUIpath
	VarSetCapacity(buffer, 85*2)
	length:=DllCall("GetUserDefaultLocaleName","uint",&buffer,"uint",85)
	locale:=COM_Ansi4Unicode(&buffer)
	shell32MUIpath:=A_WinDir "\winsxs\*_microsoft-windows-*resources*" locale "*" ;\x86_microsoft-windows-shell32.resources_31bf3856ad364e35_6.1.7600.16385_de-de_b08f46c44b512da0\shell32.dll.mui
	loop %shell32MUIpath%,2,0
	{
		if(FileExist(A_LoopFileFullPath "\shell32.dll.mui"))
		{
			shell32MUIpath:=A_LoopFileFullPath "\shell32.dll.mui"
			found:=true
			break
		}
	}	
	if(found)
	{
		global ExplorerConfirmationDialogTitle1:=TranslateMUI(shell32MUIpath,16705)
		global ExplorerConfirmationDialogTitle2:=TranslateMUI(shell32MUIpath,16877)
		global ExplorerConfirmationDialogTitle3:=TranslateMUI(shell32MUIpath,16875)
		global ExplorerConfirmationDialogTitle4:=TranslateMUI(shell32MUIpath,16876)
		global ExplorerConfirmationDialogTitle5:=TranslateMUI(shell32MUIpath,16706)
		global ExplorerConfirmationDialogTitle6:=TranslateMUI(shell32MUIpath,16864)
		global ExplorerConfirmationDialogButton1:=strStripRight(TranslateMUI(shell32MUIpath,16928),"%")
		global ExplorerConfirmationDialogButton2:=strStripRight(TranslateMUI(shell32MUIpath,17039),"%")
		global ExplorerConfirmationDialogButton3:=TranslateMUI(shell32MUIpath,16663)
		return true
	}
	Outputdebug Failed to acquire translated Explorer dialog names
	return false
}

WriteIni()
{
	global
	local temp
	IniWrite, %DebugEnabled%, %A_ScriptDir%\Settings.ini, General, DebugEnabled
	
	IniWrite, %FTP_Enabled%, %A_ScriptDir%\Settings.ini, FTP, UseFTP
	IniWrite, %FTP_Username%, %A_ScriptDir%\Settings.ini, FTP, Username
	IniWrite, %FTP_Password%, %A_ScriptDir%\Settings.ini, FTP, Password
	IniWrite, %FTP_Host%, %A_ScriptDir%\Settings.ini, FTP, Host
	IniWrite, %FTP_PORT%, %A_ScriptDir%\Settings.ini, FTP, Port
	IniWrite, %FTP_URL%, %A_ScriptDir%\Settings.ini, FTP, URL
	IniWrite, %FTP_Path%, %A_ScriptDir%\Settings.ini, FTP, Path
	
	/*
	IniWrite, %ReplaceCalendar%, %A_ScriptDir%\Settings.ini, Calendar, ReplaceCalendar
	IniWrite, %CalendarClass%, %A_ScriptDir%\Settings.ini, Calendar, CalendarClass
	x:=Quote(CalendarCommand,0)
	IniWrite, %x%, %A_ScriptDir%\Settings.ini, Calendar, CalendarCommand
	*/
	
	IniWrite, %ImgName%, %A_ScriptDir%\Settings.ini, Explorer, Image
	IniWrite, %TxtName%, %A_ScriptDir%\Settings.ini, Explorer, Text
	IniWrite, %TextEditor%, %A_ScriptDir%\Settings.ini, Explorer, TextEditor
	IniWrite, %ImageEditor%, %A_ScriptDir%\Settings.ini, Explorer, ImageEditor
	IniWrite, %HKCreateNewFile%, %A_ScriptDir%\Settings.ini, Explorer, HKCreateNewFile
	IniWrite, %HKCreateNewFolder%, %A_ScriptDir%\Settings.ini, Explorer, HKCreateNewFolder
	IniWrite, %HKCopyFilenames%, %A_ScriptDir%\Settings.ini, Explorer, HKCopyFilenames
	IniWrite, %HKCopyPaths%, %A_ScriptDir%\Settings.ini, Explorer, HKCopyPaths
	IniWrite, %HKAppendClipboard%, %A_ScriptDir%\Settings.ini, Explorer, HKAppendClipboard
	
	IniWrite, %HKFastFolders%, %A_ScriptDir%\Settings.ini, Explorer, HKFastFolders
	IniWrite, %HKFFMenu%, %A_ScriptDir%\Settings.ini, Explorer, HKFFMenu
	IniWrite, %HKPlacesBar%, %A_ScriptDir%\Settings.ini, Explorer, HKPlacesBar
	IniWrite, %HKCleanFolderBand%, %A_ScriptDir%\Settings.ini, Explorer, HKCleanFolderBand
	IniWrite, %HKFolderBand%, %A_ScriptDir%\Settings.ini, Explorer, HKFolderBand	
	
	IniWrite, %HKProperBackspace%, %A_ScriptDir%\Settings.ini, Explorer, HKProperBackspace
	;IniWrite, %HKImprovedWinE%, %A_ScriptDir%\Settings.ini, Explorer, HKImprovedWinE
	IniWrite, %HKSelectFirstFile%, %A_ScriptDir%\Settings.ini, Explorer, HKSelectFirstFile
	IniWrite, %HKImproveEnter%, %A_ScriptDir%\Settings.ini, Explorer, HKImproveEnter
	IniWrite, %HKDoubleClickUpwards%, %A_ScriptDir%\Settings.ini, Explorer, HKDoubleClickUpwards
	IniWrite, %HKShowSpaceAndSize%, %A_ScriptDir%\Settings.ini, Explorer, HKShowSpaceAndSize
	IniWrite, %HKMouseGestureBack%, %A_ScriptDir%\Settings.ini, Explorer, HKMouseGestureBack
	IniWrite, %HKAutoCheck%, %A_ScriptDir%\Settings.ini, Explorer, HKAutoCheck
	IniWrite, %ScrollUnderMouse%, %A_ScriptDir%\Settings.ini, Explorer, ScrollUnderMouse
	
	IniWrite, %HKToggleAlwaysOnTop%, %A_ScriptDir%\Settings.ini, Windows, HKToggleAlwaysOnTop
	IniWrite, %HKActivateBehavior%, %A_ScriptDir%\Settings.ini, Windows, HKActivateBehavior
	IniWrite, %HKKillWindows%, %A_ScriptDir%\Settings.ini, Windows, HKKillWindows
	IniWrite, %HKToggleWallpaper%, %A_ScriptDir%\Settings.ini, Windows, HKToggleWallpaper
	IniWrite, %TaskbarLaunchPath%, %A_ScriptDir%\Settings.ini, Windows, TaskbarLaunchPath
	IniWrite, %HKTitleClose%, %A_ScriptDir%\Settings.ini, Windows, HKTitleClose
	IniWrite, %HKMiddleClose%, %A_ScriptDir%\Settings.ini, Windows, HKMiddleClose
	IniWrite, %AeroFlipTime%, %A_ScriptDir%\Settings.ini, Windows, AeroFlipTime
	IniWrite, %HKSlideWindows%, %A_ScriptDir%\Settings.ini, Windows, HKSlideWindows
	IniWrite, %SlideWindowsBorder%, %A_ScriptDir%\Settings.ini, Windows, SlideWindowsBorder
	IniWrite, %HKFlashWindow%, %A_ScriptDir%\Settings.ini, Windows, HKFlashWindow
	IniWrite, %HKToggleWindows%, %A_ScriptDir%\Settings.ini, Windows, HKToggleWindows
	
	IniWrite, %HKImproveConsole%, %A_ScriptDir%\Settings.ini, Misc, HKImproveConsole
	IniWrite, %HKPhotoViewer%, %A_ScriptDir%\Settings.ini, Misc, HKPhotoViewer
	IniWrite, %ImageExtensions%, %A_ScriptDir%\Settings.ini, Misc, ImageExtensions
	IniWrite, %JoyControl%, %A_ScriptDir%\Settings.ini, Misc, JoyControl
	IniWrite, %FullscreenExclude%, %A_ScriptDir%\Settings.ini, Misc, FullscreenExclude
	IniWrite, %FullscreenInclude%, %A_ScriptDir%\Settings.ini, Misc, FullscreenInclude
	IniWrite, %ClipboardManager%, %A_ScriptDir%\Settings.ini, Misc, ClipboardManager
	;FastFolders
	Loop 10
	{
	    x:=A_Index-1
	    y:=FF%x%
	    z:=FFTitle%x%
	    IniWrite, %y%, %A_ScriptDir%\Settings.ini, FastFolders, Folder%x%
	    IniWrite, %z%, %A_ScriptDir%\Settings.ini, FastFolders, FolderTitle%x%
	}
	
	Loop 10
	{
		x:=ClipboardList[A_Index]
		x := RegExReplace(RegExReplace(RegExReplace(x, "``", "````"), "\r?\n", "``r``n"), "%", "``%")
		IniWrite, %x%, %A_ScriptDir%\Settings.ini, Misc, Clipboard%A_Index%
	}
}
