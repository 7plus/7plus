HookProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime ){ 
	global HKShowSpaceAndSize,HKAutoCheck
	;outputdebug event %event% hwnd %hwnd%
	;Events 10 and 11 aren't fired for trillian windows apparently, so let's use a polling method instead
	
	;timer while explorer is moved for info gui update
	if(HKShowSpaceAndSize && WinActive("ahk_group ExplorerGroup"))
	{
		if(event = 10) 
			settimer,MoveExplorer,10    
	  else if (event=11)
			settimer,MoveExplorer, off		 
	} 	   
	
	;On dialog popup, check if its an explorer confirmation dialog
	if(event=0x00008002) ;EVENT_OBJECT_SHOW
	{	
		if(HKAutoCheck)
			FixExplorerConfirmationDialogs()
	}
}

ShellMessage( wParam,lParam ) 
{
	global Vista7, ExplorerPath,hwnd1,HKShowSpaceAndSize,BlinkingWindows
	;CalendarShellHook(wParam, lParam)
	;outputdebug Shellmessage, wParam=%wparam% lparam=%lparam%
	; Execute a command based on wParam and lParam 
	if(false && wParam=5)
	{		
		outputdebug getminrect %lParam%
		hwnd := NumGet(lParam+0, 0, "UInt")
		;Disable Minimize/Restore animation
		RegRead, Animate, HKCU, Control Panel\Desktop\WindowMetrics , MinAnimate
		outputdebug animate is currently set to %animate%
		VarSetCapacity(struct, 8, 0)	
	  NumPut(8, struct, 0, "UInt")
	  NumPut(0, struct, 4, "Int")
		DllCall("SystemParametersInfo", "UINT", 0x0049,"UINT", 8,"STR", struct,"UINT", 0x0003) ;SPI_SETANIMATION            0x0049 SPIF_SENDWININICHANGE 0x0002
		WinActivate ahk_id %hwnd%
		;Possibly activate it again
		if(Animate=1)
		{
	  	NumPut(1, struct, 4, "UInt")
	  	DllCall("SystemParametersInfo", "UINT", 0x0049,"UINT", 8,"STR", struct,"UINT", 0x0003) ;SPI_SETANIMATION            0x0049 SPIF_SENDWININICHANGE 0x0002
	  }
		outputdebug %hwnd%
		
	}
	;Blinking windows detection, add new blinking windows
	if(wParam=32774)
	{
		class:=WinGetClass("ahk_id " lParam)
		outputdebug blinking window %class%
		if(BlinkingWindows.indexOf(lParam)=0)
		{			
			BlinkingWindows.Append(lParam)
			ct:=BlinkingWindows.len()
			outputdebug add window, count is now %ct%
		}
	}
	
	;Window Activation
	if(wParam=4||wParam=32772) ;HSHELL_WINDOWACTIVATED||HSHELL_RUDEAPPACTIVATED
	{
		TaskbarShellMessage()		
		;Explorer info stuff
		if(Vista7 && HKShowSpaceAndSize)
		{
			SetTimer, UpdateInfos, 100
		}
		;Blinking windows detection, remove activated windows
		if(x:=BlinkingWindows.indexOf(lParam))
			BlinkingWindows.Delete(x)
		outputdebug activate
		;If we change from another program to explorer/desktop/dialog
		if(WinActive("ahk_group ExplorerGroup")||WinActive("ahk_group DesktopGroup")||IsDialog())
    {
    	;Backup current clipboard contents and write "simple" text/image data in clipboard while explorer is active
			ExplorerPath:=GetCurrentFolder()
			;Paste text/image as file file creation
			CreateFile()
		}
	}
	;Redraw is fired on Explorer path change
	else if(wParam=6)
	{
		;Detect changed path
    if(WinActive("ahk_group ExplorerGroup")||IsDialog())
    {
    	newpath:=GetCurrentFolder()
    	if(newpath && newpath!=ExplorerPath)
    	{
    		outputdebug Explorer path changed from %ExplorerPath% to %newpath%
    		ExplorerPathChanged(ExplorerPath, newpath)
    		ExplorerPath:=newpath
    	}
    }
  }
}

