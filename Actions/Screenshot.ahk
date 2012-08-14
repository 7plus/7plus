Class CScreenshotAction Extends CAction
{
	static Type := RegisterType(CScreenshotAction, "Take a screenshot")
	static Category := RegisterCategory(CScreenshotAction, "System")
	static __WikiLink := "Screenshot"
	static Area := "Screen"
	static Quality := 95
	static TargetFolder := ""
	static TargetFile := ""
	
	Execute(Event)
	{
		TargetFolder := Event.ExpandPlaceholders(this.TargetFolder)
		TargetFile := Event.ExpandPlaceholders(this.TargetFile)
		if(this.Area = "Screen")
			pBitmap := Gdip_BitmapFromScreen()
		else if(this.Area = "Window")
			pBitmap := Gdip_BitmapFromHWND(WinExist("A"))
		else if(this.Area = "User selection")
		{
			if(!this.tmpState)
			{
				this.tmpState := 1
				;Credits of code below go to sumon/Learning one
				CoordMode, Mouse ,Screen 
				this.tmpGuiNum0 := GetFreeGUINum(10)
				Gui % this.tmpGuiNum0 ": Default"
				Gui, +AlwaysOnTop -caption -Border +ToolWindow +LastFound 
				Gui, Color, White
				Gui, Font, s50 c0x5090FF, Verdana
				Gui, Add, Text, % "x0 y" (A_ScreenHeight/10) " w" A_ScreenWidth " Center", Drag a rectangle around the area you want to capture!
				WinSet, TransColor, White
				this.tmpGuiNum := GetFreeGUINum(10)
				Gui % this.tmpGuiNum ": Default"
				SysGet, VirtualX, 76
				SysGet, VirtualY, 77
				SysGet, VirtualW, 78
				SysGet, VirtualH, 79
				Gui, +AlwaysOnTop -caption +Border +ToolWindow +LastFound 
				WinSet, Transparent, 1
				Gui % this.tmpGuiNum0 ":Show", X%VirtualX% Y%VirtualY% W%VirtualW% H%VirtualH%
				Gui, Show, X%VirtualX% Y%VirtualY% W%VirtualW% H%VirtualH%
				this.tmpGuiNum1 := GetFreeGUINum(10)
				Gui % this.tmpGuiNum1 ": Default"
				Gui, +AlwaysOnTop -caption +Border +ToolWindow +LastFound 
				WinSet, Transparent, 120 
				Gui, Color, 0x5090FF
				return -1
			}
			else if(this.tmpState = 1) ;Wait for mouse down
			{
				if(GetKeyState("LButton", "p"))
				{
					this.tmpState := 2				
					MouseGetPos, MX, MY
					this.tmpMX := MX
					this.tmpMY := MY
				}
				return -1
			}
			else if(this.tmpState = 2) ;Dragging
			{
				MouseGetPos, MXend, MYend 
				w := abs(this.tmpMX - MXend) 
				h := abs(this.tmpMY - MYend) 
				If ( this.tmpMX < MXend ) 
					X := this.tmpMX 
				Else 
					X := MXend 
				If ( this.tmpMY < MYend ) 
					Y := this.tmpMY 
				Else 
					Y := MYend 
				Gui, % this.tmpGuiNum1 ": Show", x%X% y%Y% w%w% h%h% 
				if(GetKeyState("LButton", "p")) ;Resize selection rectangle
				   return -1
				else ;Mouse release
				{
					Gui, % this.tmpGuiNum1 ": Destroy"
					If ( this.tmpMX > MXend ) 
					{ 
					   temp := this.tmpMX 
					   this.tmpMX := MXend 
					   MXend := temp 
					} 
					If ( this.tmpMY > MYend ) 
					{ 
					   temp := this.tmpMY 
					   this.tmpMY := MYend 
					   MYend := temp 
					} 
					Gui, % this.tmpGuiNum0 ": Destroy"
					Gui, % this.tmpGuiNum ": Destroy"
					pBitmap := Gdip_BitmapFromScreen(this.tmpMX "|" this.tmpMY "|" w "|" h)
					this.Remove("tmpMX")
					this.Remove("tmpMY")
					this.Remove("tmpGuiNum")
					this.Remove("tmpGuiNum0")
					this.Remove("tmpGuiNum1")
					this.Remove("tmpState")
				}
			}
		}
		Gdip_SaveBitmapToFile(pBitmap, TargetFolder "\" TargetFile, this.Quality)
		Gdip_DisposeImage(pBitmap)
		return 1
	} 

	DisplayString()
	{
		if(this.Area = "Screen")
			return "Take screenshot"
		else if(this.Area = "Window")
			return "Take screenshot of active window"
		else if(this.Area = "User selection")
			return "Take screenshot of user selected area"
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "DropDownList", "Area", "Screen|Window|User selection", "", "Area:")
			this.AddControl(GUI, "Edit", "Quality", "", "", "Quality:","","","","","0-100")
			this.AddControl(GUI, "Edit", "TargetFolder", "", "", "Target folder:", "Browse", "Action_Screenshot_Browse", "Placeholders", "Action_Screenshot_Placeholders_TargetFolder")
			this.AddControl(GUI, "Edit", "TargetFile", "", "", "Target file:", "Placeholders", "Action_Screenshot_Placeholders_TargetFile")
		}
		else if(GoToLabel = "Browse")
			this.Browse(sGUI, "TargetFolder")
		else if(GoToLabel = "Placeholders_TargetFolder")
			ShowPlaceholderMenu(sGUI, "TargetFolder")
		else if(GoToLabel = "Placeholders_TargetFile")
			ShowPlaceholderMenu(sGUI, "TargetFile")
	}
}
Action_Screenshot_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return

Action_Screenshot_Placeholders_TargetFolder:
GetCurrentSubEvent().GuiShow("", "Placeholders_TargetFolder")
return

Action_Screenshot_Placeholders_TargetFile:
GetCurrentSubEvent().GuiShow("", "Placeholders_TargetFile")
return
