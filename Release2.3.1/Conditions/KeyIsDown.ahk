Class CKeyIsDownCondition Extends CCondition
{
	static Type := RegisterType(CKeyIsDownCondition, "Key is down")
	static Category := RegisterCategory(CKeyIsDownCondition, "Other")
	static Physical := 1
	static Toggle := 0
	static Key := ""
	
	Evaluate(Event)
	{
		return GetKeyState(this.Key, (this.Toggle ? "T" : (this.Physical ? "P" : "")))
	}
	DisplayString()
	{
		return this.Key " is " (this.Toggle ? "on" : "down")
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "Edit", "Key", "", "", "Key:", "Key names", "KeyNames")
		this.AddControl(GUI, "Checkbox", "Physical", "Use physical keystate")
		this.AddControl(GUI, "Checkbox", "Toggle", "Use toggle state (capslock,numlock, etc only)")
	}
}
KeyNames:
run http://www.autohotkey.com/docs/KeyList.htm,,UseErrorLevel
return
