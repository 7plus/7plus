/*
Note: CEventSystem, CTrigger, CCondition and CAction need to be defined before any real subevent class.
Possible Problem: newly created subevents may not have local properties. This could be a problem if HasKey is used somewhere.
*/
Class CEventSystem extends CRichObject
{	
	;These arrays contain all types of the subevents indexed by their type names
	static Triggers := RichObject()
	static Conditions := RichObject()
	static Actions := RichObject()
	
	;Global placeholders can be shared between different events
	static GlobalPlaceholders := RichObject()
	
	;EventSchedule (contains copies of the event objects in the Events list) is a list of events that are currently being processed.
	static EventSchedule := Array()

	;Event schedule ID is assigned to each scheduled event so they can be identified by this ID.
	EventScheduleID := 0

	Startup()
	{		
		;Create CEvents instance
		this.Events := new CEvents()
		
		;Temporary events are not visible in settings GUI and won't be saved. See ControlEvent -> Copy Event for usage example.
		this.TemporaryEvents := new CEvents() ;object("base", object("base", Array(), "HighestID", -1, "Add", "Events_Add","RegisterEvent", "EventSystem_RegisterEvent"))
		;Call startup functions for all subevents
		for index, Trigger in this.Triggers
			Trigger.Startup()
		for index, Condition in this.Conditions
			Condition.Startup()
		for index, Action in this.Actions
			Action.Startup()
		;Load main events file. This will create event objects for all stored event configs in Events object.
		this.Events.ReadMainEventsFile()
		
		;Make sure the subevents can enabled themselves
		for index, Event in this.Events
			if(Event.Enabled)
				Event.Enable()
		
		;Trigger events with 7plusStart trigger
		Trigger := new C7plusStartTrigger()
		this.OnTrigger(Trigger)
		
		;If 7plus was started with a commandline parameter through an Explorer Button trigger, process it here.
		if(1 = "-id")
		{
			Trigger := new CExplorerButtonTrigger()
			ID = %2%
			Trigger.ID := ID
			this.OnTrigger(Trigger)
		}
		
		;Setup the message handler for receiving triggers from other instances of 7plus (and possibly other programs) and from the Shell extension.
		OnMessage(55555, "TriggerFromOtherInstance")
		
		;Make sure that non-elevated processes can send this messages to the elevated 7plus process.
		;Keyword: UIPI
		DllCall("ChangeWindowMessageFilter", "UInt", 55555, "UInt", 1) 
		DllCall("ChangeWindowMessageFilter", "UInt", 55556, "UInt", 1) 
	}
	OnExit()
	{
		for index, Event in this.Events
		{
			Event.Trigger.OnExit()
			for ActionIndex, Action in Event.Actions
				Action.OnExit()
		}
		for index, Event in this.TemporaryEvents
		{
			Event.Trigger.OnExit()
			for ActionIndex, Action in Event.Actions
				Action.OnExit()
		}
		this.Events.WriteMainEventsFile()
	}
	
	;This function is called when a trigger event is received. 
	;Trigger is a CTrigger implementation instance that contains information 
	;that is used by the triggers of events to decide if the event should be triggered.
	OnTrigger(Trigger)
	{
		if(!Trigger.Extends("CTrigger"))
		{
			Notify("Event System Error!", "Invalid trigger!`nName: " Trigger.Name "`nID: " Trigger.ID, 5, NotifyIcons.Error)
			return
		}
		
		;Find matching triggers
		for index, Event in EventSystem.Events
			Event.TriggerThisEvent(Trigger)
		for index, Event in EventSystem.TemporaryEvents
			Event.TriggerThisEvent(Trigger)
		return
	}
	
	;This is the main event processing function in which all scheduled events are processed.
	;It checks if the conditions of an event are fulfilled and if they are, the actions of the event are performed.
	;An event may stay on the EventSchedule stack as long as it needs to when the current CAction.Execute() returns -1.
	EventScheduler()
	{
		Critical, Off
		;First, check the conditions of all events in the queue to make sure an event can't influence the result of a condition check of another event.
		EventPos := 1
		Loop % this.EventSchedule.MaxIndex()
		{			
			Event := this.EventSchedule[EventPos]
			
			;Check conditions
			if(Event.Conditions.Success != 1) ;Check if conditions have been evaluated before.
			{
				Success := Event.CheckConditions(true)
				
				;if the conditions were not fulfilled, remove this event and continue with the next one
				if(!Success)
				{
					this.EventSchedule.Remove(EventPos)
					outputdebug % "Conditions of event " event.id " were not fulfilled."
					continue
				}
				else
					Event.Conditions.Result := 1 ;Set result so conditions don't have to be checked again when this event has a waiting action.
			}
			EventPos++
		}
		
		;Now the event queue contains only those events which passed the condition check. These can be processed now.
		EventPos := 1
		Loop % this.EventSchedule.MaxIndex()
		{
			Event := this.EventSchedule[EventPos]
			outputdebug % "Process event ID: " Event.ID " Name: " Event.Name
			
			Loop % Event.Actions.MaxIndex()
			{	
				; outputdebug % "perform " Event.Actions[1].DisplayString()
				result := Event.Actions[1].Execute(Event)
				if(result = 0) ;Action was cancelled, stop all further actions
				{
					Event.Actions := Array()
					if(Settings.General.ShowExecutingEvents)
						Notify("Event Cancelled", "The execution of event" Event.ID ": " Event.Name " was cancelled", 5, NotifyIcons.Info)
					break
				}
				else if(result = -1) ;Action needs more time to finish, check back in next main loop
					break
				else
					Event.Actions.Remove(1)
				if(Settings.General.ShowExecutingEvents)
					Notify("Event Executed", "The event" Event.ID ": " Event.Name " was executed", 5, NotifyIcons.Info)
			}
			;if no more actions in this event, consider it processed and remove it from queue
			if(!Event.Actions.MaxIndex())
			{
				this.EventSchedule.Remove(EventPos)
				OriginalEvent := this.Events.GetEventWithValue("ID", Event.ID) ;Will return the event from Events or TemporaryEvents
				if(Event.DisableAfterUse && OriginalEvent)
					OriginalEvent.SetEnabled(false)
				if(Event.DeleteAfterUse && OriginalEvent)
					this.Events.Delete(OriginalEvent)
				outputdebug % "Finished execution of event ID: " event.id " Name:" event.name
				continue
			}
			EventPos++
		}
	}

	;Finds the queued event and subevent in which a subevent has a specific key with a specific value. Filter specifies which types of subevents should be searched.
	EventFromSubEventKey(ByRef pEvent, ByRef pSubEvent, Key, Value, Filter = "TCA")
	{
		for index, Event in this.EventSchedule
		{
			if(InStr(Filter, "A"))
			{
				for index2, Action in Event.Actions
				{
					if(Action[Key] = Value)
					{
						pEvent := Event
						pSubEvent := Action
						return Event
					}
				}
			}
			if(InStr(Filter, "C"))
			{
				for index3, Condition in Event.Conditions
				{
					if(Condition[Key] = Value)
					{
						pEvent := Event
						pSubEvent := Condition
						return Event
					}
				}
			}
			
			if(Event.Trigger[Key] = Value && InStr(Filter, "T"))
			{
				pEvent := Event
				pSubEvent := Event.Trigger
				return Event
			}
		}
		return 0
	}
	;Same as EventFromSubEventKey except that it returns only the SubEvent
	SubEventFromSubEventKey(Key, Value, Filter = "TCA")
	{
		this.EventFromSubEventKey("", SubEvent, Key, Value, Filter)
		return SubEvent
	}
	;Finds the event and subevent of a running event of specified type by its gui number
	;This function assumes that the gui number is stored as "tmpGUINum" in the subevent of the specified type.
	EventFromGUI(ByRef pEvent, ByRef pSubEvent)
	{
		return this.EventFromSubEventKey(pEvent, pSubEvent, "tmpGUINum", A_GUI)
	}
	;Same as EventFromGUI except that it returns only the SubEvent
	SubEventFromGUI()
	{
		this.EventFromGUI("", SubEvent)
		return SubEvent
	}
}

