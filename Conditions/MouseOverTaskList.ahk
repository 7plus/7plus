Class CMouseOverTaskList Extends CCondition
{
	static Type := RegisterType(CMouseOverTaskList, "Mouse over taskbar list")
	static Category := RegisterCategory(CMouseOverTaskList, "Mouse")
	Evaluate()
	{
		return IsMouseOverTaskList()
	}
	DisplayString()
	{
		return "Mouse is over task list"
	}
}