#if Settings.Explorer.Tabs.UseTabs && WinActive("ahk_group ExplorerGroup")
^t::CreateTab(WinActive("ahk_group ExplorerGroup")+0)
#if
#if Settings.Explorer.Tabs.UseTabs && IsTabbedWindow(WinExist("A")+0)
^Tab Up::ExplorerWindows.GetItemWithValue("hwnd", WinExist("A")+0).TabContainer.CycleTabs(1)
^+Tab Up::ExplorerWindows.GetItemWithValue("hwnd", WinExist("A")+0).TabContainer.CycleTabs(-1)
^w::CloseActiveTab()
#if
#if Settings.Explorer.Tabs.UseTabs && IsMouseOverTabButton()
LButton::MouseActivateTab()
MButton::MouseCloseTab()
#if
CloseActiveTab()
{
	global ExplorerWindows
	outputdebug close active tab
	TabContainer := ExplorerWindows.GetItemWithValue("hwnd", WinExist("A")+0).TabContainer
	tab := TabContainer.tabs.GetItemWithValue("hwnd", WinExist("A")+0)
	if(tab)
	{
		outputdebug tab found
		outputdebug % "active tab " tab.path WinExist("A")+0
		TabContainer.CloseTab(tab)
	}
}
IsTabbedWindow(hwnd)
{
	global ExplorerWindows
	if(IsObject(ExplorerWindows) && IsObject(ExplorerWindow := ExplorerWindows.GetItemWithValue("hwnd", hwnd+0)) && IsObject(ExplorerWindow.TabContainer))
		return hwnd+0
	return false
}

IsMouseOverTabButton(ByRef TabContainer="")
{
	global ExplorerWindows
	CoordMode, Mouse, Screen
	MouseGetPos,x,y,window
	if(window && WinExist("TabWindow ahk_class AutoHotkeyGUI ahk_id " window))
	{
		WinGetPos,WinX,WinY,,,ahk_id %window%
		;Tab Coords are relative
		x-=WinX
		y-=WinY
		; outputdebug correct window x%x% y%y%
		TabContainer:=ExplorerWindows.TabContainerList.GetItemWithValue("TabWindow", window+0)
		if(TabContainer)
		{
			; outputdebug tab container
			Loop % TabContainer.tabs.MaxIndex()
			{
				if(IsInArea(x,y,TabContainer.tabs[A_Index].x,TabContainer.tabs[A_Index].y,TabContainer.tabs[A_Index].width,TabContainer.tabs[A_Index].height))
					return A_Index
			}
			; outputdebug not found
		}
	}
	; CoordMode, Mouse, Screen
	return false
}

MouseActivateTab()
{
	index := IsMouseOverTabButton(TabContainer)
	outputdebug mouse over tab button %index%
	if(index && TabContainer && TabContainer.tabs[index].hwnd != TabContainer.active)
		TabContainer.ActivateTab(index)
}
MouseCloseTab()
{	
	index := IsMouseOverTabButton(TabContainer)
	if(index)
		TabContainer.CloseTab(TabContainer.tabs[index])
	return index > 0
}

CalculateTabText(tab)
{
	global ExplorerWindows
	outputdebug % "calculate tab text for " tab.hwnd+0
	TabContainer := ExplorerWindows.GetItemWithValue("hwnd", tab.hwnd+0).TabContainer
	WinGetPos x,y,w,h,% "ahk_id " TabContainer.TabWindow
	
	; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
	hbm := CreateDIBSection(w, h)

	; Get a device context compatible with the screen
	hdc := CreateCompatibleDC()

	; Select the bitmap into the device context
	obm := SelectObject(hdc, hbm)

	; Get a pointer to the graphics of the bitmap, for use with drawing functions
	G := Gdip_GraphicsFromHDC(hdc)
	
	Font := ExplorerWindows.TabContainerList.Font
	FontSize:=ExplorerWindows.TabContainerList.FontSize
			
	;Measure the spaces
	RectF:=Gdip_TextToGraphics(G, tab.DisplayName, " s" FontSize " r4", Font,"","",1)
	StringSplit, RectF, RectF, |
	DrawText := tab.DisplayName
	drawcharcount := strlen(tab.DisplayName)
	outputdebug % ExploreObj(tab)
	while(RectF3 > (tab.width-2*ExplorerWindows.TabContainerList.hPadding))
	{
		oldcount := drawcharcount
		drawcharcount := max(min(oldcount-1,floor(strlen(tab.DisplayName) * (Tab.Width -2*ExplorerWindows.TabContainerList.hPadding)/ RectF3)),0)
		if(drawcharcount = 0)
		{
			outputdebug clear drawtext
			drawtext := ""
			break
		}
		drawtext := SubStr(tab.DisplayName,1, drawcharcount) "..."		
		RectF:=Gdip_TextToGraphics(G, drawtext, " s" FontSize " r4", Font,"","",1)
		StringSplit, RectF, RectF, |
	}
	tab.DrawText := drawtext
	outputdebug set drawtext to %drawtext%
	; Select the object back into the hdc
	SelectObject(hdc, obm)
	
	; Now the bitmap may be deleted
	DeleteObject(hbm)

	; Also the device context related to the bitmap may be deleted
	DeleteDC(hdc)

	; The graphics may now be deleted
	Gdip_DeleteGraphics(G)	
}

