Class CMouseWindowDragAction Extends CAction
{
	static Type := RegisterType(CMouseWindowDragAction, "Drag window with mouse")
	static Category := RegisterCategory(CMouseWindowDragAction, "Window")
	static __WikiLink := "MouseWindowDrag"
	
	Execute(Event)
	{
		if(this.HasKey("tmpDraggingWindow") && this.tmpDraggingWindow = false) ;This only happens when the event has finished already
			return 1
		else if(this.HasKey("tmpDraggingWindow")) ;Dragging still in progress
			return -1
		for index, QueuedEvent in EventSystem.EventSchedule ;Make sure no drag event is in progress
		{
			if(QueuedEvent.ID = Event.ID)
				continue
			if(QueuedEvent.Actions.GetItemWithValue("Type", "MouseWindowResize").HasKey("tmpResizingWindow") || QueuedEvent.Actions.GetItemWithValue("Type", "MouseWindowDrag").HasKey("tmpDraggingWindow"))
				return 0
		}
		this.tmpDraggingWindow := true
		CoordMode, Mouse, Screen
		MouseGetPos, Drag_OriginalMouseX, Drag_OriginalMouseY, Drag_HWND
		WinGetPos, Drag_OriginalWindowX, Drag_OriginalWindowY,,, ahk_id %Drag_HWND%
		this.tmpOriginalMouseX := Drag_OriginalMouseX
		this.tmpOriginalMouseY := Drag_OriginalMouseY
		this.tmpOriginalWindowX := Drag_OriginalWindowX
		this.tmpOriginalWindowY := Drag_OriginalWindowY
		this.tmpHWND := Drag_HWND
		this.tmpActiveWindow := WinExist("A")
		SetTimer, Action_MouseWindowDrag_Timer, 10
		return -1
	}
	DragLoop(Event)
	{
		Key := ExtractKey(Event.Trigger.Is(CHotkeyTrigger) && Event.Trigger.Key ? Event.Trigger.Key : "LButton")
		GetKeyState, KeyState, %Key%, P
		if(KeyState = "U")  ; Button has been released, so drag is complete.
		{
			SetTimer, Action_MouseWindowDrag_Timer, off
			this.tmpDraggingWindow := false ;This will make Execute() return 1 to finish the drag action.
			return
		}
		GetKeyState, EscapeState, Escape, P
		if(EscapeState = "D" || WinExist("A") != this.tmpActiveWindow)  ; Escape has been pressed or another program was activated, so drag is cancelled.
		{
			OutputDebug % "Active " WinExist("A") " temp: " this.tmpActiveWindow
			SetTimer, Action_MouseWindowDrag_Timer, off
			WinMove, % "ahk_id " this.tmpHWND,, % this.tmpOriginalWindowX, % this.tmpOriginalWindowY
			this.tmpDraggingWindow := false ;This will make Execute() return 1 to finish the drag action.
			return
		}
		
		;Do the dragging
		CoordMode, Mouse, Screen
		MouseGetPos, MouseX, MouseY
		WinGetPos, WinX, WinY,,, % "ahk_id " this.tmpHWND
		SetWinDelay, -1 
		newx := this.tmpOriginalWindowX + MouseX - this.tmpOriginalMouseX
		newy := this.tmpOriginalWindowY + MouseY - this.tmpOriginalMouseY
		if(abs(MouseX - this.tmpOriginalMouseX) > 10 || abs(MouseY - this.tmpOriginalMouseY) > 10) ;Allow alt-left clicks
			WinMove, % "ahk_id " this.tmpHWND,, newx, newy
	}
	DisplayString()
	{
		return "Drag window under cursor with mouse"
	}
}
Action_MouseWindowDrag_Timer:
MouseWindowDragRouter()
return

MouseWindowDragRouter()
{
	EventSystem.EventFromSubEventKey(Event, Action, "tmpDraggingWindow", true, "A")
	Action.DragLoop(Event)
}