EventScheduler:
SetTimer, EventScheduler, Off
EventSystem.EventScheduler()
SetTimer, EventScheduler, 100
return

Class CEvent extends CRichObject
{
	ID := -1
	Name := "New event"
	Category := "Uncategorized"
	Enabled := 1
	EventComplexityLevel := 0
	OneInstance := 0
	DeleteAfterUse := 0
	DisableAfterUse := 0
	Trigger := new CHotkeyTrigger()
	Conditions := new CArray()
	Actions := new CArray()
	PlaceHolders := object()
	
	;Enabled state needs to be set through this function, to allow syncing with settings window
	SetEnabled(Value) 
	{
		this.Enabled := Value
		;if settings are open and updating a regular event, update its counterpart in SettingsWindow.Events
		;Note that GetItemWithValue is called instead of GetEventWithValue so that only events from this CEvent instance are retrieved.
		if(SettingsActive() && EventSystem.Events.GetItemWithValue("ID", this.ID))
		{
			SettingsEvent := SettingsWindow.Events.GetItemWithValue("ID", this.ID)
			if(IsObject(SettingsEvent))
			{
				SettingsEvent.Enabled := Value
				SettingsWindow.FillEventsList()
			}
		}
	}
	
	;Called when an event is deleted. It forwards this call to its trigger
	Delete()
	{
		this.Trigger.Delete(this)
	}
	Enable()
	{
		this.SetEnabled(true)
		this.Trigger.Enable(this)
	}

	Disable()
	{
		this.SetEnabled(false)
		this.Trigger.Disable(this)
	}
	;Applies a patch to this event, overwriting only some of its values
	ApplyPatch(Patch)
	{
		for key, Value in Patch
			if(key != "PatchOnly")
				this[key] := value
	}
	
	;Main function to expand placeholders. Placeholders are marked by ${key} and by %PATH%
	;This function is implemented as a global function so it can be called independently of a subevent
	static ExpandPlaceholders := Func("ExpandPlaceholders")

	;Evaluates the conditions of this event. Returns -1 if the conditions can't be evaluated completely, 0 if they evaluated to false and 1 if they evuated to true
	CheckConditions()
	{
		result := this.Enabled || this.Trigger.Type = "Timer" ;Check enabled state again here, because it might have changed since it was appended to queue
		if(result)
		{
			;Group conditions separated by OR conditions
			ConditionGroups := Array()
			ConditionGroup := Array()
			for index, Condition in this.Conditions
			{
				if(!Condition.Is(CORCondition))
					ConditionGroup.Insert(Condition)
				else
				{
					if(ConditionGroup.MaxIndex()) ;Skip empty groups
					{
						ConditionGroups.Insert(ConditionGroup)
						ConditionGroup := Array()
					}
				}
			}
			if(ConditionGroup.MaxIndex()) ;Skip empty group
				ConditionGroups.Insert(ConditionGroup)

			for index, ConditionGroup in ConditionGroups
			{
				for index2, Condition in ConditionGroup
				{
					result := Round(Clamp(Condition.Evaluate(this), -1, 1))
					if(result = -1) ;Not decided yet, check later
						break
					else if(Condition.Negate) ;Result is 0 or 1 before, now invert it
						result := !result
					
					;Condition did not match
					if(result = 0)
						break
					else if(result = 1) ;This condition was fulfilled, remove it from conditions and continue with next condition
						continue
				}
				if(result = 1)
					return 1
			}
		}
		return result
	}

	;Tests if this event matches to a trigger. If it does, this event is schedule for execution.
	;To just trigger it without performing trigger matching, leave Trigger Parameter empty.
	;It returns the event on the EventSchedule so its state can be examined later.
	TriggerThisEvent(Trigger="")
	{
		;Order of this if condition is important here, because Event.Trigger.Matches() can disable the event for timers
		if(this.Enabled && (!IsObject(Trigger) || (this.Trigger.Type = Trigger.Type && this.Trigger.Matches(Trigger, this)) || (Trigger.Is(CTriggerTrigger) && this.ID = Trigger.TargetID)))
		{
			;Test if the event is already running and mustn't be run multiple times
			if(!this.OneInstance || !EventSystem.EventSchedule.FindKeyWithValue("ID", this.ID))
			{
				EventSystem.EventSchedule.Insert(Copy := this.DeepCopy())
				Copy.EventScheduleID := EventSystem.EventScheduleID
				EventSystem.EventScheduleID++ ;Increment event schedule ID for next scheduled event.
			}
			return Copy
		}
	}
}