;Called when a tab is activated
; TabEvent:
; outputdebug activate tab %TabControl%, previous exp window is %hwnd%
; NoTabUpdate:=true
; OldTab:=TabControl
; Gui, %TabNum%:Submit
; if(TabClose)
; {	
	; TabClose:=false
	; hwnd:=TabContainerList.Active
	; class:=WinGetClass("ahk_id " hwnd)
	; TabContainer:=TabContainerList.ContainsHWND(TabContainerList.active)
	; CloseTab(TabContainer.tabs[TabControl],TabContainer)
	; outputdebug current tab: %class%
	; WinActivate ahk_id %hwnd%
; }
; else
	; ActivateTab(TabControl)
; NoTabUpdate:=false
; UpdateTabs()
; return

CloseAllInactiveTabs()
{
	global ExplorerWindows
	len := ExplorerWindows.TabContainerList.MaxIndex()
	loop %len% ;Fixed length for delete loop
		ExplorerWindows.TabContainerList[1].CloseInactiveTabs()
}

/*
TabContainerList_indexOf(TabContainerList,TabContainer)
{
	Loop % TabContainerList.MaxIndex()
	{
		tc:=TabContainerList[A_Index]
		if(tc.ContainsHWND(TabContainer.active))
			return A_Index
	}
}
*/

