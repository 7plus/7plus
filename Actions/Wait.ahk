Class CWaitAction Extends CAction
{
	static Type := RegisterType(CWaitAction, "Wait")
	static Category := RegisterCategory(CWaitAction, "7plus")
	static __WikiLink := "Wait"
	static Time := 1000
	
	Execute(Event)
	{
		if(!this.tmpStartTime) ;First trigger, store start time
		{
			this.tmpStartTime := A_TickCount
			return -1
		}
		else if(A_TickCount > this.tmpStartTime + this.Time) ;If wait time has run out
		{
			this.Time := 0
			return 1
		}
		else ;Still waiting
			return -1
	}
	DisplayString()
	{
		return "Wait " this.Time "ms"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This action waits by a specified amount of time. Afterwards the next event is executed.")
		this.AddControl(GUI, "Edit", "Time", "", "", "Time (ms):", "", "")
	}
}