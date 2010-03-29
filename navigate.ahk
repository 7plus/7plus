/*
LPITEMIDLIST ConvertPathToLpItemIdList(const char *pszPath)
{
    LPITEMIDLIST  pidl;
    LPSHELLFOLDER pDesktopFolder;
    OLECHAR       olePath[MAX_PATH];
    ULONG         chEaten;
    ULONG         dwAttributes;
    HRESULT       hr;

    if (SUCCEEDED(SHGetDesktopFolder(&pDesktopFolder)))
    {
        MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, pszPath, -1, olePath, 
                            MAX_PATH);
        hr = pDesktopFolder->ParseDisplayName(NULL,NULL,olePath,&chEaten,
                                              &pidl,&dwAttributes);
        pDesktopFolder->Release();
    }
    return pidl;
}
*/

Shell_GoBack(hWnd=0)
{
  Critical
	If   hWnd||(hWnd:=WinExist("ahk_class CabinetWClass"))||(hWnd:=WinExist("ahk_class ExploreWClass")) 
  {
		sa := Com_CreateObject("Shell.Application")
		wins := sa.Windows
		loop % wins.count
		{
		window:=wins.Item(A_Index-1)
		If Not InStr( window.FullName, "steam.exe" ) ; ensure pwb isn't IE
			if(window.Hwnd=hWnd)
				break
		}
    Window.GoBack()
		return
  }
}
ShellNavigate(sPath, hWnd=0) 
{ 
	Critical
	If   hWnd||(hWnd:=WinExist("ahk_class CabinetWClass"))||(hWnd:=WinExist("ahk_class ExploreWClass")) 
  {
		sa := Com_CreateObject("Shell.Application")
		wins := sa.Windows
		loop % wins.count
		{
		window:=wins.Item(A_Index-1)
		If Not InStr( window.FullName, "steam.exe" ) ; ensure pwb isn't IE
			if(window.Hwnd=hWnd)
				break
		}
    DllCall("shell32\SHParseDisplayName", "Uint", COM_Unicode4Ansi(wPath,sPath) , "Uint", 0, "UintP", pidl, "Uint", 0, "Uint", 0)
    VarSetCapacity(sa,24,0), NumPut(DllCall("shell32\ILGetSize","Uint",pidl), NumPut(pidl, NumPut(1, NumPut(1,sa)),4)) 
		Window.Navigate2(COM_Parameter(0x2011,&sa))
		return
  }
}
RefreshExplorer() 
{ 
	Critical
	hwnd:=WinExist("A")
	If (WinActive("ahk_group ExplorerGroup"))
  {
		sa := Com_CreateObject("Shell.Application")
		wins := sa.Windows
		loop % wins.count
		{
			window:=wins.Item(A_Index-1)
			If Not InStr( window.FullName, "steam.exe" ) ; ensure pwb isn't IE
				if(window.Hwnd=hWnd)
					break
		}
		Window.Refresh()		
  }
  else if(IsDialog())
  	Send {F5}
}
  	/*
	;Get Desktop IShellFolder
	DllCall("SHGetDesktopFolder","str",pDesktopFolder)
	Ansi2Unicode(sPath,sPath)
	
	hr = pDesktopFolder->ParseDisplayName(NULL,NULL,olePath,&chEaten,
                                              &pidl,&dwAttributes);
                                              
	DllCall("MultiByteToWideChar"
	DllCall("MultiByteToWideChar", "Uint", 0, "Uint", 0, "str", sPath, "int", -1, "Uint", 0, "int", 0)
	window.Navigate(sPath)
	}
	return
	*/
	
