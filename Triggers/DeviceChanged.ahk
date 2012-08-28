Class CDeviceChangedTrigger Extends CTrigger
{
	static Type := RegisterType(CDeviceChangedTrigger, "Device Changed")
	static Category := RegisterCategory(CDeviceChangedTrigger, "System")
	static __WikiLink := "DeviceChanged"
	static ChangeType := "Volume Added"
	static Drive := "All"
	
	Startup()
	{
		;OnMessage(0x219, "WM_DEVICECHANGE")
		WM_MEDIA_CHANGE := 0x0400 + 666 ;WM_USER + 666
		VarSetCapacity(shcne, A_PtrSize + 4, 0) ;SHChangeNotifyEntry
		NumPut(true, shcne + A_PtrSize, "UINT")
		/*
		ULONG SHChangeNotifyRegister(
		  _In_  HWND hwnd,
		  int fSources,
		  LONG fEvents,
		  UINT wMsg,
		  int cEntries,
		  _In_  const SHChangeNotifyEntry *pshcne
		);
		*/
		hNotify := DllCall("Shell32.dll\SHChangeNotifyRegister", "Ptr", A_ScriptHWND, "INT", SHCNE_DISKEVENTS := 0x0002381F, "INT", (SHCNE_MEDIAREMOVED := 0x00000040) | (SHCNE_MEDIAINSERTED := 0x00000020) | (SHCNE_DRIVEADD := 0x00000100) | (SHCNE_DRIVEREMOVED := 0x00000080), "UINT", WM_MEDIA_CHANGE, "INT", 1, "PTR*", shcne, "UINT")
		outputdebug % hNotify ", " A_LastError ", " Errorlevel
		OnMessage(WM_MEDIA_CHANGE, "WM_MEDIA_CHANGE")
	}
	
	Matches(Filter, Event)
	{
		;Check for correct type
		if(this.ChangeType != "All" && this.ChangeType != Filter.ChangeType)
			return false
		if(this.Drive != "All" && InStr(Filter.Drive, this.Drive) != 1) ; != this.Drive)
			return false
		Event.Placeholders.Drive := Filter.Drive
		return true
	}
	
	DisplayString()
	{
		return "Device changed: " this.ChangeType ": " this.Drive
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "ComboBox", "ChangeType", "All|Volume Added|Volume Removed", "", "Trigger on:")
		this.AddControl(GUI, "ComboBox", "Drive", "All|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z", "", "Drive:")
	}
}

;Called when media/drives are added/removed
WM_MEDIA_CHANGE(wParam, lParam, msg, hwnd)
{
	static lastEvent := ""
	static lastDrive := ""
	;lastTime := ""
	;struct SHNOTIFYSTRUCT
	;{
	;    ITEMIDLIST *dwItem1;
	;    ITEMIDLIST *dwItem2;
	;};
	VarSetCapacity(Drive, 260 * 2 + 2, 0)
	pidl := NumGet(wParam+0, "PTR")
	result := DllCall("Shell32.dll\SHGetPathFromIDListW", "PTR", pidl, "STR", Drive, "UINT")
	if(lParam = (SHCNE_MEDIAINSERTED := 0x00000020) || lParam = (SHCNE_DRIVEADD := 0x00000100))
	{
		if(Drive != lastDrive || lastEvent != 1)
		{
			DeviceChangedTrigger := new CDeviceChangedTrigger()
			DeviceChangedTrigger.ChangeType := "Volume Added"
			DeviceChangedTrigger.Drive := Drive
			EventSystem.OnTrigger(DeviceChangedTrigger)
		}
		lastDrive := Drive
		lastEvent := 1
	}
	else if(lParam = (SHCNE_MEDIAREMOVED := 0x00000040) || lParam = (SHCNE_DRIVEREMOVED := 0x00000080))
	{
		if(Drive != lastDrive || lastEvent != 0)
		{
			DeviceChangedTrigger := new CDeviceChangedTrigger()
			DeviceChangedTrigger.ChangeType := "Volume Removed"
			DeviceChangedTrigger.Drive := Drive
			EventSystem.OnTrigger(DeviceChangedTrigger)
		}
		lastDrive := Drive
		lastEvent := 0
	}
}

;WM_DEVICECHANGE(wParam, lParam, msg, hwnd)
;{
;	static LastChangeType := ""
;	static LastMask := ""
;	static LastCall := ""
;	outputdebug % wParam ", " lParam ", " msg ", " hwnd
;	if(wParam = 0x8000 || wParam = 0x8004)
;	{
;		Mask := NumGet(lParam + 12, "UINT")
;		ChangeType := wParam = 0x8000 ? "Volume Added" : "Volume Removed"
;		;Send triggers for each drive
;		if(A_TickCount - 1000 > LastCall || LastChangeType != ChangeType || Mask != LastMask)
;			Loop 26
;				if(Mask & (1 << (A_Index - 1)))
;				{
;					DeviceChangedTrigger := new CDeviceChangedTrigger()
;					DeviceChangedTrigger.ChangeType := ChangeType
;					DeviceChangedTrigger.Drive := Chr(64 + A_Index)
;					EventSystem.OnTrigger(DeviceChangedTrigger)
;				}
;		LastChangeType := ChangeType
;		LastMask := Mask
;		LastCall := A_TickCount
;	}
;}