Class CEvents extends CArray
{
	Categories := Array()
	HighestID := -1
	
	;Creates an event, adds it to this CEvents instance and assigns an ID that is based on the max ID of EventSystem.Events and its settings copy, and increases HighestID count of this CEvents instance
	RegisterEvent(Event = "", Enable = 1)
	{
		;Temporary events use negative ID for find functions
		if(this = EventSystem.TemporaryEvents)
			HighestID := EventSystem.TemporaryEvents.HighestID - 1
		else
			HighestID := max(EventSystem.Events.HighestID, SettingsActive() ? SettingsWindow.Events.HighestID : 0) + 1 ;Make sure highest ID is used from both event arrays
		
		;Assign the new highest ID
		this.HighestID := HighestID	
		
		if(!IsObject(Event))
			Event := new CEvent()
		Event.ID := HighestID
		this.Add(Event)
		if(Enable)
			Event.SetEnabled(true)
		return Event
	}
	
	;This function is used internally to add events, to allow syncing with settings window
	;It should probably not be called directly, as it doesn't adjust the ID properly. Instead, call CEvents.RegisterEvent()
	Add(Event) 
	{
		this.Insert(Event)
		if(SettingsActive() && this != SettingsWindow.Events && this != EventSystem.TemporaryEvents) ;Non-temporary and non-settings event that needs to be synced with an open settings gui
		{
			SettingsWindow.Events.Insert(Event.DeepCopy())
			SettingsWindow.RecreateTreeView()
		}
	}

	;This function needs to be used to remove events from the main Events object, to allow syncing with settings window
	;It returns true when a category was deleted.
	Delete(Event, UpdateGUI = true) 
	{
		if(!IsObject(Event) || ! (index := this.FindKeyWithValue("ID", Event.ID)))
			return
		Event := this[index]	
		if(this != EventSystem.TemporaryEvents && Event.ID < 0)
		{
			EventSystem.TemporaryEvents.Delete(Event, UpdateGUI)
			return
		}
		
		if(this != SettingsWindow.Events)
		{
			;Disable the event
			Event.Disable()
			
			;Call the delete function of the event so it may do further processing
			Event.Delete()
			
			;Remove the event on the settings page too
			if(SettingsActive())
			{
				SettingsWindow.Events.Delete(SettingsWindow.Events.GetEventWithValue("ID", Event.ID), false)
				if(UpdateGUI)
					SettingsWindow.RecreateTreeView()
			}
		}
		
		;Actually remove the event from the list
		this.Remove(index)
		
		;Adjust HighestID to the highest ID that is present
		this.HighestID := -1
		for i, Event2 in this
			if(Event2.ID > this.HighestID)
				this.HighestID := Event2.ID
		
		if(this.FindKeyWithValue("Category", Event.Category))
			return false
		this.Categories.Remove(this.Categories.IndexOf(Event.Category))
		return true
	}
	
	;CEvents implements a GetEventWithValue function that should be used instead of CArray.GetItemWithValue so that it can redirect negative IDs to EventSystem.TemporaryEvents
	GetEventWithValue(Key, Value)
	{
		;Call the regular function from CArray on the matching CEvents instance.
		if(Key = "ID" && Value < 0)
			return EventSystem.TemporaryEvents.GetItemWithValue(Key, Value)
		else
			return this.GetItemWithValue(Key, Value)
	}

	;Events  overrides CArray.FindKeyWithValue function so that it can redirect negative IDs to EventSystem.TemporaryEvents
	FindKeyWithValue(Key, Value)
	{
		;Call the regular function from CArray on the matching CEvents instance.
		if(Key = "ID" && Value < 0 && this != EventSystem.TemporaryEvents)
			return EventSystem.TemporaryEvents.FindKeyWithValue(Key, Value)
		else
			return Base.FindKeyWithValue(Key, Value)
	}
	ReadMainEventsFile()
	{
		this.ReadEventsFile(Settings.ConfigPath "\Events.xml")
	}	

	WriteMainEventsFile()
	{
		this.WriteEventsFile(Settings.ConfigPath "\Events.xml")
	}

	ReadEventsFile(Path, OverwriteCategory = "", Update = "")
	{
		global MajorVersion, MinorVersion, BugfixVersion, PatchVersion, XMLMajorVersion, XMLMinorVersion, XMLBugfixVersion
		FileRead, xml, %path%
		XMLObject := XML_Read(xml)
		XMLMajorVersion := XMLObject.MajorVersion
		XMLMinorVersion := XMLObject.MinorVersion
		XMLBugfixVersion := XMLObject.BugfixVersion
		if(CompareVersion(XMLMajorVersion,MajorVersion,XMLMinorVersion,MinorVersion,XMLBugfixVersion,BugfixVersion) > 0)
			Msgbox Events file was made with a newer version of 7plus. Compatibility is not guaranteed. Please update, or use at own risk!
		
		if(Update)
			Update.Message := Update.Message (XMLObject.Message? "`n" XMLObject.Message : "")
		if(path = Settings.ConfigPath "\Events.xml") ;main config file, read patch version
			PatchVersion := XMLObject.PatchVersion ? XMLObject.PatchVersion : 0
		
		count := this.MaxIndex()
		lowestID := 999999999999
		HighestID := this.HighestID
		len := max(XMLObject.Events.Event.MaxIndex(), XMLObject.Events.HasKey("Event"))
		Loop % len
		{
			i := A_Index
			;Check if end of Events is reached
			if(len = 1)
				XMLEvent := XMLObject.Events.Event
			else
				XMLEvent := XMLObject.Events.Event[i]
			
			if(!XMLEvent)
				continue
			
			;Create new Event
			Event := new CEvent()
			
			;Event ID
			if(XMLEvent.HasKey("ID"))
			{
				Event.ID := XMLEvent.ID
				if(Event.ID < lowestID)
					lowestID := Event.ID
			}
			else
				Event.Remove("ID")
			
			;Event Name
			if(XMLEvent.HasKey("Name"))
				Event.Name := XMLEvent.Name
			else
				Event.Remove("Name")
			
			;Event Description
			if(XMLEvent.HasKey("Description"))
				Event.Description := XMLEvent.Description
			else
				Event.Remove("Description")
			
			;Event Category
			if(XMLEvent.HasKey("Category") || OverwriteCategory)
			{
				Event.Category := OverwriteCategory ? OverwriteCategory : XMLEvent.Category ? XMLEvent.Category : "Uncategorized"
				this.Categories.InsertUnique(Event.Category)
			}
			else
				Event.Remove("Category")
			
			;Event state
			if(XMLEvent.HasKey("Enabled"))
				Event.Enabled := XMLEvent.Enabled
			else
				Event.Remove("Enabled")
				
			;Disable after use
			if(XMLEvent.HasKey("DisableAfterUse"))
				Event.DisableAfterUse := XMLEvent.DisableAfterUse
			else
				Event.Remove("DisableAfterUse")
			
			;Delete after use
			if(XMLEvent.HasKey("DeleteAfterUse"))
				Event.DeleteAfterUse := XMLEvent.DeleteAfterUse
			else
				Event.Remove("DeleteAfterUse")
			
			;One Instance
			if(XMLEvent.HasKey("OneInstance"))
				Event.OneInstance := XMLEvent.OneInstance
			else
				Event.Remove("OneInstance")
			
			;Official event identifier for update processes
			if(XMLEvent.HasKey("OfficialEvent"))
				Event.OfficialEvent := XMLEvent.OfficialEvent
			
			;Complexity level indicates if an event may be hidden from the user to avoid confusion(1) or if it is always shown(0)
			if(XMLEvent.HasKey("EventComplexityLevel"))
				Event.EventComplexityLevel := XMLEvent.EventComplexityLevel
			else
				Event.Remove("EventComplexityLevel")
			
			;Read trigger values
			if(IsObject(XMLEvent.Trigger) && XMLEvent.Trigger.HasKey("Type"))
			{
				if(!EventSystem.Triggers.HasKey(XMLEvent.Trigger.Type))
				{
					if(!CTrigger.CLegacyTypes.HasKey(XMLEvent.Trigger.Type) || !IsObject(EventSystem.Triggers[CTrigger.CLegacyTypes[xmlEvent.Trigger.Type]]))
					{
						Notify("Event System Error!", "No known trigger of Type " XMLEvent.Trigger.Type ", skipping event " Event.ID ": " Event.Name, 5, NotifyIcons.Error)
						continue
					}
					else
						TriggerTemplate := EventSystem.Triggers[CTrigger.CLegacyTypes[XMLEvent.Trigger.Type]]
				}
				else
					TriggerTemplate := EventSystem.Triggers[XMLEvent.Trigger.Type]
				Event.Trigger := new TriggerTemplate()
				Event.Trigger.ReadXML(XMLEvent.Trigger)
			}
			else
				Event.Remove("Trigger")
			
			;Read conditions
			if(IsObject(XMLEvent.Conditions) && XMLEvent.Conditions.HasKey("Condition"))
			{
				if(!XMLEvent.Conditions.Condition.Is(CArray)) ;Single condition
					XMLEvent.Conditions.Condition := new CArray(XMLEvent.Conditions.Condition)
			
				for index, XMLCondition in XMLEvent.Conditions.Condition
				{
					;Create new condition
					if(!EventSystem.Conditions.HasKey(XMLCondition.Type))
					{
						if(!CCondition.CLegacyTypes.HasKey(XMLCondition.Type) || !IsObject(EventSystem.Conditions[CCondition.CLegacyTypes[XMLCondition.Type]]))
						{
							Notify("Event System Error!", "No known Condition of Type " XMLCondition.Type ", skipping event " Event.ID ": " Event.Name, 5, NotifyIcons.Error)
							continue
						}
						else
							ConditionTemplate := EventSystem.Conditions[CCondition.CLegacyTypes[XMLCondition.Type]]
					}
					else
						ConditionTemplate := EventSystem.Conditions[XMLCondition.Type]
					Condition :=  new ConditionTemplate()
					
					;Read Negation
					Condition.Negate := XMLCondition.Negate
					
					;Read condition values
					Condition.ReadXML(XMLCondition)
					
					Event.Conditions.Insert(Condition)
				}
			}
			
			;Read actions
			if(IsObject(XMLEvent.Actions) && XMLEvent.Actions.HasKey("Action"))
			{
				if(!XMLEvent.Actions.Action.Is(CArray)) ;Single Action
					XMLEvent.Actions.Action := new CArray(XMLEvent.Actions.Action)
				
				for index, XMLAction in XMLEvent.Actions.Action
				{
					;Create new action
					if(!EventSystem.Actions.HasKey(XMLAction.Type))
					{
						if(!CAction.CLegacyTypes.HasKey(XMLAction.Type) || !IsObject(EventSystem.Actions[CAction.CLegacyTypes[XMLAction.Type]]))
						{
							Notify("Event System Error!", "No known Action of Type " XMLAction.Type ", skipping event " Event.ID ": " Event.Name, 5, NotifyIcons.Error)
							continue
						}
						else
							ActionTemplate := EventSystem.Actions[CAction.CLegacyTypes[XMLAction.Type]]
					}
					else
						ActionTemplate := EventSystem.Actions[XMLAction.Type]
					Action := new ActionTemplate()
					
					;Read action values
					Action.ReadXML(XMLAction)
					
					Event.Actions.Insert(Action)
				}
			}
			
			if(Event.HasKey("OfficialEvent") && (OldEvent := this.GetEventWithValue("OfficialEvent", Event.OfficialEvent))) ;If an official event already exists, apply this as patch
			{			
				if(!XMLEvent.HasKey("Conditions"))
					Event.Remove("Conditions")
				if(!XMLEvent.HasKey("Actions"))
					Event.Remove("Actions")
				Event.Remove("PlaceHolders")
				OldEvent.ApplyPatch(Event) ;No update messages are generated here, those are handled manually
			}
			else if(!Event.PatchOnly)
			{
				if(Update)
					Update.Message := Update.Message "`n- Added Event: " Event.Name
				this.Insert(Event)
			}
		}
		;fix IDs from import
		;Loop over all new events
		pos := count + 1
		count := this.MaxIndex()
		while(pos <= count)
		{
			Event := this[pos]
			;Make sure Event ID is higher than all previous IDs, but conserve relative differences between IDs
			offset := (highestID - lowestID) + 1
			Event.ID := Event.ID + offset
			;Find highest ID
			if(Event.ID > this.HighestID)
				this.HighestID := Event.ID
			
			;Now adjust Event ID references
			for k,v in Event.Trigger
			{
				if(strEndsWith(k, "ID") && IsNumeric(v))
					Event.Trigger[k] := Event.Trigger[k] + offset
			}
			for index, Condition in Event.Conditions
				for k,v in Condition
					if(strEndsWith(k, "ID") && IsNumeric(v))
						Condition[k] := Condition[k] + offset
			
			for index, Action in Event.Actions
				for k,v in Action
					if(strEndsWith(k, "ID") && IsNumeric(v))
						Action[k] := Action[k] + offset
			
			pos++
		}
		if(XMLObject.HasKey("Remove")) ;If Objects are to be removed
		{
			if(XMLObject.Remove.HasKey("OfficialEvent") && !XMLObject.Remove.OfficialEvent.Is(CArray)) ;Single condition
				XMLObject.Remove.OfficialEvent := new CArray(XMLObject.Remove.OfficialEvent)
			for index, OfficialEvent in XMLObject.Remove.OfficialEvent
			{
				if((DeathCandidate := this.GetEventWithValue("OfficialEvent", OfficialEvent)))
				{
					if(Update) ;Should be true if we are here
						Update.Message := Update.Message "`n- Removed Event: " DeathCandidate.Name
					this.Delete(DeathCandidate, false)
				}
			}
		}
		return this
	}
	
	;This function writes this event configuration into the file specified by path.
	WriteEventsFile(Path)
	{
		global MajorVersion, MinorVersion, BugfixVersion, PatchVersion
		
		;Create Events node
		xmlObject := Object()
		xmlObject.MajorVersion := MajorVersion
		xmlObject.MinorVersion := MinorVersion
		xmlObject.BugfixVersion := BugfixVersion
		
		;Store Patch version information in the main events file.
		if(path = Settings.ConfigPath "\Events.xml")
			xmlObject.PatchVersion := PatchVersion
		
		xmlObject.Events := Object()
		xmlEvents := Array()
		xmlObject.Events.Event := xmlEvents
		;Write Events entries
		for index, Event in this
		{
			xmlEvent := Object()
			xmlEvents.Insert(xmlEvent)
			
			;Don't save temporary events that are only used during runtime
			if(Event.Temporary)
				continue
			
			;Write ID
			xmlEvent.ID := Event.ID
			
			;Write name
			xmlEvent.Name := Event.Name
			
			;Write description
			xmlEvent.Description := Event.Description
			
			;Write category
			xmlEvent.Category := Event.Category
			
			;Write state
			xmlEvent.Enabled := Event.Enabled
			
			;Disable after use
			xmlEvent.DisableAfterUse := Event.DisableAfterUse
			
			;Delete after use
			xmlEvent.DeleteAfterUse := Event.DeleteAfterUse
			
			;One Instance
			xmlEvent.OneInstance := Event.OneInstance
			
			;Complexity level
			xmlEvent.EventComplexityLevel := Event.EventComplexityLevel
			
			if(Event.HasKey("Officialevent"))
				xmlEvent.OfficialEvent := Event.OfficialEvent
			
			
			;Uncomment the lines below to save events with an "official" tag that allows to identify them in update processes
			if(Settings.General.DebugEnabled && !Event.OfficialEvent && !InStr(Path, A_Temp)) ;Find an unused Event ID to be used as Official Event ID
			{			
				Loop
				{
					if(this.FindKeyWithValue("OfficialEvent", A_Index))
						continue ;Already in use
					xmlEvent.OfficialEvent := A_Index ;Not used
					Event.OfficialEvent := A_Index
					break
				}
			}
			
			
			xmlTrigger := Object()
			xmlEvent.Trigger := xmlTrigger
			xmlTrigger.Type := Event.Trigger.Type
			for key, Value in Event.Trigger
			{
				if(key = "Category" || InStr(key, "tmp") = 1 || InStr(key, "_") = 1)
					continue
				xmlTrigger[key] := value
			}
			
			;Since some triggers might have to do special preprocessing, lets allow them to overwrite the values read above
			;Event.Trigger.WriteXML(EventsFileHandle, "/Events/Event[" i "]/Trigger/")
			
			;Write Conditions
			xmlEvent.Conditions := Object("Condition", XMLConditions := new CArray())
			for index2, Condition in Event.Conditions
			{
				xmlCondition := Object()
				XMLConditions.Insert(xmlCondition)
				
				;Write condition type, since it's stored in base object, and isn't iterated below
				xmlCondition.Type := Condition.Type
				
				for key, Value in Condition
				{
					if(key = "Category" || InStr(key, "tmp") = 1 || InStr(key, "_") = 1)
						continue
					xmlCondition[key] := value
				}
			}
			xmlEvent.Actions := Object("Action", XMLActions := Array())
			for index2, Action in Event.Actions
			{
				xmlAction := Object()
				xmlActions.Insert(xmlAction)
				
				;Write action type, since it's stored in base object, and isn't iterated below
				xmlAction.Type := Action.Type
				
				for key, Value in Action
				{
					if(key = "Category" || InStr(key, "tmp") = 1 || InStr(key, "_") = 1)
						continue
					xmlAction[key] := value
				}
			}
		}
		XML_Save(xmlObject, Path)
		return
	}
}