/*
fileO:
FO_MOVE   := 0x1 
FO_COPY   := 0x2 
FO_DELETE := 0x3 
FO_RENAME := 0x4

flags:
Const FOF_SILENT = 4
Const FOF_RENAMEONCOLLISION = 8
Const FOF_NOCONFIRMATION = 16
Const FOF_NOERRORUI = 1024
http://msdn.microsoft.com/en-us/library/bb759795(VS.85).aspx for more
*/
ShellFileOperation( fileO=0x0, fSource="", fTarget="", flags=0x0, ghwnd=0x0 )     
{ 
 If ( SubStr(fSource,0) != "|" ) 
      fSource := fSource . "|" 

 If ( SubStr(fTarget,0) != "|" ) 
      fTarget := fTarget . "|" 

 fsPtr := &fSource 
 Loop, % StrLen(fSource) 
  If ( *(fsPtr+(A_Index-1)) = 124 ) 
      DllCall( "RtlFillMemory", UInt, fsPtr+(A_Index-1), Int,1, UChar,0 ) 

 ftPtr := &fTarget 
 Loop, % StrLen(fTarget) 
  If ( *(ftPtr+(A_Index-1)) = 124 ) 
      DllCall( "RtlFillMemory", UInt, ftPtr+(A_Index-1), Int,1, UChar,0 ) 

 VarSetCapacity( SHFILEOPSTRUCT, 30, 0 )                 ; Encoding SHFILEOPSTRUCT 
 NextOffset := NumPut( ghwnd, &SHFILEOPSTRUCT )          ; hWnd of calling GUI 
 NextOffset := NumPut( fileO, NextOffset+0    )          ; File operation 
 NextOffset := NumPut( fsPtr, NextOffset+0    )          ; Source file / pattern 
 NextOffset := NumPut( ftPtr, NextOffset+0    )          ; Target file / folder 
 NextOffset := NumPut( flags, NextOffset+0, 0, "Short" ) ; options 

 DllCall( "Shell32\SHFileOperationA", UInt,&SHFILEOPSTRUCT ) 
Return NumGet( NextOffset+0 ) 
}
SetDirectory(sPath)
{
	sPath:=ExpandEnvVars(sPath)
	if(strEndsWith(sPath,":"))
		sPath .="\"s
	If (WinActive("ahk_group ExplorerGroup")) ;&& InStr(FileExist(sPath), "D"))
	{
		if (InStr(FileExist(sPath), "D") || SubStr(sPath,1,3)="::{" || SubStr(sPath,1,6)="ftp://" || strEndsWith(sPath,".search-ms")) 
		{
			hWnd:=WinExist("A")
			ShellNavigate(sPath,hwnd)
		}
		else
		{
			ToolTip(1, "The path " sPath " cannot be opened!", "Invalid path","O1 L1 P99 C1 XTrayIcon YTrayIcon I4")
			SetTimer, ToolTipClose, -5000
			TooltipShowSettings:=false
		} 
	}
	else if (IsWinRarExtractionDialog())
		SetWinRarDirectory(sPath)
	else if (IsDialog())
		SetDialogDirectory(sPath)
	else
		MsgBox Can't navigate: Wrong window
}
SetWinRarDirectory(Path)
{
	ControlSetText , Edit1, %sPath%, A 
	ControlClick, Button1, A
}
SetDialogDirectory(Path)
{
	ControlGetFocus, focussed, A
	ControlGetText, w_Edit1Text, Edit1, A
	ControlClick, Edit1, A
	ControlSetText, Edit1, %Path%, A
	hwnd:=WinExist("A")
	ControlSend, Edit1, {Enter}, A
	Sleep, 100	; It needs extra time on some dialogs or in some cases.
	while(hwnd!=WinExist("A")) ;If there is an error dialog, wait until user closes it before continueing
		Sleep, 100
	ControlSetText, Edit1, %w_Edit1Text%, A
	ControlFocus %focussed%,A
}
IsDialog(window=0)
{
	result:=0
	if(window)
		window:="ahk_id " window
	else
		window:="A"
	if(WinGetClass(window)="#32770")
	{
		;Check for new FileOpen dialog
		ControlGet, hwnd, Hwnd , , DirectUIHWND3, %window%
		if(hwnd)
		{
			ControlGet, hwnd, Hwnd , , SysTreeView321, %window%
			if(hwnd)
			{
				ControlGet, hwnd, Hwnd , , Edit1, %window%
				if(hwnd)
				{
					ControlGet, hwnd, Hwnd , , Button2, %window%
					if(hwnd)
					{
						ControlGet, hwnd, Hwnd , , ComboBox2, %window%
						if(hwnd)
						{
						ControlGet, hwnd, Hwnd , , ToolBarWindow323, %window%
						if(hwnd)
							result:=1
						}
					}
				}
			}
		}
		;Check for old FileOpen dialog
		if(!result)
		{ 
			ControlGet, hwnd, Hwnd , , ToolbarWindow321, %window%
			if(hwnd)
			{
				ControlGet, hwnd, Hwnd , , SysListView321, %window%
				if(hwnd)
				{
					ControlGet, hwnd, Hwnd , , ComboBox3, %window%
					if(hwnd)
					{
						ControlGet, hwnd, Hwnd , , Button3, %window%
						if(hwnd)
						{
							ControlGet, hwnd, Hwnd , , SysHeader321 , %window%
							if(hwnd)
								result:=2
						}
					}
				}
			}
		}
	}
	return result
}