DrawTabWindow:
ExplorerWindows.GetItemWithValue("hwnd", WinExist("A")+0).DrawTabWindow()
return
Class CTabContainer
{
	__New(ExplorerWindow)
	{
		global ExplorerWindows
		this.Tabs := Array()
		this.x := 0
		this.y := 0
		this.w := 0
		this.h := 0
		this.state := 0
		this.Active := ExplorerWindow.hwnd
		ExplorerWindows.TabContainerList.Insert(this)
		this.Add(ExplorerWindow)
		this.CreateTabWindow()
	}
	__Delete()
	{
		Gui % this.TabNum ":Destroy"
	}
	CreateTabWindow()
	{
		global ExplorerWindows
		;Critical
		outputdebug Create tab window
		this.TabNum:=GetFreeGUINum(10)
		Gui, % this.TabNum ":+LastFound +ToolWindow -Border -Resize -Caption +E0x80000"
		this.TabWindow := WinExist()+0
		AttachToolWindow(this.Active, this.TabNum, false)
		TabNum := this.TabNum
		Gui %TabNum%:Show, NA, TabWindow
		this.UpdatePosition()
		this.UpdateTabs()
		Return
	}
	Add(ExplorerWindow,position="", Activate = 0)
	{
		global ExplorerWindows
		if(!ExplorerWindow.DisplayName)
			ExplorerWindow.DisplayName := Navigation.GetDisplayName(ExplorerWindow.hwnd)
		tab := Object("hwnd",ExplorerWindow.hwnd, "DisplayName", ExplorerWindow.DisplayName)
		tab.y := ExplorerWindows.TabContainerList.InActiveHeightDifference
		tab.height := ExplorerWindows.TabContainerList.height - ExplorerWindows.TabContainerList.InActiveHeightDifference
		if(position="")
		{
			this.tabs.Insert(tab)
			this.CalculateHorizontalTabPositions(this.tabs.MaxIndex())
			this.CalculateVerticalTabPosition(this.tabs.MaxIndex())
		}
		else
		{
			this.tabs.insert(position,tab)
			this.CalculateHorizontalTabPositions(position)
			this.CalculateVerticalTabPosition(position)
		}
		ExplorerWindow.TabContainer := this
		if(this.tabs.MaxIndex() > 1)
		{
			if(Activate)
				this.ActivateTab(position = "" ? this.Tabs.MaxIndex() : position)
			else
			{
				;To hide the old tab without showing the hide anim, it is moved outside of the screen first
				WinMove, % "ahk_id " ExplorerWindow.hwnd,,-10000,-10000
				WinHide, % "ahk_id " ExplorerWindow.hwnd
			}
		}
		; CalculateTabText(tab)
		this.DrawTabWindow()
	}
	CalculateVerticalTabPosition(index)
	{
		global ExplorerWindows
		tab := this.tabs[index]
		if(tab)
		{
			if(tab.hwnd = this.Active)
			{
				tab.y := 0
				tab.height := ExplorerWindows.TabContainerList.height
			}
			else
			{
				tab.y := ExplorerWindows.TabContainerList.InActiveHeightDifference
				tab.height := ExplorerWindows.TabContainerlist.height - ExplorerWindows.TabContainerList.InActiveHeightDifference
			}
		}
	}
	ActivateTab(pos)
	{
		global ExplorerWindows
		; outputdebug ActivateTab(%pos%)
		SetWinDelay, -1
		hwnd := this.tabs[pos].hwnd + 0
		;DisableMinimizeAnim(1)
		ExplorerWindows.TabContainerList.TabActivationInProgress := true
		OldTab := this.active
		;To hide the old tab without showing the hide anim, it is moved outside of the screen first
		WinMove,ahk_id %OldTab%,, -10000, -10000
		DeAttachToolWindow(this.TabNum)
		WinHide,ahk_id %OldTab%
		DetectHiddenWindows, On
		if(this.w != 0)
		{
			if(this.state = 1)
				WinSetPlacement(hwnd, this.x, this.y, this.w, this.h, 3)
			else
				WinSetPlacement(hwnd, this.x, this.y, this.w, this.h, 1)
			;WinMove ahk_id %hwnd%,,%x%,%y%,%w%,%h%
		}		
		/*
		if(this.state = 1)
			WinMaximize ahk_id %hwnd%
		else if(this.state = 0)
			WinRestore ahk_id %hwnd%
			*/
		
		WinShow, ahk_id %hwnd%
		WinActivate, ahk_id %hwnd%
		this.Active := hwnd
		AttachToolWindow(hwnd, this.TabNum, false)
		;DisableMinimizeAnim(0)
		this.CalculateVerticalTabPosition(pos)
		this.CalculateVerticalTabPosition(this.tabs.FindKeyWithValue("hwnd", OldTab + 0))
		this.UpdatePosition()
		this.UpdateTabs()
		Gui, % this.TabNum ":Show", NA
		Sleep 10 ;To allow any message hooks to be executed
		ExplorerWindows.TabContainerList.TabActivationInProgress := false
	}
	
	/*
	 * Cycles through tabs in order indicated by dir
	*/
	CycleTabs(dir)
	{
		if(this.tabs.MaxIndex()>1)
		{
			pos:=this.tabs.FindKeyWithValue("hwnd", this.active+0)
			pos+=dir
			if(pos<1)
				pos+=this.tabs.MaxIndex()
			Else if(pos>this.tabs.MaxIndex())
				pos-=this.tabs.MaxIndex()
			outputdebug activate tab %pos%
			this.ActivateTab(pos)
		}
		Else
			Notify("Explorer Tabs Error!", "Tab container is too small!", 5, NotifyIcons.Error)
	}
	/*
	 * Recreates Tabs
	*/
	UpdateTabs()
	{
		global ExplorerWindows
		outputdebug updatetabs
		; global
		; local TabContainer, hwnd,tabhwnd,folder,tabs
		; WasCritical := A_IsCritical
		; Critical
		; if(!SuppressTabEvents && !NoTabUpdate)
		; {
			; hwnd:=WinActive("ahk_group ExplorerGroup")
			; TabContainer:=TabContainerList.ContainsHWND(hwnd)
			; if(hwnd && TabContainer)
			; {
		Loop % ExplorerWindows.MaxIndex()
		{
			if(ExplorerWindows[A_Index].TabContainer != this)
				continue
			DisplayName := ExplorerWindows[A_Index].DisplayName
			Tab := ExplorerWindows[A_Index].TabContainer.tabs.GetItemWithValue("hwnd", ExplorerWindows[A_Index].hwnd+0)
			if(Tab && DisplayName != Tab.DisplayName)
			{
				Tab.DisplayName := DisplayName
				CalculateTabText(Tab)
			}
		}
		this.CalculateHorizontalTabPositions()
			; }
			; SuppressTabEvents:=false
		this.DrawTabWindow()
		; }
		; if(!WasCritical)
			; Critical, Off
		return
		/*
		SuppressTabEvents:=true
		
		*/
	}
	UpdatePosition()
	{
		global ExplorerWindows
		outputdebug updateposition
		; global SuppressTabEvents, TabContainerList, TabControl, NoTabUpdate
		; static gid=0   ;fid & gid are function id and global id. I use them to see if the function interupted itself. 
		SetWinDelay -1
		/*
		if(SuppressTabEvents)
		{
			outputdebug update suppressed
			return
		}
		*/
		; if(NoTabUpdate)
			; return
		; fid:=gid+=1
		;SuppressTabEvents:=true
		; hwnd:=WinActive("ahk_group ExplorerGroup")
		; TabContainer:=TabContainerList.ContainsHWND(hwnd)
		; class:=WinGetClass("A")
		; if( hwnd && TabContainer)
		; {
			;Get restored-state coordinates
		WinGetPlacement(this.Active,x,y,w,h)
		;Update stored position so we can restore it if a tab is closed		
		WinGet, state, minmax, % "ahk_id " this.Active
		changed := this.x != x || this.y != y || this.w != w || this.h != h || this.state != state
		changedsize := this.w != w || this.h != h
		if(changed)
		{
			outputdebug update coords to x%x% y%y% w%w% h%h%
			this.state := state
			this.x := x
			this.y := y
			this.w := w
			this.h := h
			;Now get current coordinates for tab window placement
			WinGetPos, x,y,width,h, % "ahk_id " this.Active
			x+=24
			y+=4
			w := width - 135
			;The Explorer in Windows 8 finally uses its window space more effectively. In return this means that there's no real space for the tabs anymore.
			;For now they will be placed in the center of the titlebar. This increases the chance of not overlapping with other elements.
			if(WinVer = WIN_8)
			{
				w -= 150
				x := (x - 24) + (width / 2 - w / 2)
			}
			h:=ExplorerWindows.TabContainerList.height
			outputdebug move tabwindow x%x% y%y% w%w% h%h%
			WinMove, % "ahk_id " this.TabWindow,,%x%,%y%,%w%,%h%
			
			;Limit drawing rate to make resizing more smoother
			if(changedsize)
				SetTimer, DrawTabWindow, -20
		
			; if (fid != gid) 				;some newer instance of the function was running, so just return (function was interupted by itself). Without this, older instance will continue with old host window position and clients will jump to older location. This is not so visible with WinMove as it is very fast, but SetWindowPos shows this in full light. 
				; return		
		}
			;outputdebug updateposition() tab control: w%w%
			;GuiControl, %TabNum%:Move, TabControl, w%w%
			; WinGet, style, style, % "ahk_id " this.TabWindow
			; if(!(style & 0x10000000)) ;WS_VISIBLE
			; {
				; outputdebug show
				; Gui % this.TabNum ": Show", NA
			; }
			
			;WinShow ahk_id %TabWindow%
			; }
		; else if (class && (WinExist("A")!=TabWindow || WinGet("minmax","ahk_id " TabContainerList.active)=-1))
		; {
			; WinGet, style, style, ahk_id %TabWindow%
			; if(style & 0x10000000)
			; {
				; outputdebug hide %class% id %TabWindow%
				; WinHide ahk_id %TabWindow%
				; ;DllCall("AnimateWindow","Ptr",TabWindow,UInt,0,UInt,0x00010000)
			; }
		; }
		;SuppressTabEvents:=false
	}
	CloseInactiveTabs()
	{
		global ExplorerWindows
		ExplorerWindows.TabContainerList.Delete(ExplorerWindows.TabContainerList.indexOf(this))
		ExplorerWindows.TabContainerList.TabCloseInProgress := true
		loop % this.tabs.MaxIndex()
		{
			hwnd := this.tabs[A_Index].hwnd+0
			;Remove all references to the Tab Container so that its delete routine may be called and ExplorerDestroyed doesn't recurse
			ExplorerWindows.GetItemWithValue("hwnd", hwnd).Remove("TabContainer")
			if(hwnd!=this.active)
				WinClose, ahk_id %hwnd%
		}
		Loop 100
		{
			if(!ExplorerWindows.TabContainerList.TabCloseInProgress)
				return
			Sleep 100
		}
		ExplorerWindows.TabContainerList.TabCloseInProgress := false
		outputdebug tab close event timeout
	}
	CloseAllTabs()
	{
		global ExplorerWindows
		; NoTabUpdate:=true
		; SuppressTabEvents:=true
		; outputdebug close all tabs
		; TabContainerList.Print()
		; index:=TabContainerList.indexOf(TabContainer)
		ExplorerWindows.TabContainerList.Delete(ExplorerWindows.TabContainerList.indexOf(this))
		; outputdebug index %index%
		; outputdebug after deletion:
		; TabContainerList.Print()
		ExplorerWindows.TabContainerList.TabCloseInProgress := true
		loop % this.tabs.MaxIndex()
		{
			hwnd := this.tabs[A_Index].hwnd+0
			;Remove all references to the Tab Container so that its delete routine may be called and ExplorerDestroyed doesn't recurse
			ExplorerWindows.GetItemWithValue("hwnd", hwnd).Remove("TabContainer")
			WinClose, ahk_id %hwnd%
		}
		Loop 100
		{
			if(!ExplorerWindows.TabContainerList.TabCloseInProgress)
				return
			Sleep 100
		}
		ExplorerWindows.TabContainerList.TabCloseInProgress := false
		outputdebug tab close event timeout
		; NoTabUpdate:=false
		; SuppressTabEvents:=false
	}
	CalculateHorizontalTabPositions(start=1)
	{
		i:=start
		if(start>1)
			x:=this.tabs[start-1].x+this.tabs[start-1].width
		else
			x:=0
		Loop
		{
			if(i>this.tabs.MaxIndex())
				break
			this.tabs[i].x:=x
			x+=this.tabs[i].width
			i++
		}
	}
	DrawTabWindow()
	{
		global ExplorerWindows
		WinGetPos x,y,w,h, % "ahk_id " this.TabWindow
		outputdebug draw tab window current size x%x% y%y% w%w% h%h%
		count := this.tabs.MaxIndex()
		desiredwidth := 0
		loop % count
		{
			desiredwidth += ExplorerWindows.TabContainerList.TabWidth
			totalpadding += 2*ExplorerWindows.TabContainerList.hPadding
		}
		if(desiredwidth + totalpadding > w)
		{
			scale := max((w-totalpadding),0)/desiredwidth
			Loop % count
			{
				this.tabs[A_Index].width := floor(ExplorerWindows.TabContainerList.TabWidth * scale)
				CalculateTabText(this.tabs[A_Index])
			}
		}
		else
		{
			Loop % count
			{
				this.tabs[A_Index].width := ExplorerWindows.TabContainerList.TabWidth
				CalculateTabText(this.tabs[A_Index])
			}
		}
		this.CalculateHorizontalTabPositions()
		; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
		hbm := CreateDIBSection(w, h)

		; Get a device context compatible with the screen
		hdc := CreateCompatibleDC()

		; Select the bitmap into the device context
		obm := SelectObject(hdc, hbm)

		; Get a pointer to the graphics of the bitmap, for use with drawing functions
		G := Gdip_GraphicsFromHDC(hdc)
		
		Font := ExplorerWindows.TabContainerList.Font
		FontSize := ExplorerWindows.TabContainerList.FontSize
		
		; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
		Gdip_SetSmoothingMode(G, 4)

		; Create brushes
		pBrushActive := Gdip_BrushCreateSolid(0xFFFAFAFA)
		;Create pen for border liens
		pPenBorder := Gdip_CreatePen(0xFF808080, 1)
		;Draw all tabs
		Loop % this.tabs.MaxIndex()
		{
			tab := this.tabs[A_Index]
			Gdip_SetSmoothingMode(G, 4)
			; Draw background
			if(tab.hwnd = this.active)
			{
				outputdebug % "draw active tab x"tab.x " y" tab.y "w "tab.width " h"tab.height
				Gdip_FillRectangle(G, pBrushActive, tab.x, tab.y, tab.width, tab.height)
			}
			else
			{
				if(WinVer >= WIN_Vista && WinVer < WIN_8) ;Win 8 draws on the title bar, so the tabs must be opaque to avoid partial overdrawing
					pBrushGradient := Gdip_CreateLineBrushFromRect(0,0, tab.width, tab.height, 0xFFF8F8F8, 0x22222222)
				else
					pBrushGradient := Gdip_CreateLineBrushFromRect(0,0, tab.width, tab.height, 0xFFF8F8F8, 0xFFAAAAAA)
				Gdip_FillRectangle(G, pBrushGradient, tab.x, tab.y, tab.width, tab.height)
				Gdip_DeleteBrush(pBrushGradient)
				outputdebug % "draw inactive tab x"tab.x " y" tab.y "w "tab.width " h"tab.height
			}
			Gdip_SetSmoothingMode(G, 1)
			Gdip_DrawLine(G, pPenBorder, tab.x, tab.y, tab.x+tab.width, tab.y)
			Gdip_DrawLine(G, pPenBorder, tab.x, tab.y, tab.x, tab.y+tab.height)
			Gdip_DrawLine(G, pPenBorder, tab.x+tab.width, tab.y, tab.x+tab.width, tab.y+tab.height)
			Gdip_SetSmoothingMode(G, 4)
			
			Gdip_TextToGraphics(G, tab.drawtext, "x" (tab.x+ExplorerWindows.TabContainerList.hPadding) " y" ExplorerWindows.TabContainerList.vPadding " cff000000 r5 Centre s" FontSize, Font,tab.width - 2*ExplorerWindows.TabContainerList.hPadding,tab.height)
		}
		UpdateLayeredWindow(this.TabWindow, hdc, x, y, w, h)
		
		; Delete the brush as it is no longer needed and wastes memory
		Gdip_DeleteBrush(pBrushActive)
		Gdip_DeletePen(pPenBorder)
		; Select the object back into the hdc
		SelectObject(hdc, obm)
		
		; Now the bitmap may be deleted
		DeleteObject(hbm)

		; Also the device context related to the bitmap may be deleted
		DeleteDC(hdc)

		; The graphics may now be deleted
		Gdip_DeleteGraphics(G)
	}
	/*
	 * Closes the tab hwnd
	*/
	CloseTab(Tab)
	{
		; global TabContainerList,TabNum, NoTabUpdate
		global ExplorerWindows
		; DetectHiddenWindows, On	
		; NoTabUpdate:=true
		; Folder:=Navigation.GetPath(hwnd)
		; outputdebug close %hwnd% %folder%
		; TabContainerList.print()
		; if(!TabContainer)
			; TabContainer:=TabContainerList.ContainsHWND(hwnd)
		; outputdebug % "close tab " this.tabs.IndexOf(Tab)
		outputdebug % "currently active tab" this.tabs.FindKeyWithValue("hwnd", this.active+0)
		if(Tab.hwnd=this.active)
		{	
			if(Settings.Explorer.Tabs.OnTabClose=1)
				this.CycleTabs(-1)
			else if(Settings.Explorer.Tabs.OnTabClose=2)
				this.CycleTabs(1)
		}
		outputdebug % "currently active tab after cycling" this.tabs.FindKeyWithValue("hwnd", this.active+0)
		
		if(this.tabs.MaxIndex()=2)
		{
			;Remove all references to the Tab Container so that its delete routine may be called
			ExplorerWindows.TabContainerList.Delete(ExplorerWindows.TabContainerList.indexOf(this))
			Loop % this.tabs.MaxIndex()
				ExplorerWindows.GetItemWithValue("hwnd", this.tabs[A_Index].hwnd+0).Remove("TabContainer")
		}
		Else
		{
			this.tabs.Delete(this.tabs.IndexOf(Tab))
			ExplorerWindows.GetItemWithValue("hwnd", Tab.hwnd+0).Remove("TabContainer")
		}
		WinMove, % "ahk_id " Tab.hwnd,,-10000,-10000
		ExplorerWindows.TabContainerList.TabCloseInProgress++
		WinClose % "ahk_id " Tab.hwnd
		; outputdebug update closed
		; NoTabUpdate:=false
		this.UpdateTabs()
		Loop 100
		{
			if(!ExplorerWindows.TabContainerList.TabCloseInProgress)
				return
			Sleep 100
		}
		ExplorerWindows.TabContainerList.TabCloseInProgress := false
		outputdebug tab close event timeout
	}
	;Called when a tab is closed manually (close button, alt+f4, ...)
	TabClosed(hwnd)
	{
		global ExplorerWindows
		outputdebug tab closed manually %hwnd%
		Tab := this.Tabs.GetItemWithValue("hwnd", hwnd)
		if(!Tab)
			return false
		if(hwnd=this.active)
		{
			if(Settings.Explorer.Tabs.OnTabClose=1)
				this.CycleTabs(-1)
			else if(Settings.Explorer.Tabs.OnTabClose=2)
				this.CycleTabs(1)
		}
		
		if(this.tabs.MaxIndex()=2)
		{
			;Remove all references to the Tab Container so that its delete routine may be called
			ExplorerWindows.TabContainerList.Delete(ExplorerWindows.TabContainerList.indexOf(this))
			Loop % this.tabs.MaxIndex()
				ExplorerWindows.GetItemWithValue("hwnd", this.tabs[A_Index].hwnd+0).Remove("TabContainer")
		}
		Else
			this.tabs.Delete(this.tabs.IndexOf(Tab))
		this.UpdateTabs()
	}
}
CreateTab(hwnd, path=-1,Activate=-1)
{
	; global TabContainerList, TabContainerBase, SuppressTabEvents, TabNum, TabWindow,TabControl
	global ExplorerWindows
	if(!hwnd)
	{
		Notify("Explorer Tabs Error!", "CreateTab(): No active tab!", 5, NotifyIcons.Error)
		Return
	}
	WasCritical := A_IsCritical
	Critical
	Activate := Activate = -1 ? Settings.Explorer.Tabs.ActivateTab : Activate
	path := path = -1 ? Settings.Explorer.Tabs.TabStartupPath : path
	ExplorerWindow := ExplorerWindows.GetItemWithValue("hwnd", hwnd+0)
	if(!ExplorerWindow)
	{
		Notify("Explorer Tabs Error!", "Error creating tab: Explorer window not registered!", 5, NotifyIcons.Error)
		return false
	}
	if(path = "")
		path := ExplorerWindow.Path
	if(!TabContainer:=ExplorerWindow.TabContainer) ;Create new Tab Container if it doesn't exist yet
	{
		outputdebug add new tab container
		TabContainer := new CTabContainer(ExplorerWindow)
	}
	Prev_DetectHiddenWindows := A_DetectHiddenWindows
	DetectHiddenWindows, On
	DisableMinimizeAnim(1)	
	Run, explorer "%path%"
	WinWaitNotActive ahk_id %hwnd%
	WinWaitNotActive % "ahk_id " TabContainer.TabWindow
	WinWaitNotActive ahk_id %hwnd%
	
	Timeout := 10000
	start := A_TickCount
	Loop ;Make sure new window is really active
	{ 
		Sleep 10 
		hwndnew := WinActive("ahk_group ExplorerGroup") +0
		if(hwndnew)
		{
			ExplorerWindows.TabContainerList.TabCreationInProgress := true		;Set it to avoid ExplorerActivated function
			outputdebug 1st loop %hwndnew% %hwnd%
			If (hwndnew <> hwnd )
			   Break 
		}
		if(A_TickCount - start > Timeout)
		{
			gosub CreateTab_Cleanup
			return 0
		}
	}
	start := A_TickCount
	Loop ;Wait until new window is visible
	{
		Sleep 10
		WinGet,visible,style, ahk_id %hwndnew%
		if(visible & 0x10000000)
			break
		if(A_TickCount - start > Timeout)
		{
			gosub CreateTab_Cleanup
			return 0
		}
	}
	if(!Activate)
	{
		start := A_TickCount
		Loop ;and hide it until it is invisible again
		{
			Sleep 10
			WinGet,visible,style, ahk_id %hwndnew%
			WinGetPos,x,y,w,h,ahk_id %hwndnew%
			outputdebug 2nd loop x%x% y%y% w%w% h%h%
			if(visible & 0x10000000) ;WS_VISIBLE
			{
				outputdebug hide style %visible% title %title%
				WinHide ahk_id %hwndnew%
				;DllCall("AnimateWindow","Ptr",hwndnew,UInt,0,UInt,0x00010000)
			}
			Else
				break
				
			if(A_TickCount - start > Timeout)
			{
				gosub CreateTab_Cleanup
				return 0
			}
		}		
		outputdebug hide tab %hwndnew%
	}
	
	WinGetPlacement(hwnd,x,y,w,h,state)
	WinSetPlacement(hwndnew,x,y,w,h,state)
	if(!Activate)
		WinHide ahk_id %hwndnew%
		;DllCall("AnimateWindow","Ptr",hwndnew,UInt,0,UInt,0x00010000) ;Hide again because WinSetPlacement unhides it, but is required for max/restore state
	
	; msgbox h%hwndnew%
	;WinMove ahk_id %hwndnew%,,%x%,%y%,%w%,%h%
	;if(state = 1)
	;	WinMaximize ahk_id %hwndnew%
	if(!Activate)
		WinActivate ahk_id %hwnd%
	Else
	{
		DeAttachToolWindow(TabContainer.TabNum)
		; TabContainerList.active:=hwndnew
		TabContainer.active:=hwndnew
		WinHide ahk_id %hwnd%
		;DllCall("AnimateWindow","Ptr",hwnd,UInt,0,UInt,0x00010000)
		; outputdebug hide old tab
	}
	RegisterExplorerWindows()
	TabContainer.CalculateVerticalTabPosition(TabContainer.tabs.FindKeyWithValue("hwnd", hwnd+0))
	if(Settings.Explorer.Tabs.NewTabPosition = 1)
		TabContainer.add(ExplorerWindows.GetItemWithValue("hwnd", hwndnew+0),TabContainer.tabs.FindKeyWithValue("hwnd", hwnd+0) + 1,1) ;Add new tab right to the current tab
	else if(Settings.Explorer.Tabs.NewTabPosition = 2)
		TabContainer.add(ExplorerWindows.GetItemWithValue("hwnd", hwndnew+0),"",1) ;Add new tab to end of list
	; TabContainer.CalculateVerticalTabPosition(TabContainer.tabs.FindKeyWithValue("hwnd", hwndnew))
	if(Activate)
		AttachToolWindow(TabContainer.Active, TabContainer.TabNum, false)
	TabContainer.UpdateTabs()
	TabContainer.UpdatePosition()
	Gui, % TabContainer.TabNum ":Show", NA
	; this.DrawTabWindow()
	; GuiControl, %TabNum%:MoveDraw, TabControl
	CreateTab_Cleanup:
	DetectHiddenWindows, %Prev_DetectHiddenWindows%
	DisableMinimizeAnim(0)
	if(!WasCritical)
		Critical, Off
	ExplorerWindows.TabContainerList.TabCreationInProgress := false
	return
}

