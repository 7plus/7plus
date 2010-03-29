;---------------------------------------------------------------------------------------------------------------
; Hotkeys and startup/exit
;---------------------------------------------------------------------------------------------------------------
#if HKSlideWindows && !Winactive("ahk_group DesktopGroup") && !Winactive("ahk_group TaskbarGroup") && !WinActive("ahk_class AutoHotkeyGUI") && !SlideWindows.IsASlideWindowInState(2,3) && !IsFullScreen("A",true,true)
#+Left::
	dir:=1
	if(SlideWindow:=SlideWindowArray.ContainsHWND(WinExist("A")))
		SlideWindow.SlideOutOrRelease(dir)
	else
		SlideWindowArray.Add(WinExist("A"),dir)
	return
#+Up::
	dir:=2
	if(SlideWindow:=SlideWindowArray.ContainsHWND(WinExist("A")))
		SlideWindow.SlideOutOrRelease(dir)
	else
		SlideWindowArray.Add(WinExist("A"),dir)
	return
#+Right::
	outputdebug #^right
	dir:=3
	if(SlideWindow:=SlideWindowArray.ContainsHWND(WinExist("A")))
		SlideWindow.SlideOutOrRelease(dir)
	else
		SlideWindowArray.Add(WinExist("A"),dir)
	return
#+Down::
	dir:=4
	if(SlideWindow:=SlideWindowArray.ContainsHWND(WinExist("A")))
		SlideWindow.SlideOutOrRelease(dir)
	else
		SlideWindowArray.Add(WinExist("A"),dir)
	return
#if
#n::SlideWindowArray.Print()

SlideWindows_Startup()
{	
	global SlideWin, SlideWindowArray, BlinkingWindows
	;Slide Directions:
	;0=no/invalid direction
	;1=left, 2=top, 3=right, 4=bottom
	
	;Slide States:
	;-1: not a slide window (yet)
	;0: Hidden
	;1: Visible
	;2: Sliding in
	;3: Sliding out
  If !SlideWin 
		SlideWin := Object("hwnd", 0, "dir", 0, "OrigX", -1 
		, "OrigY", -1 , "X", -1, "Y", -1 
		, "Width", -1, "Height", -1, "SlideState", -1
		, "KeepOpen", 0, "SlideOutOrRelease", "SlideWindow_SlideOutOrRelease"
		, "SlideOut", "SlideWindow_SlideOut", "SlideIn", "SlideWindow_SlideIn"
		, "Print", "SlideWindow_Print", "Release", "SlideWindow_Release"
		, "Move", "SlideWindow_Move", "UpdatePosition", "SlideWindow_UpdatePosition") 
	SlideWindowArray:=SlideWindowArray()
	BlinkingWindows:=Array()
}

SlideWindows_Exit()
{	
	global SlideWindowArray
	SlideWindowArray.ReleaseAll()
}

;---------------------------------------------------------------------------------------------------------------
; SlideWindow Functions
;---------------------------------------------------------------------------------------------------------------

