Class CRestoreSelectionAction Extends CAction
{
	static Type := RegisterType(CRestoreSelectionAction, "Restore file selection")
	static Category := RegisterCategory(CRestoreSelectionAction, "Explorer")
	static __WikiLink := "RestoreSelection"
	
	Execute(Event)
	{
		RestoreExplorerSelection()
		return 1
	} 
	DisplayString()
	{
		return "Restore file selection"
	}
}
