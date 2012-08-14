Class CShowMenuAction Extends CAction
{
	static Type := RegisterType(CShowMenuAction, "Show menu")
	static Category := RegisterCategory(CShowMenuAction, "System")
	static Menu := ""
	static X := ""
	static Y := ""
	
	Execute(Event)
	{
		X := Event.ExpandPlaceholders(this.X)
		Y := Event.ExpandPlaceholders(this.Y)
		BuildMenu(this.Menu)
		Menu, Tray, UseErrorLevel
		Menu, % this.Menu, Show, %X%, %Y%
		Menu, Tray, UseErrorLevel, Off
		return 1
	} 

	DisplayString()
	{
		return "Show menu " this.Menu
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action shows a menu which is made up out of events with a Menu trigger and the same name as the name specified here.")
			;Look for menus in SettingsWindow.Events to catch unsaved menus
			Menus := Array()
			Loop % SettingsWindow.Events.MaxIndex()
			{
				if(SettingsWindow.Events[A_Index].Trigger.Is(CMenuItemTrigger) && Menus.indexOf(SettingsWindow.Events[A_Index].Trigger.Menu) = 0)
				{
					Menus.Insert(SettingsWindow.Events[A_Index].Trigger.Menu)
					MenuString .= (Menus.MaxIndex() = 1 ? "" : "|") SettingsWindow.Events[A_Index].Trigger.Menu
				}
			}
		
			this.AddControl(GUI, "ComboBox", "Menu", MenuString, "", "Menu:")
			this.AddControl(GUI, "Edit", "X", "", "", "X:", "Placeholders", "PlaceholdersX")
			this.AddControl(GUI, "Edit", "Y", "", "", "Y:", "Placeholders", "PlaceholdersY")
		}
		else if(GoToLabel = "PlaceholdersX")
			ShowPlaceholderMenu(sGUI, "X")
		else if(GoToLabel = "PlaceholdersY")
			ShowPlaceholderMenu(sGUI, "Y")
	}
}
PlaceholdersX:
GetCurrentSubEvent().GuiShow("", "PlaceholdersX")
return
PlaceholdersY:
GetCurrentSubEvent().GuiShow("", "PlaceholdersY")
return