SlideWindow_SlideOutOrRelease(SlideWindow,dir)
{
	Global SlideWindowArray
	outputdebug releaseorslideout
	;Recheck for free space in case size has changed somehow
	if(SlideWindow.dir=dir&&SlideWindowArray.IsSlideSpaceFree(SlideWindow.hwnd,dir))
		SlideWindow.SlideOut()
	else
		SlideWindow.Release()
}
SlideWindow_SlideOut(SlideWindow)
{
	Global SuspendWindowMoveCheck, SlideWindowArray
	SetWinDelay 0
	hwnd:=SlideWindow.hwnd
	WinGet, maxstate , minmax, ahk_id %hwnd%
	if(maxstate=1)
		return
	outputdebug slide window out %hwnd%
	outputdebug suspending check
	SuspendWindowMoveCheck:=true
	SlideWindow.SlideState:=3	
	SlideWindow.Move(SlideWindow.SlideInX,SlideWindow.SlideInY,SlideWindow.SlideOutX,SlideWindow.SlideOutY,2)
	SlideWindow.SlideState:=0
	;WinRestore ahk_id %hwnd%
	DllCall("ShowWindow","UInt", hwnd, "UINT", 11) ;#define SW_MINIMIZE         6 SW_FORCEMINIMIZE    11
	
	;DllCall("MoveWindow","UInt", hwnd, "UINT", toX, "UINT", toY, "UINT", Slidewindow.width, "UINT", SlideWindow.Height, "UINT", 1)
	;SlideWindow.UpdatePosition()
	outputdebug unsuspending check
	SuspendWindowMoveCheck:=false	
	;WinHide ahk_id %hwnd% ;Do it later
	outputdebug slide window out finished 
	SlideWindowArray.Print()
}
SlideWindow_SlideIn(SlideWindow)
{
	global SlideHwnd,SuspendWindowMoveCheck, SlideWindowArray
	SetWinDelay 0
	outputdebug slide in
	hwnd:=SlideWindow.hwnd
	WinSet, AlwaysOnTop, On , ahk_id %hwnd%
	SuspendWindowMoveCheck:=true


	;Disable Minimize/Restore animation
	RegRead, Animate, HKCU, Control Panel\Desktop\WindowMetrics , MinAnimate
	outputdebug animate is currently set to %animate%
	VarSetCapacity(struct, 8, 0)	
  NumPut(8, struct, 0, "UInt")
  NumPut(0, struct, 4, "Int")
	DllCall("SystemParametersInfo", "UINT", 0x0049,"UINT", 8,"STR", struct,"UINT", 0x0003) ;SPI_SETANIMATION            0x0049 SPIF_SENDWININICHANGE 0x0002
	;WinRestore ahk_id %hwnd%
	WinActivate ahk_id %hwnd%
	SlideWindow.SlideState:=2
	SlideWindow.Move(SlideWindow.SlideOutX,SlideWindow.SlideOutY,SlideWindow.SlideInX,SlideWindow.SlideInY,2)
	SlideWindow.SlideState:=1
	;Possibly activate it again
	if(Animate=1)
	{
  	NumPut(1, struct, 4, "UInt")
  	DllCall("SystemParametersInfo", "UINT", 0x0049,"UINT", 8,"STR", struct,"UINT", 0x0003) ;SPI_SETANIMATION            0x0049 SPIF_SENDWININICHANGE 0x0002
  }
	SuspendWindowMoveCheck:=false
	SlideWindowArray.Print()
}
;soft=Don't move window
SlideWindow_Release(SlideWindow,soft=0)
{
	global SlideWindowArray,SuspendWindowMoveCheck
	hwnd:=SlideWindow.hwnd
	outputdebug release %hwnd% %soft%
	;WinShow ahk_id %hwnd%
	SuspendWindowMoveCheck:=true
	if(!soft)
	{
		WinRestore ahk_id %hwnd%
		if(SlideWindow.SlideState=1)
			SlideWindow.Move(SlideWindow.SlideInX,SlideWindow.SlideInY,SlideWindow.OrigX,SlideWindow.OrigY,2)
		else 
		{
			SlideWindow.Move(SlideWindow.SlideOutX,SlideWindow.SlideOutY,SlideWindow.OrigX,SlideWindow.OrigY,2)
			if(SlideWindow.SlideState!=0)
				msgbox Slide window release while sliding!
		}
	}
	WinSet, AlwaysOnTop, Off , ahk_id %hwnd%
	
	SlideWindowArray.Delete(SlideWindowArray.indexOf(SlideWindow))	
	SuspendWindowMoveCheck:=false 
	SlideWindowArray.Print()
}

