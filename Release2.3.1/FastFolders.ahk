#include *i %A_ScriptDir%\Navigate.ahk
#include *i %A_ScriptDir%\MiscFunctions.ahk
Class CFastFolders extends CArray
{
	MinIndex()
	{
		return 0
	}
	MaxIndex()
	{
		return 9
	}
}
ClearStoredFolder(Slot)
{
	global FastFolders
	;Slot+=1
	FastFolders[Slot].Path := ""
	FastFolders[Slot].Name := ""
	RefreshFastFolders()
}

;Assigns a new folder to a FastFolder slot and updates registry
UpdateStoredFolder(Slot, Path = "")
{
	global FastFolders
	;Fast folder slots are 0-based externally but 1 based in the FastFolders array
	;Slot += 1
	if(Path)
		FastFolders[Slot].Path := Path
	else
	{
		FastFolders[Slot].Path := Navigation.GetPath()
		FastFolders[Slot].Name := Navigation.GetDisplayName()
	}
	if(!FastFolders[Slot].Name)
	{
		SplitPath, Path , split
		FastFolders[Slot].Name := split
	}
	RefreshFastFolders()
}

;Removes and re-adds all FastFolder Buttons
RefreshFastFolders()
{
	if(Settings.Explorer.FastFolders.ShowInFolderBand)
		RemoveAllExplorerButtons("IsFastFolderButton")
	AddAllButtons(Settings.Explorer.FastFolders.ShowInFolderBand, Settings.Explorer.FastFolders.ShowInPlacesBar)
}

;Adds all FastFolder Buttons
AddAllButtons(ToFolderBand, ToPlacesBar)
{
	global FastFolders
	Loop 10
	{
		;Fast folder slots are 0-based externally
		pos := A_Index - 1
		if(FastFolders[pos].Path)
		{				
			if(pos <= 4 && ToPlacesBar)	;update placesbar
			{
				value := FastFolders[pos].Path
				RegWrite, REG_SZ,HKCU,Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar, Place%pos%,%value%
			}				
		}
	}
	if(ToFolderBand)
	{
		;Explorer folder band bar buttons are added in a separate process since this takes a few seconds
		if(FastFolders.WorkerThread)
			FastFolders.WorkerThread.Repeat := true ;Mark for repetition with new data
		else
		{
			outputdebug starting new worker thread to refresh FastFolder buttons
			FastFolders.WorkerThread := new CWorkerThread("AddButtonsToFolderBandBar", 0, 0, 1)
			FastFolders.WorkerThread.OnFinish.Handler := "FastFolders_WorkerThread_OnFinish"
			FastFolders.WorkerThread.Start(FastFolders)
			FastFolders.WorkerThread.WaitForStart(5)
		}
	}
}

;Called on main thread when the Fast Folders worker thread has finished
FastFolders_WorkerThread_OnFinish(WorkerThread, Result)
{
	global FastFolders
	outputdebug Fast Folder buttons refresh finished
	if(WorkerThread.Repeat)
	{
		RemoveAllExplorerButtons("IsFastFolderButton")
		outputdebug starting new worker thread to refresh FastFolder buttons
		FastFolders.WorkerThread := new CWorkerThread("AddButtonsToFolderBandBar", 0, 0, 1)
		FastFolders.WorkerThread.OnFinish.Handler := "FastFolders_WorkerThread_OnFinish"
		FastFolders.WorkerThread.Start(FastFolders)
		FastFolders.WorkerThread.WaitForStart(5)
	}
	else
		;Remove the worker thread to indicate that a new one is needed next time
		FastFolders.Remove("WorkerThread")
}

;Worker function executed in seperate thread
AddButtonsToFolderBandBar(WorkerThread, FastFolders)
{
	Loop 10
		if(FastFolders[A_Index - 1].Path)
			AddButton("", FastFolders[A_Index - 1].Path, "", (A_Index - 1) ":" FastFolders[A_Index - 1].Name, "", "Both", 2) ;7plus now uses AHK=2 key in registry to indicate FastFolder buttons
}

;Callback function for determining if a specific registry key was created by 7plus
IsFastFolderButton(Command, Name, Tooltip, ahk)
{
	return ahk = 2 || RegExMatch(Name, "^\d+:") ;RegexMatch is legacy code for buttons which don't have ahk=2 set
}

