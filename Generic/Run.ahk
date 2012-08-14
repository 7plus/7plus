;Generic Run interface for subevents. They can implement this interface like this:
;static _ImplementsRun := ImplementRunInterface(CSubEvent)
;It's important to use a "_" or "tmp" at the start of the name to mark this property as temporary so it won't be saved.
ImplementRunInterface(Run)
{	
	Run.WaitForFinish := false
	Run.RunAsAdmin := false
	Run.Command := "cmd.exe"
	Run.WorkingDirectory := ""
	if(Run.HasKey("__Class"))
	{
		Run.RunExecute := Func("Run_Execute")
		Run.RunDisplayString := Func("Run_DisplayString")
		Run.RunGUIShow := Func("Run_GUIShow")
		Run.RunGUISubmit := Func("Run_GUISubmit")
	}
}

Run_Execute(SubEvent, Event)
{
	if(!SubEvent.tmpPid)
	{
		command := Event.ExpandPlaceholders(SubEvent.Command)
		WorkingDirectory := Event.ExpandPlaceholders(SubEvent.WorkingDirectory)
		if(SubEvent.WaitForFinish)
		{
			SubEvent.tmpPid := Run(command, WorkingDirectory, "", !SubEvent.RunAsAdmin)
			if(SubEvent.tmpPid) ;If retrieved properly
				return -1
			Notify("Run Command Error!", "Waiting for " command "failed", 5, NotifyIcons.Error)
			return 0
		}
		else
			Run(command, WorkingDirectory, "", !SubEvent.RunAsAdmin)
	}
	else
	{
		pid := SubEvent.tmpPid
		Process, Exist, %pid%
		if(ErrorLevel)
			return -1
	}
	return 1
}

Run_DisplayString(SubEvent)
{
	return "Run " SubEvent.Command
}

Run_GuiShow(SubEvent, GUI, GoToLabel = "")
{
	if(GoToLabel = "")
	{
		SubEvent.tmpRunGUI := GUI
		SubEvent.AddControl(GUI, "Text", "Text", "Enclose paths with spaces in quotes and append parameters in command field.")
		SubEvent.AddControl(GUI, "Edit", "Command", "", "", "Command:","Browse", "Action_Run_Browse", "Placeholders", "Action_Run_Placeholders")
		SubEvent.AddControl(GUI, "Edit", "WorkingDirectory", "", "", "Working Dir:","Browse", "Action_Run_Browse_WD", "Placeholders", "Action_Run_Placeholders_WD")
		SubEvent.AddControl(GUI, "Checkbox", "WaitForFinish", "Wait for finish", "", "")
		SubEvent.AddControl(GUI, "DropDownList", "RunAsAdmin", "-1: Current permissions|0: Standard User|1: Elevated", "", "Run as admin")
	}
	else if(GoToLabel = "Browse")
		SubEvent.SelectFile(SubEvent.tmpRunGUI, "Command", "Select File", "", 1)
	else if(GoToLabel = "Placeholders")
		ShowPlaceholderMenu(SubEvent.tmpRunGUI, "Command")
	else if(GoToLabel = "Browse_WD")
		SubEvent.Browse(SubEvent.tmpRunGUI, "WorkingDirectory", "Select working directory", "", 1)
	else if(GoToLabel = "Placeholders_WD")
		ShowPlaceholderMenu(SubEvent.tmpRunGUI, "WorkingDirectory")
}
Run_GUISubmit(SubEvent, GUI)
{
	SubEvent.Remove("tmpRunGUI")
}
Action_Run_Browse:
GetCurrentSubEvent().RunGuiShow("", "Browse")
return
Action_Run_Placeholders:
GetCurrentSubEvent().RunGuiShow("", "Placeholders")
return
Action_Run_Browse_WD:
GetCurrentSubEvent().RunGuiShow("", "Browse_WD")
return
Action_Run_Placeholders_WD:
GetCurrentSubEvent().RunGuiShow("", "Placeholders_WD")
return

Run(Target, WorkingDir = "", Mode = "", NonElevated = -1) 
{
	outputdebug running: %Target%
	;run as current user
	if(WinVer < WIN_Vista || NonElevated = -1 || (!A_IsAdmin && NonElevated) || (A_IsAdmin && !NonElevated))
	{
		Run, %Target% , %WorkingDir%, %Mode% UseErrorLevel, v
		if(A_LastError)
			Notify("Error", "Error launching " Target, 5, NotifyIcons.Error)
		Return, v
	}
	
	;Run under explorer process as normal user
	if(A_IsAdmin && NonElevated)
		return RunAsUser(Target, WorkingDir, Mode)
	
	;Split command and argument
	SplitCommandLine(Target, Args)
	
	;Show UAC prompt and run elevated
	if(!A_IsAdmin && !NonElevated)
	{		
		If(RunAsAdmin(Target, args, WorkingDir)) ;UAC prompt confirmed
			return 0
	}
	;Still here, error
	Notify("Error", "Error launching " Target, 5, NotifyIcons.Error)
}

