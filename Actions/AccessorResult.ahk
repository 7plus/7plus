;Action used to execute an Accessor result (timed one)
Class CAccessorResultAction Extends CAction
{
	static Type := RegisterType(CAccessorAction, "Execute Accessor Result")
	static Category := RegisterCategory(CAccessorAction, "7plus")
	static __WikiLink := "AccessorResult"
	
	Execute(Event)
	{
		if(this.Result && this.Action)
		{
			CAccessor.Instance.PerformAction(this.Action, this.Result)
		}
		return true
	}

	DisplayString()
	{
		return this.Type
	}
}
