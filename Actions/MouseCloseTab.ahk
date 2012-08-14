Class CMouseCloseTabAction Extends CAction
{
	static Type := RegisterType(CMouseCloseTabAction, "Close tab under mouse")
	static Category := RegisterCategory(CMouseCloseTabAction, "Explorer")
	static __WikiLink := "MouseCloseTab"
	
	Execute(Event)
	{
		MouseCloseTab()
	}
	DisplayString()
	{
		return "Close explorer tab under mouse"
	}
}
