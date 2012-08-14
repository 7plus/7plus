; see http://msdn.microsoft.com/en-us/library/dd318066(VS.85).aspxs
HookProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime ){ 
	global ResizeWindow, SlideWindows, WindowList
	ListLines, Off
	hwnd += 0
	;On dialog popup, check if its an explorer confirmation dialog
	if(event = 0x00008002) ;EVENT_OBJECT_SHOW
	{
		if(IsObject(Settings) && Settings.Explorer.AutoCheckApplyToAllFiles && WinVer >= WIN_Vista)
			FixExplorerConfirmationDialogs()
		return
	}
	if idObject or idChild ;Doesn't each much time, skip for profiling
		return
	WinGet, style, Style, ahk_id %hwnd%
	if (style & 0x40000000)	;return if hwnd is child window, for some reason idChild may be 0 for some children ?!?! ( I hate ms )
		return
	if(event = 0x0016) ;EVENT_SYSTEM_MINIMIZEEND
	{
		Trigger := new CWindowStateChangeTrigger()
		Trigger.Window := hwnd
		Trigger.Event := "Window minimized"
		EventSystem.OnTrigger(Trigger)
	}
	else if(event = 0x8001 && IsObject(Settings) && Settings.Explorer.Tabs.UseTabs) ;EVENT_OBJECT_DESTROY
	{
		; DecToHex(hwnd)
		; if(TabContainerList.ContainsHWND(hwnd))
	}
	else if(event = 0x800B) ;EVENT_OBJECT_LOCATIONCHANGE
	{
		WinGet, state, minmax, ahk_id %hwnd%
		if(state = 1)
		{
			Trigger := new CWindowStateChangeTrigger()
			Trigger.Window := hwnd
			Trigger.Event := "Window maximized"
			EventSystem.OnTrigger(Trigger)
		}
		if(InStr("CabinetWClass,ExploreWClass", WinGetClass("ahk_id " hwnd)))
			ExplorerMoved(hwnd)
		if(IsObject(SlideWindows))
			SlideWindows.CheckResizeReleaseCondition(hwnd)
		if(state != -1)
		{
			WindowList.MovedWindow := hwnd
			SetTimer, UpdateWindowPosition, -1000
		}
	}	
	else if(event = 0x000A && Settings.Windows.ShowResizeTooltip)
	{
		ResizeWindow := hwnd
		SetTimer, ResizeWindowTooltip, 50
		SlideWindows.CheckResizeReleaseCondition(hwnd)
	}
	else if(event = 0x000B)
	{
		ShowTip({Min : 4, Max : 7}, 0.1)
		if(Settings.Windows.ShowResizeTooltip)
		{
			ResizeWindow := ""
			SetTimer, ResizeWindowTooltip, Off
			ResizeWindowTooltip(true)
			Tooltip
		}
	}
	ListLines, On
}
ResizeWindowTooltip:
ResizeWindowTooltip()
return
ResizeWindowTooltip(reset = false)
{	
	global ResizeWindow
	static w,h
	if(reset)
	{
		w:=0
		h:=0
		return
	}
	WinGetPos, , , wn, hn, ahk_id %ResizeWindow%
	if(w && h && (w != wn || h != hn))
		Tooltip %w%/%h%
	w := wn
	h := hn
}

