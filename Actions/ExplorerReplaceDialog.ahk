Class CExplorerReplaceDialogAction Extends CAction
{
	static Type := RegisterType(CExplorerReplaceDialogAction, "Explorer replace dialog")
	static Category := RegisterCategory(CExplorerReplaceDialogAction, "Explorer")
	static View := "Filenames"
	static SelectedFiles := false
	Execute(Event)
	{
		global ExplorerWindows
		if(IsObject(ExplorerWindows.GetItemWithValue("hwnd", WinActive("ahk_group ExplorerGroup")).ReplaceDialog))
			Gui, % ExplorerWindows.GetItemWithValue("hwnd", WinActive("ahk_group ExplorerGroup")).ReplaceDialog.GUINum ":Show"
		else
		{
			ReplaceDialog := new CReplaceDialog(this, Event)
			if(IsObject(ReplaceDialog))
			{
				ExplorerWindows.GetItemWithValue("hwnd", ReplaceDialog.Parent).ReplaceDialog := ReplaceDialog
				return 1
			}
			return 0
		}
		return 1
	} 
	DisplayString()
	{
		return "Show Explorer Rename/Replace dialog"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "DropDownList", "View", "Filenames|Files", "", "Replace in:")
		this.AddControl(GUI, "Checkbox", "SelectedFiles", "In selected files")
	}
}
Class CReplaceDialog
{
	__New(Action, Event)
	{
		global ExplorerWindows
		Critical, Off
		if(!this.Parent := WinActive("ahk_group ExplorerGroup"))
			return 0
		if(IsObject(ExplorerWindows.GetItemWithValue("hwnd", this.Parent).ReplaceDialog))
			return 0
		this.GUINum:=GetFreeGUINum(10)
		if(!this.GUINum)
			return 0
		Gui, % this.GUINum ":Default"
		Gui, % this.GUINum ":Add",Text, x10 y10, Search in:
		Gui, % this.GUINum ":Add",Radio, x77 y10 hwndhFilenames gExplorerReplaceDialogFilenames Checked, File names
		Gui, % this.GUINum ":Add",Radio, x150 y10 hwndhFiles gExplorerReplaceDialogFiles, Files
		Gui, % this.GUINum ":Add",Text, x10 y36, Search:
		Gui, % this.GUINum ":Add",Edit, x66 y35 w346 hwndhReplace
		Gui, % this.GUINum ":Add",Text, x10 y62, Replace:
		Gui, % this.GUINum ":Add",Edit, x66 y60 w346 hwndhWith
		AddToolTip(hWith, "Use $1, $2, ...$(10)... for accessing regex subpatterns in the replace string")
		Gui, % this.GUINum ":Add",Text, x10 y88, In:
		Gui, % this.GUINum ":Add",Edit, x66 y84 w216 hwndhIn
		AddToolTip(hIn, "You may use wildcards here and use "","" as delimiter. Example: ""*.txt,text*""")
		Gui, % this.GUINum ":Add",Checkbox, % "x291 y87 hwndhInSelectedFiles Checked" (Action.SelectedFiles = 1), In selected files only
		Gui, % this.GUINum ":Add",Checkbox, x420 y36 hwndhCaseSensitive, Case sensitive
		Gui, % this.GUINum ":Add",Checkbox, x420 y59 hwndhRegex, Use regular expressions
		Gui, % this.GUINum ":Add",Checkbox, x563 y36 hwndhIncludeDirectories, Include directories
		Gui, % this.GUINum ":Add",Checkbox, x563 y59 hwndhIncludeSubdirectories, Include subdirectories
		Gui, % this.GUINum ":Add", Text, x420 y87, Action for colliding filenames:
		Gui, % this.GUINum ":Add", DropDownList, x563 y83 hwndhCollidingAction, Append (Number)||Skip
		Gui, % this.GUINum ":Add", ListView, x10 y120 w672 h310 hwndhListView gExplorerReplaceDialogListView Grid AltSubmit Checked NoSort ReadOnly, Old File|Path|New File
		LV_ModifyCol(1, 234)
		LV_ModifyCol(2, 200)
		LV_ModifyCol(3, 234)
		
		;Quick & Dirty
		;Filenames
		Gui, % this.GUINum ":Add", Groupbox, x+10 y11 w300 h420 Section, Quick && Dirty
		Gui, % this.GUINum ":Add", Text, xs+10 ys+20 hwndhInfo, Use these elements to quickly change things!
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhPrefix gExplorerReplaceDialogPrefix, Add prefix:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhPrefixEdit Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhSuffix  gExplorerReplaceDialogSuffix, Add suffix:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhSuffixEdit Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhChangeExtension  gExplorerReplaceDialogChangeExtension, Change extension:
		Gui, % this.GUINum ":Add",Edit, xs+249 y+-16 w40 hwndhChangeExtensionEdit Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhTrimStart  gExplorerReplaceDialogTrimStart, Trim characters from start:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhTrimStartEdit Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhTrimend  gExplorerReplaceDialogTrimEnd, Trim characters from end:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhTrimEndEdit Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhInsertChars  gExplorerReplaceDialogInsertChars, Insert
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhInsertCharsEdit Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhInsertCharsPosText, after character
		Gui, % this.GUINum ":Add",Edit, x+154 y+-16 w40 hwndhInsertCharsPos Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhInsertCharsDirText, relative to
		Gui, % this.GUINum ":Add",DropDownList, x+115 y+-16 w100 hwndhInsertCharsDir Disabled, Start||End	
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhRemoveChars  gExplorerReplaceDialogRemoveChars, Remove
		Gui, % this.GUINum ":Add",Edit, x+175 y+-16 w40 hwndhRemoveCharsLen Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhRemoveCharsPosText, character(s) after
		Gui, % this.GUINum ":Add",Edit, xs+247 y+-16 w40 hwndhRemoveCharsPos Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhRemoveCharsDirText, relative to
		Gui, % this.GUINum ":Add",DropDownList, x+115 y+-16 w100 hwndhRemoveCharsDir Disabled, Start||End		
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhChangeCase  gExplorerReplaceDialogChangeCase, Change case to:
		Gui, % this.GUINum ":Add",DropDownList, x+77 y+-16 hwndhChangeCaseList w100 Disabled, UPPER||lower|Start Case
		Gui, % this.GUINum ":Add", Checkbox, xs+26 y+10 hwndhChangeCaseExtension gExplorerReplaceDialogChangeCaseExtension Disabled, Include extension
		
		;Files
		Gui, % this.GUINum ":Add", Text, xs+10 ys+20 hwndhWarning Hidden, Caution: The options below can find many matches!
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhPrefixLine gExplorerReplaceDialogPrefixLine Hidden, Add line prefix:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhPrefixLineEdit Hidden Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhSuffixLine  gExplorerReplaceDialogSuffixLine Hidden, Add line suffix:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhSuffixLineEdit Hidden Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhTrimLineStart  gExplorerReplaceDialogTrimLineStart Hidden, Trim characters from start of line:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhTrimLineStartEdit Hidden Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhTrimLineEnd  gExplorerReplaceDialogTrimLineEnd Hidden, Trim characters from end of line:
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhTrimLineEndEdit Hidden Disabled
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhInsertLineChars gExplorerReplaceDialogInsertLineChars Hidden, Insert
		Gui, % this.GUINum ":Add",Edit, xs+189 y+-16 w100 hwndhInsertLineCharsEdit Hidden Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhInsertLineCharsPosText Hidden, after character
		Gui, % this.GUINum ":Add",Edit, x+154 y+-16 w40 hwndhInsertLineCharsPos Hidden Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhInsertLineCharsDirText Hidden, relative to
		Gui, % this.GUINum ":Add",DropDownList, x+115 y+-16 w100 hwndhInsertLineCharsDir Hidden Disabled, line start||line end	
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhRemoveLineChars gExplorerReplaceDialogRemoveLineChars Hidden, Remove
		Gui, % this.GUINum ":Add",Edit, x+175 y+-16 w40 hwndhRemoveLineCharsLen Hidden Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhRemoveLineCharsPosText Hidden, character(s) after
		Gui, % this.GUINum ":Add",Edit, xs+247 y+-16 w40 hwndhRemoveLineCharsPos Hidden Disabled
		Gui, % this.GUINum ":Add", Text, xs+26 y+10 hwndhRemoveLineCharsDirText Hidden, relative to
		Gui, % this.GUINum ":Add",DropDownList, x+115 y+-16 w100 hwndhRemoveLineCharsDir Hidden Disabled, line start||line end
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhLineTabsToSpaces  gExplorerReplaceDialogLineTabsToSpaces Hidden, Convert tabs to
		Gui, % this.GUINum ":Add",Edit, x+83 y+-16 w20 hwndhLineTabsToSpacesEdit Hidden Disabled, 4
		Gui, % this.GUINum ":Add", Text, x+10 y+-18 hwndhLineTabsToSpacesText Hidden, spaces
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+10 hwndhLineSpacesToTabs  gExplorerReplaceDialogLineSpacesToTabs Hidden, Convert 
		Gui, % this.GUINum ":Add",Edit, x+118 y+-16 w20 hwndhLineSpacesToTabsEdit Hidden Disabled, 4
		Gui, % this.GUINum ":Add", Text, x+10 y+-18 hwndhLineSpacesToTabsText Hidden, spaces to tabs
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+12 hwndhChangeLineCase  gExplorerReplaceDialogChangeLineCase Hidden, Change case to:
		Gui, % this.GUINum ":Add",DropDownList, x+77 y+-16 hwndhChangeLineCaseList w100 Disabled Hidden, UPPER||lower|Start Case
		Gui, % this.GUINum ":Add", Checkbox, xs+10 y+8 hwndhConvertLineSeparator gExplorerReplaceDialogConvertLineSeparator Hidden, Convert line separator to:
		Gui, % this.GUINum ":Add",DropDownList, x+37 y+-16 w100 hwndhConvertLineSeparatorList Hidden Disabled, Windows (\r\n)||Unix (\n)
		
		
		Gui, % this.GUINum ":Add",Button, x10 y440 w75 h23 gExplorerReplaceDialogRegEx, RegEx &Help
		Gui, % this.GUINum ":Add",Button, x445 y440 w75 h23 gExplorerReplaceDialogSearch Default, &Search
		Gui, % this.GUINum ":Add",Button, x526 y440 w75 h23 Disabled gExplorerReplaceDialogReplace hwndhReplaceButton, &Replace
		Gui, % this.GUINum ":Add",Button, x607 y440 w75 h23 hwndhCancel gExplorerReplaceDialogCancel, Cancel
		this.hFiles := hFiles
		this.hFilenames := hFilenames
		this.hReplace := hReplace
		this.hWith := hWith
		this.hIn := hIn
		this.hInSelectedFiles := hInSelectedFiles
		this.hCaseSensitive := hCaseSensitive
		this.hRegex := hRegex
		this.hIncludeDirectories := hIncludeDirectories
		this.hIncludeSubdirectories := hIncludeSubdirectories
		this.hCollidingAction := hCollidingAction
		
		this.QuicknDirtyFiles := Object()
		this.QuicknDirtyFiles.hWarning := hWarning
		this.QuicknDirtyFiles.hPrefixLine := hPrefixLine
		this.QuicknDirtyFiles.hPrefixLineEdit := hPrefixLineEdit
		this.QuicknDirtyFiles.hSuffixLine := hSuffixLine
		this.QuicknDirtyFiles.hSuffixLineEdit := hSuffixLineEdit
		this.QuicknDirtyFiles.hTrimLineStart := hTrimLineStart
		this.QuicknDirtyFiles.hTrimLineStartEdit := hTrimLineStartEdit
		this.QuicknDirtyFiles.hTrimLineEnd := hTrimLineEnd
		this.QuicknDirtyFiles.hTrimLineEndEdit := hTrimLineEndEdit
		this.QuicknDirtyFiles.hRemoveLineChars := hRemoveLineChars
		this.QuicknDirtyFiles.hRemoveLineCharsLen := hRemoveLineCharsLen
		this.QuicknDirtyFiles.hRemoveLineCharsPosText := hRemoveLineCharsPosText
		this.QuicknDirtyFiles.hRemoveLineCharsPos := hRemoveLineCharsPos
		this.QuicknDirtyFiles.hRemoveLineCharsDirText := hRemoveLineCharsDirText
		this.QuicknDirtyFiles.hRemoveLineCharsDir := hRemoveLineCharsDir
		this.QuicknDirtyFiles.hInsertLineChars := hInsertLineChars
		this.QuicknDirtyFiles.hInsertLineCharsEdit := hInsertLineCharsEdit
		this.QuicknDirtyFiles.hInsertLineCharsPosText := hInsertLineCharsPosText
		this.QuicknDirtyFiles.hInsertLineCharsPos := hInsertLineCharsPos
		this.QuicknDirtyFiles.hInsertLineCharsDirText := hInsertLineCharsDirText
		this.QuicknDirtyFiles.hInsertLineCharsDir := hInsertLineCharsDir
		this.QuicknDirtyFiles.hLineTabsToSpaces := hLineTabsToSpaces
		this.QuicknDirtyFiles.hLineTabsToSpacesEdit := hLineTabsToSpacesEdit
		this.QuicknDirtyFiles.hLineTabsToSpacesText := hLineTabsToSpacesText
		this.QuicknDirtyFiles.hLineSpacesToTabs := hLineSpacesToTabs
		this.QuicknDirtyFiles.hLineSpacesToTabsEdit := hLineSpacesToTabsEdit
		this.QuicknDirtyFiles.hLineSpacesToTabsText := hLineSpacesToTabsText
		this.QuicknDirtyFiles.hChangeLineCase := hChangeLineCase
		this.QuicknDirtyFiles.hChangeLineCaseList := hChangeLineCaseList
		this.QuicknDirtyFiles.hConvertLineSeparator := hConvertLineSeparator
		this.QuicknDirtyFiles.hConvertLineSeparatorList := hConvertLineSeparatorList
		
		this.QuicknDirtyFilenames := Object()
		this.QuicknDirtyFilenames.hInfo := hInfo
		this.QuicknDirtyFilenames.hPrefix := hPrefix
		this.QuicknDirtyFilenames.hPrefixEdit := hPrefixEdit
		this.QuicknDirtyFilenames.hSuffix := hSuffix
		this.QuicknDirtyFilenames.hSuffixEdit := hSuffixEdit
		this.QuicknDirtyFilenames.hChangeExtension := hChangeExtension
		this.QuicknDirtyFilenames.hChangeExtensionEdit := hChangeExtensionEdit
		this.QuicknDirtyFilenames.hTrimStart := hTrimStart
		this.QuicknDirtyFilenames.hTrimStartEdit := hTrimStartEdit
		this.QuicknDirtyFilenames.hTrimend := hTrimend
		this.QuicknDirtyFilenames.hTrimEndEdit := hTrimEndEdit
		this.QuicknDirtyFilenames.hRemoveChars := hRemoveChars
		this.QuicknDirtyFilenames.hRemoveCharsLen := hRemoveCharsLen
		this.QuicknDirtyFilenames.hRemoveCharsPosText := hRemoveCharsPosText
		this.QuicknDirtyFilenames.hRemoveCharsPos := hRemoveCharsPos
		this.QuicknDirtyFilenames.hRemoveCharsDirText := hRemoveCharsDirText
		this.QuicknDirtyFilenames.hRemoveCharsDir := hRemoveCharsDir
		this.QuicknDirtyFilenames.hInsertChars := hInsertChars
		this.QuicknDirtyFilenames.hInsertCharsEdit := hInsertCharsEdit
		this.QuicknDirtyFilenames.hInsertCharsPosText := hInsertCharsPosText
		this.QuicknDirtyFilenames.hInsertCharsPos := hInsertCharsPos
		this.QuicknDirtyFilenames.hInsertCharsDirText := hInsertCharsDirText
		this.QuicknDirtyFilenames.hInsertCharsDir := hInsertCharsDir
		this.QuicknDirtyFilenames.hChangeCase := hChangeCase
		this.QuicknDirtyFilenames.hChangeCaseList := hChangeCaseList
		this.QuicknDirtyFilenames.hChangeCaseExtension := hChangeCaseExtension
		
		this.hReplaceButton := hReplaceButton
		this.hCancel := hCancel
		Gui, % this.GUINum ":-Resize -MaximizeBox -MinimizeBox +ToolWindow +LastFound +LabelExplorerReplaceDialog"
		
		Gui, % this.GUINum ":Show", AutoSize, % (Action.View = "Files" ? "Replace in files" : "Replace filenames")
		this.hWnd := WinExist()
		if(Action.View = "Files")
		{
			GuiControl, % this.GuiNum ":Check",  Button2
			this.GuiEvent("ExplorerReplaceDialogFiles")
		}
		ControlFocus , , ahk_id %hReplace%
		AttachToolWindow(this.Parent, this.GUINum, True)
	}
	__Delete()
	{
		Gui, % this.GUINum ":Destroy"
	}
	
	;Performs a search and shows the results in the preview listview
	Search()
	{
		global ExplorerWindows
		this.Filenames := ControlGet("Checked","","","ahk_id " this.hFilenames)
		this.SearchString := ControlGetText("","ahk_id " this.hReplace)
		this.ReplaceString := ControlGetText("","ahk_id " this.hWith)
		this.ReplaceEnabled := ControlGet("Enabled","","","ahk_id " this.hWith)
		this.InString := ControlGetText("", "ahk_id " this.hIn)
		if(this.InString)
		{
			this.InString := RegexReplace(this.InString, "(\\|\.|\?|\+|\[|\{|\||\(|\)|\^|\$)", "\$1") ;Escaping
			this.InString := RegexReplace(this.InString, "\*", ".*?") ;Wildcard
			this.InString := "i)^" RegexReplace(this.InString, ",", "$|^") "$" ;start and end of line
		}
		this.InSelectedFiles := ControlGet("Checked","","","ahk_id " this.hInSelectedFiles)
		this.CaseSensitive := ControlGet("Checked","","", "ahk_id " this.hCaseSensitive)
		this.Regex := ControlGet("Checked","","", "ahk_id " this.hRegex)
		this.IncludeDirectories := ControlGet("Checked","", "", "ahk_id " this.hIncludeDirectories)
		this.IncludeSubdirectories := ControlGet("Checked", "", "", "ahk_id " this.hIncludeSubdirectories)
		this.CollidingAction := ControlGetText("", "ahk_id " this.hCollidingAction)
		
		enum := this.QuicknDirtyFilenames._newEnum()
		while enum[key,value]
		{
			key := SubStr(key, 2)
			if(WinGetClass("ahk_id " value) = "Button")
				this[key] := ControlGet("Checked","","", "ahk_id " value)
			else if(WinGetClass("ahk_id " value) = "Edit")
				this[key] := ControlGetText("", "ahk_id " value)
			else if(WinGetClass("ahk_id " value) = "ComboBox")
				this[key] := ControlGetText("", "ahk_id " value)
		}
		enum := this.QuicknDirtyFiles._newEnum()
		while enum[key,value]
		{
			key := SubStr(key, 2)
			if(WinGetClass("ahk_id " value) = "Button")
			{
				outputdebug % "button " ControlGetText("", "ahk_id " value)
				this[key] := ControlGet("Checked","","", "ahk_id " value)
			}
			else if(WinGetClass("ahk_id " value) = "Edit")
				this[key] := ControlGetText("", "ahk_id " value)
			else if(WinGetClass("ahk_id " value) = "ComboBox")
				this[key] := ControlGetText("", "ahk_id " value)
			outputdebug % key "=" this[key] ", hwnd=" value ", class = " WinGetClass("ahk_id " value)
		}
		this.SearchResults := Array()
		LV_Delete()
		if(this.Regex && !this.CaseSensitive && InStr(this.SearchString, "i)") != 1) ;Case sensitive for regex is done here to save some time
			this.SearchString := "i)" this.SearchString
		WinSetTitle, % "ahk_id " this.hWnd,,Searching...,
		ControlSetText,, Stop, % "ahk_id " this.hCancel
		if(this.Filenames)
		{
			this.DirectoryTree := Array()
			this.DirectoryTree.Directory := true			
			BasePath := ExplorerWindows.GetItemWithValue("hwnd", this.Parent).Path
			SplitPath, BasePath,Name,Path
			this.BasePath := BasePath
			this.DirectoryTree.Path := Path
			this.DirectoryTree.Name := Name
			this.CreateFilenameSearchTree(this.DirectoryTree)
			if(!this.Stop)
			{
				this.CheckForDuplicates(this.DirectoryTree, AppendPaths(this.DirectoryTree.Path, this.DirectoryTree.Name), Array())
				if(!this.Stop)
				{
					this.FlattenTree(this.DirectoryTree)
					if(!this.Stop)
					{
						Loop % this.SearchResults.MaxIndex()
						{
							if(this.Stop)
								break
							LV_Add("Check", this.SearchResults[A_Index].Name, strTrimLeft(this.SearchResults[A_Index].Path,BasePath), this.SearchResults[A_Index].FixedNewFilename ? this.SearchResults[A_Index].FixedNewFilename : this.SearchResults[A_Index].NewFilename)
						}
					}
				}
			}
		}
		else
		{
			this.BasePath := ExplorerWindows.GetItemWithValue("hwnd", this.Parent).Path
			this.FileContentSearch()
			if(!this.Stop)
			{
				Loop % this.SearchResults.MaxIndex()
				{
					if(this.Stop)
						break
					index := A_Index
					Loop % this.SearchResults[A_Index].Lines.MaxIndex()
					{
						if(this.Stop)
							break
						LV_Add("Check", strTrimLeft(this.SearchResults[index].Path,this.BasePath), this.SearchResults[index].Lines[A_Index].Line, RegexReplace(this.SearchResults[index].Lines[A_Index].Text, "D)(*ANYCRLF)\R$",""), RegexReplace(this.SearchResults[index].Lines[A_Index].NewText, "D)(*ANYCRLF)\R$",""))
					}
				}
			}
		}
		if(this.Stop)
		{
			this.Remove("SearchResults")
			this.Remove("DirectoryTree")
			this.Remove("BasePath")
			LV_Delete()
			Control, Disable,,, % "ahk_id " this.hReplaceButton
			this.Remove("Stop")
		}
		if(this.SearchResults.MaxIndex() > 0)
			Control, Enable,,, % "ahk_id " this.hReplaceButton
		WinSetTitle, % "ahk_id " this.hWnd,, % (this.Files ? "Replace in files" : "Replace filenames")
		ControlSetText,, Cancel, % "ahk_id " this.hCancel
	}
	
	; Directory structure must be kept. To archive this, a directory tree object ("DirectoryTree") is created recursively here.
	; This allows to rename the files by using a wide search and constructing the current paths from the tree.
	CreateFilenameSearchTree(Root)
	{
		if(this.Stop)
			return 0
		if(this.InSelectedFiles && Root = this.DirectoryTree) ;Base directory, skip files which are not in selection
			Selection := Navigation.GetSelectedFilepaths(this.Parent)
		items := 0
		Loop % AppendPaths(AppendPaths(Root.Path, Root.Name), "*"), 1, 0
		{
			if(this.Stop)
				return 0
			File := Array()
			SplitPath, A_LoopFileLongPath,,Path
			File.Path := Path
			File.Name := A_LoopFileName
			File.Directory := InStr(FileExist(A_LoopFileLongPath), "D")
			if(IsObject(Selection) && Selection.IndexOf(A_LoopFileLongPath) = 0) ;If selection exists and this file is not in it, skip it
				continue
			if(this.InString && !RegexMatch(A_LoopFileName,this.InString))
				continue
			if((File.Directory && ((this.IncludeDirectories && this.ProcessFilename(File)) + (this.IncludeSubdirectories &&this.CreateFilenameSearchTree(File))) > 0 ) || (!File.Directory && this.ProcessFilename(File))) ;If File should be processed itself or contains other files which are processed
			{
				File.enabled := true
				Root.Insert(File)
				items++
			}
		}
		return items > 0
	}
	
	;Locates a tree item by its Path and Name value
	FindTreeItem(Root, Path, Name)
	{
		Loop % Root.MaxIndex()
		{
			if(Root[A_Index].Path = Path && Root[A_Index].Name = Name)
				return Root[A_Index]
			if(Root[A_Index].Directory)
			{
				if(IsObject(result := this.FindTreeItem(Root[A_Index], Path, Name)))
					return result
			}
		}
		return 0
	}
	
	;Flattens the directory structure into a single array. Items which won't be renamed will be skipped.
	FlattenTree(Root)
	{
		Loop % Root.MaxIndex()
		{
			if(this.Stop)
				return 0
			if(Root[A_Index].NewFilename)
				this.SearchResults.Insert(Root[A_Index])
			if(Root[A_Index].Directory)
				this.FlattenTree(Root[A_Index])
		}
	}
	
	;This function checks for duplicates and modifies the new filenames appropriately
	CheckForDuplicates(Root, RootPath, PathsList)
	{
		index := 1
		len := Root.MaxIndex()
		Loop % len
		{
			if(this.Stop)
				return 0
			OldPath := AppendPaths(RootPath, Root[index].Name)
			NewPath := Root[index].NewFilename ? AppendPaths(RootPath, Root[index].NewFilename) : OldPath
			if(this.CollidingAction = "Append (Number)")
			{
				SplitPath, NewPath,, dir, extension, filename
				i:=1 ;Find free filename
				while((!(OldPath == NewPath) && OldPath != NewPath) && (FileExist(NewPath) || PathsList.IndexOf(NewPath))) ;Check for existing files on hdd and for target files from this rename operation
				{
					i++
					NewPath:=dir "\" filename " (" i ")" (extension = "" ? "" : "." extension)
				}
				if(i > 1)
					Root[index].FixedNewFilename := filename " (" i ")" (extension = "" ? "" : "." extension)
			}
			if(this.CollidingAction = "Skip" && FileExist(NewPath) || PathsList.IndexOf(NewPath))
			{
				Root.Remove(Index)
				continue
			}
			PathsList.Insert(NewPath)
			if(Root[index].Directory)
				this.CheckForDuplicates(Root[index], NewPath, PathsList)
			index++
		}
	}
	
	;This function performs the actual renaming
	;TODO check overwrite modes here and adjust paths based on rename success
	PerformFileNameReplace(Root, RootPath)
	{
		Loop % Root.MaxIndex()
		{
			if(this.Stop)
				return 0
			OldPath := AppendPaths(RootPath, Root[A_Index].Name)
			NewPath := AppendPaths(RootPath, Root[A_Index].FixedNewFilename ? Root[A_Index].FixedNewFilename : Root[A_Index].NewFilename)
			if(Root[A_Index].Enabled && Root[A_Index].NewFilename)
			{
				if(!Root[A_Index].Directory)
					FileMove, %OldPath%, %NewPath%, 0
				else
					FileMoveDir, %OldPath%, %NewPath%, 0
			}
			if(Root[A_Index].Directory)
				this.PerformFileNameReplace(Root[A_Index], Root[A_Index].Enabled && Root[A_Index].NewFilename ? NewPath : OldPath)
		}
	}
	
	;tests a filename for replacement
	ProcessFilename(File)
	{
		if(this.Regex)
		{
			if(this.ReplaceEnabled)
				NewFilename := RegexReplace(File.Name, this.SearchString, this.ReplaceString, Changed) ;Case insensitivity is handled before
			else
				NewFilename :=  RegexMatch(File.Name, this.SearchString) > 0 ? File.Name : ""
		}
		else
		{
			if(this.CaseSensitive)
				StringCaseSense, On
			if(this.ReplaceEnabled)
				NewFilename := StringReplace(File.Name, this.SearchString, this.ReplaceString, "All")
			else
				NewFilename := InStr(File.Name, this.SearchString) > 0 ? File.Name : ""
			StringCaseSense, Off
		}
		if(NewFilename && !this.ReplaceEnabled) ;Apply Quick & Dirty operations
		{
			SplitPath, NewFilename,,, Extension, FilenameNoExt
			if(this.TrimStart && this.TrimStartEdit)
				FilenameNoExt := LTrim(FilenameNoExt, this.TrimStartEdit)
			if(this.TrimEnd && this.TrimEndEdit)
				FilenameNoExt := RTrim(FilenameNoExt, this.TrimEndEdit)
			if(this.InsertChars && this.InsertCharsEdit && IsNumeric(this.InsertCharsPos) && this.InsertCharsPos >= 0)
			{
				if(this.InsertCharsDir = "Start")
					FilenameNoExt := SubStr(FilenameNoExt, 1, this.InsertCharsPos) this.InsertCharsEdit SubStr(FilenameNoExt, this.InsertCharsPos + 1)
				else ;End
					FilenameNoExt := SubStr(FilenameNoExt, 1, this.InsertCharsPos = 0 ? StrLen(FileNameNoExt) : -this.InsertCharsPos) this.InsertCharsEdit SubStr(FilenameNoExt, -(this.InsertCharsPos - 1), this.InsertCharsPos = 0 ? 0 : StrLen(FilenameNoExt))
			}
			if(this.RemoveChars && IsNumeric(this.RemoveCharsLen) && this.RemoveCharsLen > 0 && this.RemoveCharsPos >= 0)
			{
				if(this.RemoveCharsDir = "Start")
					FilenameNoExt := SubStr(FilenameNoExt, 1, this.RemoveCharsPos) SubStr(FilenameNoExt, this.RemoveCharsPos + this.RemoveCharsLen + 1)
				else ;End
					FilenameNoExt := SubStr(FilenameNoExt, 1, -(this.RemoveCharsPos + this.RemoveCharsLen)) SubStr(FilenameNoExt,-this.RemoveCharsPos+1, this.RemoveCharsPos = 0 ? 0 : StrLen(FilenameNoExt))
			}
			if(this.ChangeCase)
			{
				if(this.ChangeCaseList = "UPPER")
					StringUpper, FilenameNoExt, FilenameNoExt
				else if(this.ChangeCaseList = "Lower")
					StringLower, FilenameNoExt, FilenameNoExt
				else if(this.ChangeCaseList = "Start Case")
					StringUpper, FilenameNoExt, FilenameNoExt, T
				if(this.ChangeCaseExtension)
				{
					if(this.ChangeCaseList = "UPPER")
						StringUpper, Extension, Extension
					else if(this.ChangeCaseList = "Lower")
						StringLower, Extension, Extension
					else if(this.ChangeCaseList = "Start Case")
						StringUpper, Extension, Extension, T
				}
			}
			if(this.Prefix && this.PrefixEdit)
				FilenameNoExt := this.PrefixEdit FilenameNoExt
			if(this.Suffix && this.SuffixEdit)
				FilenameNoExt := FilenameNoExt this.SuffixEdit
			if(this.ChangeExtension && this.ChangeExtensionEdit)
				Extension := this.ChangeExtensionEdit
			NewFilename := FilenameNoExt "." Extension
		}
		if(!(File.Name == NewFilename))
		{
			File.NewFilename := NewFilename
			return 1
		}
		return 0
	}
	;Tests if a specific line should be replaced
	ProcessLine(File, Text, LineNumber)
	{
		if(this.Regex)
		{
			if(this.ReplaceEnabled)
				NewText := RegexReplace(Text, this.SearchString, this.ReplaceString, Count) ;Case insensitivity is handled before
			else
				NewText :=  RegexMatch(Text, this.SearchString) > 0 ? Text : ""
		}
		else
		{
			if(this.CaseSensitive)
				StringCaseSense, On
			if(this.ReplaceEnabled)
				NewText := StringReplace(Text, this.SearchString, this.ReplaceString, "All")
			else
				NewText := InStr(Text, this.SearchString) > 0 ? Text : ""
			StringCaseSense, Off
		}
		if(NewText && !this.ReplaceEnabled) ;Apply Quick & Dirty operations
		{
			r := InStr(Text, "`r")
			n := InStr(Text, "`n")
			NewText := RTrim(Text, "`r`n")
			if(this.TrimLineStart && this.TrimLineStartEdit)
				NewText := LTrim(NewText, this.TrimLineStartEdit)
			if(this.TrimLineEnd && this.TrimLineEndEdit)
			{
				NewText := RTrim(NewText, this.TrimLineEndEdit)
				outputdebug trimmed %newtext%
			}
			if(this.InsertLineChars && this.InsertLineCharsEdit && IsNumeric(this.InsertLineCharsPos) && this.InsertLineCharsPos >= 0)
			{
				if(this.InsertLineCharsDir = "line start")
					NewText := SubStr(NewText, 1, this.InsertLineCharsPos) this.InsertLineCharsEdit SubStr(NewText, this.InsertLineCharsPos + 1)
				else ;End
					NewText := SubStr(NewText, 1, this.InsertLineCharsPos = 0 ? StrLen(NewText) : -this.InsertLineCharsPos) this.InsertLineCharsEdit SubStr(NewText, -(this.InsertLineCharsPos - 1), this.InsertLineCharsPos = 0 ? 0 : StrLen(NewText))
			}
			if(this.RemoveLineChars && IsNumeric(this.RemoveLineCharsLen) && this.RemoveLineCharsLen > 0 && this.RemoveLineCharsPos >= 0)
			{
				if(this.RemoveLineCharsDir = "line start")
					NewText := SubStr(NewText, 1, this.RemoveLineCharsPos) SubStr(NewText, this.RemoveLineCharsPos + this.RemoveLineCharsLen + 1)
				else ;End
					NewText := SubStr(NewText, 1, -(this.RemoveLineCharsPos + this.RemoveLineCharsLen)) SubStr(NewText,-this.RemoveLineCharsPos+1, this.RemoveLineCharsPos = 0 ? 0 : StrLen(NewText))
			}
			if(this.LineTabsToSpaces && IsNumeric(this.LineTabsToSpacesEdit))
			{
				spaces := ""
				Loop % this.LineTabsToSpacesEdit
					spaces .= " "
				NewText := StringReplace(NewText, "`t", spaces, "All")
			}
			else if(this.LineSpacesToTabs && IsNumeric(this.LineSpacesToTabsEdit))
			{
				spaces := ""
				Loop % this.LineSpacesToTabsEdit
					spaces .= " "
				NewText := StringReplace(NewText, spaces, "`t", "All")
			}
			if(this.ChangeLineCase)
			{
				if(this.ChangeLineCaseList = "UPPER")
					StringUpper, NewText, NewText
				else if(this.ChangeLineCaseList = "Lower")
					StringLower, NewText, NewText
				else if(this.ChangeLineCaseList = "Start Case")
					StringUpper, NewText, NewText, T
			}
			if(this.PrefixLine && this.PrefixLineEdit)
				NewText := this.PrefixLineEdit NewText
			if(this.SuffixLine && this.SuffixLineEdit)
				NewText := NewText this.SuffixLineEdit
			if(this.ConvertLineSeparator && r || n)
			{
				if(this.ConvertLineSeparatorList = "Windows (\r\n)")
					NewText .= "`r`n"
				else if(this.ConvertLineSeparatorList = "Unix (\n)")
				{
					NewText .= "`n"
				}
			}
			else
				NewText .= (r ? "`r" : "") (n? "`n" : "")
		}
		if(NewText && !(NewText == Text))
		{
			File.Lines.Insert(Object("Line", LineNumber, "Text", Text, "NewText", NewText, "Enabled", true))
			return 1
		}
		return 0
	}
	FileContentSearch()
	{
		if(this.InSelectedFiles) ;skip files which are not in selection
			Selection := Navigation.GetSelectedFilepaths(this.Parent)
		items := 0
		Loop % AppendPaths(this.BasePath, "*"), 0, % this.IncludeSubdirectories
		{
			if(this.Stop)
				return 0
			File := Object()
			File.Path := A_LoopFileLongPath
			File.Lines := Array()
			if(IsObject(Selection) && Selection.IndexOf(A_LoopFileLongPath) = 0) ;If selection exists and this file is not in it, skip it
				continue
			if(this.InString && !RegexMatch(A_LoopFileName,this.InString)) ;Check filter regex
				continue
			f := FileOpen(A_LoopFileLongPath, "r")			
			;Detect file encoding
			if f.Pos == 3 
				File.cp := "UTF-8"
			else if f.Pos == 2 
				File.cp := "UTF-16 "
			else 
				File.cp := "CP0" 
			while(!f.AtEOF)
			{
				if(this.Stop)
				{
					f.Close()
					return 0
				}
				Line := f.ReadLine()
				this.ProcessLine(File, Line, A_Index)
			}
			f.Close()
			if(File.Lines.MaxIndex() > 0)				
				this.SearchResults.Insert(File)
		}
	}
	PerformFileContentReplace()
	{
		Loop % this.SearchResults.MaxIndex()
		{
			index := A_Index
			Lines := ""
			output := ""
			Loop % this.SearchResults[index].Lines.MaxIndex() ;Small loop to speed it up a bit for large files
			{
				if(this.SearchResults[index].Lines[A_Index].Enabled)
					Lines .= "," this.SearchResults[index].Lines[A_Index].Line
			}
			if(Lines = "")
				continue
			f := FileOpen(this.SearchResults[index].Path, "r") 			
			;Generate new file content
			while(!f.AtEOF)
			{
				if(this.Stop)
				{
					f.Close()
					return 0
				}
				Line := f.ReadLine()
				if(InStr(Lines, "," A_Index))
					output .= this.SearchResults[index].Lines.GetItemWithValue("Line", A_Index).NewText
				else
					output .= Line
			}
			f.Close()
			
			;Write the replaced text back into the file
			FileDelete, % this.SearchResults[index].Path
			f := FileOpen(this.SearchResults[index].Path, "rw", this.SearchResults[index].cp)
			f.Write(output)
			f.Close()
		}
	}
	ListViewEvent()
	{
		if(this.Filenames)
		{
			if(A_GUIEvent = "I") ;Check/Uncheck
			{
				if(ErrorLevel == "C") ;Check
					Enabled := true
				else if(ErrorLevel == "c") ;Uncheck
					Enabled := false
				 LV_GetText(Name, A_EventInfo, 1)
				 LV_GetText(Path, A_EventInfo, 2)
				 Path := AppendPaths(this.BasePath, Path)
				TreeItem := this.FindTreeItem(this.DirectoryTree, Path, Name)
				TreeItem.Enabled := Enabled
			}
		}
		else
		{
			if(A_GUIEvent = "I") ;Check/Uncheck
			{
				if(ErrorLevel == "C") ;Check
					Enabled := true
				else if(ErrorLevel == "c") ;Uncheck
					Enabled := false
				 LV_GetText(Path, A_EventInfo, 1)
				 LV_GetText(LineNumber, A_EventInfo, 2)
				 Result := this.SearchResults.GetItemWithValue("Path", AppendPaths(this.BasePath,Path)).Lines.GetItemWithValue("Line", LineNumber)
				Result.Enabled := Enabled
			}
		}
	}
	
	;Main GUI Handler for Quick & Dirty elements
	GuiEvent(Label)
	{
		hwnd := "h" SubStr(Label, 22) ;Get matching hwnd var
		if(InStr(Label, "Line"))
		{
			hwnd := this.QuicknDirtyFiles[hwnd]
			count := 27-18+1
			offset := 17
		}
		else
		{
			hwnd := this.QuicknDirtyFilenames[hwnd]
			count := 16 - 9 + 1
			offset := 8
		}
		
		AnyChecked := 0
		Loop % count
		{
			GuiControlGet, Checked, ,% "Button" (A_Index + offset)
			AnyChecked |= Checked
		}
		; GuiControl, Disable%AnyChecked%, Edit1
		GuiControl, Disable%AnyChecked%, Edit2
		; GuiControl, Disable%AnyChecked%, Button4
		; GuiControl, Disable%AnyChecked%, Button5
		
		ClassNN := HWNDToClassNN(hwnd)
		GuiControlGet, value, ,%ClassNN%
		
		if(Label="ExplorerReplaceDialogFiles")
		{
			SetControlDelay, 0
			Control, Disable,,, % "ahk_id " this.hIncludeDirectories
			Control, Disable,,, % "ahk_id " this.hCollidingAction
			for key, value in this.QuicknDirtyFilenames
				Control, Hide,,,  ahk_id %value%
			for key, value in this.QuicknDirtyFiles
				Control, Show,,, ahk_id %value%
			WinSetTitle, % "ahk_id " this.hwnd,, Replace in files
			LV_ModifyCol(1,100, "File")
			LV_ModifyCol(2,38, "Line")
			LV_ModifyCol(3,265, "Text")
			if(LV_GetCount("Col") = 3)
			{
				LV_Delete()
				this.Remove("SearchResults")
				this.Remove("DirectoryTree")
				this.Remove("BasePath")
				LV_InsertCol(4,265, "Replaced Text")
			}
		}
		else if(Label="ExplorerReplaceDIalogFilenames")
		{
			SetControlDelay, 0
			Control, Enable,,, % "ahk_id " this.hIncludeDirectories
			Control, Enable,,, % "ahk_id " this.hCollidingAction
			enum := this.QuicknDirtyFiles._newEnum()
			while enum[key,value]
				Control, Hide,,,  ahk_id %value%
			enum := this.QuicknDirtyFilenames._newEnum()
			while enum[key,value]
				Control, Show,,,  ahk_id %value%
			WinSetTitle, % "ahk_id " this.hwnd,, Replace filenames
			if(LV_GetCount("Col") = 4)
			{
				LV_Delete()
				this.Remove("SearchResults")
				this.Remove("BasePath")
				LV_DeleteCol(4)
			}
			LV_ModifyCol(1,234, "Old File")
			LV_ModifyCol(2,200, "Path")
			LV_ModifyCol(3,234, "New File")
		}
		else if(Label = "ExplorerReplaceDialogPrefix")
			GuiControl, Enable%value%, Edit4
		else if(Label = "ExplorerReplaceDialogSuffix")			
			GuiControl, Enable%value%, Edit5
		else if(Label = "ExplorerReplaceDialogChangeExtension")
		{
			GuiControl, Enable%value%, Edit6
			if(value)
				GuiControl, ,Button17,0
		}
		else if(Label = "ExplorerReplaceDialogTrimStart" || Label = "ExplorerReplaceDialogTrimEnd")
		{
			if(Label = "ExplorerReplaceDialogTrimStart")
				GuiControl, Enable%value%,Edit7
			else
				GuiControl, Enable%value%,Edit8
			if(value)
			{
				GuiControl,,Button14, 0 ;Insert
				GuiControl,,Button15, 0 ;Remove				
				GuiControl, Disable,Edit9
				GuiControl, Disable,Edit10
				GuiControl, Disable,ComboBox2
				GuiControl, Disable,Edit11
				GuiControl, Disable,Edit12
				GuiControl, Disable,ComboBox3
			}
		}
		else if(Label = "ExplorerReplaceDialogChangeCase")
		{
			GuiControl, Enable%value%, ComboBox4
			GuiControl, Enable%value%, Button17
		}
		else if(Label = "ExplorerReplaceDialogRemoveChars" || Label = "ExplorerReplaceDialogInsertChars")
		{
			if(Label = "ExplorerReplaceDialogInsertChars")
			{
				GuiControl, Enable%value%, Edit9
				GuiControl, Enable%value%, Edit10
				GuiControl, Enable%value%, ComboBox2
			}
			else
			{				
				GuiControl, Enable%value%,Edit11
				GuiControl, Enable%value%,Edit12
				GuiControl, Enable%value%,ComboBox3
			}
			if(value)
			{
				GuiControl,,Button12, 0 ;trim start
				GuiControl,,Button13, 0 ;trim end
				GuiControl, Disable, Edit7
				GuiControl, Disable, Edit8
			}
		}
		else if(Label = "ExplorerReplaceDialogChangeCaseExtension")
		{
			if(value)
			{
				GuiControl,, Button11, 0
				GuiControl, Disable, Edit6
			}
		}
		else if(Label = "ExplorerReplaceDialogPrefixLine")
			GuiControl, Enable%value%, Edit13
		else if(Label = "ExplorerReplaceDialogSuffixLine")			
			GuiControl, Enable%value%, Edit14
		else if(Label = "ExplorerReplaceDialogTrimLineStart" || Label = "ExplorerReplaceDialogTrimLineEnd")
		{
			if(Label = "ExplorerReplaceDialogTrimLineStart")
				GuiControl, Enable%value%,Edit15
			else
				GuiControl, Enable%value%,Edit16
			if(value)
			{
				GuiControl,,Button22, 0 ;Insert
				GuiControl,,Button23, 0 ;Remove				
				GuiControl, Disable,Edit17
				GuiControl, Disable,Edit18
				GuiControl, Disable,ComboBox5
				GuiControl, Disable,Edit19
				GuiControl, Disable,Edit20
				GuiControl, Disable,ComboBox6
			}
		}
		else if(Label = "ExplorerReplaceDialogRemoveLineChars" || Label = "ExplorerReplaceDialogInsertLineChars")
		{
			if(Label = "ExplorerReplaceDialogInsertLineChars")
			{
				GuiControl, Enable%value%, Edit17
				GuiControl, Enable%value%, Edit18
				GuiControl, Enable%value%, ComboBox5
			}
			else
			{				
				GuiControl, Enable%value%,Edit19
				GuiControl, Enable%value%,Edit20
				GuiControl, Enable%value%,ComboBox6
			}
			if(value)
			{
				GuiControl,,Button20, 0 ;trim start
				GuiControl,,Button21, 0 ;trim end
				GuiControl, Disable, Edit15
				GuiControl, Disable, Edit16
			}
		}
		else if(Label = "ExplorerReplaceDialogLineTabsToSpaces")
		{
			GuiControl, Enable%value%, Edit21
			if(value)
			{
				GuiControl,,Button25, 0
				GuiControl, Disable, Edit22
			}
		}
		else if(Label = "ExplorerReplaceDialogLineSpacesToTabs")
		{
			GuiControl, Enable%value%, Edit22			
			if(value)
			{
				GuiControl,,Button24, 0
				GuiControl, Disable, Edit21
			}
		}
		else if(Label = "ExplorerReplaceDialogChangeLineCase")
			GuiControl, Enable%value%, ComboBox7
		else if(Label = "ExplorerReplaceDialogConvertLineSeparator")
			GuiControl, Enable%value%, ComboBox8
	}
	Replace()
	{
		global ExplorerWindows
		WinSetTitle, % "ahk_id " this.hWnd,,Working...,
		if(this.Filenames)
			this.PerformFileNameReplace(this.DirectoryTree, AppendPaths(this.DirectoryTree.Path, this.DirectoryTree.Name))
		else
			this.PerformFileContentReplace()
		if(this.Stop)
		{
			this.Remove("SearchResults")
			this.Remove("DirectoryTree")
			this.Remove("BasePath")
			this.Remove("Stop")
			LV_Delete()
			WinSetTitle, % "ahk_id " this.hWnd,, % (this.Files ? "Replace in files" : "Replace filenames")
			ControlSetText,, Cancel, % "ahk_id " this.hCancel
			Control, Disable,,, % "ahk_id " this.hReplaceButton
		}
		ExplorerWindows.GetItemWithValue("hwnd", this.Parent).Remove("ReplaceDialog")
	}
}
ExplorerReplaceDialogFiles:
ExplorerReplaceDialogFilenames:
ExplorerReplaceDialogPrefix:
ExplorerReplaceDialogSuffix:
ExplorerReplaceDialogChangeExtension:
ExplorerReplaceDialogTrimStart:
ExplorerReplaceDialogTrimEnd:
ExplorerReplaceDialogChangeCase:
ExplorerReplaceDialogChangeCaseExtension:
ExplorerReplaceDialogRemoveChars:
ExplorerReplaceDialogInsertChars:

