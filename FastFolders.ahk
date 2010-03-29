#include %a_scriptdir%\FolderButtonManager.ahk
FFCondition()
{
	global Vista7, HKFastFolders
	if(Vista7)
	  ControlGetFocus focussed, A
	else
		focussed:=XPGetFocussed()
	if HKFastFolders && ((WinActive("ahk_group ExplorerGroup") ) || IsDialog()||IsWinRarExtractionDialog())  && !strStartsWith(focussed,"Edit")
		return true
	return false
}
#if FFCondition()
Numpad0::SetDirectory(FF0)
Numpad1::SetDirectory(FF1)
Numpad2::SetDirectory(FF2)
Numpad3::SetDirectory(FF3)
Numpad4::SetDirectory(FF4)
Numpad5::SetDirectory(FF5)
Numpad6::SetDirectory(FF6)
Numpad7::SetDirectory(FF7)
Numpad8::SetDirectory(FF8)
Numpad9::SetDirectory(FF9)
^Numpad0::UpdateStoredFolder(FF0,FFTitle0)
^Numpad1::UpdateStoredFolder(FF1,FFTitle1)
^Numpad2::UpdateStoredFolder(FF2,FFTitle2)
^Numpad3::UpdateStoredFolder(FF3,FFTitle3)
^Numpad4::UpdateStoredFolder(FF4,FFTitle4)
^Numpad5::UpdateStoredFolder(FF5,FFTitle5)
^Numpad6::UpdateStoredFolder(FF6,FFTitle6)
^Numpad7::UpdateStoredFolder(FF7,FFTitle7)
^Numpad8::UpdateStoredFolder(FF8,FFTitle8)
^Numpad9::UpdateStoredFolder(FF9,FFTitle9)
!Numpad0::ClearStoredFolder(FF0,FFTitle0)
!Numpad1::ClearStoredFolder(FF1,FFTitle1)
!Numpad2::ClearStoredFolder(FF2,FFTitle2)
!Numpad3::ClearStoredFolder(FF3,FFTitle3)
!Numpad4::ClearStoredFolder(FF4,FFTitle4)
!Numpad5::ClearStoredFolder(FF5,FFTitle5)
!Numpad6::ClearStoredFolder(FF6,FFTitle6)
!Numpad7::ClearStoredFolder(FF7,FFTitle7)
!Numpad8::ClearStoredFolder(FF8,FFTitle8)
!Numpad9::ClearStoredFolder(FF9,FFTitle9)
#if

ClearStoredFolder(ByRef FF, ByRef FFTitle)
{
	global
	Critical
	local pos, name
	FF:=""
	FFTitle:=""
	if (HKFolderBand)
	{
		RemoveAllButtons(IsFastFolderButton)
		loop 10
		{
			pos:=A_Index-1
			if FF%pos%
			{			
				if(!name)
					name:=path
				AddButton("",FF%pos%,,pos ":" FFTitle%pos%)
			}
		}
	}
}
UpdateStoredFolder(ByRef FF, ByRef FFTitle)
{
	;Update values of FF and FFTitle, then refresh fast folders
	FF:=GetCurrentFolder()
	title:=FF	
	if(strStartsWith(title,"::") && WinActive("ahk_group ExplorerGroup"))
		WinGetTitle,title,A
		
	SplitPath, title , FFTitle
	if(!FFTitle)
		FFtitle:=title
	RefreshFastFolders()	
}
RefreshFastFolders()
{
	global
	local pos, value
	Critical
	if(!(HKFolderBand||HKPlacesBar))
		return
	if (HKFolderBand)
		RemoveAllButtons(IsFastFolderButton)
	loop 10
	{
		pos:=A_Index-1
		if FF%pos%
		{				
			if (HKFolderBand)		
				AddButton("",FF%pos%,,pos ":" FFTitle%pos%)
			if(pos<=4 && HKPlacesBar)	;Also update placesbar
			{
				value:=FF%pos%
				RegWrite, REG_SZ,HKCU,Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar, Place%pos%,%value%
			}				
		}
	}
}
IsFastFolderButton(Command,Title,Tooltip)
{
x:=substr(Title,1,1)
if(IsNumeric(x)&&substr(Title,2,1)=":")
	return true
return false
}

FastFolderMenu()
{
	global
	Menu, FastFolders, add, 1,FastFolderMenuHandler1
	Menu, FastFolders, DeleteAll
	if (HKFastFolders && HKFFMenu && (IsWindowUnderCursor("ExploreWClass")||IsWindowUnderCursor("CabinetWClass")||IsWindowUnderCursor("WorkerW")||IsWindowUnderCursor("Progman")) && !IsRenaming())
	{
		win:=WinExist("A")
		y:=GetSelectedFiles()
		loop 10
		{
			i:=A_INDEX-1
			if(FF%i%)
			{
				x:=FFTitle%i%
				if(x && (!strStartsWith(x,"ftp://")||!y))
				{
					Menu, FastFolders, add, %x%, FastFolderMenuHandler%i%
				}
			} 
		}
		hwnd:=WinExist("A")
		Menu, FastFolders, Show
		return true
	}	
	return false
}
FastFolderMenuHandler0:
FastFolderMenuClicked(0)
return
FastFolderMenuHandler1:
FastFolderMenuClicked(1)
return
FastFolderMenuHandler2:
FastFolderMenuClicked(2)
return
FastFolderMenuHandler3:
FastFolderMenuClicked(3)
return
FastFolderMenuHandler4:
FastFolderMenuClicked(5)
return
FastFolderMenuHandler5:
FastFolderMenuClicked(5)
return
FastFolderMenuHandler6:
FastFolderMenuClicked(6)
return
FastFolderMenuHandler7:
FastFolderMenuClicked(7)
return
FastFolderMenuHandler8:
FastFolderMenuClicked(8)
return
FastFolderMenuHandler9:
FastFolderMenuClicked(9)
return
FastFolderMenuClicked(index)
{
	global
	local y:=FF%index%
	local ctrldown := GetKeyState("CTRL")
	if(paste)
	{
		MuteClipboardList:=true
		ClipboardBackup:=ClipboardAll
		Clipboard:=y
		Send ^v
		Sleep 20
		Clipboard:=ClipboardBackup
		MuteClipboardList:=false
		outputdebug paste %y% to %paste%
		paste:=false
		return
	}	
	x:=GetSelectedFiles()
	StringReplace, x, x, `n , |, A
	if(x)
	{	
		if(ctrldown)
			ShellFileOperation(0x2, x, y,0,hwnd)   
		else
			ShellFileOperation(0x1, x, y,0,hwnd)
	}
	else
	{
		SetDirectory(y)
	}
	Menu, FastFolders, DeleteAll
}