;Used to let CEventSystem know about the SubEvent implementation. Needs to be called like this in the class definition:
;static Type := RegisterType(this, "SomeType")
RegisterType(Class, Type)
{
	if(Class.Extends("CTrigger"))
		CEventSystem.Triggers.Insert(Type, Class)
	else if(Class.Extends("CCondition"))
		CEventSystem.Conditions.Insert(Type, Class)
	else if(Class.Extends("CAction"))
		CEventSystem.Actions.Insert(Type, Class)
	return Type
}

;Used to let CEventSystem know about the category of this SubEvent implementation. Needs to be called like this in the class definition:
;static Category := RegisterCategory(this, "SomeCategory")
RegisterCategory(Class, Category)
{
	if(Class.Extends("CTrigger"))
		Categories := CTrigger.Categories
	else if(Class.Extends("CCondition"))
		Categories := CCondition.Categories
	else if(Class.Extends("CAction"))
		Categories := CAction.Categories
	
	if(!Categories[Category].Is(CArray))
		Categories[Category] := new CArray()
	Categories[Category].Insert(Class)
	return Category
}

;Called when an external program sends a message to 7plus to make it execute an event.
TriggerFromOtherInstance(wParam, lParam)
{
	Critical, On
	if(lParam = 0) ;0 = Single trigger from something else than context menus
	{
		Trigger := new CTriggerTrigger()
		Trigger.TargetID := wParam
		EventSystem.OnTrigger(Trigger)
	}
	else if(lParam = 1) ;1 = Trigger from context menu
	{		
		;Read list of selected files written by shell extension
		if(FileExist(A_Temp "\7plus\files.txt"))
			FileRead, files, % "*t " A_Temp "\7plus\files.txt"
		FileDelete, % A_Temp "\7plus\files.txt"
		;if it failed (because static context menu is used), try to get it from explorer window
		EventSystem.GlobalPlaceholders.Context := files ? files : Navigation.GetSelectedFilepaths()
		
		Trigger := new CTriggerTrigger()
		Trigger.TargetID := wParam
		EventSystem.OnTrigger(Trigger)
	}
	Critical, Off
}