ExplorerReplaceDialogPrefixLine:
ExplorerReplaceDialogSuffixLine:
ExplorerReplaceDialogTrimLineStart:
ExplorerReplaceDialogTrimLineEnd:
ExplorerReplaceDialogRemoveLineChars:
ExplorerReplaceDialogInsertLineChars:
ExplorerReplaceDialogLineTabsToSpaces:
ExplorerReplaceDialogLineSpacesToTabs:
ExplorerReplaceDialogChangeLineCase:
ExplorerReplaceDialogConvertLineSeparator:
Loop % ExplorerWindows.MaxIndex()
	if(ExplorerWindows[A_Index].ReplaceDialog.GUINum = A_GUI)
		ExplorerWindows[A_Index].ReplaceDialog.GuiEvent(A_ThisLabel)
return


ExplorerReplaceDialogListView:
Loop % ExplorerWindows.MaxIndex()
	if(ExplorerWindows[A_Index].HasKey("ReplaceDialog") && ExplorerWindows[A_Index].ReplaceDialog.GUINum = A_GUI)
		ExplorerWindows[A_Index].ReplaceDialog.ListViewEvent()
return
ExplorerReplaceDialogSearch:
Loop % ExplorerWindows.MaxIndex()
	if(ExplorerWindows[A_Index].HasKey("ReplaceDialog") && ExplorerWindows[A_Index].ReplaceDialog.GUINum = A_GUI)
		ExplorerWindows[A_Index].ReplaceDialog.Search()
