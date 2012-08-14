Class CShowTipAction Extends CAction
{
	static Type := RegisterType(CShowTipAction, "Show Tip")
	static Category := RegisterCategory(CShowTipAction, "7plus")
	static TipIndex := 1
	static Min := 0
	static Max := 0

	Execute(Event)
	{
		ShowTip(this.Min && this.Max ? {Min : this.Min, Max : this.Max} : this.TipIndex)
		return true
	}

	DisplayString()
	{
		return "Show Tip"
	}

	GuiShow(ActionGUI)
	{
		this.AddControl(ActionGUI, "Edit", "TipIndex", "", "", "Tip Index:")
		this.AddControl(ActionGUI, "Edit", "Min", "", "", "Min Index:")
		this.AddControl(ActionGUI, "Edit", "Max", "", "", "Max Index:")
	}
}

Class CTips
{
	static 1  := new CTips.Tip("Clipboard Manager", "You can press WIN + V to open the clipboard manager, which can be used to paste recently copied text, persistent clips or recently used directories")
	static 2  := new CTips.Tip("Pasting in CMD", "The command prompt now also supports CTRL + V to paste text.")
	static 3  := new CTips.Tip("Pasting text or images as files", "You can paste a copied text or image directly as file in Explorer and file dialogs.")
	static 4  := new CTips.Tip("Window features", "You can move a window by holding the ALT key and dragging it with the left mouse button without using the title bar.")
	static 5  := new CTips.Tip("Window features", "You can resize a window by holding the ALT key and dragging it with the right mouse button without using its borders.")
	static 6  := new CTips.Tip("Window features", "You can minimize or maximize the window under the cursor with ALT and the mouse wheel.")
	static 7  := new CTips.Tip("Window features", "You can toggle the ""Always on Top"" state of a window by right clicking its title bar or pressing WIN + A.")
	static 8  := new CTips.Tip("Volume", "You can quickly change the volume by using the mouse wheel over the taskbar.")
	static 9  := new CTips.Tip("File renaming", "You can toggle between the selection of the name, the extension and the complete filename by pressing F2 again.")
	static 10 := new CTips.Tip("File selecting", "You can quickly select a number of files by pressing WIN + S and entering a part of their name.")
	static 11 := new CTips.Tip("File selecting", "You can undo an unwanted change in the selected files by pressing CTRL + SHIFT + Z.")
	static 12 := new CTips.Tip("Activating flashing windows", "You can activate windows that are flashing in the task bar by pressing CAPSLOCK.")
	static 13 := new CTips.Tip("Toggling between windows", "You can toggle between the current and the previous window by pressing CAPSLOCK.")
	static 14 := new CTips.Tip("Copying file paths", "You can also copy the filename (or filepath) of the selected file(s) by pressing (CTRL +) ALT + C.`nIf you additionally hold SHIFT the text will be appended to the current clipboard.")
	static 15 := new CTips.Tip("Adding files to the clipboard", "By pressing SHIFT + C or SHIFT + X you can add the selected files to the files which are already in the clipboard.")
	static 16 := new CTips.Tip("Taking screenshots of a specific area", "By pressing WIN + PrintScreen you can select an area of which a screenshot will be made.")

	;Accessor tips
	static 17 := new CTips.Tip("About Accessor", "Accessor is used to access all kinds of functions, most prominently launching programs.`nIt analyzes the entered text and provides dynamic actions for it.")
	static 18 := new CTips.Tip("About Accessor plugins", "Accessor uses plugins that provide different kind of functionalities.`nYou can configure the single plugins on the settings page.")
	static 19 := new CTips.Tip("About Accessor keywords", "You can define keywords that are internally expanded into longer text for things like web searches.")
	static 20 := new CTips.Tip("Timed actions", "Many actions in Accessor can be timed by using "" in [Time here]"" at the end of the command.`nThe time can be formatted in natural language,`nsomething like ""in 1hour, 10 minutes"" or ""in 10:28"" are valid examples.")
	static 21 := new CTips.Tip("Accessor events", "Custom actions can be implemented in Accessor by using the ""Accessor Trigger"" in the event system.`nExamples of this are the ""Message"" and ""Shutdown"" commands.")
	static 22 := new CTips.Tip("Accessor context menu", "Many useful functions are available through the context menu of the single Accessor results.`nSome are also reachable through hotkeys.")
	static 23 := new CTips.Tip("Accessor history", "Accessor keeps a temporary history of the previously executed commands so you can execute them again quickly.")
	static 24 := new CTips.Tip("Accessor text history", "You can access the previously entered text by pressing CTRL + SHIFT + UP/DOWN in the textfield of the Accessor window.")
	static 25 := new CTips.Tip("Accessor context sensitivity", "Accessor will sometimes use the selected text or selected files automatically`nto show some results that might be useful in your current situation.`nYou can turn these things off individually if they annoy you.")
	static 26 := new CTips.Tip("Creating Accessor keywords", "You can quickly create keywords by selecting some text or a file and entering ""Learn as [name]"" in Accessor, where name is the new keyword.")
	
	;tips for various Accessor plugins
	static 27 := new CTips.Tip("Program Launcher plugin", "Accessor learns about the programs you're running, so it will also index programs which you manually started.`nAnother good way to add a single program to the index is to start it by entering its complete path in Accessor.")
	static 28 := new CTips.Tip("Program Launcher plugin", "You can add your own paths and file extensions as indexed paths if you have custom directories that you want to include.")
	static 29 := new CTips.Tip("Program Launcher plugin", "You can define custom actions for each indexed directory. An example for this is to provide an ""enqueue"" action for media files.")
	static 30 := new CTips.Tip("Program Launcher plugin", "You can open a file with a non-default program:`nSelect the file, press CTRL + O, enter program name.`nMuch faster than the ""Open With"" dialog!")
	static 31 := new CTips.Tip("File system plugin", "You can browse through the file system by entering file paths. It is possible to quickly navigate by using TAB to autocomplete directories.")
	static 32 := new CTips.Tip("File system plugin", "You quickly find files in the current explorer/file dialog directory`nby pressing CTRL + . and entering a part of the filename.")
	static 33 := new CTips.Tip("Recent folders plugin", "You can use Accessor to open a recently used directory in the currently open Explorer/File dialog/CMD window.")
	static 34 := new CTips.Tip("Clipboard plugin", "You can search through your stored clips with Accessor and insert them. You can also quickly store the selected text as persistent clip.")
	static 35 := new CTips.Tip("Window switcher plugin", "You can quickly switch between open windows in Accessor.")
	static 36 := new CTips.Tip("Registry plugin", "You can quickly open registry keys in Regedit found on webpages by selecting the key and opening Accessor.")
	static 37 := new CTips.Tip("Uninstall plugin", "You can uninstall programs by typing ""Uninstall [name]"" in Accessor.")
	static 38 := new CTips.Tip("URL plugin", "You can open URLs by typing them into Accessor. Another method is to select some text that contains a URL and open Accessor.")
	static 39 := new CTips.Tip("URL plugin", "The URL plugin can index the bookmarks of Opera, Chrome and Internet Explorer and allows you to search them.")
	static 40 := new CTips.Tip("Calculator plugin", "You can perform simple calculations and unit conversions in Accessor.")
	static 41 := new CTips.Tip("Weather plugin", "The Weather plugin makes it possible to search for weather in any location by typing ""weather [location]"".")
	static 42 := new CTips.Tip("File switcher plugins", "You can quickly switch open tabs of Notepad++ or SciTE4AHK in Accessor.")

	Class Tip
	{
		__new(Title, Text)
		{
			this.Title := Title
			this.Text := Text
		}
	}
}

