Class CExplorerPathChangedTrigger Extends CTrigger
{
	static Type := RegisterType(CExplorerPathChangedTrigger, "Explorer path changed")
	static Category := RegisterCategory(CExplorerPathChangedTrigger, "Explorer")
	Matches(Filter)
	{
		return true ;type is checked elsewhere
	}
}