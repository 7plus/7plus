Class CIfCondition Extends CCondition
{
	static Type := RegisterType(CIfCondition, "If")
	static Category := RegisterCategory(CIfCondition, "Other")
	static _ImplementsIf := ImplementIfInterface(CIfCondition)
	
	Evaluate(Event)
	{
		return this.IfEvaluate(Event)
	}
	
	DisplayString()
	{
		return this.IfDisplayString()
	}

	GuiShow(GUI, GoToLabel="")
	{
		this.IfGuiShow(GUI)
	}
}