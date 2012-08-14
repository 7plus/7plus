;Checks if a context menu is active and has focus
;Need to check if other context menus are active (trillian, browsers,...)
IsContextMenuActive() 
{ 
	GuiThreadInfoSize := 24 + 6 * A_PtrSize 
	VarSetCapacity(GuiThreadInfo, GuiThreadInfoSize) 
	NumPut(GuiThreadInfoSize, GuiThreadInfo, 0) 
	if not DllCall("GetGUIThreadInfo", uint, 0, "Ptr", &GuiThreadInfo) 
	{ 
	  ;MsgBox GetGUIThreadInfo() indicated a failure. 
	  return 
	} 
	; GuiThreadInfo contains a DWORD flags at byte 4 
	; Bit 4 of this flag is set if the thread is in menu mode. GUI_INMENUMODE = 0x4 
	if (NumGet(GuiThreadInfo, 4) & 0x4) 
		return true
	return false
}

;This stuff doesn't properly use COM.ahk yet :(
/*
Executes context menu entries of shell items without showing their menus
Usage:
ShellContextMenu("Desktop",1)			;Calls "Next Desktop background" in Win7
1st parameter can be "Desktop" for empty selection desktop menu, a path, or an idl
Leave 2nd parameter empty to show context menu and extract idn by clicking on an entry (shows up in debugview)
*/ 
ShellContextMenu(sPath,idn=0) 
{ 
	result := DllCall(Settings.DllPath "\Explorer.dll\ExecuteContextMenuCommand", "Str", sPath, "Int", idn, "PTR", A_ScriptHwnd)
	if(Errorlevel != 0)
		Notify("Couldn't execute context menu command!", "Error Calling ExecuteContextMenuCommand() in Explorer.dll!", 5, NotifyIcons.Error)
} 