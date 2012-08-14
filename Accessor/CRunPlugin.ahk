Class CRunPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Run", CRunPlugin)
	
	Description := "This plugin tries to execute the entered text directly. You can press CTRL+Enter`n in the Accessor window to execute this action even if it is not selected.`nCTRL+SHIFT+Enter will run it with admin permissions."
	
	AllowDelayedExecution := true
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "run"
		KeywordOnly := false
		MinChars := 1
		BasePriority := 0.2
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := CAccessorPlugin.CActions.Run
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.RunAsAdmin)
			}
		}
		Type := "Run"
		Detail1 := "Run command"
		Actions := new this.CActions()
		Priority := CRunPlugin.Instance.Priority
		MatchQuality := 1 ; Only one result with perfect matching
		;By indexing the results from this plugin it will rank higher when a specific command has been executed multiple times
		ResultIndexingKey := "Path"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}
	
	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := Array()
		Result := new this.CResult()
		Result.Title := Filter
		Result.Path := Filter
		Result.Icon := Accessor.GenericIcons.Application
		Results.Insert(Result)
		return Results
	}
}