;Removes all buttons created with this script. Function can be the name of a function with these arguments: func(command, Title, tooltip, ahk) and it can be used to tell the script if an entry may be deleted
RemoveAllExplorerButtons(function = "")
{
	BaseKey := "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes"
	;go into view folders (clsid)
	Loop, HKLM, %BaseKey%, 2, 0
	{			
		clsid := A_LoopRegName
		;code below needs to be executed for two folders each, [selected item / no selected item]
		Keys := {TasksItemsSelected : "", TasksNoItemsSelected : ""}
		for Key, v in Keys
		{
			;go into numbered folders of single buttons
			Loop, HKLM, %BaseKey%\%clsid%\%Key%, 2, 0
			{
				ButtonNumber := A_LoopRegName

				;This function will only remove buttons created by 7plus which have an additional AHK key
				RegRead, ahk, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%, AHK		

				;go into clsid folder
				Loop, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%, 2, 0
				{
					skip := false
					RegRead, value, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%\%A_LoopRegName%, InfoTip
					RegRead, Title, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%\%A_LoopRegName%, Title
					RegRead, cmd, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%\%A_LoopRegName%\shell\InvokeTask\command
					
					;Custom skip function code
					if(IsFunc(function))
						if(!%function%(cmd, Title, value, ahk))
						{
							skip := true
							break
						}
				}
				if(skip)
					continue	
				if(ahk)
					RegDelete, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%
			}
		}
	}
}

