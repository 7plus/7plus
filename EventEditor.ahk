;Gets the event which is currently being edited by the GUI Name of the editor window
GetCurrentSubEvent()
{
	if(!IsObject(EventEditor := CGUI.GUIList[A_GUI]))
	{
		Notify("Event Editor Error!", "Can't find the trigger/condition or action of the currently edited event because the event editor was not found!", 5, NotifyIcons.Error)
		return
	}
	CurrentTab := EventEditor.Tab.SelectedItem.Text
	if(CurrentTab = "Trigger")
		return EventEditor.Event.Trigger
	else if(CurrentTab = "Conditions")
		return EventEditor.Event.Conditions[EventEditor.listConditions.SelectedIndex]
	else if(CurrentTab = "Actions")
		return EventEditor.Event.Actions[EventEditor.listActions.SelectedIndex]
	return 
}
Class CEventEditor extends CGUI
{
	;Some controls use | in text so newline is used as delimiter
	Delimiter := "`n"
	btnOK := this.AddControl("Button", "btnOK", "x729 y557 w70 h23", "&OK")
	btnCancel := this.AddControl("Button", "btnCancel", "x809 y557 w80 h23", "&Cancel")
	Tab := this.AddControl("Tab", "Tab", "x17 y8 w872 h512", "Trigger`nConditions`nActions`nOptions")
	
	;Trigger controls
	txtTrigger := this.Tab.Tabs[1].AddControl("Text", "txtTrigger", "x31 y36", "Here you can define how this event gets triggered.")
	txtTriggerCategory := this.Tab.Tabs[1].AddControl("Text", "txtTriggerCategory", "x31 y60", "Category:")
	txtTriggerTrigger := this.Tab.Tabs[1].AddControl("Text", "txtTriggerTrigger", "x31 y90", "Trigger:")
	ddlTriggerCategory := this.Tab.Tabs[1].AddControl("DropDownList", "ddlTriggerCategory", "x101 y56 w300", "")
	ddlTriggerType := this.Tab.Tabs[1].AddControl("DropDownList", "ddlTriggerType", "x101 y86 w300", "")
	btnTriggerHelp := this.Tab.Tabs[1].AddControl("Button", "btnTriggerHelp", "x+10 y85", "Help")
	grpTriggerOptions := this.Tab.Tabs[1].AddControl("GroupBox", "grpTriggerOptions", "x31 y116 w846 h384", "Options")
	
	;Condition controls
	txtCondition := this.Tab.Tabs[2].AddControl("Text", "txtCondition", "x31 y36", "The conditions below must be fullfilled to allow this event to execute.")
	listConditions := this.Tab.Tabs[2].AddControl("ListBox", "listConditions", "x31 y56 w270 h454", "")
	btnAddCondition := this.Tab.Tabs[2].AddControl("Button", "btnAddCondition", "x311 y56 w90", "Add Condition")
	btnDeleteCondition := this.Tab.Tabs[2].AddControl("Button", "btnDeleteCondition", "x311 y86 w90", "Delete Condition")
	btnAddOR := this.Tab.Tabs[2].AddControl("Button", "btnAddOR", "x311 y116 w90", "Add OR branch")
	btnCopyCondition := this.Tab.Tabs[2].AddControl("Button", "btnCopyCondition", "x311 y146 w90", "Copy Condition")
	btnPasteCondition := this.Tab.Tabs[2].AddControl("Button", "btnPasteCondition", "x311 y176 w90", "Paste Condition")
	btnMoveConditionUp := this.Tab.Tabs[2].AddControl("Button", "btnMoveConditionUp", "x311 y206 w90", "Move Up")
	btnMoveConditionDown := this.Tab.Tabs[2].AddControl("Button", "btnMoveConditionDown", "x311 y236 w90", "Move Down")
	txtCondition2 := this.Tab.Tabs[2].AddControl("Text", "txtCondition2", "x431 y36", "Here you can define the selected condition.")
	chkNegateCondition := this.Tab.Tabs[2].AddControl("Checkbox", "chkNegateCondition", "x431 y56", "Negate Condition")
	txtConditionCategory := this.Tab.Tabs[2].AddControl("Text", "txtConditionCategory", "x431 y89", "Category:")
	txtConditionType := this.Tab.Tabs[2].AddControl("Text", "txtConditionType", "x431 y119", "Condition:")
	ddlConditionCategory := this.Tab.Tabs[2].AddControl("DropDownList", "ddlConditionCategory", "x501 y86 w300", "")
	btnConditionHelp := this.Tab.Tabs[2].AddControl("Button", "btnConditionHelp", "x+10 y114", "Help")
	ddlConditionType := this.Tab.Tabs[2].AddControl("DropDownList", "ddlConditionType", "x501 y116 w300", "")
	grpConditionOptions := this.Tab.Tabs[2].AddControl("GroupBox", "grpConditionOptions", "x431 y146 w446 h364", "Options")
	
	;Action controls
	txtAction := this.Tab.Tabs[3].AddControl("Text", "txtAction", "x31 y36", "These actions will be executed when the event gets triggered.")
	listActions := this.Tab.Tabs[3].AddControl("ListBox", "listActions", "x31 y56 w270 h454 -Multi", "")
	btnAddAction := this.Tab.Tabs[3].AddControl("Button", "btnAddAction", "x311 y56 w90", "Add Action")
	btnDeleteAction := this.Tab.Tabs[3].AddControl("Button", "btnDeleteAction", "x311 y86 w90", "Delete Action")
	btnCopyAction := this.Tab.Tabs[3].AddControl("Button", "btnCopyAction", "x311 y116 w90", "Copy Action")
	btnPasteAction := this.Tab.Tabs[3].AddControl("Button", "btnPasteAction", "x311 y146 w90", "Paste Action")
	btnMoveActionUp := this.Tab.Tabs[3].AddControl("Button", "btnMoveActionUp", "x311 y176 w90", "Move Up")
	btnMoveActionDown := this.Tab.Tabs[3].AddControl("Button", "btnMoveActionDown", "x311 y206 w90", "Move Down")
	txtAction2 := this.Tab.Tabs[3].AddControl("Text", "txtAction2", "x431 y36", "Here you can define what this action does.")
	txtActionCategory := this.Tab.Tabs[3].AddControl("Text", "txtActionCategory", "x431 y60", "Category:")
	txtActionType := this.Tab.Tabs[3].AddControl("Text", "txtActionType", "x431 y90", "Action:")
	ddlActionCategory := this.Tab.Tabs[3].AddControl("DropDownList", "ddlActionCategory", "x501 y56 w300", "")
	btnActionHelp := this.Tab.Tabs[3].AddControl("Button", "btnActionHelp", "x+10 y85", "Help")
	ddlActionType := this.Tab.Tabs[3].AddControl("DropDownList", "ddlActionType", "x501 y86 w300", "")
	grpActionOptions := this.Tab.Tabs[3].AddControl("GroupBox", "grpActionOptions", "x431 y116 w446 h394", "Options")
	
	;Option controls
	txtEventName := this.Tab.Tabs[4].AddControl("Text", "txtEventName", "x31 y48", "Event Name:")
	editEventName := this.Tab.Tabs[4].AddControl("Edit", "editEventName", "x131 y44 w300", "")
	txtEventDescription := this.Tab.Tabs[4].AddControl("Text", "txtEventDescription", "x31 y74", "Event Description:")
	editEventDescription := this.Tab.Tabs[4].AddControl("Edit", "editEventDescription", "x131 y70 w300 h60 Multi", "")
	txtEventCategory := this.Tab.Tabs[4].AddControl("Text", "txtEventCategory", "x31 y140", "Event Category:")
	comboEventCategory := this.Tab.Tabs[4].AddControl("ComboBox", "comboEventCategory", "x131 y139 w300", "")
	chkDisableEventAfterUse := this.Tab.Tabs[4].AddControl("CheckBox", "chkDisableEventAfterUse", "x31 y166", "Disable after use")
	chkDeleteEventAfterUse := this.Tab.Tabs[4].AddControl("CheckBox", "chkDeleteEventAfterUse", "x31 y196", "Delete after use")
	chkEventOneInstance := this.Tab.Tabs[4].AddControl("CheckBox", "chkEventOneInstance", "x31 y226", "Disallow this event from being run in parallel")
	chkComplexEvent := this.Tab.Tabs[4].AddControl("CheckBox", "chkComplexEvent", "x31 y256", "Advanced event (hidden from simple view)")
	
	;SubeventGUIs contain information about specific subparts of the GUI which are handled by the sub-events like triggers, conditions and actions
	TriggerGUI := ""
	ConditionGUI := ""
	ActionGUI := ""
	__New(Event, TemporaryEvent)
	{
		if(!Event)
		{
			Notify("Event Editor Error!", "Event not found!", 5, NotifyIcons.Error)
			this.Result := ""
			this.Close()
		}
		this.Event := Event
		this.TemporaryEvent := TemporaryEvent

		;Disable the settings window that opened this dialog if it exists
		SettingsWindow.Enabled := false
		this.Owner := SettingsWindow.hwnd
		;Setup control states
		;Initialize trigger tab (categories and types and trigger gui)
		IndexToSelect := 1
		for CategoryName, Category in CTrigger.Categories
		{
			this.ddlTriggerCategory.Items.Add(CategoryName)
			if(CategoryName = this.Event.Trigger.Category)
				IndexToSelect := A_Index
		}
		this.ddlTriggerCategory.SelectedIndex := IndexToSelect
		
		;Initilialize conditions tab (conditions, categories, types and condition gui)
		if(!IsObject(ConditionClipboard))
			this.btnPasteCondition.Enabled := false
		
		;Fill conditions list
		for index, Condition in this.Event.Conditions
			this.listConditions.Items.Add((Condition.Negate ? "NOT " : "" ) ToSingleLine(Condition.DisplayString())

		;Fill condition categories
		for CategoryName, Category in CCondition.Categories
			this.ddlConditionCategory.Items.Add(CategoryName)
		
		if(this.listConditions.Items.MaxIndex())
			this.listConditions.SelectedIndex := 1
		else
		{
			this.ddlConditionCategory.Enabled := false
			this.ddlConditionType.Enabled := false
			this.chkNegateCondition.Enabled := false
			this.chkNegateCondition.Checked := false
			this.btnDeleteCondition.Enabled := false
			this.btnCopyCondition.Enabled := false
			this.btnMoveConditionDown.Enabled := false
			this.btnMoveConditionUp.Enabled := false
		}
		this.btnPasteCondition.Enabled := IsObject(EventSystem.ConditionClipboard)
		
		AssignHotkeyToControl(this.listConditions.hwnd, "Delete", "EventEditor_DeleteCondition")
		
		;Initilialize actions tab (actions, categories, types and action gui)
		if(!IsObject(ActionClipboard))
			this.btnPasteAction.Enabled := false
		
		;Fill actions list
		for index, Action in this.Event.Actions
			this.listActions.Items.Add(ToSingleLine(Action.DisplayString()))
		
		;Fill action categories
		for CategoryName, Category in CAction.Categories
			this.ddlActionCategory.Items.Add(CategoryName)
		
		if(this.listActions.Items.MaxIndex())
			this.listActions.SelectedIndex := 1
		else
		{
			this.ddlActionCategory.Enabled := false
			this.ddlActionType.Enabled := false
			this.btnDeleteAction.Enabled := false
			this.btnCopyAction.Enabled := false
			this.btnMoveActionDown.Enabled := false
			this.btnMoveActionUp.Enabled := false
		}
		this.btnPasteAction.Enabled := IsObject(EventSystem.ActionClipboard)
		
		AssignHotkeyToControl(this.listActions.hwnd, "Delete", "EventEditor_DeleteAction")
		
		;Initialize options tab
		this.editEventName.Text := this.Event.Name
		this.editEventDescription.Text := this.Event.Description
		for index, Category in SettingsWindow.Events.Categories
			this.comboEventCategory.Items.Add(Category)
		this.comboEventCategory.Text := Event.Category
		
		this.chkDisableEventAfterUse.Checked := Event.DisableAfterUse = 1
		this.chkDeleteEventAfterUse.Checked := Event.DeleteAfterUse = 1
		this.chkEventOneInstance.Checked := Event.OneInstance = 1
		this.chkComplexEvent.Checked := Event.EventComplexityLevel = 1
		
		
		;Setup some window options
		this.DestroyOnClose := true
		this.CloseOnEscape := true
		this.Title := "Event Editor"
		this.Show()
	}
	
	btnOK_Click()
	{
		this.SubmitTrigger()
		if(this.HasKey("Condition"))
			this.SubmitCondition()
		if(this.HasKey("Action"))
			this.SubmitAction()
		this.Event.Name := this.editEventName.Text
		this.Event.Description := this.editEventDescription.Text
		this.Event.Category := this.comboEventCategory.Text ? this.comboEventCategory.Text : "Uncategorized"
		this.Event.DisableAfterUse := this.chkDisableEventAfterUse.Checked
		this.Event.DeleteAfterUse := this.chkDeleteEventAfterUse.Checked
		this.Event.OneInstance := this.chkEventOneInstance.Checked
		this.Event.EventComplexityLevel := this.chkComplexEvent.Checked
		this.Result := this.Event
		this.Close()
	}
	btnCancel_Click()
	{
		this.Result := ""
		this.Close()
	}
	PreClose()
	{
		;Enable the settings window that opened this dialog if it exists
		SettingsWindow.Enabled := true
		SettingsWindow.FinishEditing(this.Result, this.TemporaryEvent)
	}



	/*
	Trigger
	*/

	ddlTriggerCategory_SelectionChanged(Item)
	{
		if(this.TriggerGUI) ;if a trigger is already showing a gui, check if the new one is different
			if(this.Event.Trigger.Category = Item.Text) ;selecting same item, ignore
				return
		
		;Get all triggers of the new category
		category := CTrigger.Categories[Item.Text]
		
		this.ddlTriggerType.DisableNotifications := true
		this.ddlTriggerType.Items.Clear()
		IndexToSelect := 1
		for index, Trigger in CTrigger.Categories[Item.Text]
		{
			this.ddlTriggerType.Items.Add(Trigger.Type)
			if(this.Event.Trigger.Type = Trigger.Type)
				IndexToSelect := index
		}
		this.ddlTriggerType.DisableNotifications := false
		this.ddlTriggerType.SelectedIndex := IndexToSelect
		return
	}
	ddlTriggerType_SelectionChanged(Item)
	{
		Type := Item.Text
		Category := this.ddlTriggerCategory.SelectedItem.Text
		;At startup, TriggerGUI isn't set, and so the original Trigger doesn't get overriden
		;If it is set, the code below treats a change of type by destroying the previous window elements and creates a new trigger
		if(this.TriggerGUI)
		{
			if(this.Event.Trigger.Type = Type && this.Event.Trigger.Category = Category) ;selecting same item, ignore
				return
			this.SubmitTrigger()
			TriggerTemplate := EventSystem.Triggers[Type]
			this.Event.Trigger := new TriggerTemplate()
		}
		;Show trigger-specific part of the gui and store hwnds in TriggerGUI
		this.ShowTrigger()
		return
	}
	SubmitTrigger()
	{
		Gui, % this.GUINum ": Default"
		Gui, Tab, 1
		this.Event.Trigger.GuiSubmit(this.TriggerGUI)
		Gui, Tab
	}
	ShowTrigger()
	{
		this.TriggerGUI := {Type: this.Event.Trigger.Type, Delimiter : this.Delimiter}
		this.TriggerGUI.x := 38
		this.TriggerGUI.y := 148
		this.TriggerGUI.GUINum := this.GUINum
		this.TriggerBackup := this.Event.Trigger.DeepCopy()
		
		Gui, % this.GUINum ": Default"
		Gui, Tab, 1
		this.Event.Trigger.GuiShow(this.TriggerGUI)
		Gui, Tab
	}
	btnTriggerHelp_Click()
	{
		OpenWikiPage("docsTriggers" (this.Event.Trigger.__WikiLink ? this.Event.Trigger.__WikiLink : this.Event.Trigger.Type))
	}


	/*
	Conditions
	*/

	listConditions_SelectionChanged(Item)
	{
		this.RefreshConditionControlStates()
		;A new item was selected
		if(this.listConditions.SelectedIndex && this.listConditions.PreviouslySelectedItem.Index != this.listConditions.SelectedIndex)
		{
			if(this.Condition)
				this.SubmitCondition()

			this.Condition :=  this.Event.Conditions[this.listConditions.SelectedIndex]
			;Mark that the Condition stored under this.Condition should be used instead of creating a new one of the type set in the type dropdownlist.
			this.UseCondition := true
			if(this.Condition.Category != this.ddlConditionCategory.Text) ;The category of the new Condition is different from the old one
				this.ddlConditionCategory.Text := this.Condition.Category
			else if(this.Condition.Type != this.ddlConditionType.Text) ;The type of the new Condition is different from the old one
				this.ddlConditionType.Text := this.Condition.Type
			else ;The Condition is of the same type
				this.ddlConditionType_SelectionChanged(this.ddlConditionType.SelectedItem)
		}		
		else if(!this.listConditions.SelectedIndex) ;Item deselected
			this.SubmitCondition()
	}
	ddlConditionCategory_SelectionChanged(Item)
	{
		this.ddlConditionType.DisableNotifications := true
		this.ddlConditionType.Items.Clear()
		IndexToSelect := 1
		for index, Condition in CCondition.Categories[Item.Text]
		{
			this.ddlConditionType.Items.Add(Condition.Type)
			if(this.Condition.Type = Condition.Type)
				IndexToSelect := index
		}
		this.ddlConditionType.DisableNotifications := false
		this.ddlConditionType.SelectedIndex := IndexToSelect
		return
	}
	ddlConditionType_SelectionChanged(Item)
	{
		if(!IsObject(Item)) ;Make sure not to do anything when type DropDownList is cleared
			return
		;Instantiate new condition if this value is set
		if(!this.UseCondition)
		{
			this.SubmitCondition()
			ConditionTemplate := EventSystem.Conditions[Item.Text]
			this.Event.Conditions[this.listConditions.SelectedIndex] := this.Condition := new ConditionTemplate()
			this.Condition.Negate := this.chkNegateCondition.Checked
		}
		this.UseCondition := false
		
		;Show Condition-specific part of the gui and store hwnds in ConditionGUI
		this.ShowCondition()
		return
	}
	SubmitCondition()
	{
		Gui, % this.GUINum ": Default"
		Gui, Tab, 2
		this.Condition.GuiSubmit(this.ConditionGUI)
		this.listConditions.Items[this.Event.Conditions.IndexOf(this.Condition)].Text := (this.Condition.Negate ? "NOT " : "" ) ToSingleLine(this.Condition.DisplayString())
		Gui, Tab
		this.Remove("Condition")
		this.Remove("ConditionGUI")
	}
	ShowCondition()
	{
		this.chkNegateCondition.Checked := this.Condition.Negate && !this.Condition.Is(CORCondition)
		this.chkNegateCondition.Enabled := !this.Condition.Is(CORCondition)
		this.ConditionGUI := {Type: this.Condition.Type, Delimiter : this.Delimiter, glabel : "EventEditor_ConditionLabel"}
		this.ConditionGUI.x := 438
		this.ConditionGUI.y := 178
		this.ConditionGUI.GUINum := this.GUINum
		this.ConditionBackup := this.Condition.DeepCopy()
		Gui, % this.GUINum ": Default"
		Gui, Tab, 2
		this.Condition.GuiShow(this.ConditionGUI)
		Gui, Tab		
		;Needed for changing the type of a condition
		this.listConditions.Items[this.Event.Conditions.IndexOf(this.Condition)].Text := (this.Condition.Negate ? "NOT " : "" ) ToSingleLine(this.Condition.DisplayString())
	}
	RefreshConditionDisplayString()
	{
		this.listConditions.SelectedItem.Text := (this.Condition.Negate ? "NOT " : "" ) ToSingleLine(this.Condition.DisplayString())
	}
	chkNegateCondition_CheckedChanged()
	{
		if(this.HasKey("Condition"))
		{
			this.Condition.Negate := this.chkNegateCondition.Checked
			this.listConditions.SelectedItem.Text := (this.Condition.Negate ? "NOT " : "" ) ToSingleLine(this.Condition.DisplayString())
		}
	}
	btnAddCondition_Click()
	{
		this.Event.Conditions.Insert(Condition := new CWindowActiveCondition())
		this.listConditions.Items.Add((Condition.Negate ? "NOT " : "" ) ToSingleLine(Condition.DisplayString()))
		this.UseCondition := true
		this.listConditions.SelectedIndex := this.listConditions.Items.MaxIndex()
	}

	btnDeleteCondition_Click()
	{
		if(SelectedIndex := this.listConditions.SelectedIndex)
		{
			this.SubmitCondition()
			this.Event.Conditions.Remove(SelectedIndex)
			this.Remove("Condition")
			this.listConditions.Items.Delete(SelectedIndex)
			if(Count := this.listConditions.Items.MaxIndex())
				this.listConditions.SelectedIndex := clamp(SelectedIndex, 1, Count)
		}
	}

	btnAddOR_Click()
	{
		this.Event.Conditions.Insert(Condition := new CORCondition())
		this.listConditions.Items.Add(ToSingleLine(Condition.DisplayString()))
		this.UseCondition := true
		this.listConditions.SelectedIndex := this.listConditions.Items.MaxIndex()
	}

	RefreshConditionControlStates()
	{
		SelectedIndex := this.listConditions.SelectedIndex
		this.ddlConditionCategory.Enabled 	:= SelectedIndex > 0
		this.ddlConditionType.Enabled 		:= SelectedIndex > 0
		this.chkNegateCondition.Enabled 	:= SelectedIndex > 0 && !this.Condition.Is(CORCondition)
		if(!(SelectedIndex > 0))
			this.chkNegateCondition.Checked := false
		this.btnConditionHelp.Enabled 		:= SelectedIndex > 0
		this.btnDeleteCondition.Enabled 	:= SelectedIndex > 0
		this.btnCopyCondition.Enabled 		:= SelectedIndex > 0
		this.btnMoveConditionDown.Enabled 	:= SelectedIndex < this.listConditions.Items.MaxIndex()
		this.btnMoveConditionUp.Enabled 	:= SelectedIndex > 1
	}
	btnCopyCondition_Click()
	{
		EventSystem.ConditionClipboard := this.Event.Conditions[this.listConditions.SelectedIndex].DeepCopy()
		this.btnPasteCondition.Enabled := true
	}
	btnPasteCondition_Click()
	{
		this.Event.Conditions.Insert(EventSystem.ConditionClipboard.DeepCopy())
		this.listConditions.Items.Add((EventSystem.ConditionClipboard.Negate ? "NOT " : "") ToSingleLine(EventSystem.ConditionClipboard.DisplayString()), -1, true)
	}
	btnMoveConditionUp_Click()
	{
		SelectedIndex := this.listConditions.SelectedIndex
		if(!(SelectedIndex > 1))
			return
		Text := this.listConditions.SelectedItem.Text
		this.Event.Conditions.swap(SelectedIndex, SelectedIndex - 1)
		this.listConditions.DisableNotifications := true
		this.listConditions.Items.Delete(SelectedIndex)
		this.listConditions.Items.Add(Text, SelectedIndex - 1, true)
		this.listConditions.DisableNotifications := false
		this.RefreshConditionControlStates()
	}
	btnMoveConditionDown_Click()
	{
		SelectedIndex := this.listConditions.SelectedIndex
		if(SelectedIndex >= this.listConditions.Items.MaxIndex())
			return
		Text := this.listConditions.Items[SelectedIndex].Text
		this.Event.Conditions.swap(SelectedIndex, SelectedIndex + 1)
		this.listConditions.DisableNotifications := true
		this.listConditions.Items.Delete(SelectedIndex)
		this.listConditions.Items.Add(Text, SelectedIndex + 1, true)
		this.listConditions.DisableNotifications := false
		this.RefreshConditionControlStates()
	}
	btnConditionHelp_Click()
	{
		OpenWikiPage("docsConditions" (this.Condition.__WikiLink ? this.Condition.__WikiLink : this.Condition.Type))
	}
	

	/*
	Actions
	*/

	listActions_SelectionChanged(Item)
	{
		this.RefreshActionControlStates()
		;A new item was selected
		if(this.listActions.SelectedIndex && this.listActions.PreviouslySelectedItem.Index != this.listActions.SelectedIndex)
		{
			if(this.Action)
				this.SubmitAction()

			this.Action :=  this.Event.Actions[this.listActions.SelectedIndex]
			;Mark that the Action stored under this.Action should be used instead of creating a new one of the type set in the type dropdownlist.
			this.UseAction := true
			if(this.Action.Category != this.ddlActionCategory.Text) ;The category of the new Action is different from the old one
				this.ddlActionCategory.Text := this.Action.Category
			else if(this.Action.Type != this.ddlActionType.Text) ;The type of the new Action is different from the old one
				this.ddlActionType.Text := this.Action.Type
			else ;The Action is of the same type
				this.ddlActionType_SelectionChanged(this.ddlActionType.SelectedItem)
		}		
		else if(!this.listActions.SelectedIndex) ;Item deselected
			this.SubmitAction()
	}
	ddlActionCategory_SelectionChanged(Item)
	{
		this.ddlActionType.DisableNotifications := true
		this.ddlActionType.Items.Clear()
		IndexToSelect := 1
		for index, Action in CAction.Categories[Item.Text]
		{
			this.ddlActionType.Items.Add(Action.Type)
			if(this.Action.Type = Action.Type)
				IndexToSelect := index
		}
		this.ddlActionType.DisableNotifications := false
		this.ddlActionType.SelectedIndex := IndexToSelect
		return
	}
	ddlActionType_SelectionChanged(Item)
	{
		if(!IsObject(Item)) ;Make sure not to do anything when type DropDownList is cleared
			return
		;Instantiate new Action if this value is set
		if(!this.UseAction)
		{
			this.SubmitAction()
			ActionTemplate := EventSystem.Actions[Item.Text]
			this.Event.Actions[this.listActions.SelectedIndex] := this.Action := new ActionTemplate()
		}
		this.UseAction := false
		
		;Show Action-specific part of the gui and store hwnds in ActionGUI
		this.ShowAction()
		return
	}
	SubmitAction()
	{
		Gui, % this.GUINum ": Default"
		Gui, Tab, 3
		this.Action.GuiSubmit(this.ActionGUI)
		this.listActions.Items[this.Event.Actions.IndexOf(this.Action)].Text := ToSingleLine(this.Action.DisplayString())
		Gui, Tab
		this.Remove("Action")
		this.Remove("ActionGUI")
	}
	ShowAction()
	{
		this.ActionGUI := {Type: this.Action.Type, Delimiter : this.Delimiter, glabel : "EventEditor_ActionLabel"}
		this.ActionGUI.x := 438
		this.ActionGUI.y := 148
		this.ActionGUI.GUINum := this.GUINum
		this.ActionBackup := this.Action.DeepCopy()
		Gui, % this.GUINum ": Default"
		Gui, Tab, 3
		this.Action.GuiShow(this.ActionGUI)
		Gui, Tab		
		;Needed for changing the type of a Action
		this.listActions.Items[this.Event.Actions.IndexOf(this.Action)].Text := ToSingleLine(this.Action.DisplayString())
	}
	RefreshActionDisplayString()
	{
		this.listActions.Items[this.Event.Actions.IndexOf(this.Action)].Text := ToSingleLine(this.Action.DisplayString())
	}
	btnAddAction_Click()
	{
		this.Event.Actions.Insert(Action := new CRunAction())
		this.listActions.Items.Add(ToSingleLine(Action.DisplayString()))
		this.UseAction := true
		this.listActions.SelectedIndex := this.listActions.Items.MaxIndex()
	}
	btnDeleteAction_Click()
	{
		if(SelectedIndex := this.listActions.SelectedIndex)
		{
			this.SubmitAction()
			this.Event.Actions.Remove(SelectedIndex)
			this.Remove("Action")
			this.listActions.Items.Delete(SelectedIndex)
			if(Count := this.listActions.Items.MaxIndex())
				this.listActions.SelectedIndex := clamp(SelectedIndex, 1, Count)
		}
	}
	RefreshActionControlStates()
	{
		SelectedIndex := this.listActions.SelectedIndex
		this.ddlActionCategory.Enabled 	:= SelectedIndex > 0
		this.ddlActionType.Enabled 		:= SelectedIndex > 0
		this.btnActionHelp.Enabled 		:= SelectedIndex > 0
		this.btnDeleteAction.Enabled 	:= SelectedIndex > 0
		this.btnCopyAction.Enabled 		:= SelectedIndex > 0
		this.btnMoveActionDown.Enabled 	:= SelectedIndex < this.listActions.Items.MaxIndex()
		this.btnMoveActionUp.Enabled 	:= SelectedIndex > 1
	}
	btnCopyAction_Click()
	{
		EventSystem.ActionClipboard := this.Event.Actions[this.listActions.SelectedIndex].DeepCopy()
		this.btnPasteAction.Enabled := true
	}
	btnPasteAction_Click()
	{
		this.Event.Actions.Insert(EventSystem.ActionClipboard.DeepCopy())
		this.listActions.Items.Add(ToSingleLine(EventSystem.ActionClipboard.DisplayString()), -1, true)
	}
	btnMoveActionUp_Click()
	{
		SelectedIndex := this.listActions.SelectedIndex
		if(!(SelectedIndex > 1))
			return
		Text := this.listActions.SelectedItem.Text
		this.Event.Actions.swap(SelectedIndex, SelectedIndex - 1)
		this.listActions.DisableNotifications := true
		this.listActions.Items.Delete(SelectedIndex)
		this.listActions.Items.Add(Text, SelectedIndex - 1, true)
		this.listActions.DisableNotifications := false
		this.RefreshActionControlStates()
	}
	btnMoveActionDown_Click()
	{
		SelectedIndex := this.listActions.SelectedIndex
		if(SelectedIndex >= this.listActions.Items.MaxIndex())
			return
		Text := this.listActions.Items[SelectedIndex].Text
		this.Event.Actions.swap(SelectedIndex, SelectedIndex + 1)
		this.listActions.DisableNotifications := true
		this.listActions.Items.Delete(SelectedIndex)
		this.listActions.Items.Add(Text, SelectedIndex + 1, true)
		this.listActions.DisableNotifications := false
		this.RefreshActionControlStates()
	}
	btnActionHelp_Click()
	{
		OpenWikiPage("docsActions" (this.Action.__WikiLink ? this.Action.__WikiLink : this.Action.Type))
	}
}

;These events get triggered as g-labels by the controls added with AddControl(). However, right now they can't refresh the DisplayStrings of the conditions/actions because
;the values have not been updated yet in the condition or action. Fixing this would require to adjust many conditions/actions to use a new parameter in GuiSubmit() that tells
;it if only the values should get updated or if the controls should also be removed. This wasn't planned originally and now limits the updating here.
EventEditor_ConditionLabel:
CGUI.GUIList["CEventEditor1"].RefreshConditionDisplayString()
return
EventEditor_ActionLabel:
CGUI.GUIList["CEventEditor1"].RefreshActionDisplayString()
return

EventEditor_DeleteCondition:
CGUI.GUIList["CEventEditor1"].btnDeleteCondition_Click()
return

EventEditor_DeleteAction:
CGUI.GUIList["CEventEditor1"].btnDeleteAction_Click()
return