Class CCalculatorPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Calculator", CCalculatorPlugin)
	
	Description := "Use Google Calc to make calculations `nand unit conversions (e.g. ""g in pounds"")."
	
	Cleared := false
	List := Array()

	AllowDelayedExecution := false

	Column1Text := "Calculation"
	Column2Text := "Result to Copy"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "="
		KeywordOnly := false ;This is actually true, but IsInSinglePluginContext needs to be called every time so it is handled manually here
		MinChars := 0
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Copy Result`tCTRL + C", "Copy")
			__new()
			{
			}
		}
		Type := "Calculator"
		Actions := new this.CActions()
		Priority := CCalculatorPlugin.Instance.Priority
		MatchQuality := 1
		Detail1 := "Calculator"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return InStr(Filter, this.Settings.Keyword) = 1
	}

	OnOpen(Accessor)
	{
		this.List := Array()
	}

	Enable()
	{
		this.Icon := ExtractIcon(ExpandPathPlaceholders("%WinDir%\system32\calc.exe"), 1)
	}

	Disable()
	{
		if(this.Icon)
			DestroyIcon(this.Icon)
	}

	OnClose(Accessor)
	{
		if(IsObject(this.List))
			for index, ListEntry in this.List
				if(ListEntry.Icon != Accessor.GenericIcons.Application)			
					DestroyIcon(ListEntry.Icon)
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(InStr(Accessor.FilterWithoutTimer, this.Settings.Keyword) != 1)
			return
		Filter := SubStr(Accessor.FilterWithoutTimer, StrLen(this.Settings.Keyword) + 1)
		Results := Array()
		Result := new this.CResult()
		r := Eval(Filter)
		Result.Title := Filter " = " r
		Result.Path := r
		Result.Icon := this.Icon
		Results.Insert(Result)
		return Results
	}

	Copy(Accessor, ListEntry)
	{
		if(ListEntry)
			Clipboard := ListEntry.Path
	}
}