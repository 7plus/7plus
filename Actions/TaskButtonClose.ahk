Class CTaskButtonClose Extends CAction
{
	static Type := RegisterType(CTaskButtonClose, "Close taskbar button under mouse")
	static Category := RegisterCategory(CTaskButtonClose, "Window")
	static __WikiLink := "TaskButtonClose"
	
	Execute(Event)
	{
		;This action prevents further actions from happening if a task is successfully closed.
		return TaskButtonClose()
	}
	DisplayString()
	{
		return "Close window belonging to task button under the mouse"
	}
}