return

ExplorerReplaceDialogCancel:
Loop % ExplorerWindows.MaxIndex()
{
	if(ExplorerWindows[A_Index].HasKey("ReplaceDialog") && ExplorerWindows[A_Index].ReplaceDialog.GUINum = A_GUI)
	{
		if(ControlGetText("","ahk_id " ExplorerWindows[A_Index].ReplaceDialog.hCancel) = "Stop")
			ExplorerWindows[A_Index].ReplaceDialog.Stop := true
		else
			ExplorerWindows[A_Index].Remove("ReplaceDialog")
	}
}
return
ExplorerReplaceDialogClose:
ExplorerReplaceDialogEscape:
Loop % ExplorerWindows.MaxIndex()
	if(ExplorerWindows[A_Index].HasKey("ReplaceDialog") && ExplorerWindows[A_Index].ReplaceDialog.GUINum = A_GUI)
	{
		ExplorerWindows[A_Index].ReplaceDialog.Stop := true
		ExplorerWindows[A_Index].Remove("ReplaceDialog")
	}
return
ExplorerReplaceDialogReplace:
Loop % ExplorerWindows.MaxIndex()
	if(ExplorerWindows[A_Index].HasKey("ReplaceDialog") && ExplorerWindows[A_Index].ReplaceDialog.GUINum = A_GUI)
		ExplorerWindows[A_Index].ReplaceDialog.Replace()
return
ExplorerReplaceDialogRegEx:
run http://www.autohotkey.com/docs/misc/RegEx-QuickRef.htm
return