Class CSubEvent extends CRichObject
{
	;Some functions which are defined outside this class because they are also used elsewhere.
	static AddControl := Func("AddControl")
	static SubmitControls := Func("SubmitControls")
	static SelectFile := Func("SelectFile")
	static Browse := Func("Browse")
	__New()
	{
		if(!this.base.HasKey("Type"))
			MsgBox % "Type property needs to be set for " __Class
		if(!this.base.HasKey("Category"))
			MsgBox % "Category property needs to be set for " __Class
	}
	
	
	;Can be implemented by the specific inheriting subevent.
	;Not needed usually because defining static properties in the subevent automatically loads them.
	ReadXML(XML)
	{
		for key, value in this.base
			if(InStr(key, "__") != 1 && key != "base" && key != "Type" && key != "Category" && !IsObject(this.base[key]))
				this.ReadVar(XML, key)
	}
	
	;Reads a property from an xml object and stores it in a subevent if the property exists.
	ReadVar(xml, key)
	{
		Assert(IsObject(this) && IsObject(xml) && key != "", "Error reading " key " in " this.Type)
		if(xml.HasKey(key))
			this[key] :=  xml[key]
	}
	
	;Can be implemented by the specific inheriting subevent.
	;Called on the SubEvent class (not the instance!) when the event system is starting up. This Subevent may read special configuration data or similar here.
	Startup()
	{		
	}
	;To be implemented by the specific inheriting subevent
	DisplayString()
	{
		return this.Type
	}
	
	;Can be implemented by the specific inheriting subevent. This implementation only works for text data.
	GuiShow(GUI)
	{
		for key, value in this.base
			if(InStr(key, "__") != 1 && key != "base" && key != "Type" && key != "Category" && !IsFunc(this[key]))
				this.AddControl(GUI, "Edit", key)
	}
	
	;Can be implemented by the specific inheriting subevent
	GuiSubmit(GUI)
	{
		this.SubmitControls(GUI)
	}
}

