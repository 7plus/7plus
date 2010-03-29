,;Show calendar when event notification pops up
CalendarShellHook(wParam, lParam)
{
	global ReplaceCalendar, CalendarPID
	if(wParam=6)
	{
		if (ReplaceCalendar)
		{
			WinGet, pid,pid,ahk_id %lParam%
			if(pid=CalendarPID)
			{
				WinShow ahk_id %lParam%
				WinActivate ahk_id %lParam%
			}
		}
	}
}

;Click on Clock -> start calendar
#if ReplaceCalendar && IsMouseOverClock()
LButton::ClockClick()	
#if
ClockClick()
{
	global CalendarCommand, CalendarPID, CalendarClass
	outputdebug click on clock
	DetectHiddenWindows, on
	SplitCommand(CalendarCommand,cmd,args)
	cmd:=ExpandEnvVars(cmd)
	outputdebug cmd %cmd%
	if WinExist("ahk_class " CalendarClass)
	{
		WinGet,winStyle,Style, ahk_class %CalendarClass%
    visible := winStyle & 0x10000000 
    WingetTitle, title, ahk_class %calendarclass%
    outputdebug window exists and is visible: %visible% title: %title%
    if (visible)
    	WinHide ahk_class %CalendarClass%
    else
    {
			WinShow ahk_class %CalendarClass%
			WinActivate ahk_class %CalendarClass%
    }		
	}
	else if(FileExist(cmd))
	{   
		RunCalendar()
	}
	else
		Send {LButton}
	return
}

;Starts calendar in hidden mode
RunCalendar()
{
	global CalendarCommand,CalendarClass,ReplaceCalendar, CalendarPID	
	outputdebug runcalendar()
	DetectHiddenWindows, On	
	SplitCommand(CalendarCommand,cmd,args)
	cmd:=ExpandEnvVars(cmd) 
	if (ReplaceCalendar && FileExist(cmd))
	{
		cmd:=Quote(cmd) args
		outputdebug run calendar
		run, %cmd%,,Hide,CalendarPID
		
		x:=0
		while(x<10000)
		{
			id:=WinExist("ahk_class " CalendarClass)
			if(id)
			{
				Winget, pid,pid,ahk_class %CalendarClass%
				if(pid=CalendarPID)
				{
					WinGet,style,style,ahk_class %CalendarClass%
					if(style&0x10000000)
						break
				}
			}
			Sleep 20
			x+=20
		}
		outputdebug run pid %Calendarpid%, acquired pid %pid%
		outputdebug hide %x%
		winhide ahk_class %CalendarClass%
	}
}

;Stops calendar on shutdown
KillCalendar()
{
	global CalendarPID
	DetectHiddenWindows, On
	if (WinExist("ahk_pid " CalendarPID))
	{
		winclose ahk_pid %CalendarPID%
	}
}

;catch close and min button on calendar app
#if ReplaceCalendar && IsMouseOverCalendar()
LButton::
  z:=MouseHittest()
  ;If we hit something, we swallow the click and hide the window instead
	If (z=8 || z=20 ) ;8,20; min and max button
	{
		outputdebug hide %CalendarClass%
  	WinHide, A
  }
  else
  {
  	MouseClick, , , , , , D
  	while(GetKeyState("LButton", "P"))
  		Sleep 50
  	MouseClick, , , , , , U
  }
	Return
#if

IsMouseOverCalendar()
{
	global CalendarPID, ReplaceCalendar
	MouseGetPos, , , WindowUnderMouseID 
	WinGet, pid,pid, ahk_id %WindowUnderMouseID%
	outputdebug cpid %calendarpid% pid %pid%
  if(ReplaceCalendar && CalendarPID && CalendarPID=pid)
		return true
	return false
}