SlideWindow_Print(SlideWindow)
{	
	class:=WinGetClass("ahk_id " SlideWindow.hwnd)	
	outputdebug("hwnd: " SlideWindow.hwnd)
	outputdebug("class: " class)
	outputdebug("dir: " SlideWindow.dir)
	outputdebug("state: " SlideWindow.slidestate)
	outputdebug("keep open: " SlideWindow.KeepOpen)
	outputdebug("Origx: " SlideWindow.Origx)
	outputdebug("Origy: " SlideWindow.Origy)
	outputdebug("Width: " SlideWindow.Width)
	outputdebug("Height: " SlideWindow.Height)
	outputdebug("SlideOutX: " SlideWindow.SlideOutX)
	outputdebug("SlideOutY: " SlideWindow.SlideOutY)
	outputdebug("SlideInX: " SlideWindow.SlideInX)
	outputdebug("SlideInY: " SlideWindow.SlideInY)
}
/*
SlideWindow_UpdatePosition(SlideWindow)
{
	hwnd:=SlideWindow.hwnd
	WinGetPos X, Y, Width, Height, ahk_id %hwnd%
	SlideWindow.X:=X
	SlideWindow.Y:=Y
	SlideWindow.Width:=Width
	SlideWindow.Height:=Height
	outputdebug("updated position of " WinGetClass("ahk_id " hwnd) " to " X " " Y " " Width " " Height) 
}
*/
;---------------------------------------------------------------------------------------------------------------
; SlideWindowArray functions
;---------------------------------------------------------------------------------------------------------------

