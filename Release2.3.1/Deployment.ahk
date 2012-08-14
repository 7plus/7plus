AutoUpdate()
{	
	global MajorVersion,MinorVersion,BugfixVersion
	outputdebug AutoUpdate
	if(IsConnected())
	{
		random, rand
		;Disable keyboard hook to increase responsiveness
		Suspend, On
		URLDownloadToFile, http://7plus.googlecode.com/files/NewVersion.ini?x=%rand%, %A_Temp%\7plus\Version.ini
		Suspend, Off
		if(!Errorlevel && FileExist(A_Temp "\7plus\Version.ini"))
		{
			IniRead, tmpMajorVersion, %A_Temp%\7plus\Version.ini, Version,MajorVersion
			IniRead, tmpMinorVersion, %A_Temp%\7plus\Version.ini, Version,MinorVersion
			IniRead, tmpBugfixVersion, %A_Temp%\7plus\Version.ini, Version,BugfixVersion
			Update := (CompareVersion(tmpMajorVersion, MajorVersion, tmpMinorVersion, MinorVersion, tmpBugfixVersion, BugfixVersion) = 1)
			if(Update)
			{
				IniRead, UpdateMessage, %A_Temp%\7plus\Version.ini, Version,UpdateMessage
				if(UpdateMessage != "ERROR")
				{
					MsgBox,4,,%UpdateMessage%
					IfMsgBox Yes
					{
						Progress zh0 fs18,Downloading Update, please wait.
						Sleep 10
						;Versions pre 2.4.0 have the following, erroneous code, and thus need a separate updating script that downloads the correct update:
						;~ if(A_IsCompiled)
							;~ IniRead, Link, %A_Temp%\7plus\Version.ini, Version,Link
						;~ else
							;~ IniRead, Link, %A_Temp%\7plus\Version.ini, Version,LinkSource
						
						link := "Link" (!A_IsCompiled ? "Source" : "") (A_PtrSize = 8 ? "x64" : "x86")
						IniRead, Link, %A_Temp%\7plus\Version.ini, Version,%Link%
						
						URLDownloadToFile, %link%?x=%rand%,%A_Temp%\7plus\Updater.exe
						if(!Errorlevel)
						{
							;Write config path and script dir location to temp file to let updater know
							IniWrite, % Settings.ConfigPath, %A_Temp%\7plus\Update.ini, Update, ConfigPath
							IniWrite, %A_ScriptDir%, %A_Temp%\7plus\Update.ini, Update, ScriptDir
							Run %A_Temp%\7plus\Updater.exe,,UseErrorlevel
							OnExit
							ExitApp
						}
						else
						{
							MsgBox Error while updating. Make sure http://7plus.googlecode.com is reachable.
							Progress, Off
						}
					}
				}
				else
					MsgBox Error while updating. Make sure http://7plus.googlecode.com is reachable.
			}
		}
		else
			MsgBox Could not download version info. Make sure http://7plus.googlecode.com is reachable.
	}
}
PostUpdate()
{
	global MajorVersion,MinorVersion,BugfixVersion
	outputdebug PostUpdate
	;If there is an Updater.exe in 7plus temp directory, it is likely that an update was performed.
	if(FileExist(A_TEMP "\7plus\Updater.exe"))
	{
		;Check if the version from downloaded version.ini in temp directory matches the version of the current instance. If yes, an update has been performed.
		IniRead, tmpMajorVersion, %A_TEMP%\7plus\Version.ini,Version,MajorVersion
		IniRead, tmpMinorVersion, %A_TEMP%\7plus\Version.ini,Version,MinorVersion
		IniRead, tmpBugfixVersion, %A_TEMP%\7plus\Version.ini,Version,BugfixVersion
		if(CompareVersion(tmpMajorVersion, MajorVersion, tmpMinorVersion, MinorVersion, tmpBugfixVersion, BugfixVersion) = 0)
		{
			ApplyUpdateFixes()
			if(FileExist(A_ScriptDir "\Changelog.txt"))
			{
				MsgBox,4,, Update successful. View Changelog?
				IfMsgBox Yes
					run %A_ScriptDir%\Changelog.txt,, UseErrorlevel
			}
		}		
		FileDelete %A_TEMP%\7plus\Updater.exe
	}
	FileDelete %A_TEMP%\7plus\Version.ini
}
ApplyFreshInstallSteps()
{
	ApplyUpdateFixes()
}