WM_LBUTTONUP(wParam,lParam,msg,hWnd){
	SetTimer, TooltipClose, -20
} 

WM_NOTIFY(wParam, lParam, msg, hWnd){ 
	Critical
  ToolTip("",lParam,"") 
} 
ToolTip: 
link:=ErrorLevel 
SetTimer, TooltipClose, off
ToolTip()
If(TooltipShowSettings && Link) { 
	ShowSettings()
	TooltipShowSettings:=false
}
Return 

ToolTipClose: 
Tooltip()
return


API_SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) { 
   DllCall("CoInitialize", "uint", 0) 
   return DllCall("SetWinEventHook", "uint", eventMin, "uint", eventMax, "uint", hmodWinEventProc, "uint", lpfnWinEventProc, "uint", idProcess, "uint", idThread, "uint", dwFlags) 
}

;NOT USED
;Hook for trapping minimization				NOTE: For some reason these hooks can't be packed into one single function?
CBTHook(wParam, lParam, msg, hwnd)
{ 
	static SuppressHook
	Global SlideWindowArray
	if(!SuppressHook)
	{
		DllCall("ReplyMessage", "UInt", 1)
		outputdebug don't SuppressHook
	}
	else
	{
		DllCall("ReplyMessage", "UInt", 2)
		outputdebug SuppressHook
		return 2
	}
	showtype:=lParam & 0x000FFFF	
	if(lParam=6 && y:=SlideWindowArray.ContainsHWND(wParam)) ;minimize
	{
		;Disable minimize, then disable animation, and minimize again
		if(y.SlideState=1)
			y.SlideOut()
		else
		{
			;Disable Minimize/Restore animation
			RegRead, Animate, HKCU, Control Panel\Desktop\WindowMetrics , MinAnimate
			VarSetCapacity(struct, 8, 0)	
		  NumPut(8, struct, 0, "UInt")
		  NumPut(0, struct, 4, "Int")
			DllCall("SystemParametersInfo", "UINT", 0x0049,"UINT", 8,"STR", struct,"UINT", 0x0003) ;SPI_SETANIMATION            0x0049 SPIF_SENDWININICHANGE 0x0002
			SuppressHook:=true
			WinMinimize ahk_id %wParam%
		  SuppressHook:=false
			;Possibly activate it again
			if(Animate=1)
			{
		  	NumPut(1, struct, 4, "UInt")
		  	DllCall("SystemParametersInfo", "UINT", 0x0049,"UINT", 8,"STR", struct,"UINT", 0x0003) ;SPI_SETANIMATION            0x0049 SPIF_SENDWININICHANGE 0x0002
		  }
	  }
	}
	else
	{
		SuppressHook:=true
		DllCall("ShowWindow","UInt", wParam, "UINT", showtype)
		SuppressHook:=false
	}
	return 1
}
/*
;Main timer for stuff that needs polling somewhat frequently
PollingTimer:
Process, Exist, %CalendarPID%
if(ReplaceCalendar&&ErrorLevel=0)
	RunCalendar()
return
*/
SetWindowsHookEx(idHook, pfn) 
{ 
   Return DllCall("SetWindowsHookEx", "int", idHook, "Uint", pfn, "Uint", DllCall("GetModuleHandle", "Uint", 0), "Uint", 0) 
} 

UnhookWindowsHookEx(hHook) 
{ 
   Return DllCall("UnhookWindowsHookEx", "Uint", hHook) 
}
CallNextHookEx(nCode, wParam, lParam, hHook = 0) 
{ 
   Return DllCall("CallNextHookEx", "UInt", hHook, "Int", nCode, "Uint", wParam, "Uint", lParam) 
}
