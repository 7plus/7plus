Class CEventPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Event Plugin", CEventPlugin)
	
	Description := "Makes it possible to implement an Accessor function by using the event system.`nThe parameters after the keyword of an event can be accessed`nthrough the ${Acc1} - ${Acc9} placeholders."
	
	AllowDelayedExecution := true

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "Event"
		KeywordOnly := false
		MinChars := 2
		BasePriority := 0.8
	}
	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Execute", "TriggerEvent", "", true, true, true, A_WinDir "\System32\Shell32.dll", 177)
		}
		Type := "Event Plugin"
		Actions := new this.CActions()
		Priority := CEventPlugin.Instance.Priority
		ResultIndexingKey := "ID"
		__Delete()
		{
			if(this.Icon && !CAccessor.Instance.GenericIcons.IndexOf(this.Icon))
				DestroyIcon(this.Icon)
		}
	}
	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}
	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := Array()
		for index, Event in EventSystem.Events
		{
			if(Event.Trigger.Is(CAccessorTrigger) && (MatchQuality := FuzzySearch(Event.Trigger.Keyword, Parameters[0], false)) > Accessor.Settings.FuzzySearchThreshold)
			{
				Result := new this.CResult()
				Result.Title := Event.Trigger.Title
				Result.Path := Event.ExpandPlaceholders(Event.Trigger.Path)
				Result.Detail1 := Event.ExpandPlaceholders(ListEntry.Event.Trigger.Detail1)
				Result.Event := Event
				;This ID is stored for indexing results to improve weighting.
				Result.ID := Event.ID
				Result.Parameters := Parameters
				Result.MatchQuality := MatchQuality
				if(Icon := Event.Trigger.Icon)
				{
					if(InStr(Icon, ","))
					{
						StringSplit, icon, icon, `,,%A_Space%
						Result.Icon := ExtractIcon(ExpandPathPlaceholders(icon1), icon2, 64)
					}
					else
						Result.Icon := ExtractIcon(ExpandPathPlaceholders(Icon))
				}
				else
					Result.Icon := Accessor.GenericIcons.Application
				Results.Insert(Result)
			}
		}
		return Results
	}
	TriggerEvent(Accessor, ListEntry)
	{
		ScheduledEvent := ListEntry.Event.TriggerThisEvent()
		for index, Parameter in ListEntry.Parameters
			ScheduledEvent.Placeholders["Acc" index] := Parameter
	}
}