Class CTrigger extends CSubEvent
{
	;This is an object containing categories. It is automatically populated by the triggers when they set the "Category" key.
	static Categories := RichObject()
	
	;This class is used to convert old subevent types into changed ones during loading
	Class CLegacyTypes
	{
		static ContextMenu := "Context menu"
		static DoubleClickDesktop := "Double click on desktop"
		static DoubleClickTaskbar := "Double click on taskbar"
		static ExplorerButton := "Explorer bar button"
		static ExplorerPathChanged := "Explorer path changed"
		static ExplorerDoubleClickSpace := "Double click on empty space"
		static MenuItem := "Menu item clicked"
		static OnMessage := "On window message"
		static ScreenCorner := "Screen corner"
		static None := "Triggered by an action"
		static 7plusStart := "On 7plus start"
		static WindowActivated := "Window activated"
		static WindowClosed := "Window closed"
		static WindowCreated := "Window created"
		static WindowStateChange := "Window state changed"
	}
	
	;This function NEEDS to be implemented by the trigger implementation inheriting from CTrigger
	;Filter is a trigger instance of a specific type that specifies some parameters that describe the trigger. This function decides
	;if the event owning the instance of this trigger class should get triggered by the Filter trigger.
	Matches(Filter, Event)
	{
		return false
	}
	
	;The functions below can be implemented by the trigger implementation inheriting from CTrigger
	
	;Called when the event owning this trigger is enabled so the trigger may prepare itself to make receiving triggers possible.
	Enable(Event)
	{
	}
	
	;Called when the event owning this trigger is disabled so the trigger may stop listening for events that would trigger it.
	Disable(Event)
	{
	}
	
	;Called before the event owning to this trigger is copied to a temporary copy for the settings window.
	PrepareCopy(Event)
	{
	}
	
	;Called before the event to which this trigger belongs is replaced by its copy from the settings window.
	PrepareReplacement(OriginalEvent, NewEvent)
	{
	}
	
	;Called when an event instance gets deleted.
	Delete(Event)
	{
	}
}
Class CExampleTrigger extends CTrigger
{
	static Type := "ExampleTrigger"
	static Category := "ExampleTriggerCategory"
	Static Property := 5
	
	Matches(Filter, Event)
	{
		return Check.Something()
	}
	DisplayString()
	{
		return "ExampleTrigger"
	}
}

Class CCondition extends CSubEvent
{
	;This is an object containing condition categories. It is automatically populated by the conditions when they set the "Category" key.
	static Categories := RichObject()
	
	;If true, the condition must evaluate to false to be accepted.
	Negate := false
	
	;This class is used to convert old subevent types into changed ones during loading
	Class CLegacyTypes
	{
		static IsDialog := "Window is file dialog"
		static IsContextMenuActive := "Context menu active"
		static IsDragable := "Window is dragable"
		static IsRenaming := "Explorer is renaming"
		static KeyIsDown := "Key is down"
		static IsFullScreen := "Fullscreen window active"
		static MouseOver := "Mouse over"
		static MouseOverFileList := "Mouse over file list"
		static MouseOverTabButton := "Mouse over tab button"
		static MouseOverTaskList := "Mouse over taskbar list"
		static WindowActive := "Window active"
		static WindowExists := "Window exists"
	}
	
	;This function NEEDS to be implemented by the condition implementation inheriting from CCondition.
	;Called when the event owning this condition gets triggered. This function decides if this condition is fullfilled
	;and influences if the actions contained in the event will be executed.
	Evaluate(Event)
	{
		return true
	}
}
Class CExampleCondition extends CCondition
{
	static Type := "ExampleCondition"
	static Category := "ExampleConditionCategory"
	static Property := 5
	Evaluate(Event)
	{
		return Check.Something()
	}
	DisplayString()
	{
		return "ExampleCondition"
	}
}

