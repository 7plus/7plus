Class CFlatViewAction Extends CAction
{
	static Type := RegisterType(CFlatViewAction, "Show Explorer flat view")
	static Category := RegisterCategory(CFlatViewAction, "Explorer")
	static __WikiLink := "FlatView"
	static Paths := "${SelN}"
	Execute(Event)
	{
		if(WinVer >= Win_Vista)
			FlatView(ToArray(Event.ExpandPlaceholders(this.Paths)))
		return 1
	} 

	DisplayString()
	{
		return "Show flat view of these files: " this.Paths
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Paths", "", "", "Paths:", "Placeholders", "Action_FlatView_Placeholders","","","This can be multiple, newline-delimited paths such as ${SelNM}")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Paths")
	}
}

Action_FlatView_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return

;Makes a currently active explorer window show all files contained in "files" list. Only folders are used, files are ignored.
;files is a `n separated list of complete paths
FlatView(files)
{
	if(files = "")
		return
		
	Path := FindFreeFileName(A_Temp "\7plus\FlatView.search-ms")
	searchString = 
	(
	<?xml version="1.0"?>
	<persistedQuery version="1.0">
		<viewInfo viewMode="details" iconSize="16" stackIconSize="0" displayName="Search" autoListFlags="0">
			<visibleColumns>
				<column viewField="System.ItemNameDisplay"/>
				<column viewField="System.ItemTypeText"/>
				<column viewField="System.Size"/>
				<column viewField="System.ItemFolderPathDisplayNarrow"/>
			</visibleColumns>
			<sortList>
				<sort viewField="System.Search.Rank" direction="descending"/>
				<sort viewField="System.ItemNameDisplay" direction="ascending"/>
			</sortList>
		</viewInfo>
		<query>
			<attributes/>
			<kindList>
				<kind name="item"/>
			</kindList>
			<scope>
	)
	Loop % files.MaxIndex()
	{ 
		if(InStr(FileExist(files[A_Index]), "D"))
		{
			searchString .= "<include path=""" files[A_Index] """/>"
			DirectoriesFound := true
		}
	}
	if(DirectoriesFound)
	{
		searchString .= "</scope></query></persistedQuery>"
		FileAppend, %searchString%, %Path%
		Navigation.SetPath(Path)
	}
}