BuildMenu(Name)
{
	global ClipboardList, ExplorerHistory, FastFolders
	Menu, Tray, UseErrorLevel
	Menu, %Name%, DeleteAll
	;Fake default menu items
	if(Name = "Tray")
	{
		Menu, tray, NoStandard
		Menu, tray, add, Settings, SettingsHandler  ; Creates a new menu item.
		Menu, tray, Icon, Settings, % A_WinDir "\system32\shell32.dll", 166
		menu, tray, Default, Settings
	}
	else if(Name = "ClipboardMenu")
	{
		;Persistent clips
		Menu, PersistentClipboard, DeleteAll

		;Unfortunately this check will change the clipboard owner which results in capturing a clipboard change although the original owner should be ignored
		;if(text := GetSelectedText())
		;{
			Menu, PersistentClipboard, add, Add selected text as persistent clip ..., AddClip
			Menu, PersistentClipboard, Icon, Add selected text as persistent clip ..., % A_WinDir "\system32\wmploc.dll", 16
		;}
		Menu, PersistentClipboard, add, Edit persistent clips ..., EditClips
		Menu, PersistentClipboard, Icon, Edit persistent clips ..., % A_WinDir "\system32\shell32.dll", 270

		if(ClipboardList.Persistent.MaxIndex())
			for index, Entry in ClipboardList.Persistent
				Menu, PersistentClipboard, add, % Entry.Name, PersistentClipboardHandler
		Menu, ClipboardMenu, add, Clips, :PersistentClipboard
		Menu, ClipboardMenu, Icon, Clips, % A_WinDir "\system32\shell32.dll", 55
		
		CanNavigate := Navigation.FindNavigationSource(WinExist("A"), "SetPath")
		;Explorer history
		if(ExplorerHistory.MaxIndex())
		{
			Menu, ExplorerHistory, DeleteAll
			if(CanNavigate)
			{
				for index, Entry in ExplorerHistory.History
				{
					Menu, % "ExplorerHistory_" Entry.Path, DeleteAll
					Menu, % "ExplorerHistory_" Entry.Path, Add, Paste, ClipboardMenu_DeepPasteHandler
					Menu, % "ExplorerHistory_" Entry.Path, Icon, Paste, % A_WinDir "\system32\shell32.dll", 2
					Menu, % "ExplorerHistory_" Entry.Path, Add, SetPath, ClipboardMenu_SetPathHandler
					Menu, % "ExplorerHistory_" Entry.Path, Icon, SetPath, % A_WinDir "\system32\shell32.dll", 4

					Menu, ExplorerHistory, Add, % Entry.Path, % ":ExplorerHistory_" Entry.Path
					Menu, ExplorerHistory, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
				}
			}
			else
			{
				for index, Entry in ExplorerHistory.History
				{
					Menu, ExplorerHistory, Add, % Entry.Path, ClipboardMenu_PasteHandler
					Menu, ExplorerHistory, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
				}
			}
			Menu, ClipboardMenu, Add, Path History, :ExplorerHistory
			Menu, ClipboardMenu, Icon, Path History, % A_WinDir "\system32\shell32.dll", 4


			Menu, ExplorerFrequent, DeleteAll
			if(CanNavigate)
			{
				for index, Entry in ExplorerHistory.FrequentPaths
				{
					Menu, % "ExplorerFrequent_" Entry.Path, DeleteAll
					Menu, % "ExplorerFrequent_" Entry.Path, Add, Paste, ClipboardMenu_DeepPasteHandler
					Menu, % "ExplorerFrequent_" Entry.Path, Icon, Paste, % A_WinDir "\system32\shell32.dll", 2
					Menu, % "ExplorerFrequent_" Entry.Path, Add, SetPath, ClipboardMenu_SetPathHandler
					Menu, % "ExplorerFrequent_" Entry.Path, Icon, SetPath, % A_WinDir "\system32\shell32.dll", 4

					Menu, ExplorerFrequent, Add, % Entry.Path, % ":ExplorerFrequent_" Entry.Path
					Menu, ExplorerFrequent, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
				}
			}
			else
			{
				for index, Entry in ExplorerHistory.FrequentPaths
				{
					Menu, ExplorerFrequent, Add, % Entry.Path, ClipboardMenu_PasteHandler
					Menu, ExplorerFrequent, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
				}
			}
			;for index, Entry in ExplorerHistory.FrequentPaths
			;{
			;	Menu, ExplorerFrequent, Add, % Entry.Path, PathHandler
			;	Menu, ExplorerFrequent, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
			;}
			Menu, ClipboardMenu, Add, Frequent Paths, :ExplorerFrequent
			Menu, ClipboardMenu, Icon, Frequent Paths, % A_WinDir "\system32\shell32.dll", 4
		}

		;FastFolders
		Menu, FastFoldersMenu, DeleteAll
		if(CanNavigate)
		{
			for index, Entry in FastFolders
			{
				outputdebug % "path " Entry.Path
				Menu, % "FastFolders_" Entry.Path, DeleteAll
				Menu, % "FastFolders_" Entry.Path, Add, Paste, ClipboardMenu_DeepPasteHandler
				Menu, % "FastFolders_" Entry.Path, Icon, Paste, % A_WinDir "\system32\shell32.dll", 2
				Menu, % "FastFolders_" Entry.Path, Add, SetPath, ClipboardMenu_SetPathHandler
				Menu, % "FastFolders_" Entry.Path, Icon, SetPath, % A_WinDir "\system32\shell32.dll", 4

				Menu, FastFoldersMenu, Add, % Entry.Path, % ":FastFolders_" Entry.Path
				Menu, FastFoldersMenu, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
			}
		}
		else
		{
			for index, Entry in FastFolders
			{
				Menu, FastFoldersMenu, add, % Entry.Path, ClipboardMenu_PasteHandler
				Menu, FastFoldersMenu, Icon, % Entry.Path, % A_WinDir "\system32\shell32.dll", 4
			}
		}
		Menu, ClipboardMenu, add, Fast Folders, :FastFoldersMenu
		Menu, ClipboardMenu, Icon, Fast Folders, % A_WinDir "\system32\shell32.dll", 4

		;Clipboard history
		Loop % ClipboardList.MaxIndex()
		{
			x := ClipboardList[A_Index]
			StringReplace, x, x, `r,, All
			StringReplace, x, x, `n, [NEWLINE], All
			y := "`t"
			StringReplace, x, x, %y%, [TAB], All ;Weird syntax bug requires `t to be stored in a variable here
			x := "&" (A_Index - 1) ": " Substr(x, 1, 100)
			if(x)
			{
				Menu, ClipboardMenu, add, %x%, ClipboardHandler%A_Index%
				Menu, ClipboardMenu, Icon, %x%, % A_WinDir "\system32\shell32.dll", 2
			}
		}
	}
	;Add menu entries that are defined through events
	for index, Event in EventSystem.Events
	{
		if(Event.Trigger.Is(CMenuItemTrigger) && Event.Trigger.Menu = Name)
		{
			if(Event.Trigger.Submenu = "")
			{
				Menu, %Name%, add, % Event.Trigger.Name, MenuItemHandler
				if(icon := Event.Trigger.Icon)
				{
					StringSplit, icon, icon, `,,%A_Space%
					Menu, %Name%, Icon, % Event.Trigger.Name, %icon1%, %icon2%
				}
				if(!Event.Enabled)
					Menu, %Name%, disable, % Event.Trigger.Name
			}
			else
			{
				entries := BuildMenu(Event.Trigger.Submenu)
				if(entries)
					Menu, %Name%, add, % Event.Trigger.Name, % ":" Event.Trigger.Submenu
			}
			entries := true
		}
	}

	;Add tools for Tray menu
	if(Name = "Tray")
	{
		Loop %A_ScriptDir%\Tools\*.ahk, 0, 0
		{
			Menu, Tray_Debug_Tools, add, %A_LoopFileName%, Tray_Debug_Tools_Handler
			Added := true
		}
		Loop %A_ScriptDir%\Tools\*.exe, 0, 0
		{
			Menu, Tray_Debug_Tools, add, %A_LoopFileName%, Tray_Debug_Tools_Handler
			Added := true
		}
		if(Added)
			Menu, tray, add, Tools, :Tray_Debug_Tools

		Menu, tray, add  ; Creates a separator line.		
		if(!A_IsCompiled)
		{
			Menu, tray, add, Open, Tray_Open
			Menu, tray, add
		}
		Menu, tray, add, Help, Tray_FAQ
		Menu, tray, Icon, Help, % A_WinDir "\system32\shell32.dll", 155
		Menu, tray, add, Report Bug, Tray_ReportBug
		Menu, tray, Icon, Report Bug, % A_WinDir "\system32\shell32.dll", 134
		Menu, tray, add, Visit Homepage, Tray_VisitHP
		Menu, tray, Icon, Visit Homepage, % A_WinDir "\system32\shell32.dll", 136

		Menu, tray, add
		Menu, tray, add, Suspend Hotkeys, Tray_Suspend
		
		if(!A_IsCompiled)
			Menu, tray, add, Pause Script, Tray_Pause
		Menu, tray, add, Reload 7plus, Tray_Reload
		Menu, tray, Icon, Reload 7plus, % A_WinDir "\system32\shell32.dll", 239
		Menu, tray, add, Exit, Tray_Exit
		Menu, tray, Icon, Exit, % A_WinDir "\system32\shell32.dll", 28
	}
	Menu, Tray, UseErrorLevel, Off
	return entries
}

