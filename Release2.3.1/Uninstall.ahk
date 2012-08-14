; #include %A_ScriptDir%\lib\com.ahk
ComObjError(0) ;Set for removing autorun (it will show an error if autorun is off)
#NoTrayIcon
global Vista7 := IsVista7()
MsgBox, 4,, Do you really want to uninstall 7plus? This will delete the folder where 7plus is installed, possibly %A_AppData%\7plus and undo all changes to the registry.
IfMsgBox Yes
{
	if(FileExist(A_ScriptDir "\7plus.exe") || FileExist(A_ScriptDir "\7plus.ahk"))
	{
		DetectHiddenWindows, On
		FileRead, hwnd, %A_Temp%\7plus\hwnd.txt
		if(WinExist("ahk_id " hwnd))
		{
			WinGet, pid, pid, ahk_id %hwnd%
			Loop 10
			{
				Process, Close, %pid%
				Sleep 100
				if(!WinExist("ahk_pid " pid))
					break
				else if(A_Index = 10)
				{
					Msgbox Error closing 7plus!
					ExitApp
				}
			}
		}
		FileRemoveDir, %A_Temp%\7plus, 1
		if(FileExist(A_Temp "\7plus"))
		{
			ScheduleDeletion(A_Temp "\7plus")
			FilesLeft := true
		}
		FileRemoveDir, %A_AppData%\7plus, 1	
		if(FileExist(A_AppData "\7plus"))
		{
			ScheduleDeletion(A_AppData "\7plus")
			FilesLeft := true
		}
		run, regsvr32.exe /u /s "%A_ScriptDir%\ShellExtension.dll"
		DisableAutorun()
		RegDelete, HKCU, Software\7plus
		RestoreFolderBandButtons()
		RestorePlacesBar()
		RestoreFolderBand()
		RemoveAllExplorerButtons()
		RemoveUninstallInformation()
		
		;Close explorer windows that may have a handle on the current directory
		WinGet, id, list,,, Program Manager
		Loop, %id%
		{
			this_id := id%A_Index%
			WinGetClass, this_class, ahk_id %this_id%
			if(this_class = "CabinetWClass" || this_class = "ExploreWClass")
			{
				folder :=  ShellFolder(this_id,1)
				if(folder = A_ScriptDir)
					WinClose ahk_id %this_id%
			}
		}
		Loop % A_ScriptDir "\*.*", 1, 1
		{
			if(InStr(FileExist(A_LoopFileLongPath), "D"))
				FileRemoveDir, %A_loopFileLongPath%, 1
			else
				FileDelete, %A_LoopFileLongPath%
		}
		if(FileExist(A_ScriptDir))
		{
			ScheduleDeletion(A_ScriptDir)
			FilesLeft := true
		}
		if(FilesLeft)
			Msgbox 7plus was successfully uninstalled. However, some files could not be deleted. These will be deleted automatically after the next reboot. Please report any possible errors or problems that caused you to uninstall it.
		else
			Msgbox 7plus was successfully uninstalled. Please report any possible errors or problems that caused you to uninstall it.
	}
	else
		Msgbox 7plus not found!
}
ExitApp