Class CAction extends CSubEvent
{
	;This is an object containing action categories. It is automatically populated by the actions when they set the "Category" key.
	static Categories := RichObject()
	
	;This class is used to convert old subevent types into changed ones during loading
	Class CLegacyTypes
	{
		static Upload := "Upload to FTP"
		static Exit7plus := "Exit 7plus"
		static ShowAccessor := "Show Accessor"
		static ShowSettings := "Show settings"
		static FlashingWindows := "Flashing windows"
		static Restart7plus := "Restart 7plus"
		static Accessor := "Show Accessor"
		static ShowMenu := "Show menu"
		static ShowAeroFlip := "Show Aero Flip"
		static AutoUpdate := "Check for updates"
		static Clipboard := "Write to clipboard"
		static ClipMenu := "Clipboard Manager menu"
		static ClipPaste := "Paste clipboard entry"
		static ControlTimer := "Control Timer"
		static ControlEvent := "Control event"
		static ExplorerReplaceDialog := "Explorer replace dialog"
		static FastFoldersStore := "Save Fast Folder"
		static FastFoldersRecall := "Open Fast Folder"
		static FastFoldersClear := "Clear Fast Folder"
		static FastFoldersMenu := "Fast Folder menu"
		static Delete := "Delete file"
		static FileCopy := "Copy file"
		static FileMove := "Move file"
		static FileWrite := "Write to file"
		static FilterList := "Filter list"
		static FlatView := "Show Explorer flat view"
		static FocusControl := "Focus a control"
		static ImageConverter := "Show Image Converter"
		static ImageUpload := "Upload image to image hoster"
		static Input := "Ask for user input"
		static InvertSelection := "Invert file selection"
		static MergeTabs := "Merge Explorer windows"
		static MD5 := "Show Explorer checksum dialog"
		static MouseClick := "Mouse click"
		static MouseCloseTab := "Close tab under mouse"
		static MouseWindowDrag := "Drag window with mouse"
		static MouseWindowResize := "Resize window with mouse"
		static NewFile := "Create new file"
		static NewFolder := "Create new folder"
		static OpenInNewFolder := "Open folder in new window / tab"
		static PlaySound := "Play a sound"
		static RestoreSelection := "Restore file selection"
		static Run := "Run a program"
		static RunOrActivate := "Run a program or activate it"
		static Screenshot := "Take a screenshot"
		static SelectFiles := "Select files"
		static SendKeys := "Send keyboard input"
		static SendMessage := "Send a window message"
		static SetDirectory := "Set current directory"
		static SetWindowTitle := "Set window title"
		static SlideWindowOut := "Move Slide Window out of screen"
		static ShortenURL := "Shorten a URL"
		static Shutdown := "Shutdown computer"
		static TaskButtonClose := "Close taskbar button under mouse"
		static ToggleWallpaper := "Change desktop wallpaper"
		static ToolTip := "Show a tooltip"
		static ViewMode := "Change explorer view mode"
		static Volume := "Change sound volume"
		static WindowActivate := "Activate a window"
		static WindowClose := "Close a window"
		static WindowHide := "Hide a window"
		static WindowMove := "Move a window"
		static WindowResize := "Resize a window"
		static WindowSendToBottom := "Put window in background"
		static WindowShow := "Show a window"
		static WindowState := "Change window state"
	}
	
	;This function NEEDS to be implemented by the action implementation inheriting from CAction.
	;Execute() is called when this action is performed. It can return 1 on success, 0 on failure 
	;or -1 if it is still running and should be continously queried about its state. This is used for showing
	;dialogs for example.
	Execute(Event)
	{
	}

	;This function can be implemented by the action implementation inheriting from CAction
	;Called when the program exits so the action can perform any steps necessary to stop itself if it's currently running.
	OnExit()
	{
		
	}
}
Class CExampleAction extends CAction
{
	static Type := "ExampleAction"
	static Category := "ExampleActionCategory"
	Static Property := 5

	Execute(Event)
	{
		Do.Something()
	}

	DisplayString()
	{
		return "ExampleAction"
	}
}
#include %A_ScriptDir%\Triggers\AccessorTrigger.ahk
#include %A_ScriptDir%\Triggers\ContextMenu.ahk
#include %A_ScriptDir%\Triggers\DirectoryChangeTrigger.ahk
#include %A_ScriptDir%\Triggers\DoubleClickDesktop.ahk
#include %A_ScriptDir%\Triggers\DoubleClickTaskbar.ahk
#include %A_ScriptDir%\Triggers\ExplorerButton.ahk
#include %A_ScriptDir%\Triggers\ExplorerPathChanged.ahk
#include %A_ScriptDir%\Triggers\ExplorerDoubleClickSpace.ahk
#include %A_ScriptDir%\Triggers\Hotkey.ahk
#include %A_ScriptDir%\Triggers\MenuItem.ahk
#include %A_ScriptDir%\Triggers\OnMessage.ahk
#include %A_ScriptDir%\Triggers\ScreenCorner.ahk
#include %A_ScriptDir%\Triggers\Trigger.ahk
#include %A_ScriptDir%\Triggers\Timer.ahk
;#include %A_ScriptDir%\Triggers\VoiceCommand.ahk
#include %A_ScriptDir%\Triggers\WindowActivated.ahk
#include %A_ScriptDir%\Triggers\WindowClosed.ahk
#include %A_ScriptDir%\Triggers\WindowCreated.ahk
#include %A_ScriptDir%\Triggers\WindowStateChange.ahk
#include %A_ScriptDir%\Triggers\7plusStart.ahk

