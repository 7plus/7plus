Class CAutoUpdateAction Extends CAction
{
	static Type := RegisterType(CAutoUpdateAction, "Check for updates")
	static Category := RegisterCategory(CAutoUpdateAction, "7plus")
	static __WikiLink := "AutoUpdate"
	Execute(Event)
	{
		AutoUpdate()
		return 1
	} 
	DisplayString()
	{
		return "7plus Autoupdate"
	}
}
