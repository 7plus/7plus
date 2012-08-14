Class CFastFoldersMenuAction Extends CAction
{
	static Type := RegisterType(CFastFoldersMenuAction, "Fast Folders menu")
	static Category := RegisterCategory(CFastFoldersMenuAction, "Fast Folders")
	
	Execute(Event)
	{
		MsgBox Fast Folders menu action: This action is deprecated. Please use Accessor for FastFolders! 
		return 1
		;if(!this.tmpShowing)
		;{
		;	this.tmpShowing := true
		;	FastFolderMenu()
		;}
		;else if(!IsContextMenuActive()) ;Menu closed
		;{
		;	this.tmpShowing := false
		;	return 1
		;}
		;return -1 ;Waiting for menu to close
	}

	DisplayString()
	{
		return "Deprecated: Show Fast Folders menu"
	}
}