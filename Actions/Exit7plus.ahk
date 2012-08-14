Class CExit7plusAction Extends CAction
{
	static Type := RegisterType(CExit7plusAction, "Exit 7plus")
	static Category := RegisterCategory(CExit7plusAction, "7plus")
	static __WikiLink := "Exit7plus"
	Execute(Event)
	{
		GoSub ExitSub
		return 1
	} 
	DisplayString()
	{
		return "Exit 7plus"
	}
}
