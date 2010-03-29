IsMouseOverStartButton()
{
	MouseGetPos,,,win
	WinGetClass,class,ahk_id %win%
	return class="button"
}
GetTaskbarDirection()
{
	WinGetPos X, Y, Width, Height, ahk_class Shell_TrayWnd
	x:=(x+x+width)/2
	y:=(y+y+height)/2
	if(x<0.1*A_ScreenWidth)
		return 1
	if(x>0.9*A_ScreenWidth)
		return 2
	if(y<0.1*A_ScreenHeight)
		return 3
	if(y>0.9*A_ScreenHeight)
		return 4
	if(IsFullscreen("A",false,false))
		return -1
	msgbox Invalid Taskbar position detected!
	return 0
}
IsMouseOverTaskList()
{
	WinGetPos , X, Y,,, ahk_class Shell_TrayWnd
	if(A_OSVersion="WIN_7")
		ControlGetPos , TaskListX, TaskListY, TaskListWidth, TaskListHeight, MSTaskListWClass1, ahk_class Shell_TrayWnd
	else
		ControlGetPos , TaskListX, TaskListY, TaskListWidth, TaskListHeight, MSTaskSwWClass1, ahk_class Shell_TrayWnd
	;Transform to screen coordinates
	TaskListX+=X
	TaskListY+=Y
	MouseGetPos,x,y
	;outputdebug x %x% y %y% tlx %tasklistX% tly %tasklisty% tlw %tasklistwidth% tlh %tasklistheight% 
	;blah:=IsInArea(x,y,TaskListX,TaskListY,TaskListWidth,TaskListHeight)
	z:=GetTaskBarDirection()
	if(z=2||z=4)
		return IsMouseOverTaskbar() && IsInArea(x,y,TaskListX,TaskListY,TaskListWidth,TaskListHeight)
	if(z=1||z=3)
		return IsMouseOverTaskbar() && IsInArea(x,y,TaskListX,TaskListY,TaskListWidth,TaskListHeight)
	return false
}

IsMouseOverTray()
{
	MouseGetPos,x,y
	ControlGetPos , TrayX, TrayX, TrayWidth, TrayHeight, ToolbarWindow321, ahk_class Shell_TrayWnd
	z:=GetTaskBarDirection()
	if(z=2||z=4)
		return IsMouseOverTaskbar() && IsInArea(x,y,TrayX,TrayY,TrayWidth,TrayHeight)
	if(z=1||z=3)
		return IsMouseOverTaskbar() && IsInArea(x,y,TrayX,TrayY,TrayWidth,TrayHeight)
	return false
}

IsMouseOverClock()
{
	MouseGetPos, , , , ControlUnderMouse   
  outputdebug control under mouse: %ControlUnderMouse%
  result:=false
  if(ControlUnderMouse="TrayClockWClass1")
		result:=true
	outputdebug IsMouseOverClock()? %result%
	return result
}

IsMouseOverShowDesktop()
{
	MouseGetPos,x,y
	z:=GetTaskBarDirection()
	ControlGetPos , ShowDesktopX, ShowDesktopY, ShowDesktopWidth, ShowDesktopHeight, TrayShowDesktopButtonWClass1, ahk_class Shell_TrayWnd
	if(z=2||z=4)
		return IsMouseOverTaskbar() && IsInArea(x,y,ShowDesktopX,ShowDesktopY,ShowDesktopWidth,ShowDesktopHeight)
	if(z=1||z=3)
		return IsMouseOverTaskbar() && IsInArea(x,y,ShowDesktopX,ShowDesktopY,ShowDesktopWidth,ShowDesktopHeight)
	return false
}

IsMouseOverTaskbar()
{
	MouseGetPos, , , WindowUnderMouseID 
  WinGetClass, winclass , ahk_id %WindowUnderMouseID%
  result:=false
  if(winclass="Shell_TrayWnd")
  	result:=true
	return result
}

IsMouseOverFreeTaskListSpace()
{
	Critical
	global result,IsRunning,Vista7
	
	/*
	while(IsRunning=true)
	{
		outputdebug wait for finish
		Sleep 10
	}
	*/
	SetWinDelay 0
	SetKeyDelay 0
	SetMouseDelay 0
	/*
	if(result!="")
	{
		IsRunning:=false
		outputdebug return cached result
		return %result%
	}
	*/
	if(!IsMouseOverTaskList())
	{
		IsRunning:=false
		return false
	}
	if(!Vista7)
	{
		x:=HitTest()
		outputdebug x %x%
		return x<0
	}
	IsRunning:=true
	Send {RButton}
	result:=0
	x:=0
	while(x<50)
	{
		if(WinExist("ahk_class #32768")) ;ahk_id #32768"))
		{
			result:=true
			outputdebug break
			break
		} 
		else if(WinActive("ahk_id DV2ControlHost"))
		{
			result:=false
			outputdebug break
			break
		}
		outputdebug sleep %x%
		x+=10
		sleep 10
	}
	outputdebug return with %result% and send esc
	while(WinExist("ahk_class #32768")||WinActive("ahk_class DV2ControlHost"))
		Send {Esc}
	IsRunning:=false
	return %result%
}

;This hackish function figures out what taskbar element was clicked.
;It should only be called when there was an actual click on the taskbar (Use IsMouseOverTaskbar for this)
;Return values are: Timeout, Start, Multi, Empty, Single, Tray, Clock, ShowDesktop
GetClickedTaskbarElement()
{
	global listening, ClickedTaskbarElement
	Outputdebug taskbarclick
	ClickedTaskbarElement:="Checking"
	listening:=1
	SetTimer, CheckShellMessage , 200
	loop
	{
		if(ClickedTaskbarElement!="Checking")
			return ClickedTaskbarElement
		Sleep 10
		if(A_Index>110)
			break
	}
	return "Timeout"
}

CheckShellMessage:
SetTimer, CheckShellMessage , off
outputdebug timer
If(listening)
{
	outputdebug and listening
	listening:=false
	TaskbarClicked()
}
return

TaskbarClicked()
{
	global ClickedTaskbarElement
	outputdebug TaskbarClicked
	
	;outputdebug TrayX: %trayx% Tray Width: %traywidth% mouse x: %x%
	WinGetClass classname, A
	;outputdebug ActiveWindow: %classname%
	if (IsMouseOverStartButton())
	{
		OutputDebug startbutton clicked
		ClickedTaskbarElement:="Start"
	}
	else if (IsMouseOverTaskList())
	{
		if WinActive("ahk_class TaskListThumbnailWnd")
		{
			ClickedTaskbarElement:="Multi"
			OutputDebug multibutton clicked
			
		}	
		else if WinActive("ahk_class Shell_TrayWnd")
		{
			ClickedTaskbarElement:="Empty"
			OutputDebug empty space clicked
		}
		else
		{
			ClickedTaskbarElement:="Single"
			OutputDebug Single button clicked
		}
	}
	else if (IsMouseOverTray())
	{
		ClickedTaskbarElement:="Tray"
		OutputDebug, Tray clicked
	}
	else if (IsMouseOverClock())
	{
		ClickedTaskbarElement:="Clock"
		OutputDebug Clock clicked
	}
	else if (IsMouseOverShowDesktop())
	{
		ClickedTaskbarElement:="ShowDesktop"
		OutputDebug Show desktop clicked
	}	
}

;Function gets called on windows_activated shell message
TaskbarShellMessage() 
{
	global listening
	if(listening){
	outputdebug and listening
	;need a IsMouseOverTaskbar check here?
		listening:=false
		TaskbarClicked()
	}
}
