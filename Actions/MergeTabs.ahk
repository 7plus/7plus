Class CMergeTabsAction Extends CAction
{
	static Type := RegisterType(CMergeTabsAction, "Merge Explorer windows")
	static Category := RegisterCategory(CMergeTabsAction, "Explorer")
	static __WikiLink := "MergeTabs"
	
	DisplayString()
	{
		return "Merge all explorer windows into one window with tabs"
	}
	Execute(Event)
	{
		global ExplorerWindows
		if(!Settings.Explorer.Tabs.UseTabs)
			return 0
		Active := WinActive("ahk_group ExplorerGroup")
		if(!Active)
			return 0
		if(ExplorerWindows.TabContainerList.TabCreationInProgress)
			return 0
		if(ExplorerWindows.MaxIndex() < 2)
			return 0
		TabContainer := ExplorerWindows.GetItemWithValue("hwnd", Active).TabContainer
		;Possibly create new container
		if(!TabContainer) 
			TabContainer := new CTabContainer(ExplorerWindows.GetItemWithValue("hwnd", Active))
		;Add all explorer windows to container
		Loop % ExplorerWindows.MaxIndex()
		{
			if(!TabContainer.tabs.GetItemWithValue("hwnd", ExplorerWindows[A_Index].hwnd))
				TabContainer.Add(ExplorerWindows[A_Index], "", 0)
		}
		;Remove all redundant tab containers
		index := 1
		Loop % ExplorerWindows.TabContainerList.MaxIndex()
		{
			if(ExplorerWindows.TabContainerList[index] != TabContainer)
				ExplorerWindows.TabContainerList.Remove(index)
			else
				index++
		}
	}
}