;See http://msdn.microsoft.com/en-us/library/ms644991(VS.85).aspx
ShellMessage( wParam, lParam, Msg)
{
	WasCritical := A_IsCritical
	Critical
	ListLines, Off
	global BlinkingWindows, WindowList, Accessor, RecentCreateCloseEvents, ToolWindows, ExplorerWindows, LastWindow, LastWindowClass, SlideWindows, CurrentWindow, PreviousWindow, ExplorerHistory
	Trigger := new COnMessageTrigger()
	Trigger.Message := wParam
	Trigger.lParam := lParam
	Trigger.Msg := Msg
	EventSystem.OnTrigger(Trigger)
	if(wParam = 1 || wParam = 2) ;Window Created/Closed
	{
		lParam += 0
		;Keep a list of recently received create/close messages, because they can be sent multiple times and we only want one.
		if(!IsObject(RecentCreateCloseEvents))
			RecentCreateCloseEvents := Array()
		SetTimer, ClearRecentCreateCloseEvents, -300
		if(!RecentCreateCloseEvents.HasKey(lParam))
		{
			RecentCreateCloseEvents[lParam] := 1
			Trigger := wParam = 1 ? new CWindowCreatedTrigger() : new CWindowClosedTrigger()
			class:= wParam = 1 ? WinGetClass("ahk_Id " lParam) : (IsObject(WindowList) && IsObject(WindowList[lParam]) ? WindowList[lParam].class : "INVALID WINDOW CLASS")
			Trigger.Window := lParam
			EventSystem.OnTrigger(Trigger)
			;Keep a list of windows and their required info stored. This allows to identify windows which were closed recently.
			WinGet, hwnds, list,,, Program Manager
			Loop, %hwnds%
			{
				hwnd := hwnds%A_Index%+0
				WinGetTitle, title, ahk_id %hwnd%
				if(IsObject(WindowList[hwnd]))
					WindowList[hwnd].title := title
				else
				{
					WinGetClass, class, ahk_id %hwnd%
					WinGet, exe, ProcessName, ahk_id %hwnd%
					WinGet, Path, ProcessPath, ahk_id %hwnd%
					WindowList[hwnd] := Object("class", class, "title", title, "Executable", exe, "Path", Path)
				}
			}
		}
		if(wParam = 2)
		{
			if(IsObject(WindowList[lParam]) && InStr("CabinetWClass,ExploreWClass", WindowList[lParam].class))
				GoSub WaitForClose
			else ;Code below is also executed in WaitForClose for separate Explorer handling (why can't explorer send close messages properly like a normal window??)
			{
				if(IsObject(ToolWindows))
				{
					Loop % ToolWindows.MaxIndex()
					{
						if(ToolWindows[A_Index].hParent = lParam && ToolWindows[A_Index].AutoClose)
						{
							WinClose % "ahk_id " ToolWindows[A_Index].hGui
							ToolWindows.Remove(A_Index)
							break
						}
					}
				}
				SlideWindows.WindowClosed(lParam)
			}
		}
		if(wParam = 1)
		{
			if(IsObject(SlideWindows))
				SlideWindows.WindowCreated(lParam)
			AutoCloseWindowsUpdate(lParam)
			;~ SlideWindows.CreatedWindow := lParam
			;~ SetTimer, SlideWindows_WindowCreated, -100
		} ;	SlideWindows.WindowCreated(lParam)
	}	
	;Blinking windows detection, add new blinking windows
	else if(wParam = 32774)
	{
		lParam += 0
		if(!BlinkingWindows.indexOf(lParam))
		{
			BlinkingWindows.Insert(lParam)
			ShowTip(12)
		}
	}	
	;Window Activation
	else if(wParam = 4 || wParam = 32772) ;HSHELL_WINDOWACTIVATED||HSHELL_RUDEAPPACTIVATED
	{
		ShowTip(13, 0.05)
		if(IsAltTabWindow(lParam))
		{
			PreviousWindow := CurrentWindow
			CurrentWindow := lParam
		}
		lParam += 0
		Trigger := new CWindowActivatedTrigger()
		EventSystem.OnTrigger(Trigger)
		;Blinking windows detection, remove activated windows
		if(x := BlinkingWindows.indexOf(lParam))
			BlinkingWindows.Delete(x)

		if(IsObject(CAccessor.Instance.GUI) && CAccessor.Instance.Settings.CloseWhenDeactivated && WinExist("A") != CAccessor.Instance.GUI.hwnd)
			CAccessor.Instance.Close()

		;If we change from another program to explorer/desktop/dialog
		if((IsExplorer := WinActive("ahk_group ExplorerGroup"))||WinActive("ahk_group DesktopGroup")||IsDialog())
		{
			if(!WinActive("ahk_group DesktopGroup")) ;By doing this, recall explorer path works also when double clicking desktop to launch explorer
				Settings.Explorer.CurrentPath := Navigation.GetPath()
			;Paste text/image as file file creation
			CreateFileFromClipboard()
			if((IsExplorer && ExplorerWindows.GetItemWithValue("hwnd", IsExplorer).Path != Settings.Explorer.CurrentPath) || !IsExplorer)
			{
				Entry := RichObject()
				Name := Entry.Path := Settings.Explorer.CurrentPath
				SplitPath, Name, Name
				Entry.Name := IsExplorer ? Navigation.GetDisplayName(lParam) : Name
				Entry.Usage := 0
				Entry := ExplorerHistory.Push(Entry) ;This can return a different entry that already exists in the list!
				Entry.Usage++
			}
		}
		if(LastWindowClass && InStr("CabinetWClass,ExploreWClass", LastWindowClass) && !ExplorerWindows.TabContainerList.TabCreationInProgress && !ExplorerWindows.TabContainerList.TabActivationInProgress)
			ExplorerDeactivated(LastWindow)
		
		LastWindow := lParam
		LastWindowClass := WinGetClass("ahk_id " lParam)
		
		if(InStr("CabinetWClass,ExploreWClass", LastWindowClass) && LastWindowClass && !ExplorerWindows.TabContainerList.TabCreationInProgress && !ExplorerWindows.TabContainerList.TabActivationInProgress)
			ExplorerActivated(LastWindow)
		
		if(IsObject(SlideWindows))
			SlideWindows.WindowActivated()
	}
	;Redraw is fired on Explorer path change
	else if(wParam = 6)
	{
		lParam += 0
		;Detect changed path
		if(InStr("CabinetWClass,ExploreWClass", WinGetClass("ahk_id " lParam)))
		{
			ExplorerPathChanged(ExplorerWindows.GetItemWithValue("hwnd", lParam))
			; newpath := Navigation.GetPath()
			; if(newpath && newpath != Settings.Explorer.CurrentPath)
			; {
				; outputdebug Explorer path changed from %ExplorerPath% to %newpath%
				; ExplorerPathChanged(Settings.Explorer.CurrentPath, newpath)
				; Settings.Explorer.PreviousPath := Settings.Explorer.CurrentPath
				; Settings.Explorer.CurrentPath := newpath
				; Trigger := new CExplorerPathChangedTrigger()
				; EventSystem.OnTrigger(Trigger)
				; if(Settings.Explorer.Tabs.UseTabs && !SuppressTabEvents && hwnd:=WinActive("ahk_group ExplorerGroup"))
					; UpdateTabs()
			; }
		}
	}
	ListLines, On
	if(!WasCritical)
		Critical, Off
}

;Timer for clearing the list of recently received create/close events
ClearRecentCreateCloseEvents:
RecentCreateCloseEvents := Array()
return
UpdateWindowPosition:
UpdateWindowPosition()
return
UpdateWindowPosition()
{
	global WindowList
	WinGetPos, x, y, w, h, % "ahk_id " WindowList.MovedWindow
	if(!IsObject(WindowList[WindowList.MovedWindow]))
		return
	WindowList[WindowList.MovedWindow].x := x
	WindowList[WindowList.MovedWindow].y := y
	WindowList[WindowList.MovedWindow].w := w
	WindowList[WindowList.MovedWindow].h := h
}
WM_POWERBROADCAST(wParam, lParam, msg)
{
	if (wParam = 18)
		AutoCloseWindowsUpdate(WinExist("Windows Update ahk_class #32770"))
}