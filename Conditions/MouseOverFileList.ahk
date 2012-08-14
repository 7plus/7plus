Class CMouseOverFileList Extends CCondition
{
	static Type := RegisterType(CMouseOverFileList, "Mouse over file list")
	static Category := RegisterCategory(CMouseOverFileList, "Mouse")
	static __WikiLink := "MouseOverFileList"
	Evaluate()
	{
		return IsMouseOverFileList()
	}
	DisplayString()
	{
		return "Mouse is over explorer/file dialog file list"
	}
}
