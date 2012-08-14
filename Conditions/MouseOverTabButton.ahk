Class CMouseOverTabButtonCondition Extends CCondition
{
	static Type := RegisterType(CMouseOverTabButtonCondition, "Mouse over tab button")
	static Category := RegisterCategory(CMouseOverTabButtonCondition, "Mouse")
	static __WikiLink := "MouseOverTabButton"
	
	Evaluate()
	{
		return IsMouseOverTabButton()
	}
	DisplayString()
	{
		return "Mouse is over Explorer tab button"
	}
}
