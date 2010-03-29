;---------------------------------------------------------------------------------------------------------------
;This file contains methods for storing and restoring fast folders related registry settings
;---------------------------------------------------------------------------------------------------------------


PrepareFolderBand()
{
	global Vista7
	if(Vista7)
	{
		runwait regedit /e "%a_scriptdir%\FolderTypesBackup.reg" HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes
		runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes /setowner=S-1-5-32-544,,Hide
		runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes /grant=S-1-5-32-545=F,,Hide
	}
}
BackupAndRemoveFolderBandButtons()
{
	global Vista7
	if(Vista7)
	{
		runwait regedit /e "%a_scriptdir%\FolderBandBackup.reg" HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore
		runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell /setowner=S-1-5-32-544,,Hide
		runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell /grant=S-1-5-32-545=F,,Hide
		
		RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Burn
		RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Organize
		RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.IncludeInLibrary
		RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NewFolder
		RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.Share
	}
}
BackupPlacesBar()
{
	runwait regedit /e "%a_scriptdir%\PlacesBarBackup.reg" HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar
}

;---------------------------------------------------------------------------------------------------------------

RestoreFolderBand()
{
	global Vista7
	if(Vista7)
	{
		if(FileExist(a_scriptdir "\FolderTypesBackup.reg"))
		{
			RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes
			runwait regedit.exe /S "%a_scriptdir%\FolderTypesBackup.reg",, Hide
			runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes /revoke=S-1-5-32-545,,Hide
			runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes /grant=S-1-5-32-545=R,,Hide
		}
		else
			MsgBox %a_scriptdir%\FolderTypesBackup.reg not found, failed to restore registry keys!
	}
}
RestoreFolderBandButtons()
{
	global Vista7
	if(Vista7)
	{
		if(FileExist(a_scriptdir "\FolderBandBackup.reg"))
		{
			RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore
			runwait regedit.exe /S "%a_scriptdir%\FolderBandBackup.reg",, Hide
			runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore /revoke=S-1-5-32-545,,Hide
			runwait subinacl /subkeyreg HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore /grant=S-1-5-32-545=R,,Hide
		}
		else
			MsgBox %a_scriptdir%\FolderBandBackup.reg not found, failed to restore registry keys!
	}
}
RestorePlacesBar()
{
	global Vista7
	if(Vista7)
	{
		;The registry key which should be restored here doesn't have to exist, if it wasn't customized it seems
		if(FileExist(a_scriptdir "\PlacesBarBackup.reg"))
			runwait regedit.exe /S "%a_scriptdir%\PlacesBarBackup.reg",, Hide
		else
		{
			RegDelete, HKCU, Software\Microsoft\Windows\CurrentVersion\Policies\comdlg32\Placesbar
		}
	}
}
