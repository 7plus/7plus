;Main autoupdate function. Possibly downloads an update and runs the updater executable.
AutoUpdate()
{	
	global MajorVersion,MinorVersion,BugfixVersion
	outputdebug AutoUpdate
	BaseURL := "http://7plus.googlecode.com"
	if(IsConnected())
	{
		random, rand
		NewVersionPath := "/files/NewVersion.ini?x=" rand
		;Disable keyboard hook to increase responsiveness
		Suspend, On
		URLDownloadToFile, %BaseURL%%NewVersionPath%, %A_Temp%\7plus\Version.ini
		Suspend, Off
		if(!Errorlevel && FileExist(A_Temp "\7plus\Version.ini"))
		{
			IniRead, tmpMajorVersion, %A_Temp%\7plus\Version.ini, Version, MajorVersion
			IniRead, tmpMinorVersion, %A_Temp%\7plus\Version.ini, Version, MinorVersion
			IniRead, tmpBugfixVersion, %A_Temp%\7plus\Version.ini, Version, BugfixVersion
			IniRead, tmpBuildVersion, %A_Temp%\7plus\Version.ini, Version, BuildVersion
			DifferentVersion := CompareVersion(tmpMajorVersion, MajorVersion, tmpMinorVersion, MinorVersion, tmpBugfixVersion, BugfixVersion)
			BetaUpdate := DifferentVersion >= 0 && tmpBuildVersion > BuildVersion && Settings.General.UseBeta
			Update := DifferentVersion = 1
			if(BetaUpdate)
			{
				IniRead, UpdateMessage, %A_Temp%\7plus\Version.ini, Version, BetaUpdateMessage
				IniRead, Link, %A_Temp%\7plus\Version.ini, Version, % "BetaLink" (!A_IsCompiled ? "Source" : "") (A_PtrSize = 8 ? "x64" : "x86")
			}
			else if(Update)
			{
				IniRead, UpdateMessage, %A_Temp%\7plus\Version.ini, Version, UpdateMessage
				IniRead, Link, %A_Temp%\7plus\Version.ini, Version, % "Link" (!A_IsCompiled ? "Source" : "") (A_PtrSize = 8 ? "x64" : "x86")
			}
			if(Update || BetaUpdate)
			{
				if(UpdateMessage != "ERROR")
				{
					MsgBox, 4, , %UpdateMessage%
					IfMsgBox Yes
					{
						Progress, zh0 fs18, Downloading Update, please wait.
						Sleep 10
						;Versions before 2.4.0 have the following, erroneous code, and thus need a separate updating script that downloads the correct update:
						;~ if(A_IsCompiled)
							;~ IniRead, Link, %A_Temp%\7plus\Version.ini, Version,Link
						;~ else
							;~ IniRead, Link, %A_Temp%\7plus\Version.ini, Version,LinkSource
						
						URLDownloadToFile, %link%?x=%rand%, %A_Temp%\7plus\Updater.exe
						if(!Errorlevel)
						{
							;Write config path and script dir location to temp file to let updater know
							IniWrite, % Settings.ConfigPath, %A_Temp%\7plus\Update.ini, Update, ConfigPath
							IniWrite, %A_ScriptDir%, %A_Temp%\7plus\Update.ini, Update, ScriptDir
							Run %A_Temp%\7plus\Updater.exe, , UseErrorlevel
							OnExit
							ExitApp
						}
						else
						{
							MsgBox, Error while updating. Make sure %BaseURL% is reachable.
							Progress, Off
						}
					}
				}
				else
					MsgBox, Error while updating. Make sure %BaseURL% is reachable.
			}
		}
		else
			MsgBox, Could not download version info. Make sure %BaseURL% is reachable.
	}
}

;This function carries out all necessary steps after an update has been installed. This code is executed in the updated script.
PostUpdate()
{
	global MajorVersion, MinorVersion, BugfixVersion
	outputdebug PostUpdate
	;If there is an Updater.exe in 7plus temp directory, it is likely that an update was performed.
	if(FileExist(A_TEMP "\7plus\Updater.exe"))
	{
		;Check if the version from downloaded version.ini in temp directory matches the version of the current instance. If yes, an update has been performed.
		IniRead, tmpMajorVersion, %A_TEMP%\7plus\Version.ini, Version, MajorVersion
		IniRead, tmpMinorVersion, %A_TEMP%\7plus\Version.ini, Version, MinorVersion
		IniRead, tmpBugfixVersion, %A_TEMP%\7plus\Version.ini, Version, BugfixVersion
		IniRead, tmpBuildVersion, %A_TEMP%\7plus\Version.ini, Version, BuildVersion
		if(CompareVersion(tmpMajorVersion, MajorVersion, tmpMinorVersion, MinorVersion, tmpBugfixVersion, BugfixVersion) = 0 && (!Settings.General.UseBeta || tmpBuildVersion = BuildVersion))
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
	;Check if the user did a manual upgrade by extracting an archive over the previous 7plus installation
	else if(CompareVersion(XMLMajorVersion, MajorVersion, XMLMinorVersion, MinorVersion, XMLBugfixVersion, BugfixVersion) = -1)
		ApplyUpdateFixes()

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
	global MajorVersion, MinorVersion, BugfixVersion
	ApplyReleasePatch()

	;Register shell extension quietly
	RegisterShellExtension(1)
	AddUninstallInformation()

	;Version specific code
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
			XMLObject := Object("List", Array())
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

;This function applies the release patch during the updating process.
;It will do nothing on new installations where the event file is already up to date.
ApplyReleasePatch()
{
	global MajorVersion, MinorVersion, BugfixVersion, BuildVersion, XMLMajorVersion, XMLMinorVersion, XMLBugfixVersion, XMLBuildVersion
	;On fresh installation, the versions are identical since a new Events.xml is used and no events patch needs to be applied
	;After autoupdate has finished, the XML version is lower and the events are patched
	;After manually overwriting 7plus, the XML version is lower and the events are patched
	DifferentVersion := CompareVersion(XMLMajorVersion, MajorVersion, XMLMinorVersion, MinorVersion, XMLBugfixVersion, BugfixVersion)
	if(XMLMajorVersion != "" && DifferentVersion = -1 || (DifferentVersion <= 0 && Settings.UseBeta && XMLBuildVersion < BuildVersion))
	{		
		;apply release patch without showing messages
		if(FileExist(A_ScriptDir "\Events\ReleasePatch\" MajorVersion "." MinorVersion "." BugfixVersion "." BuildVersion ".xml")) 
		{
			;This will also set the XML version variables.
			;In case this is triggered by an autoupdate, it will make sure that case C) won't be recognized afterwards.
			;This requires that the version is specified in the patch.
			EventSystem.Events.ReadEventsFile(A_ScriptDir "\Events\ReleasePatch\" MajorVersion "." MinorVersion "." BugfixVersion "." BuildVersion ".xml")
			
			;Save the patched file immediately
			EventSystem.Events.WriteMainEventsFile()
		}
	}
}

AddUninstallInformation()
{
	global MajorVersion, MinorVersion, BugfixVersion, BuildVersion
	if(ApplicationState.IsPortable)
		return
	RegWrite, REG_SZ, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7plus, DisplayName, 7plus V.%MajorVersion%.%MinorVersion%.%BugfixVersion%.%BuildVersion%
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