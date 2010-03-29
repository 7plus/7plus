;Check screen borders/corners for Aero Flip 3D and Slide Windows
hovercheck: 
HoverCheck()
return

HoverCheck()
{
	global HKSlideWindows,Vista7,MouseX,MouseY,AeroFlipTime
	static lastx,lasty
	MouseGetPos, MouseX,MouseY,win,control
	WinGetClass, class, ahk_id %win%
	x:=IsFullscreen("A",false,false)
	if(!x)
	{
		if(MouseX != lastx || MouseY != lasty)
			SlideWindows_OnMouseMove(MouseX,MouseY)
		SlideWindows_CheckWindowState()
	}
  if (Vista7 && !x && (MouseX != lastx || MouseY != lasty) && MouseX=0 && MouseY=0 && !WinActive("ahk_class Flip3D"))
  { 
  	z:=-(AeroFlipTime*1000+1)
    SetTimer, hovering, %z%
  } 
  lastx := MouseX
  lasty := MouseY
	return
}
;Hovering timer for Aero Flip 3D
hovering: 	
	if (GetKeyState("LButton") || GetKeyState("RButton") || WinActive("ahk_class Flip3D")) 
      return 
  if(MouseX!=0||MouseY!=0)
		return 
	if(IsFullscreen("A",false,false))
		return
  Send ^#{Tab} 
	SetTimer, hovering, off
  return

;Key remappers for Aero Flip 3D
#IfWinActive, ahk_class Flip3D 
Space::Enter 
Left::Right 
Right::Left 
Down::Up 
Up::Down 
RButton::Esc 
RWin::Esc
LWin::Esc
WheelUp::WheelDown
WheelDown::WheelUp
#if

;ctrl+v in cmd->paste, alt+F4 in cmd->close
#if HKImproveConsole && WinActive("ahk_class ConsoleWindowClass")
^v::
	Coordmode,Mouse,Relative
	MouseGetPos, MouseX, MouseY
	Click right 40,40
	Send {Down 3}
	send {Enter}
	MouseMove MouseX,MouseY
	return
!F4::
	WinClose, A
	return
#If

;Alt+F5: Kill active window
#if HKKillWindows
!F5::
	CloseKill()
	return
#if
;Force kill program on Alt+F5 and on right click close button
CloseKill()
{
	WinGet, pid, pid, A
	WinKill A, , 1
	WinGet, pid1 , pid, A
	if(pid=pid1)
		Process close, %pid1%
}

;Close on middle click titlebar
TitleBarClose()
{
	global
	if(!HKTitleClose)
		return false
	x:=MouseHittest()
	if(x=2)
		WinClose, A
	else
		return false
	return true
}

;Middle click on taskbutton->close task
TaskButtonClose()
{
	global
	outputdebug taskbuttonclose
	if(HKMiddleClose && IsMouseOverTaskList())
	{
		if(A_OSVersion="WIN_7")
			Send {Shift down}
		click right
		while(!IsContextMenuActive())
			sleep 10
		if(A_OSVersion="WIN_7")
			Send {Shift up}
		Send {up}{enter}
		return true
	}
	outputdebug not handled
	return false
}

;Flash Windows activation
#if HKFlashWindow && BlinkingWindows.len()>0 && !IsFullscreen()
Capslock::
	z:=BlinkingWindows[1]
	WinActivate ahk_id %z%
	return
#if

;Current/Previous Window toggle
#if HKToggleWindows && (!HKFlashWindow || BlinkingWindows.len()=0) && !IsFullscreen()
Capslock::WinActivate ahk_id %PreviousWindow%
#if

;RButton on title bar -> toggle always on top
#if HKToggleAlwaysOnTop
~RButton::
	x:=MouseHittest()
  ;If we hit something, we swallow the click, and need that toggle var therefore
	If (x=2) ;,3,8,9,20,21 ; in titlebar enclosed area - top of window 
  {  
    WinSet, AlwaysOnTop, toggle, A
    ;outputdebug clicked on title bar, toggle always on top and cancel menu
    SendInput {Escape} ;Escape is needed to suppress the annoying win7 menu on titlebar right click     
  }
	else if(x=20 && HKKillWindows)
  	CloseKill()  	
	Return
#if

