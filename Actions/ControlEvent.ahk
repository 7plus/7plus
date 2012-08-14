Class CControlEventAction Extends CAction
{
	static Type := RegisterType(CControlEventAction, "Control event")
	static Category := RegisterCategory(CControlEventAction, "7plus")
	static _ImplementsIf := ImplementIfInterface(CControlEventAction)
	static Action := "Enable Event"
	static Compare := ""
	static EventID := ""
	static EvaluateOnCopy := 1
	static Placeholder := ""
	static DeleteAfterUse := 1
	
	Execute(Event)
	{
		if(this.IfEvaluate(Event))
		{
			TargetEvent := EventSystem.Events.GetItemWithValue("ID", Event.ExpandPlaceholders(this.EventID))
			if(this.Action = "Enable Event")
				TargetEvent.Enable()
			else if(this.Action = "Disable Event")
				TargetEvent.Disable()
			else if(this.Action = "Toggle Enable/Disable")
			{
				if(TargetEvent.Enabled)
					TargetEvent.Disable()
				else
					TargetEvent.Enable()
			}
			else if(this.Action = "Trigger Event")
			{
				Trigger := new CTriggerTrigger()
				Trigger.TargetID := this.EventID
				EventSystem.OnTrigger(Trigger)
			}
			else if(this.Action = "Copy Event")
			{
				Copy := EventSystem.TemporaryEvents.RegisterEvent(TargetEvent.DeepCopy(), 0)
				Copy.DeleteAfterUse := this.DeleteAfterUse
				;Placeholders may be evaluated at the time of the copy operation, 
				;so they don't use placeholders which may have changed in the meantime
				if(this.EvaluateOnCopy)
					objDeepPerform(Copy, "ExpandPlaceHolders", Copy)
				EventSystem.GlobalPlaceholders[this.Placeholder] := Copy.ID
			}
		}
		return 1
	} 

	DisplayString()
	{
		return this.Action ": " this.EventID ": " SettingsWindow.Events.GetItemWithValue("ID", this.EventID).Name	
	}

	GuiShow(GUI, GoToLabel = "")
	{
		if(GoToLabel = "")
		{
			this.tmpGUI := GUI
			this.tmpPreviousSelection := ""
			this.AddControl(GUI, "Text", "Desc", "This action can do various stuff with other events. It is only performed if the condition below is matched. Leave both text fields empty to always perform it.")
			this.IfGuiShow(GUI)
			this.AddControl(GUI, "DropDownList", "Action", "Copy Event|Disable Event|Enable Event|Toggle Enable/Disable|Trigger Event", "Action_ControlEvent_SelectionChange", "Action:")
			this.AddControl(GUI, "ComboBox", "EventID", "TriggerType:", "", "Event:")
			this.GuiShow("", "ControlEvent_SelectionChange")
		}
		else if(GoToLabel = "ControlEvent_SelectionChange")
		{
			ControlGetText, Action, , % "ahk_id " this.tmpGUI.DropDown_Action
			if(Action = "Copy Event")
			{
				if(Action != this.tmpPreviousSelection)
				{
					this.EvaluateOnCopy := true
					this.DeleteAfterUse := true
					this.AddControl(this.tmpGUI, "Text", "Text", "Copied event is stored in placeholder (Enter without ${})")
					this.AddControl(this.tmpGUI, "Edit", "Placeholder", "", "", "Placeholder:")
					this.AddControl(this.tmpGUI, "Checkbox", "EvaluateOnCopy", "Evaluate placeholders when copying to make them use the current value")
					this.AddControl(this.tmpGUI, "Checkbox", "DeleteAfterUse", "Delete copy after use")
				}
			}
			else
			{
				if(this.tmpPreviousSelection = "Window")
					this.tmpGUI.y := this.tmpGUI.y - 130
			}
			this.tmpPreviousSelection := Action
		}
	}
	GuiSubmit(GUI)
	{
		this.IfGuiSubmit(GUI)
		this.Remove("tmpGUI")
		this.Remove("tmpPreviousSelection")
		Base.GuiSubmit(GUI)
	}
}
Action_ControlEvent_SelectionChange:
GetCurrentSubEvent().GuiShow("","ControlEvent_SelectionChange")
return