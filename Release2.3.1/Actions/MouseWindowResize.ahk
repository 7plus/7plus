Class CMouseWindowResizeAction Extends CAction
{
	static Type := RegisterType(CMouseWindowResizeAction, "Resize window with mouse")
	static Category := RegisterCategory(CMouseWindowResizeAction, "Window")
	
	Execute(Event)
	{
		if(this.HasKey("tmpResizingWindow") && this.tmpResizingWindow = false) ;This only happens when the event has finished already
			return 1
		else if(this.HasKey("tmpResizingWindow")) ;Resizing still in progress
			return -1
		for index, QueuedEvent in EventSystem.EventSchedule ;Make sure no Resize event is in progress
		{
			if(QueuedEvent.ID = Event.ID)
				continue
			if(QueuedEvent.Actions.GetItemWithValue("Type", "MouseWindowResize").HasKey("tmpResizingWindow") || QueuedEvent.Actions.GetItemWithValue("Type", "MouseWindowDrag").HasKey("tmpDraggingWindow"))
				return 0
		}
		this.tmpResizingWindow := true
		CoordMode, Mouse, Screen
		MouseGetPos, Drag_OriginalMouseX, Drag_OriginalMouseY, Drag_HWND
		WinGetPos, Drag_OriginalWindowX, Drag_OriginalWindowY,Drag_OriginalWindowW,Drag_OriginalWindowH, ahk_id %Drag_HWND%
		this.tmpOriginalMouseX := Drag_OriginalMouseX
		this.tmpOriginalMouseY := Drag_OriginalMouseY
		this.tmpOriginalWindowX := Drag_OriginalWindowX
		this.tmpOriginalWindowY := Drag_OriginalWindowY
		this.tmpOriginalWindowW := Drag_OriginalWindowW
		this.tmpOriginalWindowH := Drag_OriginalWindowH
		this.tmpLeft := Drag_OriginalMouseX < Drag_OriginalWindowX + Drag_OriginalWindowW / 2
		this.tmpTop := Drag_OriginalMouseY < Drag_OriginalWindowY + Drag_OriginalWindowH / 2
		this.tmpHWND := Drag_HWND
		this.tmpActiveWindow := WinExist("A")
		SetTimer, Action_MouseWindowResize_Timer, 10
		return -1
	} 
	ResizeLoop(Event)
	{
		Key := ExtractKey(Event.Trigger.Is(CHotkeyTrigger) && Event.Trigger.Key ? Event.Trigger.Key : "LButton")
		GetKeyState, KeyState, %Key%, P
		if(KeyState = "U")  ; Button has been released, so Resize is complete.
		{
			SetTimer, Action_MouseWindowResize_Timer, off
			this.tmpResizingWindow := false ;This will make Execute() return 1 to finish the Resize action.
			return
		}
		GetKeyState, EscapeState, Escape, P
		if(EscapeState = "D" || WinExist("A") != this.tmpActiveWindow)  ; Escape has been pressed or another program was activated, so Resize is cancelled.
		{
			SetTimer, Action_MouseWindowResize_Timer, off
			WinMove, % "ahk_id " this.tmpHWND,, % this.tmpOriginalWindowX, % this.tmpOriginalWindowY, % this.tmpOriginalWindowW, % this.tmpOriginalWindowH
			this.tmpResizingWindow := false ;This will make Execute() return 1 to finish the Resize action.
			return
		}
		
		;Do the resizing
		CoordMode, Mouse, Screen
		MouseGetPos, MouseX, MouseY
		WinGetPos, WinX, WinY,,, % "ahk_id " this.tmpHWND
		SetWinDelay, -1 
		newx := this.tmpLeft ? this.tmpOriginalWindowX + MouseX - this.tmpOriginalMouseX : this.tmpOriginalWindowX
		newy := this.tmpTop ? this.tmpOriginalWindowY + MouseY - this.tmpOriginalMouseY : this.tmpOriginalWindowY
		neww := this.tmpLeft ? this.tmpOriginalWindowW + this.tmpOriginalWindowX - newx  : this.tmpOriginalWindowW + MouseX - this.tmpOriginalMouseX 
		newh := this.tmpTop ? this.tmpOriginalWindowH + this.tmpOriginalWindowY - newy  : this.tmpOriginalWindowH + MouseY - this.tmpOriginalMouseY 
		if(abs(MouseX - this.tmpOriginalMouseX) > 10 || abs(MouseY - this.tmpOriginalMouseY) > 10)
			WinMove, % "ahk_id " this.tmpHWND,, newx, newy, neww, newh
	}
	DisplayString()
	{
		return "Resize window under cursor with mouse"
	}
}
Action_MouseWindowResize_Timer:
MouseWindowResizeRouter()
return

MouseWindowResizeRouter()
{
	EventSystem.EventFromSubEventKey(Event, Action, "tmpResizingWindow", true, "A")
	Action.ResizeLoop(Event)
}