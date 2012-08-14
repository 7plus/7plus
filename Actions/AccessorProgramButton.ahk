Class CAccessorProgramButtonAction Extends CAction
{
	static Type := RegisterType(CAccessorProgramButtonAction, "AccessorProgramButton")
	static Category := RegisterCategory(CAccessorProgramButtonAction, "7plus")
	static __WikiLink := "AccessorProgramButton"
	static Slot := 1
	
	DisplayString()
	{
		return "Run Accessor program/file/folder button"
	}
	
	Execute(Event)
	{
		CAccessor.Instance.ProgramButtons[this.Slot].Execute()
		return 1
	}
	
	GuiShow(GUI)
	{
		this.AddControl(GUI, "DropDownList", "Slot", "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18", "", "Slot:")
	}
}