Class Navigation
{
	static NavigationSources := Array()
	
	;Finds the class that can handle the window and function if available
	FindNavigationSource(hwnd, func)
	{
		WinGetClass, class, ahk_id %hwnd%
		for index, NavigationSource in this.NavigationSources
			if(NavigationSource.Processes(hwnd, class) && IsFunc(NavigationSource[func]))
				return NavigationSource
		return 0
	}
	
	;Called by classes acting as navigation source to register with this class
	RegisterNavigationSource(Class, Type)
	{
		this.NavigationSources.Insert(Class)
		return Type
	}

	;Default call operation for functions in this class.
	;Gets a window handle of active window if not provided,
	;finds the navigation source and calls the function on it.
	Call(Name, DefaultReturnValue, Params*)
	{
		hwnd := Params.Remove()
		if(!hwnd)
			hwnd := WinExist("A")
		
		if(NavigationSource := this.FindNavigationSource(hwnd, Name))
		{
			Params.Insert(hwnd)
			return NavigationSource[Name](Params*)
		}
		return DefaultReturnValue
	}

	GetPath(hwnd = 0)
	{
		return this.Call("GetPath", "", hwnd)
	}

	;Gets the name of the current path in a nice form for displaying
	GetDisplayName(hwnd = 0)
	{
		return this.Call("GetDisplayName", "", hwnd)
	}

	SetPath(Path, hwnd = 0)
	{
		;If Path is a file, select it in new explorer instances or ignore it elsewhere
		if(!InStr(FileExist(Path), "D") && !StrEndsWith(Path, ".search-ms"))
			SplitPath, Path, Name, Dir
		else
			Dir := Path
		if(this.Call("SetPath", 0, Dir, hwnd) = 0)
		{
			if(!Name)
				RunAsUser(A_WinDir "\explorer.exe /n,/e," Path)
			else
				RunAsUser(A_WinDir "\explorer.exe /select," Path)
		}
	}

	GetSelectedFilepaths(hwnd = 0)
	{
		return this.Call("GetSelectedFilepaths", Array(), hwnd)
	}

	GetSelectedFilenames(hwnd = 0)
	{
		return this.Call("GetSelectedFilenames", Array(), hwnd)
	}

	;Selects the files in Files in the view
	SelectFiles(Files, hwnd = 0)
	{
		if(!IsObject(Files) && Files)
			Files := Array(Files)
		return this.Call("SelectFiles", 0, Files, hwnd)
	}

	GetFocusedFilename(hwnd = 0)
	{
		return this.Call("GetFocusedFilename", "", hwnd)
	}

	GetFocusedFilePath(hwnd = 0)
	{
		return this.Call("GetFocusedFilePath", "", hwnd)
	}

	Refresh(hwnd = 0)
	{
		return this.Call("Refresh", 0, hwnd)
	}

	GoBack(hwnd = 0)
	{
		return this.Call("GoBack", 0, hwnd)
	}

	GoForward(hwnd = 0)
	{
		return this.Call("GoForward", 0, hwnd)
	}

	GoUpward(hwnd = 0)
	{
		return this.Call("GoUpward", 0, hwnd)
	}
}


Class CWinRarNavigationSource
{
	static Type := Navigation.RegisterNavigationSource(CWinRarNavigationSource, "WinRar")
	Processes(hwnd, class)
	{
		static WinRarTitle
		if(class = "#32770" && WinRarTitle != "WinRar not found")
		{
			if(WinRarTitle="")
			{
				RegRead, path, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe ,Path
				if(path)
				{
					Loop, read, %path%\winrar.lng
					{
						if(InStr(A_LoopReadLine,"8f827d31") = 1)
						{
							WinRarTitle := Unquote(A_LoopReadLine)
							break
						}
					}
					if(!WinRarTitle)
						WinRarTitle := "WinRar not found"
				}
			}		
			WinGetTitle, wintitle, ahk_id %hwnd%
			if(WinRarTitle = wintitle)
				return true
		}
		return false
	}

	SetPath(Path, hwnd)
	{
		ControlSetText , Edit1, %Path%, ahk_id %hwnd%
		ControlClick, Button1, ahk_id %hwnd%
	}

	GetPath(hwnd)
	{
		ControlGetText, Path, Edit1, ahk_id %hwnd%
		return Path
	}
}


