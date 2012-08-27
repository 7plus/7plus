Class CDeviceChangedTrigger Extends CTrigger
{
	static Type := RegisterType(CDeviceChangedTrigger, "Device Changed")
	static Category := RegisterCategory(CDeviceChangedTrigger, "System")
	static __WikiLink := "DeviceChanged"
	static ChangeType := "Volume Added"
	static Drive := "All"
	
	Startup()
	{
		OnMessage(0x219, "WM_DEVICECHANGE")
	}
	
	Matches(Filter, Event)
	{
		;Check for correct type
		if(this.ChangeType != "All" && this.ChangeType != Filter.ChangeType)
			return false
		if(this.Drive != "All" && Filter.Drive != this.Drive)
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

;Called when a file monitored by one of this triggers is changed
WM_DEVICECHANGE(wParam, lParam, msg, hwnd)
{
	static LastChangeType := ""
	static LastMask := ""
	static LastCall := ""
	if(wParam = 0x8000 || wParam = 0x8004)
	{
		Mask := NumGet(lParam + 12, "UINT")
		ChangeType := wParam = 0x8000 ? "Volume Added" : "Volume Removed"
		;Send triggers for each drive
		if(A_TickCount - 1000 > LastCall || LastChangeType != ChangeType || Mask != LastMask)
			Loop 26
				if(Mask & (1 << (A_Index - 1)))
				{
					DeviceChangedTrigger := new CDeviceChangedTrigger()
					DeviceChangedTrigger.ChangeType := ChangeType
					DeviceChangedTrigger.Drive := Chr(64 + A_Index)
					EventSystem.OnTrigger(DeviceChangedTrigger)
				}
		LastChangeType := ChangeType
		LastMask := Mask
		LastCall := A_TickCount
	}
}