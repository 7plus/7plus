;~ #Warn, UseUnsetGlobal
Suspend On
#SingleInstance Off
#NoTrayIcon ;Added later
; #InstallMouseHook
; #InstallKeyBdHook
#MaxThreads 255
#IfTimeout 150ms ;Might soften up mouse hook timeout problem
#MaxHotkeysPerInterval 1000 ;Required for mouse wheel
SetBatchLines, -1
SetMouseDelay, -1 ; no pause after mouse clicks 
SetKeyDelay, -1 ; no pause after keys sent 
SetDefaultMouseSpeed, 0
CoordMode, Mouse, Screen
SetWinDelay, -1
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases. 
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability. 
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
DetectHiddenWindows, On ;We don't want to miss any usually
SetTitleMatchMode, 2 ;Match anywhere in title
;SetFormat, Integer, D
MajorVersion := 2
MinorVersion := 6
BugfixVersion := 0
ComObjError(1)
StartupTime := A_TickCount

#include %A_ScriptDir%\Globals.ahk ;Some global variable definitions
#include %A_ScriptDir%\AutoExecute.ahk ;include first to avoid issues with autoexecute ending too soon because of labels
#include <RichObject>
#include <Array>
#include <CQueue>
#include <Delegate>
#include <CGUI>
#include <Crypt>
#include <Cursor>
#include <Edit>
#include <Functions>
#include <gdip>
;#include <json> ;Can be used for CURLPlugin Chrome bookmark import. Right now lson is used because that is included anyway.
#include <Navigation>
#include <Parse>
#include <RemoteBuf>
#include <Taskbutton>
#include <Thumbnail>
#include <unhtml>
#include <VA>
#include <Win>
#include <DllCalls>
#include <CNotification>
#include <_Struct>
#include <ControlHotkey>
#include <WaitForEvent>
#include <WorkerThread>
#include <ObjectTools>
#include <winclipapi>
#include <winclip>

#include %A_ScriptDir%\CApplicationState.ahk
#include %A_ScriptDir%\CSettings.ahk
#include %A_ScriptDir%\Accessor\Accessor.ahk
#include %A_ScriptDir%\Deployment.ahk
#include %A_ScriptDir%\EventSystem.ahk
#include %A_ScriptDir%\EventEditor.ahk
#include %A_ScriptDir%\Language.ahk
#include %A_ScriptDir%\WindowFinder.ahk
#include %A_ScriptDir%\Placeholders.ahk
#include %A_ScriptDir%\SubEventGUIBuilder.ahk
#include %A_ScriptDir%\MessageHooks.ahk
#include %A_ScriptDir%\Shell.ahk
#include %A_ScriptDir%\ContextMenu.ahk
#include %A_ScriptDir%\FastFolders.ahk
#include %A_ScriptDir%\WindowHandling.ahk
#include %A_ScriptDir%\WindowsSettings.ahk
#include %A_ScriptDir%\Explorer.ahk
#include %A_ScriptDir%\ImageConverter.ahk
#include %A_ScriptDir%\Clipboard.ahk
#include %A_ScriptDir%\TaskBar.ahk
#include %A_ScriptDir%\Hotstrings.ahk
#include %A_ScriptDir%\xml.ahk
#include %A_ScriptDir%\Debugging.ahk
#include %A_ScriptDir%\CSettingsWindow.ahk
#include %A_ScriptDir%\MiscFunctions.ahk
#include %A_ScriptDir%\Registry.ahk
#include %A_ScriptDir%\SlideWindows.ahk
#include %A_ScriptDir%\JoyControl.ahk
#include %A_ScriptDir%\ExplorerTabs.ahk