SplitCommandLine(ByRef Target, ByRef Args)
{
	;Split command and argument
	if(InStr(Target, """")=1 && InStr(Target, """",false,3)) ;command has quotes, split it
	{
		Args := SubStr(Target,InStr(Target, """", false, 3) + 2)
		Target := SubStr(Target, 2,InStr(Target, """", false, 3) - 2)
	}
	else if(InStr(Target, " ")) ;look for spaces after the command, e.g. "C:\Program Files\bla.exe -arg"
	{
		Args := SubStr(Target, InStr(Target, " ", false) + 1)
		Target := SubStr(Target, 1, InStr(Target, " ", false) - 1)
	}
	else
		Args := "" ;Single Command
}

GetWorkingDir(Command)
{
	WorkingDir := ""
	if(Exists := FileExist(Command) && !InStr(Exists, "D"))
		SplitPath, Command,, WorkingDir
	return WorkingDir
}
RunAsUser(Command, WorkingDir = "", Options = "")
{
	result := DllCall(Settings.DllPath "\Explorer.dll\CreateProcessMediumIL", Str, Command, Str, WorkingDir, Str, Options, "UInt")
	if(A_LastError = 740) ;ERROR_ELEVATION_REQUIRED
	{
		Run, %Command% , %WorkingDir%, %Mode% UseErrorLevel, v
		if(A_LastError)
			Notify("Error", "Error launching " Target, 5, NotifyIcons.Error)
		Return, v
	}
}
RunAsAdmin(target, args = "", WorkingDir = "")
{
	uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, target, str, args, str, WorkingDir, int, 1)
	return uacrep = 42 ;UAC dialog confirmed
}

;Opens a file by looking up the required command line in the registry and then using it.
;If not found, it will fall back by using a quoted path to the file as argument for the command line
OpenFileWithProgram(File, Program = "")
{
	SplitPath, Program, Name
	RegRead, command, HKCR, Applications\%Name%\shell\open\command
	if(command)
	{
		StringReplace, command, command, `%1, %File%
		command := ExpandPathPlaceholders(command)
		RunAsUser(command)
	}
	else if(Program)
		RunAsUser("""" Program """ """ File """")
	else
		ShellRun(File)
}

/*
  ShellRun by Lexikos
    requires: AutoHotkey_L
    license: http://creativecommons.org/publicdomain/zero/1.0/

  Credit for explaining this method goes to BrandonLive:
  http://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/
 
  Shell.ShellExecute(File [, Arguments, Directory, Operation, Show])
  http://msdn.microsoft.com/en-us/library/windows/desktop/gg537745
*/
ShellRun(prms*)
{
    shellWindows := ComObjCreate("{9BA05972-F6A8-11CF-A442-00A0C90A8F39}")
    
    ; Find desktop window object.
    VarSetCapacity(_hwnd, 4, 0)
    desktop := shellWindows.FindWindowSW(0, "", 8, ComObj(0x4003, &_hwnd), 1)
    
    ; Retrieve top-level browser object.
    if ptlb := ComObjQuery(desktop
        , "{4C96BE40-915C-11CF-99D3-00AA004AE837}"  ; SID_STopLevelBrowser
        , "{000214E2-0000-0000-C000-000000000046}") ; IID_IShellBrowser
    {
        ; IShellBrowser.QueryActiveShellView -> IShellView
        if DllCall(NumGet(NumGet(ptlb+0)+15*A_PtrSize), "ptr", ptlb, "ptr*", psv) = 0
        {
            ; Define IID_IDispatch.
            VarSetCapacity(IID_IDispatch, 16)
            NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
            
            ; IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
            DllCall(NumGet(NumGet(psv+0)+15*A_PtrSize), "ptr", psv
                , "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp)
            
            ; Get Shell object.
            shell := ComObj(9,pdisp,1).Application
            
            ; IShellDispatch2.ShellExecute
            shell.ShellExecute(prms*)
            
            ObjRelease(psv)
        }
        ObjRelease(ptlb)
    }
}