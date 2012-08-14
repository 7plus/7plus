GUI_WindowFinder(PreviousGUINum, GoToLabel="")
{
	static WindowList, sPreviousGUINum, WindowFinderView, WindowPicture, hwndWindowPicture, result, thumbnail,WindowFinder_hWnd
	if(GoToLabel = "")
	{
		sPreviousGUINum := PreviousGUINum
		
		Gui, %PreviousGUINum%:+Disabled
		Gui, EventEditor:Default
		Gui, +LabelWindowFinder +Owner%PreviousGUINum% +ToolWindow
		width := 1000
		height := 400
		Gui, Add, ListView, vWindowFinderView gWindowFinderListView r19 w500 AltSubmit -Multi, #|Title|Class|Executable
		ImageList := IL_Create(10,5,0)
		LV_SetImageList(ImageList)
		WindowList := Array()
		DetectHiddenWindows, Off
		WinGet, hwnds, list,,, Program Manager
		Loop, %hwnds%
		{
			hwnd := hwnds%A_Index%
			WinGetClass, class, ahk_id %hwnd%
			WinGetTitle, title, ahk_id %hwnd%
			WinGet, exe, ProcessName, ahk_id %hwnd%
			if((!title && exe != "Explorer.exe") ||title = "Event Editor" || title = "7plus Settings" || InStr(class, "Tooltip") || InStr(class, "SysShadow")) ;Filter some windows
				continue
			WindowListEntry := RichObject()
			WindowListEntry.class := class
			WindowListEntry.title := title
			WindowListEntry.Executable := exe
			WindowListEntry.hwnd := hwnd
			WindowListEntry.hIcon := GetWindowIcon(hwnd,0)
			WindowListEntry.IconNumber := ImageList_ReplaceIcon(ImageList, -1, WindowListEntry.hIcon)
			WindowList.Insert(WindowListEntry)
		}
		;Fill listview
		for index, WindowListEntry in WindowList
			LV_Add((A_Index = 1 ? "Select " : "") "Icon" WindowListEntry.IconNumber +1 , A_Index, WindowListEntry.Title, WindowListEntry.Class, WindowListEntry.Executable)
		; LV_ModifyCol(1, 0)
		LV_ModifyCol(2, 200)
		LV_ModifyCol(3, 150)
		LV_ModifyCol(4, "AutoHdr")
		x := Width - 176
		y := Height - 34
		Gui, Add, Button, gWindowFinderOK x%x% y%y% w70 h23, &OK
		x := Width - 96
		Gui, Add, Button, gWindowFinderCancel x%x% y%y% w80 h23, &Cancel
		
		Gui, Show, w%width% h%height%, Window Finder
		
		Gui, +LastFound
		WinGet, WindowFinder_hWnd,ID
		DetectHiddenWindows, Off
		loop
		{
			sleep 250
			IfWinNotExist ahk_id %WindowFinder_hWnd% 
				break
		}
		Gui, %sPreviousGUINum%:Default
		Loop % WindowList.MaxIndex()
		{
			DestroyIcon(WindowList[A_Index].hIcon)
			; Gdip_DisposeImage(WindowList[A_Index].Bitmap)
		}
		return result
	}
	else if(GoToLabel = "WindowFinderListView")
	{
		if(A_GuiEvent="I" && InStr(ErrorLevel, "S", true))
		{
			LV_GetText(pos,LV_GetNext(),1)
			if(IsObject(thumbnail))
				thumbnail.Destroy()
			thumbnail := new CThumbnail(WindowFinder_hWnd, WindowList[pos].hwnd)
			PictureWidth := 470
			PictureHeight := 350
			w := thumbnail.GetSourceWidth()
			h := thumbnail.GetSourceheight()
			if(w < PictureWidth && h < PictureHeight)
				s := 1
			else if(w/PictureWidth > h/PictureHeight)
				s := PictureWidth/w
			else
				s := PictureHeight/h
			thumbnail.SetDestinationRegion(513, 7, w*s, h*s)
			thumbnail.Show()
			return
		}
		else if(A_GuiEvent="DoubleClick")
			GUI_WindowFinder("","WindowFinderOK")
		return
	}
	else if(GoToLabel = "WindowFinderOK")
	{
		LV_GetText(pos,LV_GetNext(""),1)
		result := WindowList[pos].DeepCopy()
		thumbnail.Destroy()
		Gui, %sPreviousGUINum%:-Disabled
		Gui, Destroy
		
		return
	}
	else if(GoToLabel = "WindowFinderClose")
	{
		result := ""
		thumbnail.Destroy()
		Gui, %sPreviousGUINum%:-Disabled
		Gui, Destroy
		Gui, %sPreviousGUINum%:Default
		return
	}
}

WindowFinderOK:
GUI_WindowFinder("","WindowFinderOK")
return

WindowFinderClose:
WindowFinderEscape:
WindowFinderCancel:
GUI_WindowFinder("","WindowFinderClose")
return
WindowFinderListView:
GUI_WindowFinder("","WindowFinderListView")
return