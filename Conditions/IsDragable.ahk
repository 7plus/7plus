Class CIsDragableCondition Extends CCondition
{
	static Type := RegisterType(CIsDragableCondition, "Window is dragable")
	static Category := RegisterCategory(CIsDragableCondition, "Window")
	static __WikiLink := "IsDragable"
	Evaluate()
	{
		MouseGetPos,,,win
		WinGet,style,style,ahk_id %win%
		if(style & 0x80000000 && !(style & 0x00400000 || style & 0x00800000 || style & 0x00080000)) ;WS_POPUP && !WS_DLGFRAME && !WS_BORDER && !WS_SYSMENU
			return false
		WinGet, State, MinMax, ahk_id %win% 
		if(State != 0)
			return false
		class := WinGetClass("ahk_id " win)
		;Notepad++ and SciTE use Alt+LButton for rectangular text selection and should not be dragged by the default alt+mouse button hotkeys for this action.
		;It might be preferable though to move this into a separate condition.
		if(class = "Notepad++" || class = "SciTEWindow")
			return false
		if(IsFullScreen())
			return false
		return true
	}
	DisplayString()
	{
		return "Window under mouse is dragable/resizeable"
	}
}
