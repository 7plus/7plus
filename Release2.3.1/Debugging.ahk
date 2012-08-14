;Call this to use debug view
DebuggingStart()
{
	global ErrorCollector := new CErrorCollector()
	if(FileExist(A_ScriptDir "\DebugView\Dbgview.exe"))
	{
		CoordMode, Mouse, Relative 
		;Debug view
		a_scriptPID := DllCall("GetCurrentProcessId")	; get script's PID
		if(WinExist("ahk_class dbgviewClass")) ; kill it if the debug viewer is running from an older instance
		{
			winactivate, ahk_class dbgviewClass
			Winwaitactive, ahk_class dbgviewClass
			winclose, ahk_class dbgviewClass
			WinWaitNotActive ahk_class dbgviewClass
		}
		Run(A_ScriptDir "\DebugView\Dbgview.exe /f","", "UseErrorLevel")
		winwait, ahk_class dbgviewClass
		winactivate, ahk_class dbgviewClass
		Winwaitactive, ahk_class dbgviewClass
		sendinput, !E{down}{down}{down}{down}{down}{Enter}
		winwait, DebugView Filter
		winactivate, DebugView Filter
		Winwaitactive, DebugView Filter 
		ControlSetText, Edit1, [%a_scriptPID%*, A ;Set filter
		Send, {Enter}
		send, !M{Down}{Enter} ;Connect local
		Coordmode, Mouse, Screen
	}
	else
		Notify("Debugging", "DebugView not found!`nPlease make sure that it's located in %A_ScriptDir%\DebugView\Dbgview.exe,`nor disable debugging in the Settings.ini file.")
}

DebuggingEnd()
{
	global ErrorCollector
	ErrorCollector.OnExit()
}
;output debug command->function wrapper
OutputDebug(text)
{
	if(Settings.General.DebugEnabled)
		OutputDebug %text%
}

Assert(Condition, Message="")
{
	if(!Condition)
	{
		try
			throw Exception(Message, -1)
		catch e
			Msgbox % "Assertion failed at " e.File "#" e.Line ": " e.Message
	}
}
;Translates last win32 error to identifier by using errorcodes.err list in script dir
GetLastError()
{ 
	Err_code:=DllCall("GetLastError") 
	Loop, Read, %A_Scriptdir%\errorcodes.err 
	{ 
		FileReadLine, OutputVar, %A_Scriptdir%\errorcodes.err, %A_Index% 
		if (OutputVar = Err_code) 
		{ 
		  error_line_number:=A_Index+1    
		  FileReadLine, Error_msg, %A_Scriptdir%\errorcodes.err, %error_line_number% 
		  Return Err_code ": " Error_msg 
		  Break 
		} 
	} 
}

Class CErrorCollector
{
	static Errors := Array()
	__New()
	{
		return
		if(!IsObject(Settings) || !Settings.HasKey("ConfigPath"))
			return
		"".base.__Get := "".base.__Set := "".base.__Call := Func("CollectErrors")
		Loop, Read, % Settings.ConfigPath "\InvalidObjectAccess.log"
		{
			state := Mod(A_Index, 5)
			if(state = 1)
				Error := {File : A_LoopReadLine}
			else if(state = 2)
				Error.Line := A_LoopReadLine
			else if(state = 3)
				Error.Key := A_LoopReadLine
			else if(state = 4)
				Error.Value := A_LoopReadLine
			else if(state = 5)
				Error.Type := A_LoopReadLine
			else if(state = 0)
			{
				Error.LineText := A_LoopReadLine
				this.Errors.Insert(Error)
			}
		}
	}
	OnExit()
	{
		return
		FileDelete, % Settings.ConfigPath "\InvalidObjectAccess.log"
		for index, Error in this.Errors
			FileAppend, % Error.File "`n" Error.Line "`n" Error.Key "`n" Error.Value "`n" Error.LineText "`n" Error.Type "`n", % Settings.ConfigPath "\InvalidObjectAccess.log"
	}
}
;Test for attempted key access on invalid objects
CollectErrors(nonobj, p1="", p2="", p3="", p4="")
{
	return
	ex := Exception("", -1)
	for index, Error in CErrorCollector.Errors
		if(Error.File = ex.File && Error.Line = ex.Line && Error.Key = p1 && Error.Type = "Access Error")
			return
	CErrorCollector.Errors.Insert(Error := {File : ex.File, Line : ex.Line, Key : p1, Value : nonobj, LineText : ex.What, Type : "Access Error"})
	FileAppend, % ex.File "`n" ex.Line "`n" p1 "`n" nonobj "`n" ex.What "`nAccess Error`n", % Settings.ConfigPath "\InvalidObjectAccess.log"
	if(CErrorDisplay.HasKey("Instance"))
	{
		CErrorDisplay.Instance.lstErrors.Items.Add("", Error.File, Error.Line, Error.Key, Error.Value, Error.LineText, Error.Type)
		CErrorDisplay.Instance.lstErrors.ModifyCol()
	}
}
Class CErrorDisplay extends CGUI
{
	lstErrors := this.AddControl("ListView", "lstErrors", "w1000 h500", "File|Line|Key|Value|LineText|Type")
	__New()
	{
		this.DestroyOnClose := true
		this.lstErrors.IndependentSorting := true
		this.CloseOnEscape := true
		for index, Error in CErrorCollector.Errors
			this.lstErrors.Items.Add("", Error.File, Error.Line, Error.Key, Error.Value, Error.LineText, Error.Type)
		this.lstErrors.ModifyCol()
		this.base.Instance := this
		this.Show()
	}
	PreClose()
	{
		base.Remove("Instance")
	}
	lstErrors_DoubleClick(Row)
	{
		if(!FileExist(A_ProgramFiles "\AutoHotkey\SciTE_beta5\Scite.exe"))
			return
		run % """" A_ProgramFiles "\AutoHotkey\SciTE_beta5\Scite.exe"" """ Row[1] """"
		Sleep 1000
		Send ^g
		Send % Row[2] "{Enter}"
	}
	lstErrors_KeyPress(Key)
	{
		if(Key = 46 && IsObject(this.lstErrors.SelectedItem))
		{
			CErrorCollector.Errors.Remove(this.lstErrors.SelectedIndex)
			this.lstErrors.Items.Delete(this.lstErrors.SelectedItem)
		}
	}
}

#if Settings.General.DebugEnabled
#i::
x := new CErrorDisplay()
return

#x::
debug := debug ? false : true
return

#y::
AttachDebugger()
return
#b::
msgbox % Callstack(5, 1)
return
#if

AttachDebugger()
{
	DetectHiddenWindows On
	PostMessage DllCall("RegisterWindowMessage", "str", "AHK_ATTACH_DEBUGGER"),,,, ahk_id %A_ScriptHwnd%
}
FormatMessageFromSystem(ErrorCode)
{
   VarSetCapacity(Buffer, 2000)
   DllCall("FormatMessage"
      , "UInt", 0x1000      ; FORMAT_MESSAGE_FROM_SYSTEM
      , "PTR", 0
      , "UInt", ErrorCode
      , "UInt", 0x800 ;LANG_SYSTEM_DEFAULT (LANG_USER_DEFAULT=0x400)
      , "Str", Buffer
      , "UInt", 500
      , "PTR", 0)
   Return Buffer
}
CallStack(deepness = 5, printLines = 1)
{
	loop % deepness
	{
		lvl := -1 - deepness + A_Index
		oEx := Exception("", lvl)
		oExPrev := Exception("", lvl - 1)
		FileReadLine, line, % oEx.file, % oEx.line
		if(oEx.What = lvl)
			continue
		stack .= (stack ? "`n" : "") "File '" oEx.file "', Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What) (printLines ? ":`n" line : "") "`n"
	}
	return stack
}