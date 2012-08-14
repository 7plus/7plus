Class CORCondition Extends CCondition
{
	static Type := RegisterType(CORCondition, "OR")
	static Category := RegisterCategory(CORCondition, "Othe")
	static __WikiLink := "OR"
	Evaluate()
	{
		outputdebug % "Evaluate() should not get called on CORCondition!"
		return true
	}
	DisplayString()
	{
		return "OR"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "", "Use this condition to execute the event when the conditions before OR after this condition are true.")
	}
}