ScheduleDeletion(FileOrFolder)
{
	static MOVEFILE_DELAY_UNTIL_REBOOT := 4
	if(!FileExist(FileOrFolder))
		return
	
	;MoveFileEx requires that the directories which are scheduled for deletion are empty, so the files in them need to be deleted first.
	;For this we do a recursed call of this function that first schedules all files and folders at the deepest level.
	Loop %FileOrFolder%\*.*, 1, 1
	{
		if(InStr(FileExist(A_LoopFileLongPath), "D"))
			ScheduleDeletion(A_LoopFileLongPath)
		else
			DllCall("MoveFileEx", "STR", A_LoopFileLongPath, "PTR", 0, "UINT", MOVEFILE_DELAY_UNTIL_REBOOT)
	}
	DllCall("MoveFileEx", "STR", FileOrFolder, "PTR", 0, "UINT", MOVEFILE_DELAY_UNTIL_REBOOT)
}
DisableAutorun()
{
	RegDelete, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus
	if(Vista7)
	{
		objService := ComObjCreate("Schedule.Service") 
		objService.Connect()
		objFolder := objService.GetFolder("\")
		objFolder.DeleteTask("7plus Autorun", 0)
	}
}
IsVista7()
{
	;Get windows version
	RegRead, WinVersion, HKLM, SOFTWARE\Microsoft\Windows NT\CurrentVersion, CurrentVersion
	return WinVersion >= 6
}
ShellFolder(hWnd=0,returntype=0) 
{ 
	if(hWnd||(hWnd:=WinActive("ahk_class CabinetWClass"))||(hWnd:=WinActive("ahk_class ExploreWClass")))
	{
		;Find hwnd window
		for Item in ComObjCreate("Shell.Application").Windows
		{
			if (Item.hwnd = hWnd)
			{
				doc:=Item.Document
				sFolder   := doc.Folder.Self.path
				sDisplay := doc.Folder.Self.name
				;Don't get focussed item and selected files unless requested, because it will cause a COM error when called during/shortly after explorer path change sometimes
				if (returntype=2)
				{
					sFocus :=doc.FocusedItem.Path
					SplitPath, sFocus , sFocus
				}
				if(returntype=3 || returntype=4)
				{
					count := doc.SelectedItems.Count
					pos := 1
					while(pos <= count)
					{
						path :=doc.selectedItems.item(pos-1).Path ;= (returntype=3 ? sFolder "\" COM_Invoke(doc.SelectedItems, "Item", A_Index-1).Name "`n" : COM_Invoke(doc.SelectedItems, "Item", A_Index-1).Name "`n")
						if(path != "")
						{
							if(returntype=4)
								SplitPath, path , path
							sSelect := sSelect path "`n"
							pos++
						}
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
				else if (returntype=5)
					Return sDisplay
			}
		}
	}
}

RestoreFolderBand()
{
	if(!Vista7)
		return
	RemoveAllExplorerButtons()	
	RegRevokePermissions("hklm\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes")
}
RestoreFolderBandButtons()
{
	if(Vista7)
	{
		RegRename("HKLM","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Burn7pBackup","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Burn")
		RegRename("HKLM","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Organize7pBackup","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Organize")
		RegRename("HKLM","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.IncludeInLibrary7pBackup","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.IncludeInLibrary")
		RegRename("HKLM","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NewFolder7pBackup","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NewFolder")
		RegRename("HKLM","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Share7pBackup","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Share")
		RegRename("HKLM","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.SlideShow7pBackup","SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.SlideShow")
		;remove some rights
		RegRevokePermissions("hklm\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell")
	}
}

RestorePlacesBar()
{
	RegRead, place, HKCU, Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar7pBackup ,Place0
	RegDelete, HKCU, Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar
	if(place)
		RegRename("HKCU","Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar7pBackup"," Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\PlacesBar")
}

;---------------------------------------------------------------------------------------------------------------

RegRename(root,key,target)
{
	HKEY_CLASSES_ROOT   := 0x80000000   ; http://msdn.microsoft.com/en-us/library/aa393286.aspx 
	HKEY_CURRENT_USER   := 0x80000001 
	HKEY_LOCAL_MACHINE   := 0x80000002 
	HKEY_USERS         := 0x80000003 
	HKEY_CURRENT_CONFIG   := 0x80000005 
	HKEY_DYN_DATA      := 0x80000006 
	HKCR := HKEY_CLASSES_ROOT 
	HKCU := HKEY_CURRENT_USER 
	HKLM := HKEY_LOCAL_MACHINE 
	HKU    := HKEY_USERS 
	HKCC := HKEY_CURRENT_CONFIG
	hive:=%root%
	if(!hive)
		return 0
	
	result:=DllCall("Advapi32.dll\RegOpenKeyEx", "Ptr", hive, "str", key, "uint",0, "uint", 0xF003F, "Ptr *",hkey)
	if(result=0)
	{
		result:=DllCall("Advapi32.dll\RegCreateKeyEx", "Ptr", hive, "str", target, "uint", 0, "uint", 0, "uint", 0, "uint", 0xF003F, "uint", 0, "Ptr *", hNewKey, "uint",0)
		if(result=0)
		{
			result:=DllCall("Advapi32.dll\RegCopyTree", "Ptr", hkey, "uint", 0, "Ptr", hNewKey)
			if(result=0)
			{
				DllCall("Advapi32.dll\RegCloseKey", "Ptr", hkey)
				RegDelete, %root%, %key%
				DllCall("Advapi32.dll\RegCloseKey", "Ptr", hNewKey)
				return 1
			}			
			else
			{
				DllCall("Advapi32.dll\RegCloseKey", "Ptr", hNewKey)
				RegDelete, %root%, %target%
				DllCall("Advapi32.dll\RegCloseKey", "Ptr", hkey)
				return 1
			}
		}
		DllCall("Advapi32.dll\RegCloseKey", "Ptr", hkey)
	}
	return 0
}

RegRevokePermissions(key)
{
	DllPath := A_ScriptDir "\lib" (A_PtrSize = 8 ? "\x64" : "")
	RunWait % DllPath "\SetACL.exe -on """ key """ -ot Reg -actn ace -ace ""n:S-1-5-32-545;p:full;s:y;i:so,sc;m:revoke;w:dacl""","","Hide"
}
;Removes all buttons created with this script. Function can be the name of a function with these arguments: func(command,title,tooltip) and it can be used to tell the script if an entry may be deleted
RemoveAllExplorerButtons(function="")
{
	;go into view folders (clsid)
	Loop, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes, 2, 0
	{			
		regkey := A_LoopRegName
		;go into number folder
		Loop, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected, 2, 0
		{
			numberfolder := A_LoopRegName			
			
			;Custom skip function code
			;go into clsid folder
			Loop, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected\%numberfolder%, 2, 0
			{
				skip := false
				RegRead, value, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected\%numberfolder%\%A_LoopRegName%, InfoTip
				RegRead, title, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected\%numberfolder%\%A_LoopRegName%, Title
				RegRead, cmd, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected\%numberfolder%\%A_LoopRegName%\shell\InvokeTask\command
				
				if(IsFunc(function))
					if(!%function%(cmd,title,value))
					{
						skip := true
						break
					}
			}
			if(skip) 
				continue
			;Custom skip function code
			RegRead, ahk, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected\%numberfolder%, AHK			
			if(ahk)
				RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksItemsSelected\%numberfolder%
		}
		Loop, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected, 2, 0
		{
			numberfolder:=A_LoopRegName
			
			
			;Custom skip function code
			;go into clsid folder
			Loop, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected\%numberfolder%, 2, 0
			{
				skip:=false
				RegRead, value, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected\%numberfolder%\%A_LoopRegName%, InfoTip
				RegRead, title, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected\%numberfolder%\%A_LoopRegName%, Title
				RegRead, cmd, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected\%numberfolder%\%A_LoopRegName%\shell\InvokeTask\command
				
				if(IsFunc(function))
					if(!%function%(cmd,title,value))
					{
						skip:=true
						break
					}
			}
			if(skip) 
				continue
			;Custom skip function code
			
			
			RegRead, ahk, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected\%numberfolder%, AHK
			if(ahk)
				RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\%regkey%\TasksNoItemsSelected\%numberfolder%
		}
	}
}

RemoveUninstallInformation()
{
	if(IsPortable)
		return
	RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus
}