;This function is called in 3 cases:
;A) Fresh installation
;B) After autoupdate has finished and 7plus is started again
;C) If the user manually extracted a newer version
ApplyUpdateFixes()
{
	global MajorVersion, MinorVersion, BugfixVersion, PatchVersion, XMLMajorVersion, XMLMinorVersion, XMLBugfixVersion, ClipboardList
	;On fresh installation, the versions are identical since a new Events.xml is used and no events patch needs to be applied
	;After autoupdate has finished, the XML version is lower and the events are patched
	;After manually overwriting 7plus, the XML version is lower and the events are patched
	if(XMLMajorVersion != "" && CompareVersion(XMLMajorVersion, MajorVersion, XMLMinorVersion, MinorVersion, XMLBugfixVersion, BugfixVersion) = -1)
	{		
		;apply release patch without showing messages
		if(FileExist(A_ScriptDir "\Events\ReleasePatch\" MajorVersion "." MinorVersion "." BugfixVersion ".0.xml")) 
		{
			;This will also set the XML version variables. 
			;In case this is triggered by an autoupdate, it will make sure that case C) won't be recognized afterwards.
			;This requires that the version is specified in the patch.
			EventSystem.Events.ReadEventsFile(A_ScriptDir "\Events\ReleasePatch\" MajorVersion "." MinorVersion "." BugfixVersion ".0.xml")
			
			;Upgrade from previous version resets the Patch version to 0
			PatchVersion := 0
			
			;Save the patched file immediately
			EventSystem.Events.WriteMainEventsFile()
		}
	}
	;Register shell extension quietly
	RegisterShellExtension(1)
	AddUninstallInformation()
	if(MajorVersion "." MinorVersion "." BugfixVersion = "2.3.0")
	{
		;Switch to new autorun method
		RegRead, key, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus
		if(WinVer >= WIN_Vista && key != "")
		{
			DisableAutorun()
			EnableAutorun()
		}				
	}
	else if(MajorVersion "." MinorVersion "." BugfixVersion = "2.4.0")
	{
		;Remove some old files that were renamed
		FileDelete, %A_ScriptDir%\Events\ExplorerButtons.xml
		FileDelete, %A_ScriptDir%\Events\FastFolders.xml
		FileDelete, %A_ScriptDir%\Events\WindowHandling.xml
		
		;Encrypt existing clipboard history
		ClipboardList := Array()
		ClipboardList.push := "Stack_Push"
		ClipboardList := Object("Base", ClipboardList)
		if(FileExist(Settings.ConfigPath "\Clipboard.xml"))
		{
			FileRead, xml, % Settings.ConfigPath "\Clipboard.xml"
			XMLObject := XML_Read(xml)
			;Convert empty and single arrays to real array
			if(!XMLObject.List.MaxIndex())
				XMLObject.List := IsObject(XMLObject.List) ? Array(XMLObject.List) : Array()		
			
			Loop % min(XMLObject.List.MaxIndex(), 10)
				ClipboardList.Insert(Decrypt(XMLObject.List[A_Index])) ;Read encrypted clipboard history
			XMLObject := Object("List",Array())
			Loop % min(ClipboardList.MaxIndex(), 10)
				XMLObject.List.Insert(Encrypt(ClipboardList[A_Index])) ;Store encrypted
			XML_Save(XMLObject, Settings.ConfigPath "\Clipboard.xml")
		}
	}
	else if(MajorVersion "." MinorVersion "." BugfixVersion = "2.5.0")
	{
		;Categories were changed so this file is no longer needed
		FileDelete, %A_ScriptDir%\Events\FTP.xml
	}
	else if(MajorVersion "." MinorVersion "." BugfixVersion = "2.6.0")
	{
		;These files were moved to different directories with this update
		FileDelete, %A_ScriptDir%\SetACL.exe
		FileDelete, %A_ScriptDir%\Explorer.dll
	}
}
AutoUpdate_CheckPatches()
{
	global MajorVersion, MinorVersion, BugfixVersion, PatchVersion
	;Disable keyboard hook to increase responsiveness
	FileCreateDir, % Settings.ConfigPath "\Patches"
	FileDelete, % Settings.ConfigPath "\PatchInfo.xml"	
	random, rand
	if(IsConnected("http://7plus.googlecode.com/files/PatchInfo.xml?x=" rand))
	{
		URLDownloadToFile, http://7plus.googlecode.com/files/PatchInfo.xml?x=%rand%, % Settings.ConfigPath "\PatchInfo.xml"
		if(!Errorlevel)
		{
			FileRead, xml, % Settings.ConfigPath "\PatchInfo.xml"
			XMLObject := XML_Read(xml)
		}
	}
	Update := Object("Message", "") ;Object storing update message
	patch := false
	Loop ;Iteratively apply all available patches
	{
		version := MajorVersion "." MinorVersion "." BugfixVersion "." (PatchVersion + 1)
		if(IsObject(XMLObject) && !FileExist(Settings.ConfigPath "\Patches\" version ".xml") && XMLObject.HasKey(version)) ;If a new patch is available online, download it to patches directory
		{
			PatchURL := XMLObject[version]
			if(IsConnected(PatchURL "?x=" rand))
				URLDownloadToFile, %PatchURL%?x=%rand%, % Settings.ConfigPath "\Patches\" version ".xml"
		}
		if(FileExist(Settings.ConfigPath "\Patches\" version ".xml")) ;If the patch exists in patches directory (does not mean it has been downloaded now, they are stored)
		{
			EventSystem.Events.ReadEventsFile(Settings.ConfigPath "\Patches\" version ".xml","", Update)
			PatchVersion++
			EventSystem.Events.WriteMainEventsFile()
			patch := true
			continue
		}
		break
	}
	if(patch)
		MsgBox, % "A Patch has been installed that updates the event configuration. Applied changes:`n" Update.Message
}


AddUninstallInformation()
{
	global MajorVersion, MinorVersion, BugfixVersion, PatchVersion
	if(ApplicationState.IsPortable)
		return
	RegWrite, REG_SZ, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus, DisplayName, 7plus V.%MajorVersion%.%MinorVersion%.%BugfixVersion%.%PatchVersion%
	RegWrite, REG_DWORD, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus, NoModify, 1
	RegWrite, REG_DWORD, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus, NoRepair, 1
	RegWrite, REG_SZ, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus, UninstallString, 1, "%A_ScriptDir%\Uninstall.exe"
}

RemoveUninstallInformation()
{
	if(ApplicationState.IsPortable)
		return
	RegDelete, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus
}

IsAutorunEnabled()
{
	if(WinVer >= WIN_Vista)
	{
		try
		{
			objService := ComObjCreate("Schedule.Service") 
			objService.Connect()
			objFolder := objService.GetFolder("\")
			objTask := objFolder.GetTask("7plus Autorun")
			return objTask.Name != ""
		}
		catch e
			return false
	}
	else
	{
		RegRead, key, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus
		return key != ""
	}
}

DisableAutorun()
{
	RegDelete, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus
	if(WinVer >= WIN_Vista)
	{
		objService := ComObjCreate("Schedule.Service") 
		objService.Connect()
		objFolder := objService.GetFolder("\")
		objFolder.DeleteTask("7plus Autorun", 0)
	}
}

EnableAutorun()
{
	if(IsAutorunEnabled())
		DisableAutorun() ;Better re-enable it if paths have changed
	if(WinVer < WIN_Vista)
	{
		if(A_IsCompiled)
			RegWrite, REG_SZ, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus, %A_ScriptFullPath%
		else
			RegWrite, REG_SZ, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus, "%A_AhkPath%" "%A_ScriptFullPath%"
	}
	else
	{
		TriggerType = 9   ; trigger on logon. 
		ActionTypeExec = 0  ; specifies an executable action. 
		TaskCreateOrUpdate = 6 
		Task_Runlevel_Highest = 1 

		objService := ComObjCreate("Schedule.Service") 
		objService.Connect() 

		objFolder := objService.GetFolder("\") 
		objTaskDefinition := objService.NewTask(0) 

		principal := objTaskDefinition.Principal 
		principal.LogonType := 1    ; Set the logon type to TASK_LOGON_PASSWORD 
		principal.RunLevel := Task_Runlevel_Highest  ; Tasks will be run with the highest privileges. 

		colTasks := objTaskDefinition.Triggers
		objTrigger := colTasks.Create(TriggerType) 
		colActions := objTaskDefinition.Actions 
		objAction := colActions.Create(ActionTypeExec) 
		objAction.ID := "7plus Autorun" 
		if(A_IsCompiled)
			objAction.Path := """" A_ScriptFullPath """"
		else
		{
			objAction.Path := """" A_AhkPath """"
			objAction.Arguments := """" A_ScriptFullPath """"
		}
		objAction.WorkingDirectory := A_ScriptDir
		objInfo := objTaskDefinition.RegistrationInfo 
		objInfo.Author := "7plus" 
		objInfo.Description := "Run 7plus through task scheduler to prevent UAC dialog." 
		objSettings := objTaskDefinition.Settings 
		objSettings.Enabled := True 
		objSettings.Hidden := False 
		objSettings.StartWhenAvailable := True 
		objSettings.ExecutionTimeLimit := "PT0S"
		objSettings.DisallowStartIfOnBatteries := False
		objSettings.StopIfGoingOnBatteries := False
		objFolder.RegisterTaskDefinition("7plus Autorun", objTaskDefinition, TaskCreateOrUpdate , "", "", 3 ) 
	}
}