#include %A_ScriptDir%\Conditions\If.ahk
#include %A_ScriptDir%\Conditions\IsDialog.ahk
#include %A_ScriptDir%\Conditions\IsFullScreen.ahk
#include %A_ScriptDir%\Conditions\IsContextMenuActive.ahk
#include %A_ScriptDir%\Conditions\IsDragable.ahk
#include %A_ScriptDir%\Conditions\IsRenaming.ahk
#include %A_ScriptDir%\Conditions\KeyIsDown.ahk
#include %A_ScriptDir%\Conditions\MouseOver.ahk
#include %A_ScriptDir%\Conditions\MouseOverFileList.ahk
#include %A_ScriptDir%\Conditions\MouseOverTaskList.ahk
#include %A_ScriptDir%\Conditions\MouseOverTabButton.ahk
#include %A_ScriptDir%\Conditions\NavigatableWindow.ahk
#include %A_ScriptDir%\Conditions\OR.ahk
#include %A_ScriptDir%\Conditions\WindowActive.ahk
#include %A_ScriptDir%\Conditions\WindowExists.ahk

#include %A_ScriptDir%\Actions\Accessor.ahk
#include %A_ScriptDir%\Actions\AccessorProgramButton.ahk
#include %A_ScriptDir%\Actions\AccessorResult.ahk
#include %A_ScriptDir%\Actions\AeroFlip.ahk
#include %A_ScriptDir%\Actions\Autoupdate.ahk
#include %A_ScriptDir%\Actions\Clipboard.ahk
#include %A_ScriptDir%\Actions\Clipmenu.ahk
#include %A_ScriptDir%\Actions\ClipPaste.ahk
#include %A_ScriptDir%\Actions\ControlEvent.ahk
#include %A_ScriptDir%\Actions\ControlTimer.ahk
#include %A_ScriptDir%\Actions\Exit7plus.ahk
#include %A_ScriptDir%\Actions\ExplorerReplaceDialog.ahk
#include %A_ScriptDir%\Actions\FastFoldersClear.ahk
#include %A_ScriptDir%\Actions\FastFoldersMenu.ahk
#include %A_ScriptDir%\Actions\FastFoldersRecall.ahk
#include %A_ScriptDir%\Actions\FastFoldersStore.ahk
#include %A_ScriptDir%\Actions\FileCopy.ahk
#include %A_ScriptDir%\Actions\FileDelete.ahk
#include %A_ScriptDir%\Actions\FileMove.ahk
#include %A_ScriptDir%\Actions\FileWrite.ahk
#include %A_ScriptDir%\Actions\FilterList.ahk
#include %A_ScriptDir%\Actions\FlashingWindows.ahk
#include %A_ScriptDir%\Actions\FlatView.ahk
#include %A_ScriptDir%\Actions\FocusControl.ahk
#include %A_ScriptDir%\Actions\FTPUpload.ahk
#include %A_ScriptDir%\Actions\IfThisThenThat.ahk
#include %A_ScriptDir%\Actions\ImageConverter.ahk
#include %A_ScriptDir%\Actions\ImageUpload.ahk
#include %A_ScriptDir%\Actions\Input.ahk
#include %A_ScriptDir%\Actions\InvertSelection.ahk
#include %A_ScriptDir%\Actions\MergeTabs.ahk
#include %A_ScriptDir%\Actions\Message.ahk
#include %A_ScriptDir%\Actions\MD5Checksum.ahk
#include %A_ScriptDir%\Actions\MouseClick.ahk
#include %A_ScriptDir%\Actions\MouseCloseTab.ahk
#include %A_ScriptDir%\Actions\MouseWindowDrag.ahk
#include %A_ScriptDir%\Actions\MouseWindowResize.ahk
#include %A_ScriptDir%\Actions\NewFile.ahk
#include %A_ScriptDir%\Actions\NewFolder.ahk
#include %A_ScriptDir%\Actions\OpenInNewFolder.ahk
#include %A_ScriptDir%\Actions\PlaySound.ahk
#include %A_ScriptDir%\Actions\Restart7plus.ahk
#include %A_ScriptDir%\Actions\RestoreSelection.ahk
#include %A_ScriptDir%\Actions\Run.ahk
#include %A_ScriptDir%\Actions\RunOrActivate.ahk
#include %A_ScriptDir%\Actions\Screenshot.ahk
#include %A_ScriptDir%\Actions\SelectFiles.ahk
#include %A_ScriptDir%\Actions\SendKeys.ahk
#include %A_ScriptDir%\Actions\SendMail.ahk
#include %A_ScriptDir%\Actions\SendMessage.ahk
#include %A_ScriptDir%\Actions\SetDirectory.ahk
#include %A_ScriptDir%\Actions\SetWindowTitle.ahk
#include %A_ScriptDir%\Actions\SlideWindowOut.ahk
#include %A_ScriptDir%\Actions\ShortenURL.ahk
#include %A_ScriptDir%\Actions\ShowMenu.ahk
#include %A_ScriptDir%\Actions\ShowSettings.ahk
#include %A_ScriptDir%\Actions\ShowTip.ahk
#include %A_ScriptDir%\Actions\ShutDown.ahk
#include %A_ScriptDir%\Actions\TaskButtonClose.ahk
#include %A_ScriptDir%\Actions\ToggleWallpaper.ahk
#include %A_ScriptDir%\Actions\Tooltip.ahk
#include %A_ScriptDir%\Actions\ViewMode.ahk
#include %A_ScriptDir%\Actions\VoiceAction.ahk
#include %A_ScriptDir%\Actions\Volume.ahk
#include %A_ScriptDir%\Actions\Wait.ahk
#include %A_ScriptDir%\Actions\WindowActivate.ahk
#include %A_ScriptDir%\Actions\WindowClose.ahk
#include %A_ScriptDir%\Actions\WindowHide.ahk
#include %A_ScriptDir%\Actions\WindowMove.ahk
#include %A_ScriptDir%\Actions\WindowResize.ahk
#include %A_ScriptDir%\Actions\WindowSendToBottom.ahk
#include %A_ScriptDir%\Actions\WindowShow.ahk
#include %A_ScriptDir%\Actions\WindowState.ahk

#include %A_ScriptDir%\Generic\FileOperation.ahk
#include %A_ScriptDir%\Generic\If.ahk
#include %A_ScriptDir%\Generic\Run.ahk
#include %A_ScriptDir%\Generic\WindowFilter.ahk