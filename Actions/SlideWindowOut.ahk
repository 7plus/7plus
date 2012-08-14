Class CSlideWindowOutAction Extends CAction
{
	static Type := RegisterType(CSlideWindowOutAction, "Move Slide Window out of screen")
	static Category := RegisterCategory(CSlideWindowOutAction, "Window")
	static Direction := 1 ;Left
	
	Execute()
	{
		global SlideWindows
		hwnd := WinExist("A")
		SlideWindow := SlideWindows.GetByWindowHandle(hwnd, ChildIndex)
		if(IsObject(SlideWindow))
		{
			if(this.Direction = SlideWindow.Direction)
				SlideWindow.SlideOut()
			else if(abs(this.Direction - SlideWindow.Direction) = 2) ;Opposite direction
				SlideWindow.Release()
			return 1
		}
		SlideWindow := new CSlideWindow(hwnd, this.Direction)
		if(IsObject(SlideWindow))
			SlideWindows.Insert(SlideWindow)
		return 1
	} 

	DisplayString()
	{
		return "Slide active window out of the screen"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This action slides windows out of the screen (if possible) or releases slide windows")
		this.AddControl(GUI, "DropDownList", "Direction", "1: Left|2: Top|3: Right|4: Bottom", "", "Direction:")
	}
}