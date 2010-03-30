#Persistent 
#NoTrayIcon
#InstallMouseHook
#IfTimeout 150ms
#MaxHotkeysPerInterval 1000
SetBatchLines -1
SetMouseDelay, -1 ; no pause after mouse clicks 
SetKeyDelay, -1 ; no pause after keys sent 
CoordMode, Mouse, Screen
;BUGS:
;File dialogs not fully supported
;Mouse hook gets lost sometimes ; write a testing mechanism that sends some obscure mouse hotkey and reload script if not detected
;fast folder titles are generated wrong sometimes
;Middle mouse button close needs to read string from dll resource and use hotkey instead of arrow keys, since some programs have custom menus
;Lib functions included because there was some issue on xp?
;Paste as file functions don't work with text copied by .NET applications, even though CF_TEXT is there (tested with AdiIRC) 

;TODO:
;Proper calendar implementation ;calendar default configs
;Win+E
;Flatten directory: http://www.autohotkey.com/forum/post-307108.html#307108
;Non-instantaneous file filter with windows search and search option to search current dir only
;Copy/move scheduler
;Sliding windows -> add a autohide list on which windows are automatically put at startup or new window creation
;Replace in file and filenames
;store/restore selection on a per-folder basis
;combobox: use tab for autocompletion
;Additional alerts:
;TTrayAlert - Skype
;OpWindow - check some window styles for distinguation with real opera window
;tooltip_Class32 - windows tooltips
#include %a_scriptdir%\lib\binreadwrite.ahk
#include %a_scriptdir%\lib\gdip.ahk
#include %a_scriptdir%\lib\Functions.ahk
#include %a_scriptdir%\lib\com.ahk
#include %a_scriptdir%\lib\FTPLib.ahk
#include %a_scriptdir%\lib\Array.ahk
#include %a_scriptdir%\lib\SetCursor.ahk
#include %a_scriptdir%\lib\RemoteBuf.ahk
#include %a_scriptdir%\lib\win.ahk
#include %a_scriptdir%\lib\Taskbutton.ahk
#include %a_scriptdir%\Autoexecute.ahk
#include %a_scriptdir%\messagehooks.ahk
#include %a_scriptdir%\navigate.ahk
#include %a_scriptdir%\ContextMenu.ahk
#include %a_scriptdir%\FastFolders.ahk
#include %a_scriptdir%\WindowTweaks.ahk
#include %a_scriptdir%\explorer.ahk
#include %a_scriptdir%\clipboard.ahk
#include %a_scriptdir%\FTPUpload.ahk 
#include %a_scriptdir%\Taskbar.ahk
#include %a_scriptdir%\CustomHotkeys.ahk
#include %a_scriptdir%\debugging.ahk
#include %a_scriptdir%\wizard.ahk
#include %a_scriptdir%\settings.ahk
#include %a_scriptdir%\miscfunctions.ahk
#include %a_scriptdir%\Registry.ahk
#include %a_scriptdir%\SlideWindows.ahk
#include %a_scriptdir%\JoyControl.ahk
#include %a_scriptdir%\Tooltip.ahk
;#include %a_scriptdir%\Calendar.ahk
#include %a_scriptdir%\NewStuff.ahk
#if !IsFullscreen("A",true,false)
#h::
	if(WinExist("7plus Settings"))
		WinActivate 7plus Settings
	else
		GoSub Settingshandler
	return
#if
