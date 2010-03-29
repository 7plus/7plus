;Call this to use debug view
DebuggingStart()
{	
	CoordMode, Mouse, Relative 
	;Debug view
	a_scriptPID := DllCall("GetCurrentProcessId")	; get script's PID
	ifwinexist, DebugView on ; kill it if the debug viewer is running from an older instance
		{
		winactivate, DebugView on
		Winwaitactive, DebugView on
		winclose, DebugView on
		}
	run, %A_ScriptDir%\DebugView\Dbgview.exe /f
	winwait, DebugView on
	winactivate, DebugView on
	Winwaitactive, DebugView on
	sendinput, !E{down}{down}{down}{down}{down}{Enter}
	winwait, DebugView Filter
	winactivate, DebugView Filter
	Winwaitactive, DebugView Filter 
	MouseGetPos, x,y
	mouseclick, left, 125, 85,,0
	MouseMove, x,y,0
	send, [%a_scriptPID%*{Enter}
	Coordmode, Mouse, Screen
}

;output debug command->function wrapper
OutputDebug(text)
{
	global DebugEnabled
	if(DebugEnabled)
		OutputDebug %text%
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