;Removes a button. Command can either be a real command (with arguments), a path or a function with three arguments (command, key, param) which identifies the proper key
RemoveButton(Command, param="")
{
	if(!IsFunc(Command) && InStr(Command,"\",0,strlen(Command)))
		StringTrimRight, Command, Command, 1
	BaseKey := "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes"
	ButtonFound := false
	;go into view folders (clsid)
	Loop, HKLM, %BaseKey%, 2, 0
	{			
		clsid := A_LoopRegName
		;code below needs to be executed for two folders each, [selected item / no selected item]
		Keys := {TasksItemsSelected : "", TasksNoItemsSelected : ""}
		for Key, v in Keys
		{
			;Local variable inside this loop for telling found state of the selected/no selected folders
			maxnumber := -1
			;Loop through all buttons of this view (reg loop goes backwards apparently)
			Loop, HKLM, %BaseKey%\%clsid%\%Key%, 2, 0
			{
				ButtonNumber := A_LoopRegName
				maxnumber := max(ButtonNumber, maxnumber)
				
				;Keys created by 7plus have an "AHK" key added to them to make sure that only Keys related to 7plus are modified
				RegRead, ahk, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%, AHK
				if(ahk)
				{
					;go into 2nd clsid folder
					Loop, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%, 2, 0
					{
						RegRead, value, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%\%A_LoopRegName%, InfoTip
						;Check if the current key is the correct one (possibly with a caller-defined function)
						if((!IsFunc(Command) && value = Command) || (IsFunc(Command) && %Command%(value, BaseKey "\" clsid "\" Key "\" ButtonNumber "\" A_LoopRegName "\shell\InvokeTask\command", param)))
						{
							;If the key is correct, it may be deleted
							RegDelete, HKLM, %BaseKey%\%clsid%\%Key%\%ButtonNumber%
							ButtonFound := true
							;after item has been deleted, we need to move the higher ones down by one
							if(maxnumber > ButtonNumber)
							{
								i := ButtonNumber + 1
								while i <= maxnumber
								{
									j := i - 1
									Runwait, reg copy HKLM\%BaseKey%\%clsid%\%Key%\%i% HKLM\%BaseKey%\%clsid%\%Key%\%j% /s /f, , Hide
									regdelete, HKLM, %BaseKey%\%clsid%\%Key%\%i%
									i++
								}
							}
							break 2
						}
					}
				}
			}
		}
	}
	if(!ButtonFound)
		outputdebug % "Explorer button not found: " (param.Extends("CEvent") ? param.Name : Command)
	return ButtonFound
}

;Adds a button. You may specify a command (and possibly an argument) or a path, and a name which should be used.
;Other parameters are a ToolTip
AddButton(Command, path, Args = "", Name = "", Tooltip = "", AddTo = "Both", ahk = 1, IterationsSelected = "", IterationsNoSelected = "")
{
	outputdebug addbutton command %command% path %path% args %args% name %name%
	if(A_IsCompiled)
		ahk_path := """" A_ScriptDir "\7plus.exe"""
	else
		ahk_path := """" A_AhkPath """ """ A_ScriptFullPath """"
	icon := "%SystemRoot%\System32\shell32.dll,3" ;Icon is not working, probably not supported by explorer, some ms entries have icons defined but they don't show up either
	if(Command)
	{
		if(!Name)
		{
			SplitPath, Command , Name
			if(Name = "")
				Name := Command
		}
		icon := Command ",1"
		description := command
		command .= " " args
	}
	
	if(path)
	{				
		;Remove trailing backslash
		if(InStr(path,"\", 0, strlen(path)))
			StringTrimRight, path, path, 1
		if(!name)
		{
			SplitPath, path , Name
			if(Name = "")
				Name := path
		}
		Command := ahk_path " """ path """"	
		description := path	
	}		
	if(!command && !path && args) ;args only, use start 7plus with -id param
	{
		Command := """" (A_IsCompiled ? A_ScriptPath : A_AhkPath """ """ A_ScriptFullPath) """ -id:" args
		description := Tooltip
	}
	SomeCLSID := "{" . uuid(false) . "}"
	
	;These arrays store the next free index of the buttons in the FolderTypes subfolders for speed improvements
	if(!IsObject(IterationsSelected))
		IterationsSelected := []
	if(!IsObject(IterationsNoSelected))
		IterationsNoSelected := []
	BasePath := "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes"
	;go into view folders (clsid)
	Loop, HKLM, %BasePath%, 2, 0
	{
		if(AddTo = "Both" || AddTo = "Selected")
			AddButton_Write(BasePath "\" A_LoopRegName "\TasksItemsSelected", SomeCLSID, command, Name, Description, Icon, ahk, A_LoopRegName, IterationsSelected)
		if(AddTo = "Both" || AddTo = "NoSelected")
			AddButton_Write(BasePath "\" A_LoopRegName "\TasksNoItemsSelected", SomeCLSID, command, Name, Description, Icon, ahk, A_LoopRegName, IterationsNoSelected)
	}
}

;Writes the data for a single button (for selected or no-selected state)
AddButton_Write(Path, SomeCLSID, command, Title, InfoTip, Icon, AHK, Name, Iterations)
{
	;figure out first free key number
	if(!Iterations.HasKey(Name))
	{
		Iterations[Name] := 0
		Loop, HKLM, %Path%, 2, 0
			Iterations[Name]++
	}
	Path .= "\" Iterations[Name]
	;Marker for easier recognition of ahk-added entries
	RegWrite, REG_SZ, HKLM, %Path%, AHK, %AHK%
	Path .= "\" SomeCLSID
	;Write reg keys
	RegWrite, REG_EXPAND_SZ, 	HKLM, %Path%, 							Icon, 		%icon%
	RegWrite, REG_SZ, 			HKLM, %Path%, 							InfoTip, 	%InfoTip%
	RegWrite, REG_SZ, 			HKLM, %Path%, 							Title, 		%Title%
	RegWrite, REG_SZ, 			HKLM, %Path%\shell\InvokeTask\command, 	, 			%command%
	Iterations[Name]++
}

;Checks if a particular button exists
FindButton(function, param)
{
	if(!IsFunc(function))
		return false
	BasePath := "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes"
	;go into view folders (clsid)
	Loop, HKLM, %BasePath%, 2, 0
	{
		regkey := A_LoopRegName
		maxnumber := -1
		;loop through selected item number folders (loop goes backwards)
		Loop, HKLM, %Basepath%\%regkey%\TasksItemsSelected, 2, 0
		{
			numberfolder := A_LoopRegName
			RegRead, ahk, HKLM, %Basepath%\%regkey%\TasksItemsSelected\%numberfolder%, AHK
			if(ahk)
			{
				;go into clsid folder
				Loop, HKLM, %Basepath%\%regkey%\TasksItemsSelected\%numberfolder%, 2, 0
				{
					RegRead, value, HKLM, %Basepath%\%regkey%\TasksItemsSelected\%numberfolder%\%A_LoopRegName%\shell\InvokeTask\command
					if(%function%(value, Basepath "\" regkey "\TasksItemsSelected\" numberfolder "\" A_LoopRegName "\shell\InvokeTask\command", param))
						return true
				}
			}
		}
	}
	return false
}