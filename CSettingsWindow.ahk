SettingsActive()
{
	return IsObject(SettingsWindow) && IsObject(SettingsWindow.Events) 
}
SettingsHandler:
ShowSettings()
return
ShowSettings(Page = "Events")
{
	;Settings window is created in AutoExecute to save some time when this function is called the first time.
	if(!IsObject(SettingsWindow))
		SetTimer, SettingsHandler, -20
	if(SettingsActive() && !Page)
		return
	SettingsWindow.Show(Page)
}
Class CSettingsWindow Extends CGUI
{
	Width := 890
	Height := 560
	treePages := this.AddControl("TreeView", "treePages", "x19 y12 w182 h" this.Height - 47, "")
	grpPage := this.AddControl("GroupBox", "grpPage", "x+17 w" this.Width - 226 " h" this.Height - 47 " Section", "Events")
	btnOK := this.AddControl("Button", "btnOK", "x" this.Width - 254 " y" this.Height - 29 " w73 h23", "OK")
	btnCancel := this.AddControl("Button", "btnCancel", "x+5 w73 h23", "Cancel")
	btnApply := this.AddControl("Button", "btnApply", "x+5 w73 h23", "Apply")
	
	;This contains the settings pages after Introduction, Events and Accessor
	PageNames := "Clipboard|Explorer|Explorer Tabs|Fast Folders|FTP Profiles|HotStrings|If this then that Integration|Windows|Windows Settings|Misc|About"
	
	__New()
	{
		this.treePages.RegisterEvent("ItemSelected", "PageSelected")
		this.treePages.Style := "+0x10"
		this.treePages.Style := "+0x20"
		this.treePages.Style := "+0x1000"
		this.Pages := {}

		PageNames := this.PageNames
		Item := this.treePages.Items.Add("Introduction", "")
		Page := this.Pages["Introduction"] := Item.AddControl("Tab", "Introduction", "xs+0 ys+2 w" this.Width - 386 " h350", "bla")
		this.CreateIntroduction()
		Page.Hide()

		Item := this.treePages.Items.Add("All Events", "Expand")
		Item.IsEvents := true
		Page := this.Pages["Events"] := Item.AddControl("Tab", "Events", "xs+0 ys+2 w" this.Width - 386 " h350", "bla")
		this.CreateEvents()
		Page.Hide()

		Item := this.treePages.Items.Add("Accessor", "Expand")
		Page := this.Pages["Accessor"] := Item.AddControl("Tab", "Accessor", "xs+0 ys+2 w" this.Width - 386 " h350", "bla")
		this.CreateAccessor()
		Page.Hide()

		for index, Name in ["Keywords", "Plugins"]
		{
			SubItem := Item.Add(Name, "")
			Page := this.Pages[Name] := SubItem.AddControl("Tab", Name, "xs+0 ys+2 w" this.Width - 386 " h350", "bla")
			this["Create" Name]()
			Page.Hide()
		}

		;Create rest of pages
		Loop, Parse, PageNames, |
		{
			Item := this.treePages.Items.Add(A_LoopField, "Expand")
			Name := StringReplace(A_LoopField, " ", "", "All")
			Page := this.Pages[Name] := Item.AddControl("Tab", Name, "xs+0 ys+2 w" this.Width - 386 " h350", "bla")
			this["Create" Name]()
			Page.Hide()
		}
		
		this.OnMessage(0x100, "WM_KEYDOWN")
		this.OnMessage(0x101, "WM_KEYUP")
		
		this.CloseOnEscape := true
		this.Title := "7plus Settings"
	}
	
	;Shows the settings window, optionally specifying a page to show
	Show(Page = "Events")
	{
		;On first run of 7plus, start with Introduction page
		if(!Page)
			Page := Settings.General.FirstRun ? "Introduction" : "Events"
		
		PageNames := this.PageNames
		
		;Initialize the pages when the window was hidden
		if(!this.Visible)
		{
			this.InitIntroduction()
			this.InitEvents()
			this.InitAccessor()
			this.InitKeywords()
			this.InitPlugins()
			Loop, Parse, PageNames, |
			{
				Name := StringReplace(A_LoopField, " ", "", "All")
				this["Init"  Name]()			
			}
		}
		
		;Select the appropriate page
		if(this.treePages.SelectedItem.Text != Page && !((Page = "Events" && this.treePages.SelectedItem.Text = "All Events")))
		{
			for index, item in this.treePages.Items
			{
				if(item.Text = Page || (Page = "Events" && item.Text = "All Events"))
				{
					this.treePages.SelectedItem := Item
					break
				}
				;Treat second level of tree
				for index2, item2 in item
				{
					if(item2.Text = Page)
					{
						this.treePages.SelectedItem := Item2
						break 2
					}
				}
			}
		}
		else if(!this.Visible)
			this.RecreateTreeView()
		Monitor := FindMonitorFromMouseCursor()
		this.X := (Monitor.Right - Monitor.Left) / 2 - this.Width / 2
		this.Y := (Monitor.Bottom - Monitor.Top) / 2 - this.Height / 2
		base.Show()
	}
	btnApply_Click()
	{
		this.ApplySettings(0)
	}
	btnCancel_Click()
	{
		this.CancelSettings()
	}
	btnOK_Click()
	{
		this.ApplySettings(1)
	}
	PreClose()
	{
		this.Events := ""
	}
	ApplySettings(Close = 0)
	{
		this.Enabled := false
		PageNames := this.PageNames
		this.ApplyIntroduction()
		this.ApplyEvents()
		this.ApplyAccessor()
		this.ApplyKeywords()
		this.ApplyPlugins()
		Loop, Parse, PageNames, |
		{
			Name := StringReplace(A_LoopField, " ", "", "All")
			this["Apply" Name]()
		}
		Settings.Save()
		this.Enabled := true
		if(Close)
			this.Close()
	}
	CancelSettings()
	{
		this.Close()
	}
	
	;Called when a settings page gets selected
	PageSelected(Item)
	{
		if(IsObject(this.treePages.PreviouslySelectedItem) && PreviousText := StringReplace(this.treePages.PreviouslySelectedItem.Text, " ", "", "All"))
			this["Hide" PreviousText]()
		

		;This property is stored specifically for this routine to speed things up! It helps at least 500ms to do this than to check for item parent and item text like this: if(Item.Parent.ID != 0 || Item.Text = "All Events")
		if(Item.IsEvents)
		{
			;Clear event filter
			editEventFilter := this.Pages.Events.Tabs[1].Controls.editEventFilter
			editEventFilter.DisableNotifications := true
			editEventFilter.Text := ""
			editEventFilter.DisableNotifications := false
			
			;Fill the contents of the events list. The events list itself is shown by assigning the tab control as sub-control to each events page.
			this.FillEventsList()
		}
		this.grpPage.Text := Item.Text
		GuiControl, % this.GUINum ":MoveDraw", % this.treePages.hwnd
		GuiControl, % this.GUINum ":MoveDraw", % this.grpPage.hwnd
		GuiControl, % this.GUINum ":MoveDraw", % this.BtnOK.hwnd
		GuiControl, % this.GUINum ":MoveDraw", % this.BtnCancel.hwnd
		GuiControl, % this.GUINum ":MoveDraw", % this.BtnApply.hwnd

		this["Show" StringReplace(this.treePages.SelectedItem.Text, " ", "", "All")]()
	}
	
	
	;Introduction
	CreateIntroduction()
	{
		Page := this.Pages.Introduction.Tabs[1]
		Text = 
		(
		Welcome to 7plus! If you are new to this program, here are some tips:

 - Be sure to check out the events settings page (or more specifically, the subpages for specific categories).
   The event system allows to create all kinds of functions (hotkeys, timers, context menu entries...).
   If you look for a specific feature, use the search field on that page. To edit an event, just double-click it.
   Use the help buttons in the "Edit Event" window for help on specific triggers/conditions/actions.

 - You should also check out the Accessor settings. The Accessor is a launcher program that can be used
   to launch programs with the keyboard (and much more!).

 - For explorer features, check out the Explorer, Fast Folders and Explorer Tabs pages,
   in addition to the explorer-related events.

Finally, here are some settings that you're likely to change at the beginning:
)
		Page.AddControl("Text", "textIntroduction", "xs+21 ys+16 w574 h182", Text)

		Page.AddControl("CheckBox", "chkAutoUpdate", "xs+24 ys+263 w219 h17", "Automatically look for updates on startup")
		Page.AddControl("CheckBox", "chkHideTrayIcon", "xs+24 ys+240 w339 h17", "Hide Tray Icon (press WIN + H (default settings) to show settings!)")
		Page.AddControl("CheckBox", "chkAutoRun", "xs+24 ys+217 w187 h17", "Autorun 7plus on windows startup")
		chkShowTips := Page.AddControl("CheckBox", "chkShowTips", "xs+24 ys+286", "Show tips about the usage of 7plus (highly recommended to discover its features)")
		chkShowTips.ToolTip := "Tips will be shown when specific actions, such as pasting some text, are carried out. Each tip is only shown once in a non-obstrusive manner. This is recommended for most users that don't want to go through all the whole configuration of 7plus to discover most of its features."
		;Page.AddControl("Text", "txtLanguage", "xs+21 ys+339 w129 h13", "Documentation language:")
		;Page.AddControl("DropDownList", "ddlLanguage", "xs+203 ys+336 w160", "")
		Page.AddControl("Text", "txtRunAsAdmin", "xs+21 ys+312 w75 h13", "Run as admin:")
		Page.AddControl("DropDownList", "ddlRunAsAdmin", "xs+203 ys+309 w160", "Always/Ask|Never")
		Page.Controls.txtRunAsAdmin.ToolTip := "Required for explorer buttons, Autoupdate and for accessing programs which are running as admin. Also make sure that 7plus has write access to its config files when not running as admin."
		Page.Controls.ddlRunAsAdmin.ToolTip := "Required for explorer buttons, Autoupdate and for accessing programs which are running as admin. Also make sure that 7plus has write access to its config files when not running as admin."
	}
	InitIntroduction()
	{
		;global Languages
		Page := this.Pages.Introduction.Tabs[1].Controls
		Page.chkAutoUpdate.Checked := Settings.General.AutoUpdate
		Page.chkHideTrayIcon.Checked := Settings.Misc.HideTrayIcon
		if(!ApplicationState.IsPortable)
			Page.chkAutoRun.Checked := IsAutoRunEnabled()
		Page.chkShowTips.Checked := Settings.General.ShowTips
		Page.ddlRunAsAdmin.Text := Settings.Misc.RunAsAdmin
		;Page.ddlLanguage.Items.Clear()
		;for key, Language in Languages.Languages
		;	Page.ddlLanguage.Items.Add(Language.FullName, -1, Language.ShortName = Settings.General.Language)
	}
	ApplyIntroduction()
	{
		;global Languages
		Page := this.Pages.Introduction.Tabs[1].Controls
		
		Settings.General.AutoUpdate := Page.chkAutoUpdate.Checked
		
		if(!Settings.Misc.HideTrayIcon && Settings.Misc.HideTrayIcon != Page.chkHideTrayIcon.Checked)
		{
			MsgBox You have chosen to hide the tray icon. This means that you will only be able to access the settings dialog by pressing WIN + H (Default settings). Also, the program can only be ended by using the task manager then.
			Menu, Tray, NoIcon
		}
		else
			Menu, Tray, Icon		
		Settings.Misc.HideTrayIcon := Page.chkHideTrayIcon.Checked
		
		if(!ApplicationState.IsPortable &&  IsAutoRunEnabled() != Page.chkAutoRun.Checked)
		{
			if(Page.chkAutoRun.Checked)
				EnableAutorun()
			else
				DisableAutorun()
		}
		
		Settings.Misc.RunAsAdmin := Page.ddlRunAsAdmin.Text
		Settings.General.ShowTips := Page.chkShowTips.Checked

		;for index, Language in Languages.Languages
		;	if(Language.FullName = Page.ddlLanguage.Text)
		;	{
		;		Settings.General.Language := Language.ShortName
		;		break
		;	}
	}
	
	;Events
	CreateEvents()
	{
		Page := this.Pages.Events.Tabs[1]
		Page.AddControl("CheckBox", "chkShowAdvancedEvents", "xs+21 ys+53 w141 h17", "Show advanced events")
		
		Page.AddControl("Button", "btnEventHelp", "xs+567 ys+48 w80 h23", "&Help")
		Page.Controls.btnEventHelp.ToolTip := "Show help on the event system"

		Page.AddControl("Button", "btnAddEvent", "xs+567 ys+76 w80 h23", "&Add Event")
		Page.Controls.btnAddEvent.ToolTip := "Add an event"

		Page.AddControl("Button", "btnEditEvent", "xs+567 y+9 w80 h23", "&Edit Event")
		Page.Controls.btnEditEvent.ToolTip := "Edit an event"

		Page.AddControl("Button", "btnDeleteEvents", "xs+567 y+9 w80 h23", "&Delete Events")
		Page.Controls.btnDeleteEvents.ToolTip := "Delete selected events"

		Page.AddControl("Button", "btnEnableEvents", "xs+567 y+9 w80 h23", "E&nable Events")
		Page.Controls.btnEnableEvents.ToolTip := "Enable selected events"

		Page.AddControl("Button", "btnDisableEvents", "xs+567 y+9 w80 h23", "D&isable Events")
		Page.Controls.btnDisableEvents.ToolTip := "Disable selected events"

		Page.AddControl("Button", "btnCopyEvent", "xs+567 y+9 w80 h23", "&Copy Events")
		Page.Controls.btnCopyEvent.ToolTip := "Copy selected events"

		Page.AddControl("Button", "btnPasteEvent", "xs+567 y+9 w80 h23", "&Paste Events")
		Page.Controls.btnPasteEvent.ToolTip := "Paste copied events"
		
		Page.AddControl("Button", "btnImportEvents", "xs+567 y+9 w80 h23", "&Import")
		Page.Controls.btnImportEvents.ToolTip := "Import events"

		Page.AddControl("Button", "btnExportEvents", "xs+567 y+9 w80 h23", "E&xport")
		Page.Controls.btnExportEvents.ToolTip := "Export events"

		Page.AddControl("Button", "btnCreateShortcut", "xs+567 y+9 w80 h23", "Create &Shortcut")
		Page.Controls.btnCreateShortcut.ToolTip := "Create a shortcut for the selected event"

		Page.AddControl("Edit", "editEventFilter", "xs+413 ys+50 w144 h20", "")
		Page.AddControl("Text", "txtEventSearch", "xs+332 ys+53 w75 h13", "Event Search:")
		
		;ListView uses indices that are independent of the listview sorting so it can access the array with the data more easily
		lv := Page.AddControl("ListView", "listEvents", "xs+21 ys+76 w536 h311 Grid Checked -LV0x10 Count300", "Enabled|ID|Trigger|Name")
		lv.ExStyle := "+0x00010000"
		Page.Controls.listEvents.IndependentSorting := true

		Page.AddControl("GroupBox", "grpEventDescription", "xs+21 y+5 w536 h120", "Description")
		Page.AddControl("Link", "lnkEventDescription", "xp+10 yp+20 w500 h81", "")
		Page.AddControl("Text", "txtEventDescription", "xs+21 ys+16 w606 h26", "You can add events here that are triggered under certain conditions. When triggered, the event can launch a series of actions.`n This is a very powerful tool to add all kinds of features, and many features from 7plus are now implemented with this system.")
	}	
	InitEvents()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		this.SupressFillEventsList := true
		Page.chkShowAdvancedEvents.Checked := Settings.General.ShowAdvancedEvents
		if(!this.Events)
		{
			for index, Event in EventSystem.Events
				Event.Trigger.PrepareCopy(Event)
			
			this.Events := EventSystem.Events.DeepCopy()
			Page.editEventFilter.Text := ""
		}
		this.RecreateTreeView()
		;Page.listEvents.ModifyCol(2, 40)
		;Page.listEvents.ModifyCol(3, 195)
		;Page.listEvents.ModifyCol(4, "AutoHdr")
		this.ActiveControl := Page.listEvents
		this.Remove("SupressFillEventsList")
	}
	ApplyEvents()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		Settings.General.ShowAdvancedEvents := Page.chkShowAdvancedEvents.Checked
		
		; TODO: Improve code quality here.
		; Remove events that were deleted in settings window and refresh the settings copies to consider recent changes in the original events (such as timer state)
		pos := 1
		Loop % EventSystem.Events.MaxIndex()
		{
			OldEvent := EventSystem.Events[pos]
			NewEvent := this.Events.GetItemWithValue("ID", OldEvent.id)
			
			;Disable all events first (without setting enabled to false, so triggers can decide what they want to do themselves)
			OldEvent.Trigger.Disable(OldEvent)
			
			;separate destroy routine instead of simple disable is needed for removed events because of hotkey/timer discrepancy
			if(!NewEvent)
			{
				EventSystem.Events.Delete(OldEvent, false)
				continue
			}
			
			OldEvent.Trigger.PrepareReplacement(OldEvent, NewEvent)
			pos++
		}
		;Replace the original events with the copies
		EventSystem.Events := this.Events.DeepCopy()
		
		;Update enabled state
		for index, Event in EventSystem.Events
		{
			if(Event.Enabled)
				Event.Trigger.Enable(Event)
			else
				Event.Trigger.Disable(Event)
		}
		EventSystem.EventsChanged()
	}
	RecreateTreeView()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		SelectedCategory := this.GetSelectedCategory()
		this.treePages.DisableNotifications := true
		Page.listEvents.DisableNotifications := true
		ShowAdvancedEvents := Page.chkShowAdvancedEvents.Checked
		while(item := this.treePages.Items[2][1])
			this.treePages.Items.Delete(item)
		for index, Category in this.Events.Categories
		{
			for index2, Event in this.Events
			{
				if(ShowAdvancedEvents || (Event.Category = Category && !Event.EventComplexityLevel))
				{
					item := this.treePages.Items[2].Add(Category, "Sort" (SelectedCategory = Category ? " Select Vis" : ""))
					item.Controls.Insert(this.treePages.Items[2].Controls.Events)
					item.IsEvents := true
					break
				}
			}
		}
		this.FillEventsList()
		if(this.treePages.SelectedItem.IsEvents)
			this.ActiveControl := Page.listEvents
		this.treePages.DisableNotifications := false
		Page.listEvents.DisableNotifications := false
		;Page.listEvents.ModifyCol(2, 40)
		;Page.listEvents.ModifyCol(3, 195)
		;Page.listEvents.ModifyCol(4, "AutoHdr")
	}
	
	;This function needs to use speed optimizations
	FillEventsList()
	{
		;Used to suppress a redundant call to this function on init since it takes up 200-500ms on my PC.
		if(this.SupressFillEventsList)
			return
		OutputDebug FillEventsList
		Page := this.Pages.Events.Tabs[1].Controls
		SelectedCategory := this.GetSelectedCategory()
		SelectedID := Page.listEvents.SelectedItem[2]
		Filter := Page.editEventFilter.Text
		ShowAdvancedEvents := Page.chkShowAdvancedEvents.Checked
		Items := Page.listEvents.Items
		Items.Clear()
		;~ GuiControl, % this.GUINum ":-Redraw", % Page.listEvents.ClassNN
		;Add all matching events
		for index, Event in this.Events
		{
			ID := Event.ID
			DisplayString := ToSingleLine(Event.Trigger.DisplayString())
			Name := Event.Name
			;Show events that match the entered filter or the selected category and the selected complexity level
			if(this.IsEventVisible(Event, Filter, DisplayString, SelectedCategory, ShowAdvancedEvents))
			{
				item := Items.Add((Event.Enabled ? " Check": " "), "", ID, ToSingleLine(Event.Trigger.DisplayString()), Event.Name)
				if(SelectedID && ID = SelectedID)
					item.Modify("Select Focus Vis")
			}
		}
		
		if(!Page.listEvents.SelectedItems.MaxIndex() && Page.listEvents.Items.MaxIndex())
			Page.listEvents.SelectedIndex := 1
		if(Page.listEvents.SelectedItems.MaxIndex() = 1)
			Page.lnkEventDescription.Text := this.Events.GetItemWithValue("ID", Page.listEvents.SelectedItem[2]).Description
		this.listEvents_SelectionChanged("")

		Page.listEvents.ModifyCol(2, 40)
		Page.listEvents.ModifyCol(3, 195)
		Page.listEvents.ModifyCol(4, 225)
	}
	IsEventVisible(Event, Filter, TriggerDisplayString, SelectedCategory, ShowAdvancedEvents)
	{
		return (!Filter || InStr(Event.ID, Filter) || InStr(TriggerDisplayString, Filter) || InStr(Event.Name, filter) || InStr(Event.Description, Filter)) && (filter || !SelectedCategory || SelectedCategory = Event.Category)
			&& (ShowAdvancedEvents || !Event.EventComplexityLevel)
	}
	chkShowAdvancedEvents_CheckedChanged()
	{
		this.FillEventsList()
	}
	editEventFilter_TextChanged()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		pos := 1
		Loop % CGUI.EventQueue.MaxIndex()
		{
			GuiControlGet, ControlHWND, % this.GUINum ":hwnd", % CGUI.EventQueue[pos].GuiControl
			if(ControlHWND = Page.editEventFilter.hwnd)
				CGUI.EventQueue.Remove(pos)
			else
				pos++
		}
		this.FillEventsList()
	}
	listEvents_SelectionChanged(Row)
	{
		Page := this.Pages.Events.Tabs[1].Controls
		items := Page.listEvents.SelectedItems.MaxIndex()
		if(!items)
		{
			Page.btnDeleteEvents.Enabled := false
			Page.btnCopyEvent.Enabled := false
			Page.btnExportEvents.Enabled := false
			Page.btnEnableEvents.Enabled := false
			Page.btnDisableEvents.Enabled := false
		}
		else if(Items >= 1)
		{
			Page.btnDeleteEvents.Enabled := true
			Page.btnCopyEvent.Enabled := true
			Page.btnExportEvents.Enabled := true
			Page.btnEnableEvents.Enabled := true
			Page.btnDisableEvents.Enabled := true
		}
		if(items = 1)
		{
			Page.lnkEventDescription.Text := this.Events.GetItemWithValue("ID", Page.listEvents.SelectedItem[2]).Description
			Page.btnEditEvent.Enabled := true
			Page.btnCreateShortcut.Enabled := true
		}
		else
		{
			Page.lnkEventDescription.Text := ""
			Page.btnEditEvent.Enabled := false
			Page.btnCreateShortcut.Enabled := false
		}
		this.ActiveControl := Page.listEvents
	}
	listEvents_DoubleClick(Row)
	{
		this.EditEvent(0)
	}
	listEvents_CheckedChanged(Row)
	{
		if(IsObject(Row))
			this.Events.GetItemWithValue("ID", Row[2]).Enabled := Row.Checked
	}
	btnAddEvent_Click()
	{
		this.AddEvent()
	}
	btnEditEvent_Click()
	{
		this.EditEvent(0)
	}
	btnDeleteEvents_Click()
	{
		this.DeleteEvents()
	}
	btnEnableEvents_Click()
	{
		for key, item in this.Pages.Events.Tabs[1].Controls.listEvents.SelectedItems
			item.Checked := true
	}
	btnDisableEvents_Click()
	{
		for key, item in this.Pages.Events.Tabs[1].Controls.listEvents.SelectedItems
			item.Checked := false
	}
	btnCopyEvent_Click()
	{
		this.CopyEvent()
	}
	btnPasteEvent_Click()
	{
		this.PasteEvent()
	}
	btnImportEvents_Click()
	{
		this.ImportEvents()
	}
	btnExportEvents_Click()
	{
		this.ExportEvents()
	}
	btnEventHelp_Click()
	{
		OpenWikiPage("EventsOverview")
	}
	btnCreateShortcut_Click()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		if(Page.listEvents.SelectedItems.MaxIndex() != 1)
			return
		Event := this.Events.GetItemWithValue("ID", Page.listEvents.SelectedItem[2])
		if(!Event)
			return
		fd := new CFileDialog("Save")
		fd.Filter := "Link files (*.lnk)"
		if(fd.Show())
			FileCreateShortcut, % (A_IsCompiled ? A_ScriptFullPath : A_AhkPath), % (strEndsWith(fd.Filename, ".lnk") ? fd.Filename : fd.Filename ".lnk"), %A_ScriptDir%, % (A_IsCompiled ? "": """" A_ScriptFullPath """ ") "-id:" Event.ID, % "7plus: Trigger """ Event.Name """", %A_ScriptDir%\7+-128.ico
	}
	
	lnkEventDescription_Click(URL)
	{
		if(InStr(URL, "Settings:") = 1)
			this.Show(SubStr(URL, 10))
	}
	AddEvent()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		;Event is added to this.Events here and an ID is assigned
		Event := this.Events.RegisterEvent()
		ListItem := Page.listEvents.Items.Add("Select Vis", "", Event.ID, ToSingleLine(Event.Trigger.DisplayString()), Event.Name)
		Page.listEvents.SelectedItem := ListItem
		SelectedCategory := this.GetSelectedCategory(true)
		Event.Category := SelectedCategory
		this.EditEvent(Event.ID)
	}
	
	EditEvent(TemporaryEvent)
	{
		Page := this.Pages.Events.Tabs[1].Controls
		if(Page.listEvents.SelectedItems.MaxIndex() != 1)
			return
		ID := TemporaryEvent ? TemporaryEvent : Page.listEvents.SelectedItem[2]
		OriginalEvent := this.Events.GetItemWithValue("ID", ID)
		if((ApplicationState.IsPortable || !A_IsAdmin) && OriginalEvent.Trigger.Is(CExplorerButtonTrigger))
		{
			Msgbox ExplorerButton trigger events may not be modified in portable or non-admin mode, as this might cause inconsistencies with the registry.
			return
		}
		EventEditor := new CEventEditor(OriginalEvent.DeepCopy(), TemporaryEvent)
	}
	FinishEditing(NewEvent, TemporaryEvent)
	{
		Page := this.Pages.Events.Tabs[1].Controls
		if(NewEvent && (ApplicationState.IsPortable || !A_IsAdmin) && NewEvent.Trigger.Is(CExplorerButtonTrigger)) ;Explorer buttons may not be added in portable/non-admin mode
		{
			Msgbox ExplorerButton trigger events may not be modified in portable or non-admin mode, as this might cause inconsistencies with the registry.
			if(TemporaryEvent)
				this.DeleteEvents()
			return
		}
		if(NewEvent)
		{
			this.Events[this.Events.FindKeyWithValue("ID", NewEvent.ID)] := NewEvent ;overwrite edited event
			this.UpdateEventsView(NewEvent)
		}
		else if(TemporaryEvent)
			this.DeleteEvents()
	}
	UpdateEventsView(ChangedEvent)
	{
		Page := this.Pages.Events.Tabs[1].Controls
		;TODO: think about how events that won't work in portable/non-admin should be treated
		this.treePages.DisableNotifications := true
		
		DesiredCategory := SelectedCategory := this.GetSelectedCategory(false)
		
		;Check if a category is now empty
		for index, Category in this.Events.Categories
		{
			if(!this.Events.FindKeyWithValue("Category", Category))
			{
				;Check if category was renamed
				if(!this.Events.Categories.indexOf(ChangedEvent.Category))
				{
					;Rename the category in category list and in treeview
					this.treePages.Items[2].FindItemWithText(Category).Text := ChangedEvent.Category
					this.Events.Categories[this.Events.Categories.IndexOf(Category)] := ChangedEvent.Category
					DesiredCategory := SelectedCategory := ChangedEvent.Category
					break
				}
				;Remove the category from category list and from treeview
				this.Events.Categories.Remove(index)
				this.treePages.Items[2].Delete(this.treePages.Items[2].FindItemWithText(Category))
				DesiredCategory := ChangedEvent.Category
				break ;only one can change when an event changes
			}
		}
		
		;Check if a new category was created
		if(!this.Events.Categories.indexOf(ChangedEvent.Category))
		{
			;Add new category to category list and to treeview
			this.Events.Categories.Insert(ChangedEvent.Category)
			
			;Add the new category to the tree and set all required values to make it work
			Item := this.treePages.Items[2].Add(ChangedEvent.Category, "Sort")
			Item.Controls.Insert(this.treePages.Items[2].Controls.Events)
			Item.IsEvents := true
			DesiredCategory := ChangedEvent.Category
		}
		
		this.treePages.DisableNotifications := false
		;Check if category has been added, deleted or renamed
		;if added, show this category
		;if deleted, go back to all events, possibly keep the current search
		;if renamed, simply change the text of the treeview item
		
		if(DesiredCategory != SelectedCategory)
		{
			this.treePages.SelectedItem := this.treePages.FindItemWithText(DesiredCategory)
			this.FillEventsList()
			return
		}
		
		;Find the event in the listview
		for index, item in Page.listEvents.Items
			if(item[2] = ChangedEvent.ID)
			{
				ListIndex := index
				break
			}
		
		if(!ListIndex)
			return
		
		;Check if the event needs to be hidden:
		;This is the case when the event filter doesn't match it anymore (it should probably be removed then) and when it is marked as a complex event and displaying of complex events is disabled
		if(!this.IsEventVisible(ChangedEvent, Page.editEventFilter.Text, ToSingleLine(ChangedEvent.Trigger.DisplayString()), SelectedCategory, Page.chkShowAdvancedEvents.Checked))
		{
			Page.listEvents.Items.Delete(ListIndex)
			return
		}
		
		;If the event is visible, update its trigger display string, its name, its description and its enabled state
		Page.listEvents.DisableNotifications := true
		ListItem := Page.listEvents.Items[ListIndex]
		ListItem.Checked := ChangedEvent.Enabled
		ListItem[3] := ToSingleLine(ChangedEvent.Trigger.DisplayString())
		ListItem[4] := ChangedEvent.Name
		Page.lnkEventDescription.Text := ChangedEvent.Description
		Page.listEvents.DisableNotifications := false
	}
	DeleteEvents()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		Page.ListEvents.DisableNotifications := true
		ListPos := 1
		SelectedEvents := Page.listEvents.SelectedIndices
		Loop % SelectedEvents.MaxIndex()
		{
			Index := SelectedEvents[SelectedEvents.MaxIndex() - A_Index + 1]
			Event := this.Events.GetItemWithValue("ID", Page.listEvents.Items[Index][2])
			if((!ApplicationState.IsPortable && A_IsAdmin) || !Event.Trigger.Is(CExplorerButtonTrigger) && !Event.Trigger.Is(CContextMenuTrigger))
			{
				;Events object notifies its trigger about deletion
				CategoryDeleted += this.Events.Delete(Event, false)
				ListPos := Index
				Page.listEvents.Items.Delete(Index)
			}
		}
		count :=  Page.listEvents.Items.MaxIndex()
		if(count)
			Page.listEvents.SelectedIndex := min(max(ListPos, 1), count)
		Page.ListEvents.DisableNotifications := false
		if(CategoryDeleted) ;If a category was deleted
			this.RecreateTreeView()
		else
			this.ActiveControl := Page.listEvents
	}
	CopyEvent()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		count := Page.listEvents.SelectedItems.MaxIndex()
		if(!count)
			return
		ClipboardEvents := new CEvents()
		for index, item in Page.listEvents.SelectedItems
		{	
			Event := this.Events.GetItemWithValue("ID", item[2])
			Copy := Event.DeepCopy()
			Copy.Remove("OfficialEvent") ;Make sure that pasted events don't patch existing events
			if((!ApplicationState.IsPortable && A_IsAdmin) || !Event.Trigger.Is(CExplorerButtonTrigger))
				ClipboardEvents.Insert(copy)
		}
		ClipboardEvents.WriteEventsFile(A_Temp "/7plus/EventsClipboard.xml")	
		Page.btnPasteEvent.Enabled := true
	}
	PasteEvent()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		if(FileExist(A_Temp "/7plus/EventsClipboard.xml"))
		{
			SelectedCategory := this.GetSelectedCategory(true)
			this.Events.ReadEventsFile(A_Temp "/7plus/EventsClipboard.xml", SelectedCategory)
			this.FillEventsList()
		}
	}
	ImportEvents()
	{
		Page := this.Pages.Events.Tabs[1].Controls
		FileDialog := new CFileDialog("Open")
		FileDialog.Filter := "Event files (*.xml)"
		FileDialog.Title := "Import Events file"
		FileDialog.FileMustExist := true
		FileDialog.PathMustExist := true
		oldlen := this.Events.MaxIndex()
		if(FileDialog.Show())
		{
			this.Enabled := false
			this.Events.ReadEventsFile(FileDialog.Filename)
			this.RecreateTreeView()
			
			;Figure out if FTP events were added and notify the user to set the FTP profile assignments
			Loop % this.Events.MaxIndex() - oldlen
			{
				pos := A_Index + oldlen
				if(this.Events[pos].Actions.FindKeyWithValue("Type", "Upload"))
				{
					found := true
					break
				}
			}
			if(found)
				Notify("Note", "Make sure to assign the FTP profiles of all imported FTP actions!", 2, NotifyIcons.Info)
			this.Enabled := true
		}
	}
	ExportEvents()
	{
		global MajorVersion, MinorVersion, BugFixVersion
		Page := this.Pages.Events.Tabs[1].Controls	
		this.Enabled := false
		;If debug is enabled, events are exported all events separated by category to Events\Category.xml instead
		ExportAll := false
		if(Settings.General.DebugEnabled)
		{
			MsgBox, 0x4, Export Events, Export all events?
			IfMsgBox Yes
				ExportAll := true
		}
		if(ExportAll)
		{
			for index1, Category in this.Events.Categories
			{
				ExportEvents := new CEvents()
				for index, event in this.Events
					if(event.Category = Category)
						ExportEvents.Insert(event.DeepCopy())
				if(ExportEvents.MaxIndex())
					ExportEvents.WriteEventsFile(A_ScriptDir "\Events\" Category ".xml")
			}
			this.Events.WriteEventsFile(A_ScriptDir "\Events\All Events.xml")
			fd := new CFileDialog("Open")
			fd.Filter := "*.xml"
			fd.InitialDirectory := A_ScriptDir "\Events"
			if(!fd.Show())
				return
			run % """" A_AhkPath """ """   A_ScriptDir "\CreateEventPatch.ahk"" """ fd.Filename  """ """ A_ScriptDir "\Events\All Events.xml"" 0" ;Create event patch, assumes that last minor version was incremented by one since last release
			this.Enabled := true
			return
		}
		if(Page.listEvents.SelectedItems.MaxIndex())
		{
			FileDialog := new CFileDialog("Save")
			FileDialog.Filter := "Event files (*.xml)"
			FileDialog.Title := "Export Events file"
			FileDialog.FileMustExist := true
			FileDialog.PathMustExist := true
			FileDialog.OverwriteFilePrompt := true
			if(FileDialog.Show())
			{
				File := FileDialog.Filename
				if(!strEndsWith(File, ".xml"))
					File .= ".xml"
				ExportEvents := new CEvents()
				FTP := false ;Set to true if any event contains FTP actions
				for index, Item in Page.listEvents.SelectedItems
				{
						Event := this.Events.GetItemWithValue("ID", Item[2])
						ExportEvents.Insert(Event)
						if(!FTP && Event.Actions.FindKeyWithValue("Type", "Upload"))
							FTP := true
				}
				ExportEvents.WriteEventsFile(File)
				if(FTP)
					Notify("Note", "FTP profiles won't be exported by this function. To save them, create a backup of FTPProfiles.xml. This file is only updated at program exit!", 5, NotifyIcons.Info)
			}
		}
		this.Enabled := true
	}
	
	;Accessor
	CreateAccessor()
	{
		Page := this.Pages.Accessor.Tabs[1]
		Page.AddControl("Text", "txtAccessorText", "xs+21 ys+19 w431 h39", "Accessor is a versatile tool that is used to perform many commands through the keyboard, `nlike launching programs, switching windows, open URLs, browsing the filesystem,...`nPress the assigned hotkey (Default: ALT+Space) and start typing!")
		Page.AddControl("CheckBox", "chkAccessorLargeIcons", "xs+21 ys+69 h17", "Large icons")
		Page.AddControl("CheckBox", "chkAccessorCloseWhenDeactivated", "xs+21 y+3 h17", "Close Accessor window when it gets deactivated")
		;Page.AddControl("CheckBox", "chkAccessorTitleBar", "xs+21 y+3 h17", "Show title bar")
		;Page.AddControl("CheckBox", "chkAccessorUseAero", "xs+21 y+3 h17", "Use Aero glass effect (Vista/7 and newer)")
		Page.AddControl("CheckBox", "chkAccessorOpenInMonitorOfMouseCursor", "xs+21 y+3 h17", "Open in the monitor where the mouse cursor is")
		chkUseSelectionForKeywords := Page.AddControl("CheckBox", "chkUseSelectionForKeywords", "xs+21 y+3 h17", "Use the selected text as first parameter in keywords when no text is entered")
		chkUseSelectionForKeywords.ToolTip := "This can be used like this for example:`nSelect some text, open Accessor, type w and press enter.`nThis will search for the selected text on Wikipedia."
		;Page.AddControl("Slider", "sldAccessorTransparency", "x+10 y+3 Range50-255", 255)
		;Page.AddControl("Text", "txtAccessorTransparency", "xs+21 yp+3 h17", "Transparency (looks ugly with Aero enabled!):")
		;Page.AddControl("Text", "txtAccessorWidth", "xs+21 y+13 h17", "Accessor Width:")
		;Page.AddControl("Edit", "editAccessorWidth", "xs+120 yp-3 w60 h20 Number", "")
		;Page.AddControl("Text", "txtAccessorHeight", "xs+21 y+13 h17", "Accessor Height:")
		;Page.AddControl("Edit", "editAccessorHeight", "xs+120 yp-3 w60 h20 Number", "")
	}
	InitAccessor()
	{
		Page := this.Pages.Accessor.Tabs[1].Controls
		Page.chkAccessorLargeIcons.Checked := CAccessor.Instance.Settings.LargeIcons
		Page.chkAccessorCloseWhenDeactivated.Checked := CAccessor.Instance.Settings.CloseWhenDeactivated
		;Page.chkAccessorTitleBar.Checked := CAccessor.Instance.Settings.TitleBar
		;Page.chkAccessorUseAero.Checked := CAccessor.Instance.Settings.UseAero
		Page.chkOpenInMonitorOfMouseCursor.Checked := CAccessor.Instance.Settings.OpenInMonitorOfMouseCursor
		Page.chkUseSelectionForKeywords.Checked := CAccessor.Instance.Settings.UseSelectionForKeywords
		;if(CAccessor.Instance.Settings.Transparency)
		;	Page.sldAccessorTransparency.Value := CAccessor.Instance.Settings.Transparency
		;Page.editAccessorWidth.Text := Clamp(CAccessor.Instance.Settings.Width, 600, 2000)
		;Page.editAccessorHeight.Text := Clamp(CAccessor.Instance.Settings.Height, 200, 2000)
	}
	ApplyAccessor()
	{
		Page := this.Pages.Accessor.Tabs[1].Controls
		CAccessor.Instance.Settings.LargeIcons := Page.chkAccessorLargeIcons.Checked
		CAccessor.Instance.Settings.CloseWhenDeactivated := Page.chkAccessorCloseWhenDeactivated.Checked
		;CAccessor.Instance.Settings.TitleBar := Page.chkAccessorTitleBar.Checked
		;CAccessor.Instance.Settings.UseAero := Page.chkAccessorUseAero.Checked
		CAccessor.Instance.Settings.OpenInMonitorOfMouseCursor := Page.chkOpenInMonitorOfMouseCursor.Checked
		CAccessor.Instance.Settings.UseSelectionForKeywords := Page.chkUseSelectionForKeywords.Checked
		;CAccessor.Instance.Settings.Transparency := Page.sldAccessorTransparency.Value
		;if(CAccessor.Instance.Settings.Transparency = 255)
		;	CAccessor.Instance.Settings.Transparency := 0
		;CAccessor.Instance.Settings.Width := Clamp(Page.editAccessorWidth.Text, 600, 2000)
		;CAccessor.Instance.Settings.Height := Clamp(Page.editAccessorHeight.Text, 200, 2000)
	}
	;Accessor Plugins
	CreatePlugins()
	{
		Page := this.Pages.Plugins.Tabs[1]
		Page.AddControl("Button", "btnAccessorHelp", "xs+554 ys+19 w90 h23", "&Help")
		Page.AddControl("Button", "btnAccessorSettings", "xs+554 ys+48 w90 h23", "Plugin &Settings")
		Page.AddControl("ListView", "listAccessorPlugins", "xs+21 ys+19 w525 h400 Checked", "Plugin Name")
		Page.Controls.listAccessorPlugins.IndependentSorting := true

		Page.AddControl("Edit", "editPluginDescription", "xs+21 y+5 w525 h81 ReadOnly", "")
	}
	ShowPlugins()
	{
		Page := this.Pages.Plugins.Tabs[1].Controls
		this.ActiveControl := Page.listAccessorPlugins
	}
	InitPlugins()
	{
		Page := this.Pages.Plugins.Tabs[1].Controls
		this.AccessorPlugins := Array() ;We don't copy the whole AccessorPlugins structure here to save some memory (program launcher might take some for example)
		Page.listAccessorPlugins.Items.Clear()
		for index, Plugin in CAccessor.Plugins
		{
			PluginCopy := RichObject()
			PluginCopy.Type := Plugin.Type
			PluginCopy.Settings := Plugin.Settings.DeepCopy()
			this.AccessorPlugins.Insert(PluginCopy)
			Page.listAccessorPlugins.Items.Add((PluginCopy.Settings.Enabled ? "Check" : ""), PluginCopy.Type)
		}
		Page.listAccessorPlugins.ModifyCol(1, "AutoHdr")
		Page.listAccessorPlugins.SelectedIndex := 1
	}
	ApplyPlugins()
	{
		Page := this.Pages.Plugins.Tabs[1].Controls
		for index, Plugin in CAccessor.Plugins
		{
			SettingsPlugin := this.AccessorPlugins.GetItemWithValue("Type", Plugin.Type)
			Enabled := Plugin.Settings.Enabled
			SettingsPlugin.Settings.Enabled := Page.listAccessorPlugins.Items[this.AccessorPlugins.FindKeyWithValue("Type", Plugin.Type)].Checked
			Plugin.Settings := SettingsPlugin.Settings.DeepCopy()
			if(Enabled && !Plugin.Settings.Enabled)
				Plugin.Disable()
			else if(!Enabled && Plugin.Settings.Enabled)
				Plugin.Enable()
		}
	}
	listAccessorPlugins_SelectionChanged()
	{
		Page := this.Pages.Plugins.Tabs[1].Controls
		Page.editPluginDescription.Text := CAccessor.Plugins[Page.listAccessorPlugins.SelectedItem.Text].Description
	}
	btnAccessorHelp_Click()
	{
		OpenWikiPage("docsAccessor")
	}
	btnAccessorSettings_Click()
	{
		this.ShowAccessorSettings()
	}
	ShowAccessorSettings()
	{
		Page := this.Pages.Plugins.Tabs[1].Controls
		if(Page.listAccessorPlugins.SelectedItems.MaxIndex() != 1)
			return
		
		Plugin := this.AccessorPlugins[Page.listAccessorPlugins.SelectedIndex]
		AccessorPluginSettingsWindow := new CAccessorPluginSettingsWindow(Plugin, CAccessor.Plugins.GetItemWithValue("Type", Plugin.Type))
		AccessorPluginSettingsWindow.Show()
	}
	OnAccessorPluginSettingsWindowClosed(ModifiedPlugin)
	{
		if(ModifiedPlugin)
			this.AccessorPlugins[this.AccessorPlugins.FindKeyWithValue("Type", ModifiedPlugin.Type)] := ModifiedPlugin
	}
	listAccessorPlugins_CheckedChanged(Row)
	{
		if(IsObject(Row))
			this.AccessorPlugins[Row._.RowNumber].Settings.Enabled := Row.Checked
	}
	listAccessorPlugins_DoubleClick(Row)
	{
		this.ShowAccessorSettings()
	}


	;Accessor Keywords
	CreateKeywords()
	{
		Page := this.Pages.Keywords.Tabs[1]
		Page.AddControl("Text", "txtAccessorKeyword", "xs+21 ys+360 w51 h13", "Keyword:")
		Page.AddControl("Edit", "editAccessorKeyword", "xs+84 ys+357 w462 h20", "")
		Page.Controls.editAccessorKeyword.ToolTip := "The keyword which is typed into accessor at the start of the query, i.e. ""Google"""
		Page.AddControl("Text", "txtAccessorCommand", "xs+21 ys+386 w57 h13", "Command:")
		Page.AddControl("Edit", "editAccessorCommand", "xs+84 ys+383 w462 h20", "")
		Page.Controls.editAccessorCommand.ToolTip := "You can use parameters here which are inserted into the command at specific places. This is currently only supported by the URL plugin. Example: Keyword: ""google"" Command: ""www.google.com/search?q=${1}"" Entered Text: ""google 7plus"" result: ""www.google.com/search?q=7plus"""
		
		Page.AddControl("Button", "btnDeleteAccessorKeyword", "xs+554 ys+48 w90 h23", "&Delete Keyword")
		Page.AddControl("Button", "btnAddAccessorKeyword", "xs+554 ys+19 w90 h23", "&Add Keyword")
		Page.AddControl("ListView", "listAccessorKeywords", "xs+21 ys+19 w525 h332", "Keyword|Command")
		Page.Controls.listAccessorKeywords.IndependentSorting := true
	}
	InitKeywords()
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		this.AccessorKeywords := CAccessor.Instance.Keywords.DeepCopy()
		Page.listAccessorKeywords.Items.Clear()
		Page.listAccessorKeywords.ModifyCol(1, 100)
		Page.listAccessorKeywords.ModifyCol(2, "AutoHdr")
		Loop % this.AccessorKeywords.MaxIndex()
			Page.listAccessorKeywords.Items.Add(A_Index = 1 ? "Select" : "", this.AccessorKeywords[A_Index].Key, this.AccessorKeywords[A_Index].Command)
		this.listAccessorKeywords_SelectionChanged("")
	}
	ShowKeywords()
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		this.ActiveControl := Page.listAccessorKeywords
	}
	ApplyKeywords()
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		;Find duplicates
		pos := 1
		len := this.AccessorKeywords.MaxIndex()
		Loop % len
		{
			AccessorKeyword := this.AccessorKeywords[A_Index]
			Loop % this.AccessorKeywords.MaxIndex()
			{
				if(pos != A_Index && this.AccessorKeywords[A_Index].Key = AccessorKeyword.Key)
				{
					this.AccessorKeywords.Remove(pos)
					AccessorKeyword := ""
					break
				}
			}
			if(IsObject(AccessorKeyword))
				pos++
		}
		CAccessor.Instance.Keywords := this.AccessorKeywords.DeepCopy()
	}
	btnAddAccessorKeyword_Click()
	{
		this.AddAccessorKeyword()
	}
	;This function is also called by the keywords plugin when a keyword is added through the Accessor window while settings window is open.
	AddAccessorKeyword(Key = "", Command = "")
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		if(Key && index := this.AccessorKeywords.FindKeyWithValue("Key", Key))
		{
			this.AccessorKeywords[index].Command := Command
			Page.listAccessorKeywords.Items[index][2] := Command
		}
		else
		{
			this.AccessorKeywords.Insert(Object("Key", Key, "Command", Command))
			Item := Page.listAccessorKeywords.Items.Add("Select", Key, Command)
			Page.listAccessorKeywords.SelectedItem := Item
			this.ActiveControl := Page.listAccessorKeywords
		}
	}
	btnDeleteAccessorKeyword_Click()
	{
		this.DeleteAccessorKeyword()
	}
	DeleteAccessorKeyword()
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		if(Page.listAccessorKeywords.SelectedItems.MaxIndex() != 1)
			return
		SelectedIndex := Page.listAccessorKeywords.SelectedIndex
		this.AccessorKeywords.Remove(SelectedIndex)
		Page.listAccessorKeywords.Items.Delete(SelectedIndex)
		if(SelectedIndex > Page.listAccessorKeywords.Items.MaxIndex())
			SelectedIndex := Page.listAccessorKeywords.Items.MaxIndex()
		Page.listAccessorKeywords.SelectedIndex := SelectedIndex
		this.ActiveControl := Page.listAccessorKeywords
	}
	listAccessorKeywords_SelectionChanged(Row)
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		SingleSelection := Page.listAccessorKeywords.SelectedItems.MaxIndex() = 1
		Page.EditAccessorKeyword.Text := SingleSelection ? Page.listAccessorKeywords.SelectedItem[1] : ""
		Page.EditAccessorCommand.Text := SingleSelection ? Page.listAccessorKeywords.SelectedItem[2] : ""
		Page.EditAccessorKeyword.Enabled := SingleSelection
		Page.EditAccessorCommand.Enabled := SingleSelection
		Page.btnDeleteAccessorKeyword.Enabled := SingleSelection
		this.ActiveControl := Page.listAccessorKeywords
	}
	EditAccessorKeyword_TextChanged()
	{
		Page := this.Pages.Keywords.Tabs[1].Controls
		if(Page.listAccessorKeywords.SelectedItems.MaxIndex() != 1)
			return
		
		Page.listAccessorKeywords.SelectedItem[1] := Page.EditAccessorKeyword.Text
		this.AccessorKeywords[Page.listAccessorKeywords.SelectedIndex].key := Page.EditAccessorKeyword.Text
	}
	EditAccessorCommand_TextChanged()
	{		
		Page := this.Pages.Keywords.Tabs[1].Controls
		if(Page.listAccessorKeywords.SelectedItems.MaxIndex() != 1)
			return
		
		Page.listAccessorKeywords.SelectedItem[2] := Page.EditAccessorCommand.Text
		this.AccessorKeywords[Page.listAccessorKeywords.SelectedIndex].Command := Page.EditAccessorCommand.Text
	}
	
	;Clipboard
	CreateClipboard()
	{
		Page := this.Pages.Clipboard.Tabs[1]
		
		Page.AddControl("Text", "txtClipboardDescription", "xs+21 ys+19", "You can define custom clips here that can be inserted through the clipboard manager menu (Default: WIN + V)`nor through Accessor (Default: ALT + Space). These clips support %Parameters%.")
		
		Page.AddControl("Button", "btnAddClip", "xs+554 ys+49 w90 h23", "&Add Clip")
		Page.AddControl("Button", "btnDeleteClip", "xs+554 ys+79 w90 h23", "&Delete Clip")
		Page.AddControl("ListView", "listClipboard", "xs+21 ys+49 w525 h152", "Name|Text")
		Page.Controls.listClipboard.IndependentSorting := true
		
		Page.AddControl("Text", "txtClipboardName", "xs+21 ys+210 w51 h13", "Name:")
		Page.AddControl("Edit", "editClipboardName", "xs+84 ys+207 w462 h20", "")
		Page.Controls.editClipboardName.ToolTip := "The name of the clip"
		Page.AddControl("Text", "txtClipboardText", "xs+21 ys+236 w57 h13", "Text:")
		Page.AddControl("Edit", "editClipboardText", "xs+84 ys+233 w462 r7 Multi", "")
		Page.Controls.editClipboardText.ToolTip := "The text of the clip. You can use parameters like this: ""Hello %Name%""`nWhen the clip is inserted, a dialog will show up and ask for a value."

		Page.AddControl("Text", "txtClipboardIgnoreDescription", "xs+21 ys+353", "The programs listed here will be ignored by any clipboard related functions of 7plus. This can be used`nto protect the privacy of some clipboard contents such as passwords copied by password managers.")
		Page.AddControl("Button", "btnAddClipboardProgram", "xs+554 ys+383 w90 h23", "Add Program")
		Page.AddControl("Button", "btnDeleteClipboardProgram", "xs+554 ys+413 w90 h23", "Delete Program")
		Page.AddControl("ListBox", "listClipboardIgnore", "xs+21 ys+383 w525 h120", "")
	}
	InitClipboard()
	{
		global ClipboardList
		Page := this.Pages.Clipboard.Tabs[1].Controls
		this.ClipboardList := ClipboardList.Persistent.DeepCopy()
		Page.listClipboard.Items.Clear()
		Page.listClipboard.ModifyCol(1, 100)
		Page.listClipboard.ModifyCol(2, "AutoHdr")
		Loop % this.ClipboardList.MaxIndex()
			Page.listClipboard.Items.Add(A_Index = 1 ? "Select" : "", this.ClipboardList[A_Index].Name, this.ClipboardList[A_Index].Text)
		this.listClipboard_SelectionChanged("")

		for index, program in ToArray(Settings.Misc.IgnoredPrograms, "|")
			Page.listClipboardIgnore.Items.Add(program)
	}

	ShowClipboard()
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		this.ActiveControl := Page.listClipboard
	}

	ApplyClipboard()
	{
		global ClipboardList
		Page := this.Pages.Clipboard.Tabs[1].Controls
		;Find duplicates
		pos := 1
		len := this.ClipboardList.MaxIndex()
		Loop % len
		{
			Clip := this.ClipboardList[A_Index]
			Loop % this.ClipboardList.MaxIndex()
			{
				if(pos != A_Index && this.ClipboardList[A_Index].Name = ClipboardList.Persistent.Name)
				{
					this.ClipboardList.Remove(pos)
					Clip := ""
					break
				}
			}
			if(IsObject(Clip))
				pos++
		}
		ClipboardList.Persistent := this.ClipboardList.DeepCopy()

		IgnoredPrograms := ""
		for index, item in Page.listClipboardIgnore.Items
			IgnoredPrograms .= (A_Index = 1 ? "" : "|") item.Text
		Settings.Misc.IgnoredPrograms := IgnoredPrograms
	}
	btnAddClip_Click()
	{
		this.AddClip()
	}
	AddClip()
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		this.ClipboardList.Insert(Object("Name", "Name", "Text", "Text"))
		Item := Page.listClipboard.Items.Add("Select", "Name", "Text")
		Page.listClipboard.SelectedItem := Item
		this.ActiveControl := Page.listClipboard
	}
	btnDeleteClip_Click()
	{
		this.DeleteClip()
	}
	DeleteClip()
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		if(Page.listClipboard.SelectedItems.MaxIndex() != 1)
			return
		SelectedIndex := Page.listClipboard.SelectedIndex
		this.ClipboardList.Remove(SelectedIndex)
		Page.listClipboard.Items.Delete(SelectedIndex)
		if(SelectedIndex > Page.listClipboard.Items.MaxIndex())
			SelectedIndex := Page.listClipboard.Items.MaxIndex()
		Page.listClipboard.SelectedIndex := SelectedIndex
		this.ActiveControl := Page.listClipboard
	}
	listClipboard_SelectionChanged(Row)
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		SingleSelection := Page.listClipboard.SelectedItems.MaxIndex() = 1
		Page.editClipboardName.Text := SingleSelection ? this.ClipboardList[Page.listClipboard.SelectedIndex].Name : ""
		Page.editClipboardText.Text := SingleSelection ? this.ClipboardList[Page.listClipboard.SelectedIndex].Text : ""
		Page.editClipboardName.Enabled := SingleSelection
		Page.editClipboardText.Enabled := SingleSelection
		Page.btnDeleteClip.Enabled := SingleSelection
		this.ActiveControl := Page.listClipboard
	}
	editClipboardName_TextChanged()
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		if(Page.listClipboard.SelectedItems.MaxIndex() != 1)
			return
		Page.listClipboard.SelectedItem[1] := Page.editClipboardName.Text
		this.ClipboardList[Page.listClipboard.SelectedIndex].Name := Page.editClipboardName.Text
	}
	editClipboardText_TextChanged()
	{		
		Page := this.Pages.Clipboard.Tabs[1].Controls
		if(Page.listClipboard.SelectedItems.MaxIndex() != 1)
			return
		
		Page.listClipboard.SelectedItem[2] := Page.editClipboardText.Text
		this.ClipboardList[Page.listClipboard.SelectedIndex].Text := Page.editClipboardText.Text
	}
	
	btnAddClipboardProgram_Click()
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		fd := new CFileDialog("Open")
		fd.Filter := "Executable files (*.exe)"
		if(fd.Show())
		{
			SplitPath(fd.Filename, Filename)
			Page.listClipboardIgnore.Items.Add(Filename)
		}
			
	}

	btnDeleteClipboardProgram_Click()
	{
		Page := this.Pages.Clipboard.Tabs[1].Controls
		Page.listClipboardIgnore.Items.Delete(Page.listClipboardIgnore.SelectedIndex)
	}

	;Explorer
	CreateExplorer()
	{
		Page := this.Pages.Explorer.Tabs[1]
		Page.AddControl("CheckBox", "chkAutoCheckApplyToAllFiles", "xs+40 ys+134", "Automatically check ""Apply to all further operations"" checkboxes in file operations")
		;~ Page.AddControl("Link", "linkAutoCheckApplyToAllFiles", "xs+21 ys+135 w13 h13", "?")
		Page.AddControl("CheckBox", "chkAdvancedStatusBarInfo", "xs+40 ys+111" (WinVer != Win_7 ? " Disabled" : ""), "Show free space and size of selected files in status bar like in XP (7 only)")
		;~ Page.AddControl("Link", "linkAdvancedStatusBarInfo", "xs+21 ys+112 w13 h13", "?")
		Page.AddControl("CheckBox", "chkScrollTreeUnderMouse", "xs+40 ys+88", "Scroll explorer scrollbars with mouse over them when they are not focused")
		;~ Page.AddControl("Link", "linkScrollTreeUnderMouse", "xs+21 ys+89 w13 h13", "?")
		Page.Controls.chkScrollTreeUnderMouse.ToolTip := "This makes it possible to scroll the file tree or the file list when another part of the explorer window is focused."
		Page.AddControl("CheckBox", "chkImproveEnter", "xs+40 ys+65", "Files which are only focussed but not selected can be executed by pressing enter")
		;~ Page.AddControl("Link", "linkImproveEnter", "xs+21 ys+66 w13 h13", "?")
		Page.AddControl("CheckBox", "chkAutoSelectFirstFile", "xs+40 ys+42", "Explorer automatically selects the first file when you enter a directory")
		;~ Page.AddControl("Link", "linkAutoSelectFirstFile", "xs+21 ys+43 w13 h13", "?")
		Page.AddControl("CheckBox", "chkMouseGestures", "xs+40 ys+19", "Hold right mouse button and click left: Go back, hold left mouse and click right: Go Forward")
		;~ Page.AddControl("Link", "linkMouseGestures", "xs+21 ys+20 w13 h13", "?")
		Page.AddControl("CheckBox", "chkRememberPath", "xs+40 ys+157", "Win+E: Open explorer in last active directory")
		Page.AddControl("CheckBox", "chkAlignNewExplorer", "xs+40 ys+180", "Win+E + explorer window active: Open new explorer and align them left and right")
		Page.AddControl("CheckBox", "chkEnhancedRenaming", "xs+40 ys+203", "F2 while renaming: Toggle between filename, extension and full name")
		
		Page.AddControl("Text", "txtPasteAsFile", "xs+37 ys+256 h13", "Text and images from clipboard can be pasted as file in explorer with these settings")
		chkPasteImageAsFileName := Page.AddControl("CheckBox", "chkPasteImageAsFileName", "xs+40 ys+304", "Paste image as file")
		;~ Page.AddControl("Link", "linkPasteImageAsFileName", "xs+21 ys+275 w13 h13", "?")
		chkPasteTextAsFileName := Page.AddControl("CheckBox", "chkPasteTextAsFileName", "xs+40 ys+278", "Paste text as file")
		;~ Page.AddControl("Link", "linkPasteTextAsFileName", "xs+21 ys+249 w13 h13", "?")
		Page.AddControl("Text", "txtPasteImageAsFileName", "x448 ys+305", "Filename:")
		Page.AddControl("Text", "txtPasteTextAsFileName", "x448 ys+279", "Filename:")
		Page.Controls.editPasteImageAsFileName := chkPasteImageAsFileName.AddControl("Edit", "editPasteImageAsFileName", "x506 ys+302 w150", "", 1)
		Page.Controls.editPasteTextAsFileName := chkPasteTextAsFileName.AddControl("Edit", "editPasteTextAsFileName", "x506 ys+276 w150", "", 1)
	}
	InitExplorer()
	{
		Page := this.Pages.Explorer.Tabs[1].Controls
		Page.chkAutoCheckApplyToAllFiles.Checked := Settings.Explorer.AutoCheckApplyToAllFiles
		Page.chkAdvancedStatusBarInfo.Checked := Settings.Explorer.AdvancedStatusBarInfo
		Page.chkScrollTreeUnderMouse.Checked := Settings.Explorer.ScrollTreeUnderMouse
		Page.chkImproveEnter.Checked := Settings.Explorer.ImproveEnter
		Page.chkAutoSelectFirstFile.Checked := Settings.Explorer.AutoSelectFirstFile
		Page.chkMouseGestures.Checked := Settings.Explorer.MouseGestures
		Page.chkRememberPath.Checked := Settings.Explorer.RememberPath
		Page.chkAlignNewExplorer.Checked := Settings.Explorer.AlignNewExplorer
		Page.chkEnhancedRenaming.Checked := Settings.Explorer.EnhancedRenaming
		Page.chkPasteImageAsFileName.Checked := Settings.Explorer.PasteImageAsFileName != ""
		Page.chkPasteTextAsFileName.Checked := Settings.Explorer.PasteTextAsFileName != ""
		Page.editPasteImageAsFileName.Text := Settings.Explorer.PasteImageAsFileName
		Page.editPasteTextAsFileName.Text := Settings.Explorer.PasteTextAsFileName
	}
	ApplyExplorer()
	{
		Page := this.Pages.Explorer.Tabs[1].Controls
		Settings.Explorer.AutoCheckApplyToAllFiles := Page.chkAutoCheckApplyToAllFiles.Checked
		Settings.Explorer.AdvancedStatusBarInfo := Page.chkAdvancedStatusBarInfo.Checked
		Settings.Explorer.ScrollTreeUnderMouse := Page.chkScrollTreeUnderMouse.Checked
		Settings.Explorer.ImproveEnter := Page.chkImproveEnter.Checked
		Settings.Explorer.AutoSelectFirstFile := Page.chkAutoSelectFirstFile.Checked
		Settings.Explorer.MouseGestures := Page.chkMouseGestures.Checked
		Settings.Explorer.RememberPath := Page.chkRememberPath.Checked
		Settings.Explorer.AlignNewExplorer := Page.chkAlignNewExplorer.Checked
		Settings.Explorer.EnhancedRenaming := Page.chkEnhancedRenaming.Checked
		
		Settings.Explorer.PasteImageAsFileName := Page.editPasteImageAsFileName.Text
		Settings.Explorer.PasteTextAsFileName := Page.editPasteTextAsFileName.Text
	}
	
	;Explorer Tabs
	CreateExplorerTabs()
	{
		Page := this.Pages.ExplorerTabs.Tabs[1]
		chkUseTabs := Page.AddControl("CheckBox", "chkUseTabs", "xs+40 ys+62 h17", "Use Tabs in Explorer")
		Page.AddControl("Text", "txtNewTabPosition", "xs+56 ys+87 w70 h13", "Create tabs:")
		Page.Controls.ddlNewTabPosition := chkUseTabs.AddControl("DropDownList", "ddlNewTabPosition", "xs+308 ys+85 w159", "Next to current tab|At the end", 1)
		Page.AddControl("Text", "txtTabStartupPath", "xs+56 ys+115 w190 h13", "Tab startup path (empty for current dir):")
		Page.Controls.editTabStartupPath := chkUseTabs.AddControl("Edit", "editTabStartupPath", "xs+308 ys+112 w159 h20", "", 1)
		Page.Controls.btnTabStartupPath := chkUseTabs.AddControl("Button", "btnTabStartupPath", "xs+473 ys+110 w33 h23", "...", 1)
		Page.AddControl("Text", "txtOnTabClose", "xs+56 ys+188 w64 h13", "On tab close:")
		Page.Controls.ddlOnTabClose := chkUseTabs.AddControl("DropDownList", "ddlOnTabClose", "xs+308 ys+184 w159", "Activate left tab|Activate right tab", 1)
		Page.AddControl("Text", "txtTabDescription", "xs+40 ys+20 w469 h39", "7plus makes it possible to use tabs in explorer. New tabs are opened with the middle mouse button,`nand with CTRL+T, Tabs are cycled by clicking the Tabs or pressing CTRL+(SHIFT)+TAB,`nand closed by middle clicking a tab and with CTRL+W.")
		Page.Controls.chkTabWindowClose := chkUseTabs.AddControl("CheckBox", "chkTabWindowClose", "xs+53 ys+161 h17", "Close all tabs when window is closed", 1)
		Page.Controls.chkActivateTab := chkUseTabs.AddControl("CheckBox", "chkActivateTab", "xs+53 ys+138 h17", "Activate tab on tab creation", 1)
	}
	InitExplorerTabs()
	{
		Page := this.Pages.ExplorerTabs.Tabs[1].Controls
		Page.chkUseTabs.Checked := Settings.Explorer.Tabs.UseTabs
		Page.ddlNewTabPosition.SelectedIndex := Settings.Explorer.Tabs.NewTabPosition
		Page.editTabStartupPath.Text := Settings.Explorer.Tabs.TabStartupPath
		Page.chkActivateTab.Checked := Settings.Explorer.Tabs.ActivateTab
		Page.chkTabWindowClose.Checked := Settings.Explorer.Tabs.TabWindowClose
		Page.ddlOnTabClose.SelectedIndex := Settings.Explorer.Tabs.OnTabClose
	}
	ApplyExplorerTabs()
	{
		Page := this.Pages.ExplorerTabs.Tabs[1].Controls
		Settings.Explorer.Tabs.UseTabs := Page.chkUseTabs.Checked
		Settings.Explorer.Tabs.NewTabPosition := Page.ddlNewTabPosition.SelectedIndex
		Settings.Explorer.Tabs.TabStartupPath := Page.editTabStartupPath.Text
		Settings.Explorer.Tabs.ActivateTab := Page.chkActivateTab.Checked
		Settings.Explorer.Tabs.TabWindowClose := Page.chkTabWindowClose.Checked
		Settings.Explorer.Tabs.OnTabClose := Page.ddlOnTabClose.SelectedIndex
	}
	btnTabStartupPath_Click()
	{
		FolderDialog := new CFolderDialog()
		FolderDialog.Folder := this.Page.ExplorerTabs.Tabs[1].Controls.editTabStartupPath.Text
		if(FolderDialog.Show())
			this.Page.ExplorerTabs.Tabs[1].Controls.editTabStartupPath.Text := FolderDialog.Folder
	}
	
	
	;Fast Folders
	CreateFastFolders()
	{
		Page := this.Pages.FastFolders.Tabs[1]
		Page.AddControl("Text", 	"txtFastFoldersDescription", 	"xs+37 ys+20", 	"In explorer and file dialogs you can store a path in one of ten slots by pressing CTRL`nand a numpad number key (default settings), and restore it by pressing the numpad number key again.")
		Page.AddControl("CheckBox", "chkShowInFolderBand",			"xs+40 ys+51", 	"Integrate Fast Folders into explorer folder band bar (Vista/7 only)")
		Page.AddControl("CheckBox", "chkCleanFolderBand", 			"xs+40 ys+74", 	"Remove windows folder band buttons (Vista/7 only)")
		Page.Controls.chkCleanFolderBand.ToolTip := "If you use the folder band as a favorites bar like in browsers, it is recommended that you get rid of the buttons predefined by windows whereever possible (such as Slideshow, Add to Library,...)"
		
		Page.AddControl("CheckBox", "chkShowInPlacesBar", 			"xs+40 ys+97", 	"Integrate Fast Folders into open/save dialog places bar (First 5 Entries)")
		Page.AddControl("Button", 	"btnRemoveCustomButtons", 		"xs+40 ys+120", "&Remove custom Explorer buttons")
		Page.Controls.btnRemoveCustomButtons.ToolTip := "By doing this all custom buttons in the explorer folder band bar will be removed. This is useful if an error occurred and some buttons get duplicated. Once you press OK or Apply in this dialog, the buttons created with an ExplorerButton trigger will reappear. To make the FastFolder buttons reappear, save a directory to a FastFolder slot by pressing CTRL+Numpad[0-9] (Default keys)"
	}
	InitFastFolders()
	{
		Page := this.Pages.FastFolders.Tabs[1].Controls
		if(WinVer >= WIN_Vista && WinVer < WIN_8)
		{
			Page.chkShowInFolderBand.Checked := Settings.Explorer.FastFolders.ShowInFolderBand
			Page.chkCleanFolderBand.Checked := Settings.Explorer.FastFolders.CleanFolderBand
		}
		else
		{
			Page.chkShowInFolderBand.Enabled := false
			Page.chkCleanFolderBand.Enabled := false
			Page.btnRemoveCustomButtons.Enabled := false
		}
		Page.chkShowInPlacesBar.Checked := Settings.Explorer.FastFolders.ShowInPlacesBar
	}
	ApplyFastFolders()
	{
		Page := this.Pages.FastFolders.Tabs[1].Controls
		
		;Folder band settings are only usable when running non-portable as admin
		if(!ApplicationState.IsPortable || !A_IsAdmin)
		{
			if(WinVer >= WIN_Vista && WinVer < WIN_8)
			{
				if(Page.chkShowInFolderBand.Checked != Settings.Explorer.FastFolders.ShowInFolderBand || this.RequireFastFolderRecreation)
				{
					if(!Settings.Explorer.FastFolders.ShowInFolderBand || this.RequireFastFolderRecreation) ;Was off, enable
						SetTimer, PrepareFolderBand, -1000 ;Call as timer so that applying settings appears faster (but it isn't!)
					else
						RestoreFolderBand()
				}
				Settings.Explorer.FastFolders.ShowInFolderBand := Page.chkShowInFolderBand.Checked
				
				if(Page.chkCleanFolderBand.Checked != Settings.Explorer.FastFolders.CleanFolderBand)
				{
					if(!Settings.Explorer.FastFolders.CleanFolderBand) ;Was off, enable
						BackupAndRemoveFolderBandButtons()
					else
						RestoreFolderBandButtons()
				}
				Settings.Explorer.FastFolders.CleanFolderBand := Page.chkCleanFolderBand.Checked
			}
			if(Page.chkShowInPlacesBar.Checked != Settings.Explorer.FastFolders.ShowInPlacesBar)
			{
				if(!Settings.Explorer.FastFolders.ShowInPlacesBar) ;Was off, enable
					BackupPlacesBar()
				else
					RestorePlacesBar()
			}
			Settings.Explorer.FastFolders.ShowInPlacesBar := Page.chkShowInPlacesBar.Checked			
		}
	}
	btnRemoveCustomButtons_Click()
	{
		if(WinVer >= WIN_Vista && WinVer < WIN_8)
		{
			RemoveAllExplorerButtons()
			this.RequireFastFolderRecreation := true
			MsgBox If you have defined any custom explorer buttons (or use FastFolder buttons) and you press OK or Apply now, they will reappear!
		}
	}
	
	
	;FTP Profiles
	CreateFTPProfiles()
	{
		Page := this.Pages.FTPProfiles.Tabs[1]
					Page.AddControl("Text",			"txtFTPDescription",		"xs+37 ys+20", 				"You can define FTP profiles for use with the upload action here.`nBy default the selected files and folders can be uploaded by pressing CTRL + U.")
					Page.AddControl("DropDownList",	"ddlFTPProfile",			"xs+37 ys+62 w297", 		"")
					Page.AddControl("Button",		"btnAddFTPProfile",			"x+10 ys+60",				"&Add profile")
					Page.AddControl("Button",		"btnDeleteFTPProfile",		"x+10",						"&Delete profile")
					Page.AddControl("Button",		"btnTestFTPProfile",		"x+30",						"&Test profile")
					Page.AddControl("Text",			"txtFTPHostname",			"xs+37 ys+101",				"Hostname:")
					Page.AddControl("Edit",			"editFTPHostname",			"xs+258 ys+98",				"")
					Page.AddControl("Text",			"txtFTPPort",				"xs+37 ys+127",				"Port:")
					Page.AddControl("Edit",			"editFTPPort",				"xs+258 ys+124",			"")
					Page.AddControl("Text",			"txtFTPUser",				"xs+37 ys+153",				"User:")
					Page.AddControl("Edit",			"editFTPUser",				"xs+258 ys+150",			"")
					Page.AddControl("Text",			"txtFTPPassword",			"xs+37 ys+179",				"Password:")
					Page.AddControl("Edit",			"editFTPPassword",			"xs+258 ys+176 Password", 	"")
					Page.AddControl("Text",			"txtFTPURL",				"xs+37 ys+203",				"URL:")
					Page.AddControl("Edit",			"editFTPURL",				"xs+258 ys+200",			"")
					Page.AddControl("Text",			"txtFTPNumberOfSubDirs",	"xs+37 ys+227",				"Number of subdirectories:")
		subdirs := 	Page.AddControl("Edit",			"editFTPNumberOfSubDirs",	"xs+258 ys+224",			"")
		subdirs.ToolTip := "Some webservers display a deeper file structure on FTP compared to the HTTP URL.`nEnter the number of additional directories here to adjust the copied URL"
					
					Page.AddControl("Text",			"txtFTPDescription2",		"xs+37 ys+259", 			"Target folder and filename are set separately for each event that uses the FTP upload function on the Events page.")
	}

	InitFTPProfiles()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		this.FTPProfiles := CFTPUploadAction.FTPProfiles.DeepCopy()
		Page.ddlFTPProfile.Items.Clear()
		Loop % this.FTPProfiles.MaxIndex()
			Page.ddlFTPProfile.Items.Add(A_Index ": " this.FTPProfiles[A_Index].Hostname)
		Page.ddlFTPProfile.SelectedIndex := 1
		Page.ddlFTPProfile.Enabled := this.FTPProfiles.MaxIndex() > 0
		this.ddlFTPProfile_SelectionChanged()
	}

	ApplyFTPProfiles()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		this.StoreCurrentFTPProfile(this.FTPProfiles[Page.ddlFTPProfile.SelectedIndex])
		CFTPUploadAction.FTPProfiles := this.FTPProfiles
	}

	HideFTPProfiles()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		this.StoreCurrentFTPProfile(this.FTPProfiles[Page.ddlFTPProfile.SelectedIndex])
	}

	StoreCurrentFTPProfile(CurrentProfile)
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		if(CurrentProfile)
		{
			CurrentProfile.Hostname := strTrimRight(Page.editFTPHostname.Text, "/")
			CurrentProfile.Port := Page.editFTPPort.Text
			CurrentProfile.User := Page.editFTPUser.Text
			CurrentProfile.Password := Encrypt(Page.editFTPPassword.Text)
			CurrentProfile.URL := strTrimRight(Page.editFTPURL.Text, "/")
			CurrentProfile.NumberOfFTPSubDirs := Page.editFTPNumberOfSubDirs.Text
		}
	}

	btnAddFTPProfile_Click()
	{
		this.AddFTPProfile()
	}

	AddFTPProfile()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		this.FTPProfiles.Insert(Object("Hostname", "Hostname.com", "Port", 21, "User", "SomeUser", "Password", "", "URL", "http://somehost.com", "NumberOfFTPSubDirs", 0))
		len := this.FTPProfiles.MaxIndex()
		Page.ddlFTPProfile.Items.Add(len ": " this.FTPProfiles[len].Hostname)
		Page.ddlFTPProfile.SelectedIndex := len
		Page.ddlFTPProfile.Enabled := true
	}

	btnDeleteFTPProfile_Click()
	{
		this.DeleteFTPProfile()
	}

	DeleteFTPProfile()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		if(!this.FTPProfiles.MaxIndex())
			return
		this.FTPProfiles.Remove(Page.ddlFTPProfile.SelectedIndex)
		Page.ddlFTPProfile.Items.Delete(Page.ddlFTPProfile.SelectedIndex)
		if(!this.FTPProfiles.MaxIndex())
			Page.ddlFTPProfile.Enabled := false
		Notify("Info", "Make sure to update any FTP event profile assignments that pointed to the deleted profile!", 2, NotifyIcons.Info)
	}

	btnTestFTPProfile_Click()
	{
		this.TestFTPProfile()
	}

	TestFTPProfile()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		if(!this.FTPProfiles.MaxIndex())
			return
		Page.editFTPURL.Text
		FTP := FTP_Init()
		FTP.Port := Page.editFTPPort.Text
		FTP.Hostname := Page.editFTPHostname.Text
		if(!FTP.Open(FTP.Hostname, Page.editFTPUser.Text, Page.editFTPPassword.Text))
		{
			MsgBox % "Could not connect to " FTP.HostName "!"
			return 0
		}
		FTP.Close()
		MsgBox % "Connection to " FTP.Hostname " successfully established!"
		return 1
	}

	ddlFTPProfile_SelectionChanged()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		if(IsObject(Page.ddlFTPProfile.PreviouslySelectedItem))
			this.StoreCurrentFTPProfile(this.FTPProfiles[Page.ddlFTPProfile.PreviouslySelectedItem._.Index])
		SelectedIndex := Page.ddlFTPProfile.SelectedIndex
		FTPProfile := this.FTPProfiles[SelectedIndex]
		Page.editFTPHostname.Text := FTPProfile ? FTPProfile.Hostname : ""
		Page.editFTPPort.Text := FTPProfile ? FTPProfile.Port : ""
		Page.editFTPUser.Text := FTPProfile ? FTPProfile.User : ""
		Page.editFTPPassword.Text := FTPProfile ? Decrypt(FTPProfile.Password) : ""
		Page.editFTPURL.Text := FTPProfile ? FTPProfile.URL : ""
		Page.editFTPNumberOfSubDirs.Text := FTPProfile ? FTPProfile.NumberOfFTPSubDirs : ""
		Page.editFTPHostname.Enabled := IsObject(FTPProfile)
		Page.editFTPPort.Enabled := IsObject(FTPProfile)
		Page.editFTPUser.Enabled := IsObject(FTPProfile)
		Page.editFTPPassword.Enabled := IsObject(FTPProfile)
		Page.editFTPURL.Enabled := IsObject(FTPProfile)
		Page.editFTPNumberOfSubDirs.Enabled := IsObject(FTPProfile)
	}

	editFTPHostname_TextChanged()
	{
		Page := this.Pages.FTPProfiles.Tabs[1].Controls
		if(FTPProfile := this.FTPProfiles[Page.ddlFTPProfile.SelectedIndex])
			Page.ddlFTPProfile.SelectedItem.Text := Page.ddlFTPProfile.SelectedIndex ": " Page.editFTPHostname.Text
	}
	
	
	;HotStrings
	CreateHotStrings()
	{
		Page := this.Pages.HotStrings.Tabs[1]
		Page.AddControl("Text",		"txtHotStringDescription",	"xs+21 ys+364", 			"HotStrings are used to expand abbreviations and acronyms, such as ""btw"" -> ""by the way"". They support regular`nexpressions in PCRE format. If you want a HotString to trigger only when typed as a seperate word, prepend \b`nand append \s.  For case-insensitive HotStrings, put i) at the start. You can also use keys like {Enter}.")
		Page.AddControl("ListView",	"listHotStrings",		 	"xs+21 ys+19 w525 h282", 	"HotString|Output")
		Page.Controls.listHotStrings.IndependentSorting := true
		
		Page.AddControl("Button",	"btnAddHotString",		 	"xs+554 ys+19", 			"&Add HotString")
		Page.AddControl("Button",	"btnDeleteHotString",		"xs+554 ys+48", 			"&Delete HotString")
		Page.AddControl("Text",		"txtHotStringInput",		"xs+21 ys+310", 			"HotString:")
		Page.AddControl("Edit",		"editHotStringInput",		"xs+84 ys+307", 			"")
		Page.AddControl("Text",		"txtHotStringOutput",		"xs+21 ys+336", 			"Output:")
		Page.AddControl("Edit",		"editHotStringOutput",		"xs+84 ys+333", 			"")
		Page.AddControl("Button",	"btnHotStringRegExHelp",	"xs+554 ys+77", 			"&RegEx Help")
	}

	InitHotStrings()
	{
		global HotStrings
		Page := this.Pages.HotStrings.Tabs[1].Controls
		Page.listHotStrings.Items.Clear()
		Page.listHotStrings.ModifyCol(1, 150)
		Page.listHotStrings.ModifyCol(2, "AutoHdr")
		for index, HotString in HotStrings
			Page.listHotStrings.Items.Add(A_Index = 1 ? "Select" : "", HotString.Key, HotString.Value)
		this.listHotStrings_SelectionChanged("")
	}

	ShowHotStrings()
	{
		Page := this.Pages.HotStrings.Tabs[1].Controls
		this.ActiveControl := Page.listHotStrings
	}

	ApplyHotStrings()
	{
		global HotStrings
		Page := this.Pages.HotStrings.Tabs[1].Controls
		
		;Unregister the old hotstrings
		for index, HotString in HotStrings
			hotstrings(HotString.Key, "")
		
		;Find duplicates and register new hotstrings
		localHotStrings := []
		for index, HotString in Page.listHotStrings.Items
			localHotStrings.Insert({key : HotString[1], value : HotString[2]})
		
		pos := 1
		Loop % localHotStrings.MaxIndex()
		{
			HotString1 := localHotStrings[pos]
			for index2, HotString2 in localHotStrings
			{
				if(pos != index2 && HotString2.Key = HotString1.Key)
				{
					localHotStrings.Remove(pos)
					HotString1 := ""
					break
				}
			}
			if(IsObject(HotString1))
			{
				pos++
				hotstrings(HotString1.Key, HotString1.Value)
			}
		}
		HotStrings := localHotStrings
	}
	btnAddHotString_Click()
	{
		this.AddHotString()
	}
	AddHotString()
	{
		Page := this.Pages.HotStrings.Tabs[1].Controls
		Item := Page.listHotStrings.Items.Add("Select", "HotString", "Output")
		Page.listHotStrings.SelectedItem := Item
		this.ActiveControl := Page.listAccessorKeywords
	}	
	btnDeleteHotString_Click()
	{
		this.DeleteHotString()
	}
	DeleteHotString()
	{
		Page := this.Pages.HotStrings.Tabs[1].Controls
		if(Page.listHotStrings.SelectedItems.MaxIndex() != 1)
			return
		SelectedIndex := Page.listHotStrings.SelectedIndex
		Page.listHotStrings.Items.Delete(SelectedIndex)		
		if(SelectedIndex > Page.listHotStrings.Items.MaxIndex())
			SelectedIndex := Page.listHotStrings.Items.MaxIndex()
		Page.listHotStrings.SelectedIndex := SelectedIndex
		this.ActiveControl := Page.listHotStrings
	}	
	listHotStrings_SelectionChanged(Row)
	{
		Page := this.Pages.HotStrings.Tabs[1].Controls
		SingleSelection := Page.listHotStrings.SelectedItems.MaxIndex() = 1
		Page.editHotStringInput.Text := SingleSelection ? Page.listHotStrings.SelectedItem[1] : ""
		Page.editHotStringOutput.Text := SingleSelection ? Page.listHotStrings.SelectedItem[2] : ""
		Page.editHotStringInput.Enabled := SingleSelection
		Page.editHotStringOutput.Enabled := SingleSelection
		Page.btnDeleteHotString.Enabled := SingleSelection
		this.ActiveControl := Page.listHotStrings
	}
	EditHotStringInput_TextChanged()
	{
		Page := this.Pages.HotStrings.Tabs[1].Controls
		if(Page.listHotStrings.SelectedItems.MaxIndex() != 1)
			return
		
		Page.listHotStrings.SelectedItem[1] := Page.editHotStringInput.Text
	}
	editHotStringOutput_TextChanged()
	{		
		Page := this.Pages.HotStrings.Tabs[1].Controls
		if(Page.listHotStrings.SelectedItems.MaxIndex() != 1)
			return
		
		Page.listHotStrings.SelectedItem[2] := Page.editHotStringOutput.Text
	}
	btnHotStringRegExHelp_Click()
	{
		run http://www.autohotkey.com/docs/misc/RegEx-QuickRef.htm
	}
	

	;Windows
	CreateIfThisThenThatIntegration()
	{
		Page := this.Pages.IfThisThenThatIntegration.Tabs[1]
		Page.AddControl("Link", 		"lnkIfThisThenThatDescription",			"xs+42 ys+20",					"7plus can be used with <A HREF=""www.ifttt.com"">If this then that</A>, a popular web automation service,`nby sending mails to it with special #tags in the subject. This requires that you have an event in 7plus`nthat sends an email to trigger@ifttt.com from the email address you use in the email channel of ifttt (usually your registration mail).`nAdditionally you need to create a receipt on the page to react to a specific tag in the email subject.`nHere you can enter your email details to enable the predefined IFTTT events in 7plus and to be able to use the IFTTT action.")
		
		Page.AddControl("Text", 		"txtIfThisThenThatFrom", 				"xs+42 ys+103",					"From:")
		Page.AddControl("Edit", 		"editIfThisThenThatFrom", 				"xs+100 ys+100 w300",			"")
		Page.Controls.editIfThisThenThatFrom.ToolTip := "The email address you use in the email channel of IFTTT"
		Page.AddControl("Text", 		"txtIfThisThenThatServer", 				"xs+42 ys+133",					"Server:")
		Page.AddControl("Edit", 		"editIfThisThenThatServer", 			"xs+100 ys+130 w300",			"")
		Page.Controls.editIfThisThenThatServer.ToolTip := "SMTP Server address, e.g. smtp.gmail.com"
		Page.AddControl("Text", 		"txtIfThisThenThatPort", 				"xs+42 ys+163",					"Port:")
		Page.AddControl("Edit", 		"editIfThisThenThatPort", 				"xs+100 ys+160 w50",			"")
		Page.AddControl("CheckBox", 	"chkIfThisThenThatTLS", 				"xs+42 ys+193",					"TLS")
		Page.AddControl("Text", 		"txtIfThisThenThatUsername", 			"xs+42 ys+223",					"Username:")
		Page.AddControl("Edit", 		"editIfThisThenThatUsername", 			"xs+100 ys+220 w300",			"")
		Page.Controls.editIfThisThenThatUsername.ToolTip := "Email login name, e.g. user@gmail.com"
		Page.AddControl("Text", 		"txtIfThisThenThatPassword", 			"xs+42 ys+253",					"Password:")
		Page.AddControl("Edit", 		"editIfThisThenThatPassword", 			"xs+100 ys+250 w300 Password",	"")
		Page.AddControl("Text", 		"txtIfThisThenThatTimeout", 			"xs+42 ys+283",					"Timeout:")
		Page.AddControl("Edit", 		"editIfThisThenThatTimeout", 			"xs+100 ys+280 w50",			"")
		Page.AddControl("Link", 		"lnkIfThisThenThatRecipeLink",			"xs+42 ys+450",					"Tips:`n• You can find premade recipes for 7plus <A HREF=""http://ifttt.com/people/7plus"">here</A>.`n• 7plus includes an Accessor command to post Twitter messages that uses this method. Enter your details here`n    and use the Twitter recipe from the link of the previous tip, then you can post to Twitter with ""Tweet TEXT"".")
	}

	InitIfThisThenThatIntegration()
	{
		Page := this.Pages.IfThisThenThatIntegration.Tabs[1].Controls
		Page.editIfThisThenThatFrom.Text := Settings.IFTTT.From
		Page.editIfThisThenThatServer.Text := Settings.IFTTT.Server
		Page.editIfThisThenThatPort.Text := Settings.IFTTT.Port
		Page.chkIfThisThenThatTLS.Checked := Settings.IFTTT.TLS
		Page.editIfThisThenThatUsername.Text := Settings.IFTTT.Username
		Page.editIfThisThenThatPassword.Text := Decrypt(Settings.IFTTT.Password)
		Page.editIfThisThenThatTimeout.Text := Settings.IFTTT.Timeout
	}

	ApplyIfThisThenThatIntegration()
	{
		Page := this.Pages.IfThisThenThatIntegration.Tabs[1].Controls
		Settings.IFTTT.From := Page.editIfThisThenThatFrom.Text
		Settings.IFTTT.Server := Page.editIfThisThenThatServer.Text
		Settings.IFTTT.Port := Page.editIfThisThenThatPort.Text
		Settings.IFTTT.TLS := Page.chkIfThisThenThatTLS.Checked
		Settings.IFTTT.Username := Page.editIfThisThenThatUsername.Text
		Settings.IFTTT.Password := Encrypt(Page.editIfThisThenThatPassword.Text)
		Settings.IFTTT.Timeout := Page.editIfThisThenThatTimeout.Text
	}

	
	;Windows
	CreateWindows()
	{
		Page := this.Pages.Windows.Tabs[1]
		Page.AddControl("Text", 		"txtSlideWindows", 						"xs+42 ys+20",			"WIN + SHIFT + Arrow keys: Slide Window function")
		Page.Controls.txtSlideWindows.ToolTip := "A Slide Window is moved off screen and will not be shown until you activate it`n through task bar / ALT + TAB or move the mouse to the border where it was hidden.`nIt will then slide into the screen, and slide out again when the mouse leaves the window`nor when another window gets activated. Deactivate this mode by moving the window`nor pressing WIN+SHIFT+Arrow key in another direction."
		
		Page.AddControl("CheckBox", 	"chkHideSlideWindows", 					"xs+59 ys+45",			"Hide Slide Windows in taskbar and from ALT + TAB")
		Page.AddControl("CheckBox", 	"chkDisableMinimizeAnim", 				"xs+79 ys+68",			"Disable window minimize animation (Recommended)")
		Page.AddControl("CheckBox", 	"chkLimitToOnePerSide", 				"xs+59 ys+91",			"Allow only one Slide Window per screen side")
		Page.AddControl("CheckBox", 	"chkBorderActivationRequiresMouseUp", 	"xs+59 ys+114",			"Require left mouse button to be up to activate slide window at screen border")
		Page.Controls.chkBorderActivationRequiresMouseUp.ToolTip := "This feature is used to prevent accidently activating a slide window while dragging with the mouse.`n It's still possible to drag something to the slide window by holding the modifier key which is set below."
		
		Page.AddControl("Text", 		"txtModifierKey", 						"xs+59 ys+140",			"Slide Windows modifier key:")
		Page.AddControl("DropDownList", "ddlModifierKey", 						"xs+245 ys+137 w111",	"Control|Alt|Shift|Win")
		Page.Controls.ddlModifierKey.ToolTip := "If this key is pressed, the mouse may be moved out of the currently active slide window without sliding it out.`n This is useful if the slide window has child windows that don't overlap with the main window.`n If the option above is enabled, it may also be used to drag something into a hidden slide window by moving the mouse to the screen border and holding this key."
		
		Page.AddControl("CheckBox", 	"chkAutoCloseWindowsUpdate", 			"xs+42 ys+207",			"Automatically close Windows Update reboot notification dialog")
		Page.Controls.chkAutoCloseWindowsUpdate.ToolTip :=  "If you enable this setting you will not be able to open this dialog anymore. You can simply reboot windows though..."
		
		Page.AddControl("CheckBox", 	"chkShowResizeTooltip", 				"xs+42 ys+184",			"Show window size as tooltip while resizing")
	}
	InitWindows()
	{
		Page := this.Pages.Windows.Tabs[1].Controls
		Page.chkHideSlideWindows.Checked := Settings.Windows.SlideWindows.HideSlideWindows
		Page.chkDisableMinimizeAnim.Checked := Page.chkDisableMinimizeAnim.origState := WindowsSettings.GetDisableMinimizeAnim()
		this.chkHideSlideWindows_CheckedChanged()
		
		Page.chkLimitToOnePerSide.Checked := Settings.Windows.SlideWindows.LimitToOnePerSide
		Page.chkBorderActivationRequiresMouseUp.Checked := Settings.Windows.SlideWindows.chkBorderActivationRequiresMouseUp
		Page.ddlModifierKey.Text := Settings.Windows.SlideWindows.ModifierKey
		
		Page.chkAutoCloseWindowsUpdate.Checked := Settings.Windows.AutoCloseWindowsUpdate
		Page.chkShowResizeTooltip.Checked := Settings.Windows.ShowResizeToolTip
	}
	ApplyWindows()
	{
		global SlideWindows
		Page := this.Pages.Windows.Tabs[1].Controls
		
		;Slide Windows need to be notified about changes of its settings
		State := Settings.Windows.SlideWindows.HideSlideWindows
		Settings.Windows.SlideWindows.HideSlideWindows := Page.chkHideSlideWindows.Checked
		if(Settings.Windows.SlideWindows.HideSlideWindows != State)
			SlideWindows.On_HideSlideWindows_Changed()
		
		State := Page.chkDisableMinimizeAnim.Checked
		if(State != Page.chkDisableMinimizeAnim.origState)
		{
			WindowsSettings.SetDisableMinimizeAnim(State)
			Page.chkDisableMinimizeAnim.origState := State
		}

		State := Settings.Windows.SlideWindows.LimitToOnePerSide
		Settings.Windows.SlideWindows.LimitToOnePerSide := Page.chkLimitToOnePerSide.Checked
		if(Settings.Windows.SlideWindows.LimitToOnePerSide != State)
			SlideWindows.On_LimitToOnePerSide_Changed()
		
		Settings.Windows.SlideWindows.BorderActivationRequiresMouseUp := Page.chkBorderActivationRequiresMouseUp.Checked
		Settings.Windows.SlideWindows.ModifierKey := Page.ddlModifierKey.Text
		
		Settings.Windows.AutoCloseWindowsUpdate := Page.chkAutoCloseWindowsUpdate.Checked
		if(Settings.Windows.AutoCloseWindowsUpdate)
			AutoCloseWindowsUpdate(WinExist("Windows Update ahk_class #32770"))
		
		Settings.Windows.ShowResizeToolTip := Page.chkShowResizeTooltip.Checked
	}
	
	chkHideSlideWindows_CheckedChanged()
	{
		Page := this.Pages.Windows.Tabs[1].Controls
		if(Page.chkHideSlideWindows.Checked)
			Page.chkDisableMinimizeAnim.Text := "Disable window minimize animation (Recommended)"
		else
			Page.chkDisableMinimizeAnim.Text := "Disable window minimize animation"
	}
	;WindowsSettings
	CreateWindowsSettings()
	{
		Page := this.Pages.WindowsSettings.Tabs[1]
		Page.AddControl("Text", 	"txtExplorer",					"xs+21 ys+19",			"Explorer:")
		Page.AddControl("CheckBox", "chkRemoveUserDir",				"xs+21 ys+35",			"Remove user directory from directory tree")
		Page.AddControl("CheckBox", "chkRemoveWMP",					"xs+21 ys+58",			"Remove Windows Media Player context menu entries (Play, Add to playlist, Buy music")
		Page.AddControl("CheckBox", "chkRemoveOpenWith",			"xs+21 ys+81",			"Remove ""Open With Webservice or choose program"" dialogs for unknown file extensions")
		Page.AddControl("CheckBox", "chkShowExtensions",			"xs+21 ys+104",			"Always show file extensions")
		Page.AddControl("CheckBox", "chkShowHiddenFiles",			"xs+21 ys+127",			"Show hidden files")
		Page.AddControl("CheckBox", "chkShowSystemFiles",			"xs+21 ys+150",			"Show system files")
		Page.AddControl("CheckBox", "chkRemoveExplorerLibraries",	"xs+21 ys+173",			"Remove explorer libraries (from directory tree and context menus) (WIN7 or later)")
		Page.AddControl("CheckBox", "chkClassicExplorerView",		"xs+21 ys+196",			"Use classic explorer view (XP only)")
		Page.AddControl("Text", 	"txtWindows",					"xs+21 ys+235 w54 h13",	"Windows:")
		Page.AddControl("CheckBox", "chkCycleThroughTaskbarGroup",	"xs+21 ys+251",			"Left click on task group button: cycle through windows (7 or later)")
		Page.AddControl("CheckBox", "chkShowAllNotifications",		"xs+21 ys+274",			"Show all tray notification icons")
		Page.AddControl("CheckBox", "chkRemoveCrashReporting",		"xs+21 ys+297",			"Remove crash reporting dialog")
		Page.AddControl("CheckBox", "chkDisableUAC",				"xs+21 ys+320",			"Disable UAC (Vista or later)")
		Page.AddControl("Text", 	"txtThumbnailHoverTime",		"xs+21 ys+346",			"Taskbar thumbnail hover time [ms] (WIN7 or later):")
		Page.AddControl("Edit", 	"editThumbnailHoverTime",		"xs+258 ys+343",		"")
	}
	InitWindowsSettings()
	{
		Page := this.Pages.WindowsSettings.Tabs[1].Controls
		
		;Loop through all checkbox controls on this page and get the window setting by calling the specific function from WindowsSettings.ahk.
		for Name, Control in Page
			if(Control.Type = "CheckBox")
			{
				Property := WindowsSettings["Get" SubStr(Name, 4)]()
				if(Property = -1)
					Control.Disable()
				else
					Control.Checked := Control.OrigChecked := Property ;Current value is cached in the control so it is only applied when it is changed.
			}
		Property := WindowsSettings.GetThumbnailHoverTime()
		if(Property = -1)
			Page.editThumbnailHoverTime.Disable()
		else
			Page.editThumbnailHoverTime.Text := Page.editThumbnailHoverTime.OrigText := Property
	}
	ApplyWindowsSettings()
	{
		Page := this.Pages.WindowsSettings.Tabs[1].Controls
		RequiredAction := 0
		for Name, Control in Page
			if(Control.Type = "CheckBox" && Control.Checked != Control.OrigChecked)
			{
				RequiredAction |= WindowsSettings["Set" SubStr(Name, 4)](Control.Checked)
				Control.OrigChecked := Control.Checked
			}
		if(Page.editThumbnailHoverTime.Text != Page.editThumbnailHoverTime.OrigText)
			RequiredAction |= WindowsSettings.SetThumbnailHoverTime(Page.editThumbnailHoverTime.Text)
		if(RequiredAction > 0)
			MsgBox, 4,,Some settings that you changed require that you restart Explorer, log off or reboot.
	}
	

	;Misc
	CreateMisc()
	{
		Page := this.Pages.Misc.Tabs[1]
		;~ Page.AddControl("Link",	"linkGamepadRemoteControl",			"x19 ys+23 w13 h13",						"?")
		Page.AddControl("CheckBox",	"chkGamepadRemoteControl",			"xs+40 ys+20",								"Use joystick/gamepad as remote control when not in fullscreen (optimized for XBOX360 controller)")
		;~ Page.AddControl("Link",	"linkFixEditControlWordDelete",		"xs+21 y58 w13 h13",						"?")
		Page.AddControl("CheckBox",	"chkFixEditControlWordDelete",		"xs+40 ys+43",								"Make CTRL+Backspace and CTRL+Delete work in all textboxes")
		Page.Controls.chkFixEditControlWordDelete.ToolTip := "Many text boxes in windows have the problem that it's not possible to use CTRL+Backspace to delete a word. Instead, it will write a square character. Enabling this will fix it."
		Page.AddControl("CheckBox",	"chkTabAutocompletion",				"xs+40 ys+66 h17",							"Autocomplete filenames and paths with TAB in file dialogs")
		
		Page.AddControl("GroupBox",	"grpAdvanced",						"xs+37 ys+150 w" this.Width - 300 " h350",	"Advanced Settings")
		Page.AddControl("Text",		"txtImageQuality",					"xs+47 ys+180",								"Image compression quality:")
		Page.AddControl("Edit",		"editImageQuality",					"xs+228 ys+177 w52",						"")
		Page.AddControl("Text",		"txtDefaultImageExtension",			"xs+47 ys+206",								"Default image extension:")
		Page.AddControl("Edit",		"editDefaultImageExtension",		"xs+228 ys+202 w52",						"")
		Page.AddControl("Text",		"txtDefaultImageEditor",			"xs+47 ys+232",								"Default image editor:")
		Page.AddControl("Edit",		"editDefaultImageEditor",			"xs+228 ys+228 w300",						"")
		Page.AddControl("Button", 	"btnDefaultImageEditor", 			"x+5",			 							"...")
		Page.AddControl("Text",		"txtDefaultTextEditor",				"xs+47 ys+254",								"Default image text editor:")
		Page.AddControl("Edit",		"editDefaultTextEditor",			"xs+228 ys+250 w300",						"")
		Page.AddControl("Button", 	"btnDefaultTextEditor", 			"x+5",			 							"...")
		
		Page.AddControl("Text",		"txtFullScreenDescription",			"xs+47 ys+292",								"Many features of 7plus check if there is a fullscreen window active.`nYou can add window class names to include and exclude filters here to influence the fullscreen recognition.")
		Page.AddControl("Text",		"txtFullscreenInclude",				"xs+47 ys+324",								"Fullscreen detection include list:")
		Page.AddControl("Edit",		"editFullscreenInclude",			"xs+228 ys+321 w261",						"")
		Page.AddControl("Text",		"txtFullscreenExclude",				"xs+47 ys+350",								"Fullscreen detection exclude list:")
		Page.AddControl("Edit",		"editFullscreenExclude",			"xs+228 ys+347 w261",						"")
		Page.AddControl("CheckBox",	"chkEnableDebugging",				"xs+47 ys+432",								"Enable debugging")
		Page.Controls.chkEnableDebugging.ToolTip := "Enable this to see debug messages. A program like DebugView is recommended for this.`nThis will also affect some other parts of 7plus, such as event exporting."
		Page.AddControl("CheckBox",	"chkDontRegisterSelectionChanged",	"xs+47 ys+457",								"Fix hanging issues with Explorer (prevents file selection tracking + undo and Explorer status bar enhancements)")
		Page.chkDontRegisterSelectionChanged.ToolTip := "Use this if Explorer windows won't react anymore sometimes.`n""Restore Selection"" and display of file sizes in Explorer status bar`nare not going to work if this is enabled."
	}

	InitMisc()
	{
		Page := this.Pages.Misc.Tabs[1].Controls
		
		Page.chkGamepadRemoteControl.Checked := Settings.Misc.GamepadRemoteControl
		Page.chkFixEditControlWordDelete.Checked := Settings.Misc.FixEditControlWordDelete
		Page.chkTabAutocompletion.Checked := Settings.Misc.TabAutocompletion
		
		Page.editImageQuality.Text := Settings.Misc.ImageQuality
		Page.editDefaultImageExtension.Text := Settings.Misc.DefaultImageExtension
		Page.editDefaultImageEditor.Text := Settings.Misc.DefaultImageEditor
		Page.editDefaultTextEditor.Text := Settings.Misc.DefaultTextEditor

		Page.editFullscreenInclude.Text := Settings.Misc.FullscreenInclude
		Page.editFullscreenExclude.Text := Settings.Misc.FullscreenExclude

		Page.chkEnableDebugging.Checked := Settings.General.DebugEnabled
		Page.chkDontRegisterSelectionChanged.Checked := Settings.General.DontRegisterSelectionChanged
	}

	ApplyMisc()
	{
		Page := this.Pages.Misc.Tabs[1].Controls
		
		Settings.Misc.GamepadRemoteControl := Page.chkGamepadRemoteControl.Checked
		if(Settings.Misc.GamepadRemoteControl)
			JoystickStart()
		else
			JoystickStop()
		Settings.Misc.FixEditControlWordDelete := Page.chkFixEditControlWordDelete.Checked
		Settings.Misc.TabAutocompletion := Page.chkTabAutocompletion.Checked
		
		Settings.Misc.ImageQuality := Page.editImageQuality.Text
		Settings.Misc.DefaultImageExtension := Page.editDefaultImageExtension.Text
		Settings.Misc.DefaultImageEditor := Page.editDefaultImageEditor.Text
		Settings.Misc.DefaultTextEditor := Page.editDefaultTextEditor.Text

		Settings.Misc.FullscreenInclude := Page.editFullscreenInclude.Text
		Settings.Misc.FullscreenExclude := Page.editFullscreenExclude.Text
		Settings.General.DebugEnabled := Page.chkEnableDebugging.Checked
		Settings.General.DontRegisterSelectionChanged := Page.chkDontRegisterSelectionChanged.Checked
	}

	btnDefaultImageEditor_Click()
	{
		Page := this.Pages.Misc.Tabs[1].Controls
		FileDialog := new CFileDialog("Open")
		FileDialog.Filter := "Executable files (*.exe)"
		FileDialog.Title := "Select Image Editor"
		FileDialog.FileMustExist := true
		FileDialog.PathMustExist := true
		FileDialog.Filename := Page.editDefaultImageEditor.Text
		if(FileDialog.Show())
			Page.editDefaultImageEditor.Text := FileDialog.Filename
	}

	btnDefaultTextEditor_Click()
	{
		Page := this.Pages.Misc.Tabs[1].Controls
		FileDialog := new CFileDialog("Open")
		FileDialog.Filter := "Executable files (*.exe)"
		FileDialog.Title := "Select Text Editor"
		FileDialog.FileMustExist := true
		FileDialog.PathMustExist := true
		FileDialog.Filename := Page.editDefaultTextEditor.Text
		if(FileDialog.Show())
			Page.editDefaultTextEditor.Text := FileDialog.Filename
	}


	; About	
	CreateAbout()
	{
		Page := this.Pages.About.Tabs[1]
		txt7plusVersion := 	Page.AddControl("Text", 	"txt7plusVersion", 	"xs+21 w400 ys+19 h40", 	"7plus Version " VersionString(1) (ApplicationState.IsPortable ? " Portable" : ""))
		txt7plusVersion.Font.Size := 20
							Page.AddControl("Picture", 	"img7plus",			"xs+380 ys+19 w128 h128", 	A_ScriptDir "\128.png")
							Page.AddControl("Picture", 	"imgDonate",		"xs+24 ys+170", 			A_ScriptDir "\Donate.png")
							Page.AddControl("Link", 	"linkLicense",		"xs+176 ys+252", 			"<A HREF=""http://www.gnu.org/licenses/gpl.html"">GNU General Public License v3</A>")
							Page.AddControl("Link", 	"linkAHK",			"xs+21 ys+217", 			"<A HREF=""www.autohotkey.com"">www.autohotkey.com</A>")
							Page.AddControl("Link", 	"linkTwitter",		"xs+176 ys+121", 			"<A HREF=""http://www.twitter.com/7plus"">7plus</A>")
							Page.AddControl("Link", 	"linkEmail",		"xs+176 ys+105", 			"<A HREF=""mailto://fragman@gmail.com"">fragman@gmail.com</A>")
							Page.AddControl("Link", 	"linkBugs",			"xs+176 ys+73", 			"<A HREF=""http://code.google.com/p/7plus/issues/list"">http://code.google.com/p/7plus/issues/list</A>")
							Page.AddControl("Link", 	"linkHomepage",		"xs+176 ys+57", 			"<A HREF=""http://code.google.com/p/7plus/"">http://code.google.com/p/7plus/</A>")
							Page.AddControl("Link", 	"linkAutoupdater",	"xs+21 ys+281", 			"The Autoupdater uses <A HREF=""http://www.7-zip.org"">7-Zip</A>, which is licensed under the <A HREF=""http://www.gnu.org/licenses/lgpl.html"">LGPL</A>")
							Page.AddControl("Text", 	"txtCredits",		"xs+21 ys+315", 			"This program would not have been possible without the many scripts, libraries and help from:`nSean, HotKeyIt, majkinetor, polyethene, Lexikos, tic, fincs, TheGood, PhiLho, Temp01, Laszlo, jballi, Shrinker,`nM@x and the other guys and gals on #ahk and the forums.")
							Page.AddControl("Text", 	"txtLicense",		"xs+21 ys+252", 			"Licensed under")
							Page.AddControl("Text", 	"txtLanguage",		"xs+21 ys+201", 			"Proudly written in AutoHotkey")
							Page.AddControl("Text", 	"txtDonate",		"xs+21 ys+154", 			"To support the development of this project, please donate:")
							Page.AddControl("Text", 	"txtTwitter",		"xs+21 ys+121", 			"Twitter")
							Page.AddControl("Text", 	"txtEmail",			"xs+21 ys+105", 			"E-Mail")
							Page.AddControl("Text", 	"txtAuthor2",		"xs+176 ys+89", 			"Christian Sander")
							Page.AddControl("Text", 	"txtAuthor",		"xs+21 ys+89", 				"Author")
							Page.AddControl("Text", 	"txtBugs",			"xs+21 ys+73", 				"Report bugs")
							Page.AddControl("Text", 	"txtHomepage",		"xs+21 ys+57", 				"Project page:")
	}
	
	;Placeholder function, nothing to do yet
	InitAbout()
	{
		;~ Page := this.Pages.About.Tabs[1].Controls
	}

	;Placeholder function, nothing to do yet
	ApplyAbout()
	{
		;~ Page := this.Pages.About.Tabs[1].Controls
	}

	img7plus_Click()
	{
		MsgBox You found an easteregg, go get yourself a cookie!
	}
	
	imgDonate_Click()
	{
		run https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CCDPER7Z2CHZW
	}
	
	
	
	WM_KEYDOWN(Message, wParam, lParam, hwnd)
	{
		static VK_DELETE := 46, VK_A := 65
		PageEvents := this.Pages.Events.Tabs[1].Controls
		PageAccessorKeywords := this.Pages.Keywords.Tabs[1].Controls
		PageHotStrings := this.Pages.HotStrings.Tabs[1].Controls
		;VK_DELETE = 46, a=65
		if(hwnd = PageEvents.listEvents.hwnd)
		{
			if(wParam = VK_DELETE)
			{
				this.DeleteEvents()
				return true
			}
			else if(wParam = VK_A && GetKeyState("Control", "P"))
			{
				PageEvents.listEvents.SelectedItems := PageEvents.listEvents.Items
				return true
			}
			;Forward regular keys to event filter edit control
			else if(wParam != 17 && (wParam <= 32 || wParam >= 41) && !GetKeyState("Control", "P"))
			{
				PostMessage, Message, %wParam%, %lParam%,, % "ahk_id " PageEvents.editEventFilter.hwnd
				return true
			}
		}
		else if(hwnd = PageAccessorKeywords.listAccessorKeywords.hwnd)
		{
			if(wParam = VK_DELETE)
			{
				this.DeleteAccessorKeyword()
				return true
			}
		}
		else if(hwnd = PageHotStrings.listHotStrings.hwnd)
		{
			if(wParam = VK_DELETE)
			{
				this.DeleteHotString()
				return true
			}
		}
	}
	WM_KEYUP(Message, wParam, lParam, hwnd)
	{
		Page := this.Pages.Events.Tabs[1].Controls
		if(hwnd = Page.listEvents.hwnd)
		{
			;Forward regular keys to event filter edit control
			if(wParam != 17 && (wParam <= 32 || wParam >= 41) && !GetKeyState("Control", "P"))
			{
				PostMessage, 0x101, %wParam%, %lParam%,, % "ahk_id " Page.editEventFilter.hwnd
				return true
			}
		}
	}
	
	
	;Helper functions
	GetSelectedCategory(DefaultToUncategorized = false)
	{
		return this.treePages.SelectedItem.Parent = this.treePages.Items[2] ? this.treePages.SelectedItem.Text : (DefaultToUncategorized ? "Uncategorized" : "")
	}
}

;Called as timer by ApplyFastFolders to show quicker settings apply (even though it isn't in reality!)
PrepareFolderBand:
PrepareFolderBand()
return