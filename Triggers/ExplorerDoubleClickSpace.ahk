Class CExplorerDoubleClickSpaceTrigger Extends CTrigger
{
	static Type := RegisterType(CExplorerDoubleClickSpaceTrigger, "Double click on empty space")
	static Category := RegisterCategory(CExplorerDoubleClickSpaceTrigger, "Explorer")
	Matches(Filter)
	{
		return true ;type is checked elsewhere
	}
	DisplayString()
	{
		return "Explorer: Double click on empty space"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This trigger executes when an empty space in the explorer file list is double-clicked.")
	}
}

;Double click upwards is buggy in filedialogs, so only explorer for now until someone comes up with non-intrusive getpath, getselectedfiles functions
#if !IsDialog() && IsMouseOverFileList() && GetKeyState("RButton")!=1
;LButton on empty space in explorer -> go upwards
~LButton::
TestDoubleClickSpace()
return
#if

TestDoubleClickSpace()
{
	;Time for a doubleclick in windows
	static WaitTime := DllCall("GetDoubleClickTime")/1000
	static Click1X, Click1Y, path, time1, path1, Click2X, Click2Y
	CoordMode,Mouse,Relative
	
	;wait until button is released again
	KeyWait, LButton
	
	MouseGetPos, Click1X, Click1Y
	;This check is needed so that we don't send CTRL+C in a textfield control, which would disrupt the text entering process
	;Make sure only filelist is focussed
	if(!IsRenaming() && InFileList())
	{
		path := Navigation.GetPath()
		files := Navigation.GetSelectedFilepaths()
		;if more time than a double click time has passed, consider this a new series of double clicks
		if(A_TickCount - time1 > WaitTime * 1000)
		{
			time1 := A_TickCount
			path1 := path
		}
		else
		{			
			;if less time has passed, the previous double click was cancelled for some reason and we need to check its dir too to see directory changes
			time1 := A_TickCount
			if(path != path1)
			{
				time1 := 0
				return
			}					
		}
		;this check is required so that it's possible to count any double click and not every second. If at this place a file is selected, 
		;it would swallow the second click otherwise and won't be able to count it in a double clickwait for anotherat this plac
		if (files.MaxIndex())
			return
		;wait for second click
		KeyWait, LButton, D T%WaitTime% 
		If(errorlevel = 0)
		{
			MouseGetPos, Click2X, Click2Y
			if(abs(Click1X-Click2X)**2+abs(Click1Y-Click2Y)**2>16) ;Max 4 pixels between clicks
				return
		
			path1 := Navigation.GetPath()
			if(path = path1) 
			{	
				if(InFileList()&&IsMouseOverFileList()) 
				{			
					;check if no files selected after second click either
					if (!Navigation.GetSelectedFilepaths().MaxIndex())
					{
						Trigger := new CExplorerDoubleClickSpaceTrigger()
						EventSystem.OnTrigger(Trigger)
						time1:=0
					}
				}	
			}
		}
		
	}
}