GetSelectedFiles(FullName=1)
{
	global MuteClipboardSurveillance, MuteClipboardList,Vista7
	If (WinActive("ahk_group ExplorerGroup"))
	{
		hWnd:=WinExist("A")
		if FullName
			return ShellFolder(hwnd,3)
		else
			return ShellFolder(hwnd,4)
	}
	else if((Vista7 && x:=IsDialog())||WinActive("ahk_group DesktopGroup"))
	{		
		ControlGetFocus, focussed ,A
		if(x=1)
			ControlFocus DirectUIHWND2, A
		if(WinActive("ahk_group DesktopGroup"))
			ControlFocus SysListView321, A
			outputdebug mute 12
		MuteClipboardList := true
		clipboardbackup := clipboardall
		outputdebug clearing clipboard
		clipboard := ""
		ClipWait, 0.05, 1
		outputdebug mute 13
		MuteClipboardList := true
		outputdebug copying files to clipboard
		Send ^c
		ClipWait, 0.05, 1
		result := clipboard
		outputdebug mute 14
		MuteClipboardList := true
		outputdebug restoring clipboard
		clipboard := clipboardbackup
		ControlFocus %focussed%, A
		OutputDebug, Selected Files: %result%
		return result
	}
}
GetFocussedFile()
{
	If (WinActive("ahk_group ExplorerGroup"))
	{	
		return ShellFolder(WinExist("A"),2)
	}
	else if(IsDialog()=2) ;only old Dialogs supported
	{
		ControlGet, focussed, list,focus, SysListView321, A
		return focussed
	}
}
GetCurrentFolder()
{
	global MuteClipboardList
	If (WinActive("ahk_group ExplorerGroup"))
	{	
		hWnd:=WinExist("A")
		return ShellFolder(hwnd,1)
	}
	If (WinActive("ahk_group DesktopGroup"))
		return %A_Desktop%
	else if((x:=IsDialog())=1) ;No Support for old dialogs for now
	{
		ControlGetText, text , ToolBarWindow322, A
		return SubStr(text,InStr(text," "))
	}
	return ""
}
SelectFiles(sSelect, hWnd=0)
{
	Critical
	If   hWnd||(hWnd:=WinActive("ahk_class CabinetWClass"))||(hWnd:=WinActive("ahk_class ExploreWClass")) 
  {
      sa := Com_CreateObject("Shell.Application")		
			;Find hwnd window
			wins := sa.Windows
			loop % wins.count
			{
			window:=wins.Item(A_Index-1)
			If Not InStr( window.FullName, "steam.exe" ) ; ensure pwb isn't IE
				if(window.Hwnd=hWnd)
					break
			}
	    doc:=window.Document
      Loop, Parse, sSelect, `n 
				If  A_LoopField <>
				{ 
					item:=COM_Invoke(doc,"Folder.ParseName",A_LoopField)
					;first, deselect all but first item, then add other items to selection
					COM_Invoke(doc,"SelectItem",item,(A_Index=1 ? 29 : 1)) ;http://msdn.microsoft.com/en-us/library/bb774047(VS.85).aspx
				}
   } 
}
ShellFolder(hWnd=0,returntype=0) 
{ 
	Critical
	If   hWnd||(hWnd:=WinActive("ahk_class CabinetWClass"))||(hWnd:=WinActive("ahk_class ExploreWClass")) 
  {
		sa := Com_CreateObject("Shell.Application")
		
		;Find hwnd window
		wins := sa.Windows
		loop % wins.count
		{
			window:=wins.Item(A_Index-1)
			If Not InStr( window.FullName, "steam.exe" ) ; ensure pwb isn't IE
				if(window.Hwnd=hWnd)
					break
		}
    doc:=window.Document
    sFolder   := doc.Folder.Self.Path
    ;Don't get focussed item and selected files unless requested, because it will cause a COM error when called during/shortly after explorer path change sometimes
    if (returntype=2)
    {
    	sFocus :=doc.FocusedItem.Path
	    SplitPath, sFocus , sFocus
    }
    if(returntype=3 || returntype=4)
    {
	    loop % doc.SelectedItems.Count
	    {
	    	path :=doc.selectedItems.item(A_Index-1).Path "`n" ;= (returntype=3 ? sFolder "\" COM_Invoke(doc.SelectedItems, "Item", A_Index-1).Name "`n" : COM_Invoke(doc.SelectedItems, "Item", A_Index-1).Name "`n")
	    	if(returntype=4)
	    		SplitPath, path , path
	    	sSelect.=path
	    }
	    StringReplace, sSelect, sSelect, \\ , \, 1 
	  }
	  ;Remove last `n
    StringTrimRight, sSelect, sSelect, 1
		if (returntype=1)
			Return   sFolder
		else if (returntype=2)
			Return   sFocus
		else if (returntype=3)
			Return   sSelect
		else if (returntype=4)
			Return 	 sSelect
  }
}

IsWinrarExtractionDialog()
{
	global WinRarTitle
	If (WinActive("ahk_class #32770"))
	{		
		if(WinRarTitle="")
		{
			RegRead, path, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe ,Path
			if(path)
			{
				Loop, read, %path%\winrar.lng
				{
					if(strStartsWith(A_LoopReadLine,"8f827d31"))
					{
						WinRarTitle:=strStrip(A_LoopReadLine,"""")
						break
					}
				}
				if(!WinRarTitle)
					WinRarTitle:="WinRar not found"
			}
		}		
		WinGetTitle, wintitle,A
		if(WinRarTitle=wintitle)
			return true
	}
	return false
}