; Class TabContainerList
; {
	; __New()
	; {
		; this := Array()
		; return this
	; }
	; CloseAllInActiveTabs()
	; {
	
	; }
; }
;Slide Window array constructor with some additional functions
; TabContainerList(p1="N", p2="N", p3="N", p4="N", p5="N", p6="N"){ 
   ; static TabContainerList
   ; If !TabContainerListBase
      ; TabContainerListBase := Object("len", "Array_Length", "indexOf", "Array_indexOf", "join", "Array_Join" 
      ; , "append", "Array_Append", "insert", "Array_Insert", "delete", "Array_Delete" 
      ; , "sort", "Array_sort", "reverse", "Array_Reverse", "unique", "Array_Unique" 
      ; , "extend", "Array_Extend", "copy", "Array_Copy", "pop", "Array_Pop", "ContainsHWND", "TabContainerList_ContainsHWND"
	  ; , "CloseAllInactiveTabs", "TabContainerList_CloseAllInactiveTabs", "Print","TabContainerList_Print"
	  ; , "active", 0) 
   ; TabContainerList := Object("base", TabContainerListBase) 
   ; While (_:=p%A_Index%)!="N" && A_Index<=6 
      ; TabContainerList[A_Index] := _ 
   ; Return TabContainerList 
; }
; TabContainer_ContainsHWND(TabContainer,hwnd)
; {
	;;DecToHex(hwnd)
	; Loop % TabContainer.tabs.MaxIndex()
	; {
		; if(TabContainer.tabs[A_Index].hwnd = hwnd)
			; return A_Index
	; }
	; return 0
; }
; TabContainer_Print(TabContainer)
; {
	; active:=TabContainer.active
	; x:=TabContainer.x
	; y:=TabContainer.y
	; w:=TabContainer.w
	; h:=TabContainer.h
	; state:=TabContainer.state
	; outputdebug Active: %active%
	; outputdebug state: %state%
	; outputdebug x: %x%
	; outputdebug y: %y%
	; outputdebug w: %w%
	; outputdebug h: %h%
	; Loop % TabContainer.tabs.MaxIndex()
	; {
		; path:=Navigation.GetPath(TabContainer.tabs[A_Index].hwnd)
		; hwnd:=TabContainer.tabs[A_Index].hwnd
		; outputdebug %A_Tab%%A_Index% %hwnd%: %path%
	; }
; }
; TabContainerList_ContainsHWND(TabContainerList,hwnd)
; {
	;;DecToHex(hwnd)
	;;outputdebug TabContainerList_ContainsHWND(%hwnd%)
	; Loop % TabContainerList.MaxIndex()
	; {		
		; TabContainer:=TabContainerList[A_Index]
		; if(TabContainer.ContainsHWND(hwnd))
		; {	
			; return TabContainer
		; }
	; }
	; return false
; }
; TabContainerList_Print(TabContainerList)
; {
	; outputdebug --------------------------------------------
	; active:=TabContainerList.active
	; outputdebug Active: %active%
	; count:=TabContainerList.MaxIndex()
	; outputdebug tab container count: %count%
	; loop % TabContainerList.MaxIndex()
	; {
		; count:=TabContainerList[A_Index].tabs.MaxIndex()
		; outputdebug %A_Index%: %count% entries
		; TabContainerList[A_Index].Print()
	; }
	; outputdebug --------------------------------------------
; }
; #t::ExploreObj(ExplorerWindows)