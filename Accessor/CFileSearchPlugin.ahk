Class CFileSearchPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("File Search", CFileSearchPlugin)
	
	Description := "Quickly find files on the computer or the current directory."
	
	Cleared := false
	List := Array()
	Icons := Array()
	AllowDelayedExecution := true
	SearchIcon := ExtractIcon("%WINDIR%\System32\shell32.dll", 23)

	static DllPath := A_ScriptDir "\lib" (A_PtrSize = 8 ? "\x64" : "" ) "\FileSearch.dll"
	IndexingWorkerThreads := RichObject()
	FileSystemIndex := {}

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "find"
		KeywordOnly := true
		MinChars := 3
		UseIcons := true
		IndexingFrequency := 24 ;Indexing frequency [hours]
	}

	Class CSearchInAccessorResult extends CAccessorPlugin.CResult
	{
		Actions := {DefaultAction : new CAccessor.CAction("Search", "SearchInAccessor", "", false, false, false, A_WinDir "\System32\Shell32.dll", 210)}
		Type := "File Search"
		Priority := CFileSearchPlugin.Instance.Priority
		MatchQuality := 1 ;Only direct matches are used by this plugin
		Title := "Show search results in Accessor for:"
		Detail1 := "File search"
		Icon := CFileSearchPlugin.Instance.SearchIcon
	}

	Class CNoResultsResult extends CAccessorPlugin.CResult
	{
		Actions := {DefaultAction : CAccessorPlugin.CActions.Cancel}
		Type := "File Search"
		Priority := 0
		MatchQuality := 1 ;Only direct matches are used by this plugin
		Title := "No results found!"
		Path := "Please try another search term"
		Detail1 := "File search"
		Icon := CFileSearchPlugin.Instance.SearchIcon
	}

	Class CSearchingResult extends CAccessorPlugin.CResult
	{
		Actions := {DefaultAction : CAccessorPlugin.CActions.Cancel}
		Type := "File Search"
		Priority := 0
		MatchQuality := 1 ;Only direct matches are used by this plugin
		Title := "Searching, please wait..."
		Detail1 := "File search"
		Icon := CFileSearchPlugin.Instance.SearchIcon
	}

	Class CSearchResult extends CAccessorPlugin.CResult
	{
		Class CFileActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open file", "Run")
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
			}
		}

		Class CExecutableActions extends CArray
		{
			DefaultAction := CAccessorPlugin.CActions.Run
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
				this.Insert(CAccessorPlugin.CActions.RunWithArgs)
				this.Insert(CAccessorPlugin.CActions.RunAsAdmin)
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
			}
		}

		Class CFolderActions extends CArray
		{
			DefaultAction := CAccessorPlugin.CActions.OpenExplorer
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
				this.Insert(CAccessorPlugin.CActions.SearchDir)
			}
		}

		__new(Type)
		{
			if(Type = "Folder")
				this.Actions := new this.CFolderActions()
			else if(Type = "Executable")
				this.Actions := new this.CExecutableActions()
			else
				this.Actions := new this.CFileActions()
		}
		
		ResultIndexingKey := "Path"
		Type := "File Search"
		Priority := CFileSearchPlugin.Instance.Priority
		MatchQuality := 1 ;Only direct matches are used by this plugin 
		Detail1 := "Search result"
	}

	Enable()
	{
		this.hModule := DllCall("LoadLibrary", "Str", this.DllPath, "PTR")
		if(!this.hModule)
			MsgBox % A_ThisFunc ": Failed to load " this.DllPath "!"
		else
			this.BuildFileDatabase()
	}

	Disable()
	{
		this.FreeResources()
		SetTimer, UpdateFileSystemIndex, Off
	}

	FreeResources()
	{
		;Get rid of old icons from last queries
		for path, Icon in this.Icons
			DestroyIcon(Icon)
		this.Icons := Array()
		for drive, DriveIndex in this.FileSystemIndex
			DllCall(this.DllPath "\DeleteIndex", "PTR", DriveIndex)
		this.FileSystemIndex := {}
		if(this.hModule)
			DllCall("FreeLibrary", "PTR", this.hModule)
		this.Remove("hModule")
	}

	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseIcons", "Use proper icons (not recommended)", "", "", "", "", "", "", "If checked, 7plus will use the correct icon for each file. This can cause instabilities for large results.")
		AddControl(PluginSettings, PluginGUI, "UpDown", "IndexingFrequency", "1-100", "", "Indexing frequency[hours]:", "", "", "", "", "This plugin uses an index to speed up the search.`nTo make sure that the retrieved files aren't outdated`nit needs to be rebuilt regularly. Depending on the`nnumber of files this can take up to a minute.")
	}

	SaveSettings(PluginSettings, GUI, PluginGUI)
	{
		this.BuildFileDatabase()
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!KeywordSet)
			return
		outputdebug File Search Refresh List
		Results := {}
		if(this.HasKey("SearchPath"))
			SearchPath := this.SearchPath
		if((pos := InStr(Filter, " in ")))
		{
			;Ignore invalid paths
			if(!InStr(FileExist(SubStr(Filter, pos + 4)), "D"))
				return
			SearchPath := SubStr(Filter, pos + 4)
			Filter := SubStr(Filter, 1, pos - 1)
		}
		outputdebug filter %filter%
		;If there are results and they belong to the current query
		if(IsObject(this.Results) && this.Results.Query = Filter && this.Results.SearchPath = SearchPath)
		{
			outputdebug search atleast partly finished
			if(this.Results.MaxIndex())
			{
				outputdebug results available
				for index, File in this.Results
				{
					Result := new this.CSearchResult(File.IsDir ? "Folder" : (File.IsExecutable ? "Executable" : "File"))
					Result.Title := File.Title
					Result.Path := File.Path
					Result.Icon := File.Icon
					Results.Insert(Result)
				}
			}
			else if(this.Results.Finished) ;No results
			{
				outputdebug no results found!
				Results.Insert(new this.CNoResultsResult())
			}
			else ;Searching
			{
				outputdebug searching, shouldn't be here
				Results.Insert(new this.CSearchingResult())
			}
		}
		else if(StrLen(Filter) < 5 && !this.SearchAnyway)
		{
			outputdebug filter too short for search
			Result := new this.CSearchInAccessorResult()
			if(SearchPath)
			{
				Result.Title .= " " Filter
				Result.Path := SearchPath
			}
			else
				Result.Path := Filter
			Results.Insert(Result)
		}
		else if((StrLen(Filter) >= 5 && !strEndsWith(Filter, " i") && !strEndsWith(Filter, " in")) || this.SearchAnyway)
		{
			outputdebug start search
			this.SearchAnyway := false
			this.StartSearch(Filter, SearchPath)
			Results.Insert(new this.CSearchingResult())
		}
		return Results
	}

	StartSearch(Query, SearchPath)
	{
		this.CancelSearch()
		this.Results := []
		this.Results.Query := Query
		this.Results.SearchPath := SearchPath
		Drive := ""
		SplitPath, SearchPath, , , , , Drive
		Drive := SubStr(Drive, 1, 1)
		Drives := Drive ? [Drive] : this.GetIndexingDrives()
		outputdebug % "drives: " Drives.ToString(", ")
		for index, Drive in Drives
		{
			WorkerThread := new CWorkerThread("AccessorFileSearch", 0, 1, 1)
			WorkerThread.OnStop.Handler := new Delegate(this, "OnSearchThreadStopped")
			;WorkerThread.OnData.Handler := new Delegate(this, "OnData")
			WorkerThread.OnFinish.Handler := new Delegate(this, "OnSearchThreadFinished")
			this.SearchingThreads[Drive] := WorkerThread
			WorkerThread.Start(Query, Settings.ConfigPath "\" Drive ".index", SearchPath)
			;if(WorkerThread.WaitForStart(5))
			;{
			;	outputdebug Started worker thread for %Drive%
			;}
			;else if(WorkerThread.State != "Finished")
			;{
			;	outputdebug failed to wait for worker thread startup
			;	Notify("File search error!", "Couldn't start the searching process!", 5, NotifyIcons.Error)
			;}
		}
	}

	OnSearchThreadStopped(WorkerThread, Reason)
	{
		outputdebug % "WorkerThread for drive " WorkerThread.Task.Parameters[2] " stopped"
	}

	OnSearchThreadFinished(WorkerThread, Result)
	{
		outputdebug % "WorkerThread for drive " WorkerThread.Task.Parameters[2] " finished"
		if(IsObject(Result) && !WorkerThread.ShouldStop)
		{
			outputdebug results found
			ResultString := Result.Result
			Loop, Parse, ResultString, `n
			{
				SplitPath, A_LoopField, Name, Dir, ext
				IsDir := InStr(FileExist(A_LoopField), "D")
				IsExecutable := !IsDir && ext && InStr("exe,cmd,bat,ahk", ext)
				File := {IsDir : IsDir, IsExecutable : IsExecutable, Title : Name, Path : A_LoopField}
				;Result := new this.CSearchResult(IsDir ? "Folder" : (IsExecutable ? "Executable" : "File"))
				;Result.Title := Name
				;Result.Path := A_LoopField
				if(this.Settings.UseIcons || (Result.AllResults != -1 && Result.AllResults <= 20))
				{
					if(this.Icons.HasKey(A_LoopField))
						hIcon := this.Icons[A_LoopField]
					else
					{
						hIcon := ExtractAssociatedIcon(0, A_LoopField, iIndex)
						this.Icons.Insert(hIcon)
					}
					File.Icon := hIcon
				}
				else
					File.Icon := IsDir ? CAccessor.Instance.GenericIcons.Folder : (IsExecutable ? CAccessor.Instance.GenericIcons.Application : CAccessor.Instance.GenericIcons.File)
				this.Results.Insert(File)
			}
			;More results have been found
			if(Result.AllResults = -1)
				this.Results.MoreResults := true
		}
		this.SearchingThreads.Remove(this.SearchingThreads.IndexOf(WorkerThread))
		if(!this.SearchingThreads.MaxIndex())
			this.Results.Finished := true
		outputdebug % "refresh list with" this.Results.MaxIndex() "results"
		CAccessor.Instance.RefreshList()
	}
	
	CancelSearch()
	{
		outputdebug cancel previous search
		for Drive, Thread in this.SearchingThreads
		{
			Thread.Stop()
			Thread.ShouldStop := true
		}
		this.SearchingThreads := {}
		this.Results := ""
	}

	OnClose(Accessor)
	{
		outputdebug onclose
		this.CancelSearch()
	
		;Get rid of old icons from last queries
		for path, Icon in this.Icons
			DestroyIcon(Icon)
	}

	OnExit()
	{
		this.FreeResources()
	}
	
	SearchInAccessor(Accessor, ListEntry)
	{
		this.SearchAnyway := true
		Accessor.RefreshList()
	}

	;Builds a database of all files on fixed drives
	BuildFileDatabase(LoadExisting = true)
	{
		outputdebug build database
		if(this.hModule)
		{
			outputdebug hmodule
			NTFSDrives := this.GetIndexingDrives()
			DriveCount := NTFSDrives.MaxIndex()
			DrivesLeft := ""
			outputdebug % exploreobj(NTFSDrives)
			for index, Drive in NTFSDrives
			{
				IndexPath := Settings.ConfigPath "\" Drive ".index"
				if(FileExist(IndexPath))
				{
					FileGetTime, ModificationTime, %IndexPath%
					Delta := A_Now
					EnvSub, Delta, %ModificationTime%, minutes
					if(Delta > 0 && Delta / 60 < this.Settings.IndexingFrequency && LoadExisting)
						continue
				}
				Outputdebug Start worker thread to build index for %Drive%
				WorkerThread := new CWorkerThread("BuildFileDatabaseForDrive", 0, 1, 1)
				;WorkerThread.OnProgress.Handler := new Delegate(this, "ProgressHandler")
				WorkerThread.OnStop.Handler := new Delegate(this, "OnStop")
				;WorkerThread.OnData.Handler := new Delegate(this, "OnData")
				WorkerThread.OnFinish.Handler := new Delegate(this, "OnFinish")
				this.IndexingWorkerThreads[Drive] := WorkerThread
				DrivesLeft .= (StrLen(DrivesLeft) > 0 ? ", " : "") Drive
				WorkerThread.Start(Drive, IndexPath)
			}

			outputdebug % this.IndexingWorkerThreads.Count()
			if(StrLen(DrivesLeft) && this.IndexingWorkerThreads.Count())
				this.IndexingWorkerThreads.NotificationWindow := Notify("Indexing drives for file search", "Drives left: " DrivesLeft, "", NotifyIcons.Info)
			
			if(Delta > 0 && Delta < this.Settings.IndexingFrequency)
				SetTimer, UpdateFileSystemIndex, % (Delta - this.Settings.IndexingFrequency) * 3600000
			else
				SetTimer, UpdateFileSystemIndex, % "-" max(this.Settings.IndexingFrequency * 3600000, 600000) ;Should be atleast 10 minutes
		}
	}

	OnStop(WorkerThread, Reason)
	{
		;Shouldn't happen
	}

	OnFinish(WorkerThread, Result)
	{
		Drive := WorkerThread.Task.Parameters[1]
		;if(Result = true)
		;{
		;	File := WorkerThread.Task.Parameters[2]
		;	this.LoadDriveIndex(Drive, File)
		;}
		this.IndexingWorkerThreads.Remove(Drive)
		DrivesLeft := ""
		for d, value in this.IndexingWorkerThreads
			if(d != "NotificationWindow")
				DrivesLeft .= (StrLen(DrivesLeft) > 0 ? ", " : "") d
		if(StrLen(DrivesLeft))
			this.IndexingWorkerThreads.NotificationWindow.Text := "Drives left: " DrivesLeft
		else
		{
			this.IndexingWorkerThreads.NotificationWindow.Close()
			this.IndexingWorkerThreads.Remove("NotificationWindow")
		}
		outputdebug finished indexing %Drive%! Result: %Result%
	}
	LoadDriveIndex(Drive, Path)
	{
		if(FileExist(Path) && this.hModule)
		{
			outputdebug load file system index for %path%
			if(DriveIndex := DllCall(this.DllPath "\LoadIndexFromDisk", "str", Path, "PTR"))
				this.FileSystemIndex[Drive] := DriveIndex
			else
				Msgbox %A_ThisFunc%: Failed to load %Path%!
		}
	}

	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		outputdebug filter changed from "%LastFilter%" to "%filter%"
		this.CancelSearch()
		if(this.HasKey("SearchPath") && InStr(LastFilter, this.Settings.Keyword " ") = 1 && InStr(Filter, this.Settings.Keyword " ") != 1)
			this.Remove("SearchPath")
		return true
	}
	GetFooterText()
	{
		return this.Results && ! this.Results.Finished ? "Searching, please wait a few seconds..." : (this.Results.MoreResults ? "There were more results which are not displayed. Please narrow down your search term!" : "File search may take up to a few seconds, please have patience.")
	}
	;Returns a list of drives that can be indexed
	GetIndexingDrives()
	{
		DriveGet, Drives, List, FIXED
		NTFSDrives := []
		Loop, Parse, Drives
		{
			DriveGet, FS, FS, %A_LoopField%:
			if(FS = "NTFS")
				NTFSDrives.Insert(A_LoopField)
		}
		return NTFSDrives
	}
}

UpdateFileSystemIndex:
CAccessor.Plugins[CFileSearchPlugin.Type].BuildFileDatabase(false)
return

;Builds a database of all files on fixed drives
BuildFileDatabaseForDrive(WorkerThread, Drive, Path)
{
	outputdebug WT: Start indexing drive %drive%
	DllPath := A_ScriptDir "\lib" (A_PtrSize = 8 ? "\x64" : "" ) "\FileSearch.dll"
	hModule := DllCall("LoadLibrary", "Str", DllPath, "PTR")
	result := false
	if(!hModule)
		MsgBox % A_ThisFunc ": Failed to load " DllPath "!"
	else
	{
		DriveIndex := DllCall(DllPath "\CreateIndex", ushort, NumGet(Drive, "ushort"), "PTR")
		if(DriveIndex)
		{
			result := DllCall(DllPath "\SaveIndexToDisk", "PTR", DriveIndex, wstr, Path, "UINT")
			DllCall(DllPath "\DeleteIndex", "PTR", DriveIndex)
		}
	}
	if(hModule)
		DllCall("FreeLibrary", "PTR", hModule)
	outputdebug WT: Indexing for %Drive% finished with result %result%
	return result
}

AccessorFileSearch(WorkerThread, Query, IndexPath, SearchPath)
{
	strAllDrivesResult := ""
	hModule := DllCall("LoadLibrary", "Str", CFileSearchPlugin.DllPath, "PTR")
	SplitPath, IndexPath, Drive
	outputdebug WT: Running for drive %Drive% and Query %Query%
	if(hModule)
	{
		outputdebug WT: Module loaded
		if(FileExist(IndexPath))
		{
			outputdebug WT: Loading from %IndexPath%
			DriveIndex := LoadDriveIndex(Drive, IndexPath, hModule)
			if(!DriveIndex)
				return 0
			outputdebug WT: Index loaded
			pResult := DllCall(CFileSearchPlugin.DllPath "\SearchIndex", "PTR", DriveIndex, "wstr", Query, SearchPath ? "wstr" : "ptr", SearchPath ? SearchPath : 0, "int", true, "int", true, "int", 100, "int*", nResults, PTR)
			strResult := StrGet(presult + 0)
			outputdebug % "WT: " Drive ": Searched: " A_TickCount
			if(pResult)
			{
				DllCall(CFileSearchPlugin.DllPath "\FreeResultsBuffer", "PTR", pResult)
				if(strResult)
				{
					outputdebug WT: Finished search and found results for drive %Drive% and Query %Query%
					return {Result : strResult, AllResults : (nResults != -1 ? nResults : -1)}
				}
			}
		}
	}
	return 0
}

LoadDriveIndex(Drive, Path, hModule)
{
	if(FileExist(Path) && hModule)
	{
		outputdebug WT: load file system index for %path%
		if(DriveIndex := DllCall(CFileSearchPlugin.DllPath "\LoadIndexFromDisk", "str", Path, "PTR"))
			return DriveIndex
		else
			outputdebug WT: Failed to load %Path%!
	}
}

;Why is OnClose called all the time?
;Why do we see refreshes while we type? Is it really so fast? Unlikely