HasTipBeenShown(TipIndex)
{
	return SubStr(Settings.General.ShownTips, TipIndex, 1) = 1
}

;Tip index can be {Min : 1, Max : 10} for random index between these values
ShowTip(TipIndex, Probability = 0.2)
{
	global StartupTime
	if(!Settings.General.ShowTips)
		return true ;Return true anyway so other code can simply assume that the tip was shown
	Random, r, 0.0, 1.0
	if(r > Probability || A_TickCount - StartupTime < 10000)
		return -1
	;Possibly choose a random tip in a specific interval
	if(IsObject(TipIndex))
		Random, TipIndex, % TipIndex.Min, % TipIndex.Max
	if(Settings.General.ShowTips && !HasTipBeenShown(TipIndex) && !Any(CNotification.Windows, "IsTip", true))
	{
		tip := CTips[TipIndex]
		NotifyWindow := Notify(tip.Title, tip.Text, 10, NotifyIcons.Info)
		;Mark the notify window so tip windows can be counted
		NotifyWindow.IsTip := true

		;Mark the tip as shown
		Settings.General.ShownTips := SubStr(Settings.General.ShownTips, 1, TipIndex - 1) "1" (StrLen(Settings.General.ShownTips) > TipIndex ? SubStr(Settings.General.ShownTips, TipIndex + 1) : "")
		return true
	}
}