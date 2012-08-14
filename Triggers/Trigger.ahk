Class CTriggerTrigger extends CTrigger
{
	static Type := RegisterType(CTriggerTrigger, "Triggered by an action")
	static Category := RegisterCategory(CTriggerTrigger, "7plus")
	
	Matches(Filter)
	{
		return false ;This trigger is only be triggered by trigger actions which are handled elsewhere.
	}

	DisplayString()
	{
		return "Triggered by a trigger action"
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Text", "This trigger type can only be triggered by a trigger action.", "", "")
	}
}