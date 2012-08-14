Class CMouseOverTaskList Extends CCondition
{
	static Type := RegisterType(CMouseOverTaskList, "Mouse over taskbar list")
	static Category := RegisterCategory(CMouseOverTaskList, "Mouse")
	static __WikiLink := "MouseOverTaskList"
	Evaluate()
	{
		return IsMouseOverTaskList()
	}
	DisplayString()
	{
		return "Mouse is over task list"
	}
}