Class CConsoleNavigationSource
{
	static Type := Navigation.RegisterNavigationSource(CConsoleNavigationSource, "Console")
	Processes(hwnd, class)
	{
		return (class = "ConsoleWindowClass")
	}

	GetPath(hwnd)
	{
		WinGet, pid, PID, ahk_id %hwnd%
		CMDText := this.GetConsoleText(pid)
		;~ clipboard := cmdtext
		RegExMatch(CMDText, "ms`a)(?:(^[A-Z]:\\[^\>]*)\>|.)*", out)
		return out1
		pos := 0
		while(pos := RegExMatch(CMDText, "`am)^[A-Z]:\\.*?(?=>)", Match, pos + 1))
			result := Match
		return result
	}

	SetPath(Path, hwnd)
	{
		WinGet, pid, PID, ahk_id %hwnd%
		CMDText := this.GetConsoleText(pid)
		pos := 0
		while(pos := RegExMatch(CMDText, "`amP)^[A-Z]:\\.*?(?=>)", Match, pos + 1))
		{
			pos1 := pos
			length := Match
		}
		CurrentCommand := SubStr(CMDText, pos1 + length + 1)
		ControlSend, , % "{Backspace " StrLen(CurrentCommand) "}", ahk_id %hwnd%
		this.ConsoleSend("cd /d """ Path """", pid)
		ControlSend, , {Enter}, ahk_id %hwnd%
		CurrentCommand := RegExReplace(CurrentCommand, "\s*$", "")
		this.ConsoleSend(CurrentCommand, pid)
	}

	;By Lexikos
	GetConsoleText(pid)
	{
		if(!(hConOut := this.AttachConsole(pid)))
			return ""
		; Allocate memory for a CONSOLE_SCREEN_BUFFER_INFO structure.
		VarSetCapacity(info, 24, 0)
		; Get info about the active console screen buffer.
		if(!DllCall("GetConsoleScreenBufferInfo", "PTR", hConOut, "PTR", &info))
		{
			OutputDebug GetConsoleScreenBufferInfo failed - error %A_LastError%.
			this.FreeConsole(hConOut)
			return ""
		}
		; Determine which section of the buffer is on display.
		ConWinLeft := NumGet(info, 10, "Short")     ; info.srWindow.Left
		ConWinTop := NumGet(info, 12, "Short")      ; info.srWindow.Top
		ConWinRight := NumGet(info, 14, "Short")    ; info.srWindow.Right
		ConWinBottom := NumGet(info, 16, "Short")   ; info.srWindow.Bottom
		ConWinWidth := ConWinRight-ConWinLeft+1
		ConWinHeight := ConWinBottom-ConWinTop+1
		; Allocate memory to read into.
		VarSetCapacity(text, ConWinWidth*ConWinHeight*(A_IsUnicode ? 2 : 1), 0)
		; Read text.
		if(!DllCall("ReadConsoleOutputCharacter", "PTR", hConOut, "str", text, "uint", ConWinWidth*ConWinHeight, "uint", 0, "PTR*", numCharsRead, "uint"))
		{
			OutputDebug ReadConsoleOutputCharacter failed - error %A_LastError%.
			this.FreeConsole(hConOut)
			return ""
		}
		this.FreeConsole(hConOut)
		; Optional: insert line breaks every %ConWinWidth% characters.
		text := RegExReplace(text, "`a).{" ConWinWidth "}(?=.)", "$0`n")
		; Finally, display the text.
		Return text
	}

	; Sends text to a console's input stream. WinTitle may specify any window in
	; the target process. Since each process may be attached to only one console,
	; ConsoleSend fails if the script is already attached to a console.
	ConsoleSend(text, pid)
	{
		; Attach to the console belonging to %WinTitle%'s process.
		if !DllCall("AttachConsole", "UINT", pid)
			return false, ErrorLevel:="AttachConsole"
		hConIn := DllCall("CreateFile", "str", "CONIN$", "uint", 0xC0000000
					, "uint", 0x3, "PTR", 0, "uint", 0x3, "uint", 0, "PTR", 0)
		if hConIn = -1
			return false, ErrorLevel:="CreateFile"
		
		VarSetCapacity(ir, 24, 0)       ; ir := new INPUT_RECORD
		NumPut(1, ir, 0, "UShort")      ; ir.EventType := KEY_EVENT
		NumPut(1, ir, 8, "UShort")      ; ir.KeyEvent.wRepeatCount := 1
		; wVirtualKeyCode, wVirtualScanCode and dwControlKeyState are not needed,
		; so are left at the default value of zero.
		Loop, Parse, text ; for each character in text
		{
			StrPut(A_LoopField, &ir+14, 1, "UTF-16")
			
			NumPut(true, ir, 4, "Int")  ; ir.KeyEvent.bKeyDown := true
			gosub ConsoleSendWrite
			
			NumPut(false, ir, 4, "Int") ; ir.KeyEvent.bKeyDown := false
			gosub ConsoleSendWrite
		}
		gosub ConsoleSendCleanup
		return true
		
		ConsoleSendWrite:
			if !DllCall("WriteConsoleInput", "PTR", hconin, "PTR", &ir, "uint", 1, "PTR*", 0)
			{
				gosub ConsoleSendCleanup
				return false, ErrorLevel:="WriteConsoleInput"
			}
		return
		
		ConsoleSendCleanup:
			if (hConIn!="" && hConIn!=-1)
				DllCall("CloseHandle", "PTR", hConIn)
			; Detach from %WinTitle%'s console.
			DllCall("FreeConsole")
		return
	}

	AttachConsole(pid)
	{
		;~ this.FreeConsole()
		; AttachConsole accepts a process ID.
		if(!DllCall("AttachConsole","uint",pid))
		{
			OutputDebug AttachConsole failed - error %A_LastError%.
			return ""
		}
		; If it succeeded, console functions now operate on the target console window.
		; Use CreateFile to retrieve a handle to the active console screen buffer.
		hConOut := DllCall("CreateFile", "str", "CONOUT$", "uint", 0xC0000000, "uint", 7, "PTR", 0, "uint", 3, "uint", 0, "PTR", 0, "PTR")
		if hConOut = -1 ; INVALID_HANDLE_VALUE
		{
			OutputDebug CreateFile failed - error %A_LastError%.
			return ""
		}
		return hConOut
	}

	FreeConsole(hCon=0)
	{
		DllCall("FreeConsole", "uint")
		if(hCon)
			DllCall("CloseHandle", "uint", hCon)
	}
}


Class CDesktopNavigationSource
{
	static Type := Navigation.RegisterNavigationSource(CDesktopNavigationSource, "Desktop")
	Processes(hwnd, class)
	{
		return (class = "Progman" || class = "WorkerW")
	}

	GetPath(hwnd)
	{
		return A_Desktop
	}

	GetSelectedFilepaths(hwnd)
	{
		Files := Array()
		ControlGet, result, List, Selected Col1, SysListView321, ahk_id %hwnd% ;This line causes explorer to crash on 64 bit systems when used in a 32 bit AHK build
		if(result)
			Loop, Parse, result, `n, `r
				Files.Insert(A_Desktop "\" A_LoopField)
		return Files
	}


	GetSelectedFilenames(hwnd)
	{
		Files := Array()
		ControlGet, result, List, Selected Col1, SysListView321, ahk_id %hwnd% ;This line causes explorer to crash on 64 bit systems when used in a 32 bit AHK build
		if(result)
			Loop, Parse, result, `n, `r
				Files.Insert(A_LoopField)
		return Files
	}
}


Class COldFileDialogNavigationSource
{
	static Type := Navigation.RegisterNavigationSource(COldFileDialogNavigationSource, "Old file dialog")
	Processes(hWindow, class)
	{
		if(class="#32770")
		{
			ControlGet, hwnd, Hwnd , , ToolbarWindow321, ahk_id %hWindow%
			if(hwnd)
			{
				ControlGet, hwnd, Hwnd , , SysListView321, ahk_id %hWindow%
				if(hwnd)
				{
					ControlGet, hwnd, Hwnd , , ComboBox3, ahk_id %hWindow%
					if(hwnd)
					{
						ControlGet, hwnd, Hwnd , , Button3, ahk_id %hWindow%
						if(hwnd)
						{
							ControlGet, hwnd, Hwnd , , SysHeader321 , ahk_id %hWindow%
							if(hwnd)
								return true
						}
					}
				}
			}
		}
		return false
	}

	; Not supported :(
	; GetPath(hwnd)
	GetFocusedFilename(hwnd)
	{
		ControlGet, focussed, list,focus, SysListView321, A
		return focussed
	}

	SetPath(Path, hwnd)
	{
		return CNewFileDialogNavigationSource.SetPath(Path, hwnd)
	}

	Refresh(hwnd)
	{
		ControlSend, SysListView321, {F5}, ahk_id %hwnd%
	}

	GoBack(hwnd)
	{
		ControlSend, SysListView321, !{Left}, ahk_id %hwnd%
	}

	GoForward(hwnd)
	{
		ControlSend, SysListView321, !{Right}, ahk_id %hwnd%
	}

	GoUpward(hwnd)
	{
		ControlSend, SysListView321, !{Up}, ahk_id %hwnd%
	}

	GetSelectedFilepaths(hwnd)
	{
		global MuteClipboardList
		ControlGetFocus, focused , ahk_id %hwnd%
		ControlFocus SysListView321, ahk_id %hwnd%
		MuteClipboardList := true
		ClipboardBackup := ClipboardAll
		clipboard := ""
		WaitForEvent("ClipboardChange", 100)
		ControlSend, SysListView321, ^c, ahk_id %hwnd%
		result := Clipboard
		Clipboard := ClipboardBackup
		WaitForEvent("ClipboardChange", 100)
		ControlFocus %focused%, ahk_id %hwnd%
		MuteClipboardList := false
		Files := Array()
		Loop, Parse, result, `n, `r
			Files.Insert(A_LoopField)
		return Files
	}

	GetSelectedFilenames(hwnd)
	{
		Files := this.GetSelectedFilepaths(hwnd)
		for index, File in Files
		{
			SplitPath, File, File
			Files[A_Index] := File
		}
		return Files
	}
}


Class CNewFileDialogNavigationSource
{
	static Type := Navigation.RegisterNavigationSource(CNewFileDialogNavigationSource, "New file dialog")
	Processes(hWindow, class)
	{
		if(class="#32770")
		{
			;Check for new FileOpen dialog
			ControlGet, hwnd, Hwnd , , DirectUIHWND3, ahk_id %hWindow%
			if(hwnd)
			{
				ControlGet, hwnd, Hwnd , , SysTreeView321, ahk_id %hWindow%
				if(hwnd)
				{
					ControlGet, hwnd, Hwnd , , Edit1, ahk_id %hWindow%
					if(hwnd)
					{
						ControlGet, hwnd, Hwnd , , Button2, ahk_id %hWindow%
						if(hwnd)
						{
							ControlGet, hwnd, Hwnd , , ComboBox2, ahk_id %hWindow%
							if(hwnd)
							{
								ControlGet, hwnd, Hwnd , , ToolBarWindow323, ahk_id %hWindow%
								if(hwnd)
									return true
							}
						}
					}
				}
			}
		}
		return false
	}

	GetPath(hwnd)
	{
		ControlGetText, text , ToolBarWindow322, ahk_id %hwnd%
		return strTrim(SubStr(text,InStr(text," ")), " ")
	}

	SetPath(Path, hwnd)
	{
		;Set path by entering it in the filename box (restore current text afterwards)
		ControlGetFocus, focussed, ahk_id %hwnd%
		ControlGetText, Edit1Text, Edit1, ahk_id %hwnd%
		ControlClick, Edit1, ahk_id %hwnd%
		ControlSetText, Edit1, %Path%, ahk_id %hwnd%
		ControlSend, Edit1, {Space}{Backspace}, ahk_id %hwnd% ;This needs to be done to make the file dialog deselect the current file to prevent overwriting on save dialogs
		Sleep 10
		ControlSend, Edit1, {Enter}, ahk_id %hwnd%
		Sleep, 100	; It needs extra time on some dialogs or in some cases.
		WinGet, Style, Style, ahk_id %hwnd%
		while(Style & 0x08000000) ;If there is a modal error dialog (current window is disabled!), wait until user closes it before continuing
		{
			Sleep, 100
			if(A_Index > 100) ;Make sure not to stay forever in this loop
				return 0
			WinGet, Style, Style, ahk_id %hwnd%
		}
		ControlSetText, Edit1, %Edit1Text%, ahk_id %hwnd%
		ControlFocus, %focussed%, ahk_id %hwnd%
	}

	Refresh(hwnd)
	{
		ControlSend, DirectUIHWND2, {F5}, ahk_id %hwnd%
	}

	GoBack(hwnd)
	{
		ControlSend, DirectUIHWND2, !{Left}, ahk_id %hwnd%
	}

	GoForward(hwnd)
	{
		ControlSend, DirectUIHWND2, !{Right}, ahk_id %hwnd%
	}

	GoUpward(hwnd)
	{
		ControlSend, DirectUIHWND2, !{Up}, ahk_id %hwnd%
	}

	GetSelectedFilepaths(hwnd)
	{
		global MuteClipboardList
		ControlGetFocus, focussed , ahk_id %hwnd%
		ControlFocus DirectUIHWND2, ahk_id %hwnd%
		MuteClipboardList := true
		ClipboardBackup := ClipboardAll
		clipboard := ""
		WaitForEvent("ClipboardChange", 100)
		ControlSend, DirectUIHWND2, ^c, ahk_id %hwnd%
		result := Clipboard
		Clipboard := ClipboardBackup
		WaitForEvent("ClipboardChange", 100)
		ControlFocus %focussed%, ahk_id %hwnd%
		MuteClipboardList := false
		Files := Array()
		Loop, Parse, result, `n, `r
			Files.Insert(A_LoopField)
		return Files
	}

	GetSelectedFilenames(hwnd)
	{
		Files := this.GetSelectedFilepaths(hwnd)
		for index, File in Files
		{
			SplitPath, File, File
			Files[A_Index] := File
		}
		return Files
	}
}


Class CExplorerNavigationSource
{
	static Type := Navigation.RegisterNavigationSource(CExplorerNavigationSource, "Explorer")
	Processes(hwnd, class)
	{
		return (class = "ExploreWClass" || class = "CabinetWClass")
	}

	GetPath(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
				return Window.Document.Folder.Self.path
	}

	GetDisplayName(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
				return Window.Document.Folder.Self.Name
	}

	SetPath(Path, hwnd)
	{
		Exists := FileExist(Settings.DllPath "\Explorer.dll")
		if(Exists)
		{
			DllCall(Settings.DllPath "\Explorer.dll\SetPath", "Ptr", hwnd, "Str", Path, "Cdecl")
			SetTimerF("ExplorerPathChanged", -100)
		}
		else
			for Window in ComObjCreate("Shell.Application").Windows
				if(Window.hwnd = hwnd)
				{
					Window.Navigate2[Path]
					SetTimerF("ExplorerPathChanged", -100)
				}
	}

	GetSelectedFilepaths(hwnd)
	{
		Files := Array()
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
			{
				doc := Window.Document
				Loop % doc.SelectedItems.Count
					Files.Insert(doc.selectedItems.item(A_Index-1).Path)
			}
		return Files
	}

	GetSelectedFilenames(hwnd)
	{
		Files := Array()
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
			{
				doc := Window.Document
				Loop % doc.SelectedItems.Count
					Files.Insert(doc.selectedItems.item(A_Index-1).Name)
			}
		return Files
	}

	GetFocusedFilePath(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
				return Window.Document.FocusedItem.Path
	}

	GetFocusedFilename(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
				return Window.Document.FocusedItem.Name
	}

	SelectFiles(Files, hWnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
		{
			if (Window.hwnd = hWnd)
			{
				doc:=Window.Document
				value := true
				value1 := 25 
				count := doc.Folder.Items.Count
				if(count > 0)
				{
					item := doc.Folder.Items.Item(0)
					doc.SelectItem(item,4)
					doc.SelectItem(item,0)
				}
				items := Array()
				itemnames := Array()
				Loop % count
				{
					index := A_Index
					;the commands in this loop fail sometimes so we try multiple times until it works
					Loop 1000 ;Maximum wait: 10 seconds, should suffice even under heavy load
					{
						item := doc.Folder.Items.Item(index - 1)
						itemname := item.Name
						if(itemname)
							break
						Sleep 10
					}
					items.Insert(item)	
					itemnames.Insert(itemname)
				}
				Loop % Files.MaxIndex()
				{
					index := A_Index
					filter := Files[A_Index]
					If(filter)
					{
						SplitPath, filter, filter ;Make sure only names are used
						If(InStr(filter, "*"))
						{
							filter := "\Q" StringReplace(filter, "*", "\E.*\Q", 1) "\E"
							filter := strTrim(filter,"\Q\E")
							Loop % items.MaxIndex()
								if(RegexMatch(itemnames[A_Index],"i)" filter))
								{
									doc.SelectItem(items[A_Index], index=1 ? 25 : 1) ;1 (Select) + 16 (Focus) + 8 (MakeVisible)
									index++
								}
						}
						else
							Loop % items.MaxIndex()
								if(itemnames[A_Index] = filter)
								{
									doc.SelectItem(items[A_Index], index=1 ? 25 : 1)
									index++
									break
								}
					}
				}
				return 1
			}
		}
		return 0
	}

	GoBack(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
			{
				Window.GoBack()
				SetTimerF("ExplorerPathChanged", -100)
				return
			}
	}

	GoForward(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
			{
				Window.GoForward()
				SetTimerF("ExplorerPathChanged", -100)
				return
			}
	}

	GoUpward(hwnd)
	{
		path := this.GetPath(hwnd)
		if(WinVer >= WIN_Vista && !strEndsWith(path,".search-ms"))
			Send !{Up}
		else
			Send {Backspace}
		SetTimerF("ExplorerPathChanged", -100)
	}

	Refresh(hwnd)
	{
		for Window in ComObjCreate("Shell.Application").Windows
			if(Window.hwnd = hwnd)
			{
				Window.Refresh()
				return
			}
	}

	InvertSelection(hwnd)
	{
		;Calling the menu item is more reliable than doing it through COM because right now only real files are supported
		if(WinExist("A") = hwnd)
		{
			if(WinVer = WIN_8)
			{
				SendInput !rsi
				return
			}
			else
			{
				PostMessage,0x112,0xf100,0,,A
				SendInput {Right}{Down}{Up}{Enter}
				return
			}
			;selected := this.GetSelectedFilenames(hwnd)
			;path := this.GetPath(hwnd)
			;NewSelection := Array()
			;Loop, %path%\* , 1
			;	if(!selected.indexOf(A_LoopFileName))
			;		NewSelection.Insert(A_LoopFileName)
			;this.SelectFiles(hwnd, NewSelection)
		}
	}
}