Tray_Debug_Tools_Handler:
run % A_ScriptDir "\Tools\" A_ThisMenuItem
return

Tray_Open:
ListLines
return

Tray_FAQ:
OpenWikiPage("FAQ")
return

Tray_ReportBug:
run http://code.google.com/p/7plus/issues/list
return

Tray_VisitHP:
run http://code.google.com/p/7plus
return

Tray_Help:
Run %A_AhkPath%\..\AutoHotkey.chm
Return

Tray_Pause:
if(A_IsPaused)
	Menu, Tray, UnCheck, Pause Script
else
	Menu, Tray, Check, Pause Script
Pause Toggle
return

Tray_Reload:
   GoSub ReloadSub
Return

Tray_Suspend:
Suspend, Toggle
if(A_IsSuspended)
	Menu, Tray, Check, Suspend Hotkeys
else
	Menu, Tray, Uncheck, Suspend Hotkeys
return

Tray_Spy:   ;   Run Edit With SciTE 
   Run %A_AHKPath%\..\AU3_Spy.exe
Return 


Tray_Exit: ; exit script label 
   GoSub ExitSub
return


;Called by clipboard manager menu
ClipboardMenu_SetPathHandler:
Navigation.SetPath(SubStr(A_ThisMenu, InStr(A_ThisMenu, "_") + 1))
return

ClipboardMenu_DeepPasteHandler:
PasteText(SubStr(A_ThisMenu, InStr(A_ThisMenu, "_") + 1))
return

ClipboardMenu_PasteHandler:
PasteText(A_ThisMenuItem)
return