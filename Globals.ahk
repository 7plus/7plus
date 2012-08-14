/*
This file contains some global variables that are used throughout the application.
Variables which could possibly cause naming conflicts with local variables aren't made super-global.
*/

global WinVer := GetWindowsVersion()
global WIN_XP := 5.1
global WIN_XP64 := 5.2
global WIN_VISTA := 6.0
global WIN_7 := 6.1
global WIN_8 := 6.2

;~ global Vista7 := IsVista7()
;~ global shell32MUIpath := "" ;Defined in Autoexecute.ahk
global XMLMajorVersion := ""
;~ global MajorVersion := ""
global XMLMinorVersion := ""
;~ global MinorVersion := ""
global XMLBugfixVersion := ""
global NotifyIcons := new CNotifyIcons()
;~ global BugfixVersion := ""
global BlinkingWindows := Array()
GetWindowsVersion()
{
	Version := DllCall("GetVersion", "uint") & 0xFFFF
	return (Version & 0xFF) "." (Version >> 8)
}
Class CNotifyIcons
{
	Info := ExtractIcon(ExpandPathPlaceholders("%WINDIR%\System32\shell32.dll"), WinVer >= WIN_Vista ? 222 : 136)
	Error := ExtractIcon("%WINDIR%\System32\shell32.dll", WinVer >= WIN_Vista ? 78 : 110)
	Success := ExtractIcon("%WINDIR%\System32\shell32.dll", WinVer >= WIN_Vista ? 145 : 136)
	Internet := ExtractIcon("%WINDIR%\System32\shell32.dll", 136)
	Sound := ExtractIcon("%WINDIR%\System32\shell32.dll", WinVer >= WIN_Vista ? 169 : 110)
	SoundMute := ExtractIcon("%WINDIR%\System32\shell32.dll", WinVer >= WIN_Vista ? 220 : 169)
	Question := ExtractIcon("%WINDIR%\System32\shell32.dll", 24)
}
/*
Below follows information about important global objects:

Name						|	Description
========================================================================================================================================================================
Objects:
--------
Accessor					|	Main object for Accessor, the Launcher tool. Contains instances of all plugins, keywords, its settings and the GUI.
ApplicationState			|	Contains some variables which are of importance for different parts of the program.
BlinkingWindows				|	Contains a list of Windows which are currently blinking in the Taskbar.
EventSystem					|	Contains all relevant data for the Event system, includes the event loop and the current event config.
ExplorerHistory				|	Instance of CExplorerHistory, used for collecting the previously and frequently used directories.
ExplorerWindows				|	Array of instances of CExplorerWindows. Contains data about Explorer windows such as the selection history, Explorer tabs and InfoGUI.
FastFolders					|	Array containing up to ten stored directories used for quick access in various parts of the program.
Hotstrings					|	Array containing Hotstrings, which are used for an Autoreplace Text function.
Languages					|	Contains data relevant to localization. This currently affects the links to the localized documentation only.
Navigation					|	Instance of CNavigation. Provides methods to get/set current path, file selection and similar things for multiple programs.
NotifyIcons					|	Instance of CNotifyIcons. Contains handles to common icons used for notifications.
RecentCreateCloseEvents		|	Contains a list of recent Create/Close shell messages to detect duplicates
Settings					|	Contains 7plus settings by categories. Responsible for saving/loading them.
SettingsWindow				|	The GUI of the settings window.
SlideWindows				|	Contains data related to the SlideWindows feature.
WindowList					|	A list of open windows, along with window class and title.


Variables:
----------
BugfixVersion				|	The third value of the version string, used for bugfix releases only.
LastWindow					|	The window handle of the previously active window. In contrast to PreviousWindow this includes all windows.
LastWindowClass				|	The window class of the previously active window. In contrast to PreviousWindow this includes all windows.
MajorVersion				|	The first value of the version string, used for releases with huge changes. Unlikely to be ever increased again, but who knows?
MinorVersion				|	The second value of the version string, used for common releases. This value is most often changed.
MuteClipboardList			|	If true, will skip the OnClipboardChange handler. Used internally when the clipboard is needed to get/set text at the current selection.
PatchVersion				|	The fourth value of the version string. This is only increased if the event configuration was patched without changing the code.
PreviousWindow				|	The window handle of the previously active window that appears in the Alt+TAB list. Set when window activation shell message is received.
ResizeWindow				|	The window handle of the currently resizing window.
shell32MUIpath				|	This path is used for extracting some localized strings.
WinVer						|	The windows version as integer. Can be compared to the global values WIN_XP, WIN_XP64, WIN_VISTA, WIN_7, WIN_8
*/