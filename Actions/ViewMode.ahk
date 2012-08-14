Class CViewModeAction Extends CAction
{
	static Type := RegisterType(CViewModeAction, "Change explorer view mode")
	static Category := RegisterCategory(CViewModeAction, "Explorer")
	static __WikiLink := "ViewMode"
	static Action := "Toggle show hidden files"
	Execute(Event)
	{
		if(this.Action = "Toggle show hidden files")
		{
			RegRead, ShowFiles, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden 
			if(ShowFiles = 2)
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1 
			else  
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2 
		}
		else if(this.Action = "Show hidden files")
		{
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
		}
		else if(this.Action = "Hide hidden files")
		{
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
		}
		if(this.Action = "Toggle show file extensions")
		{
			RegRead, ShowFiles, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, HideFileExt 
			if(ShowFiles = 1)
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, HideFileExt, 0
			else  
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, HideFileExt, 1
		}
		else if(this.Action = "Show file extensions")
		{
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, HideFileExt, 0
		}
		else if(this.Action = "Hide file extensions")
		{
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, HideFileExt, 1
		}
		Navigation.Refresh()
		return 1
	}
	DisplayString()
	{
		return this.Action ;this.Parameter
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This action can modify various explorer settings.")
		this.AddControl(GUI, "DropDownList", "Action", "Toggle show hidden files|Show hidden files|Hide hidden files|Toggle show file extensions|Show file extensions|Hide file extensions", "", "Action:")
	}
}
