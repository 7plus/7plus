 Class CClipMenuAction Extends CAction
{
	static Type := RegisterType(CClipMenuAction, "Clipboard Manager menu")
	static Category := RegisterCategory(CClipMenuAction, "System")
	
	Execute(Event)
	{
		Notify("Deprecated Action", "The action " this.Type " is no longer supported! Please use the ""Show Menu"" action with the ClipboardMenu!", 5, NotifyIcons.Error)
		;~ if(!this.tmpShowing)
		;~ {
			;~ this.tmpShowing := true
			;~ ClipboardManagerMenu()
		;~ }
		;~ else if(!IsContextMenuActive()) ;Menu closed
		;~ {
			;~ this.tmpShowing := false
			;~ return 1
		;~ }
		;~ return -1 ;Waiting for menu to close
	} 

	DisplayString()
	{
		return "Show Clipboard Manager Menu"
	}
}