;Slide Window array constructor with some additional functions
SlideWindowArray(p1="Ņ", p2="Ņ", p3="Ņ", p4="Ņ", p5="Ņ", p6="Ņ"){ 
   static SlideBase 
   If !SlideBase 
      SlideBase := Object("len", "Array_Length", "indexOf", "Array_indexOf", "join", "Array_Join" 
      , "append", "Array_Append", "insert", "Array_Insert", "delete", "Array_Delete" 
      , "sort", "Array_sort", "reverse", "Array_Reverse", "unique", "Array_Unique" 
      , "extend", "Array_Extend", "copy", "Array_Copy", "pop", "Array_Pop", "ContainsHWND", "SlideWindowArray_ContainsHWND"
			, "Add", "SlideWindowArray_Add", "Print", "SlideWindowArray_Print"
			, "IsSlideSpaceOccupied", "SlideWindowArray_IsSlideSpaceOccupied", "IsSlideSpaceFree", "SlideWindowArray_IsSlideSpaceFree"
			, "ReleaseAll", "SlideWindowArray_ReleaseAll", "IsASlideWindowInState", "SlideWindowArray_IsASlideWindowInState") 

   Slide := Object("base", SlideBase) 
   While (_:=p%A_Index%)!="Ņ" && A_Index<=6 
      Slide[A_Index] := _ 
   Return Slide 
} 
SlideWindowArray_IsASlideWindowInState(SlideWindowArray, state, state2="")
{
	if(state2="")
		state2:=state
	Loop % SlideWindowArray.len()	
		if (SlideWindowArray[A_INDEX].SlideState >= state && SlideWindowArray[A_INDEX].SlideState <= state2)
			return SlideWindowArray[A_INDEX]
	return 0
}
SlideWindowArray_Add(SlideWindowArray, hwnd, dir)
{
	global PreviousWindow,CurrentWindow,SlideWin
	outputdebug add window
	if(SlideWindowArray.IsSlideSpaceFree(hwnd,dir) && (z:=GetTaskbarDirection())!=dir&&z>0)
	{
		outputdebug add slide window
		SlideWindow:=object("base",SlideWin)
		SlideWindow.hwnd:=hwnd
		SlideWindow.dir:=dir
		WinGetPos X, Y, Width, Height, ahk_id %hwnd%
		;Store original position
		SlideWindow.OrigX:=X
		SlideWindow.OrigY:=Y
		;Set positions of slided in/out window (once and for all, never updated unless removed and added again
		if(dir=1||dir=3)
		{
			if(dir=1)
			{
				SlideWindow.SlideOutX:=-Width
				SlideWindow.SlideInX:=0
			}
			else
			{
				SlideWindow.SlideOutX:=A_ScreenWidth
				SlideWindow.SlideInX:=A_ScreenWidth-Width-1
			}
			SlideWindow.SlideOutY:=y
			SlideWindow.SlideInY:=y
		}
		else if(dir=2||dir=4)
		{
			if(dir=2)
			{
				SlideWindow.SlideOutY:=-Height
				SlideWindow.SlideInY:=0
			}
			else
			{
				SlideWindow.SlideOutY:=A_ScreenHeight
				SlideWindow.SlideInY:=A_ScreenHeight-Height-1
			}
			SlideWindow.SlideOutX:=x
			SlideWindow.SlideInX:=x
		}
		SlideWindow.Width:=Width
		SlideWindow.Height:=Height
		SlideWindow.Print()
		SlideWindowArray.append(SlideWindow)
		ct:=SlideWindowArray.len()
		outputdebug array count: %ct%
		SlideWindow.SlideOut()
		/*
		WinGetClass,class,ahk_id %PreviousWindow%
		outputdebug activate previous window: %class%
		if(previouswindow!=hwnd&&!SlideWindowArray.ContainsHWND(PreviousWindow))
			WinActivate ahk_id %PreviousWindow%
		else if(!SlideWindowArray.ContainsHWND(CurrentWindow))
			WinActivate ahk_id %CurrentWindow%
		else
			WinActivate ahk_class Shell_TrayWnd
		*/
	}
}

SlideWindowArray_Print(SlideWindowArray)
{
	slidehwnd:=SlideWindowArray.IsASlideWindowInState(1).hwnd
	WinGetClass, class , ahk_id %slidehwnd%
	outputdebug currently active slide win: %slidehwnd%
	Loop % SlideWindowArray.len()
	{	
		outputdebug Index: %A_Index%
		SlideWindowArray[A_INDEX].Print()
	}
}

SlideWindowArray_ReleaseAll(SlideWindowArray)
{
	Loop % SlideWindowArray.len()
	{
		SlideWindowArray[A_INDEX].Release()
	}
}

SlideWindowArray_IsSlideSpaceOccupied(SlideWindowArray,x,y,width,height,dir)
{
	global SlideWindowsBorder
	
	if(dir=1||dir=3)
	{
		Loop % SlideWindowArray.len()
		{
			SlideWindow:=SlideWindowArray[A_INDEX]
			BorderY:=(Height-2*SlideWindowsBorder>0) ? SlideWindowsBorder : 0
			objBorderY:=(SlideWindow.Height-2*SlideWindowsBorder>0) ? SlideWindowsBorder : 0
			Y1:=Y+borderY
			Y2:=Y+Height-borderY
			objY1:=SlideWindow.SlideInY+objBorderY
			objY2:=SlideWindow.SlideInY+SlideWindow.Height-objBorderY
			if(SlideWindow.dir=dir)
			{
				if Y1 between %objY1% and %objY2%
					return SlideWindow
				if Y2 between %objY1% and %objY2%
					return SlideWindow
				if objY1 between %Y1% and %Y2%
					return SlideWindow
				if objY2 between %Y1% and %Y2%
					return SlideWindow
			}			
		}
	}
	else if(dir=2||dir=4)
	{
		Loop % SlideWindowArray.len()
		{
			outputdebug loop 24
			SlideWindow:=SlideWindowArray[A_INDEX]
			borderX:=(Width-2*SlideWindowsBorder>0) ? SlideWindowsBorder : 0
			objBorderX:=(SlideWindow.Width-2*SlideWindowsBorder>0) ? SlideWindowsBorder : 0
			X1:=X+borderX
			X2:=X+Width-borderX
			objX1:=SlideWindow.SlideInX+objBorderX
			objX2:=SlideWindow.SlideInX+SlideWindow.Width-objBorderX
			outputdebug("Testing from " x1 " to " x2 " against a collision area of " objX1 " to " objX2)
			if(SlideWindow.dir=dir)
			{
				if X1 between %objX1% and %objX2%
					return SlideWindow
				if X2 between %objX1% and %objX2%
					return SlideWindow
				if objX1 between %X1% and %X2%
					return SlideWindow
				if objX2 between %X1% and %X2%
					return SlideWindow
			}			
		}
	}
	return 0
}

SlideWindowArray_IsSlideSpaceFree(SlideWindowArray, hwnd,dir)
{
	WinGetPos X, Y, Width, Height, ahk_id %hwnd%
	return !SlideWindowArray.IsSlideSpaceOccupied(X,Y,Width,Height,dir)
}

SlideWindowArray_ContainsHWND(SlideWindowArray,hwnd)
{
	Loop % SlideWindowArray.len()
	{
		SlideWindow:=SlideWindowArray[A_INDEX]
		if(SlideWindow.hwnd=hwnd)
			return SlideWindow
	}
	return false
}

;Check if window was moved, closed etc
SlideWindows_CheckWindowState()
{	
	;Critical
	global SlideWindowArray, SuspendWindowMoveCheck
	DetectHiddenWindows, On
	SlideWindows_CheckActivated()
	if SuspendWindowMoveCheck
		return

	;First, a looping loop to remove all closed windows
	found:=true
	while(found)
	{
		found:=false
		Loop % SlideWindowArray.len()
		{
			SlideWindow:=SlideWindowArray[A_INDEX]
			hwnd:=SlideWindow.hwnd
			if(!WinExist("ahk_id " hwnd))
			{
				outputdebug remove closed window
				SlideWindowArray.Delete(SlideWindowArray.indexOf(SlideWindow))
				found:=true
				break
			}
		}
	}
	;Now see if a window has been moved
	Loop % SlideWindowArray.len()
	{
		SlideWindow:=SlideWindowArray[A_INDEX]
		hwnd:=SlideWindow.hwnd
		if(SlideWindow.SlideState=1)
		{
			WinGetPos X, Y, Width, Height, ahk_id %hwnd%
			if(SlideWindow.SlideInX!=x||SlideWindow.SlideInY!=y||SlideWindow.Width!=width||SlideWindow.Height!=height)
			{
				outputdebug window changed pos/size to %x% %y% %width% %height%, release it
				SlideWindow.Release(1)
			}
			;Release maximized windows
			WinGet, maxstate,minmax, ahk_id %hwnd%
			if(maxstate=1)
			{
				outputdebug release maximized window
				SlideWindow.Release(1)
			}
		}
	}
}
SlideWindow_Move(SlideWindow, fromX,fromY,toX,toY, speed)
{
	SetWinDelay 0
	hwnd:=SlideWindow.hwnd	
	outputdebug move window %hwnd% from %fromX% %fromY% %toX% %toY% %speed%
	;WinGetPos ,,, Width, Height, ahk_id %hwnd%
	diffX:=toX-fromX
	diffY:=toY-fromY
	while(fromX!=toX||fromY!=toY)
	{		
		dX:=absmin(dirmax(diffX*Speed/10,10),diffX)
		dY:=absmin(dirmax(diffY*Speed/10,10),diffY)	
		fromX:=fromX+dX
		fromY:=fromY+dY
		diffX:=toX-fromX
		diffY:=toY-fromY
		WinMove, ahk_id %hwnd%,,%fromX%, %fromY%
		SlideWindow.x:=fromX
		SlideWindow.y:=fromY
		;SlideWindow.Width:=Width
		;SlideWindow.Height:=Height
		Sleep 10
	}
	outputdebug move finished
}

SlideWindows_OnMouseMove(x,y)
{
	global SlideWindowArray,SuspendWindowMoveCheck,CurrentWindow,BorderActivation
	if(x=0)
		dir=1
	else if(y=0)
		dir=2
	else if(x=A_ScreenWidth-1)
		dir=3
	else if(y=A_ScreenHeight-1)
		dir=4
	if((z:=GetTaskbarDirection())=dir||z<=0)
		return
	;Don't Slide in while other window is active or while sliding
	SlideWindow:=SlideWindowArray.IsSlideSpaceOccupied(x,y,0,0,dir)
	if(SlideWindow)
		outputdebug at slide window pos
	if(dir>0 && !SlideWindowArray.IsASlideWindowInState(1,3) && SlideWindow)
	{		
		outputdebug mouse slide in
		hwnd:=SlideWindow.hwnd
		BorderActivation:=true
		WinGetClass class, ahk_id %hwnd%
		outputdebug activate border %class%
		;WinActivate ahk_id %hwnd% 
		SlideWindow.SlideIn()
		return
	}
	;Now see if mouse is currently over a shown slide window and maybe hide it
	MouseGetPos, , ,win
	visibleWin:=SlideWindowArray.IsASlideWindowInState(1)
	if(visibleWin && !visibleWin.KeepOpen && visibleWin.hwnd!=win)
	{
		;outputdebug slidehwnd %slidehwnd% winmouse %win%
		WinGetClass class, ahk_id %CurrentWindow%
		outputdebug mouse left window, slide out and activate %class%
		SuspendWindowMoveCheck:=1
		visibleWin.SlideOut()
		SuspendWindowMoveCheck:=0
	}
}

SlideWindows_CheckActivated()
{
	global SlideWindowArray,CurrentWindow,PreviousWindow,SuspendWindowMoveCheck,BorderActivation
	hwnd:=WinExist("A")
	if(!hwnd)
		return
	class:=WinGetClass("ahk_id " hwnd)
	SlideWindow:=SlideWindowArray.ContainsHWND(hwnd)
	visibleWindow:=SlideWindowArray.IsASlideWindowInState(1,3)
	validWindow:=true
	WinGet, ExStyle, ExStyle, ahk_id %hwnd%
  If (ExStyle & 0x80)
  	validWindow:=false
;~              If not (ExStyle & 0x40000) and DllCall("GetWindow", "UInt", id, "UInt", 4)
;~                      Continue
  WinGetPos,,, W, H, ahk_id %hwnd%
  If W+H=0
  	validWindow:=false
          
  WinGetTitle, this_title, ahk_id %hwnd%

  If this_title=
  	validWindow:=false
  if(class="WorkerW")
  	validWindow:=true
  if(class="#32770")
  	validWindow:=false
	;detect previous and current real window
	if(CurrentWindow!=hwnd&&validWindow||!CurrentWindow)
	{
		PreviousWindow:=CurrentWindow
		CurrentWindow:=hwnd
		WinGetClass,class,ahk_id %hwnd%
		WinGetClass,class2,ahk_id %PreviousWindow%
		WinGetClass,class1,ahk_id %CurrentWindow%
		outputdebug window changed from %class2% to %class1%		
		;Tooltip hwnd: %class% `ncurrent: %class1%`nprevious: %class2%
		SlideWindowPrevious:=SlideWindowArray.ContainsHWND(PreviousWindow)
		;If a (slide window was active and another )slide window gets activated
		if(SlideWindow && visibleWindow!=SlideWindow&&!BorderActivation)
		{
			visibleClass:=WinGetClass("ahk_id " visibleWindow.hwnd)
			outputdebug("activated a slide window: " hwnd WinGetClass("ahk_id " hwnd) "previously active slide window: " visibleWindow.hwnd WinGetClass("ahk_id " visibleWindow.hwnd))
			;If a slide window was visible, slide it out first
			if(visibleWindow)
			{
				outputdebug slide out other window first
				SuspendWindowMoveCheck:=true
				visibleWindow.SlideOut()
				SuspendWindowMoveCheck:=false
			}
			SlideWindow.KeepOpen:=1 
			SuspendWindowMoveCheck:=true
			SlideWindow.SlideIn()
			SuspendWindowMoveCheck:=false
		}
		;If a visible slide window gets deactivated
		else if(visibleWindow&&visibleWindow.KeepOpen&&visibleWindow.hwnd!=hwnd)
		{
			outputdebug deactivated a keep open slide window
			
			visibleWindow.KeepOpen:=0
			;if the window which is kept open was minimized, release it
			WinGet, minstate , minmax, ahk_id %PreviousWindow%
			if(minstate=-1)
			{
				outputdebug release minimized window
				visibleWindow.Release(1)
			}
			else
			{
				SuspendWindowMoveCheck:=true
				visibleWindow.SlideOut()
				SuspendWindowMoveCheck:=false
			}
		}
		else if (BorderActivation)
			BorderActivation:=false
	}	
}
