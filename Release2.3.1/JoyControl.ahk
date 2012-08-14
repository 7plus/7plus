JoystickStart()
{
	SetTimer, CheckJoystick, 5
	SetTimer, Arrows, 70
	SetTimer, Fullscreencheck, 1000
}
;Run this function to disable joystick control
JoystickStop()
{
	SetTimer, CheckJoystick, off
	SetTimer, Arrows, off
	SetTimer, Fullscreencheck, off
}

;Called every second to enable/disable joystick remote control when fullscreen state changes
FullscreenCheck:
FullscreenCheck()
return

FullscreenCheck()
{
	static WasFullScreen := false
	if(WasFullscreen && !IsFullscreen("A",true)) ;Use previous fullscreen state so timers don't get reset
	{
		SetTimer, CheckJoystick, on
		SetTimer, Arrows, on
		WasFullscreen:=false
	}
	else if(!WasFullscreen && IsFullscreen("A",true))
	{
		SetTimer, CheckJoystick, off
		SetTimer, Arrows, off
		WasFullscreen:=true
	}
	return
}

;Main function which translates axes to mouse input
CheckJoystick:
CheckJoyStick()
return

CheckJoyStick()
{
	XAxis:=0
	YAxis:=0
	GetKeyState, XAxis, JoyX ;Get axis data
	GetKeyState, YAxis, JoyY
	GetKeyState, RAxis, JoyR
	GetKeyState, UAxis, JoyU
	if(XAxis||YAxis)
	{
		if(RAxis<20) ;Mouse wheel
			Send {WheelUp}
		if(RAxis>80)
			Send {WheelDown}
		if(UAxis<20)
			Send {WheelLeft}
		if(UAxis>80)
			Send {WheelRight}
		
		XAxis-=50 ;Mouse cursor
		YAxis-=50
		if(abs(XAxis)<10)
			XAxis:=10*sign(XAxis)
		if(abs(YAxis)<10)
			YAxis:=10*sign(YAxis)
		XAxis-=10*sign(XAxis)
		YAxis-=10*sign(YAxis)
		XAxis:=0.1*abs(Round(XAxis))**1.5*sign(XAxis)
		YAxis:=0.1*abs(Round(YAxis))**1.5*sign(YAxis)
		
		
		;TODO: This is not working anymore! Is it worth the work to find the matching events and possibly block them?
		;Prevent Aero Flip from triggering due to joystick movement, because remote control doesn't work when in flip mode
		;Mouse Coords are stored in WindowsTweaks.ahk for performance reasons
		;~ if(AeroFlipTime>=0)
		;~ {
			;~ X:=MouseX
			;~ Y:=MouseY
			;~ X+=XAxis
			;~ Y+=YAxis
			;~ if(X<=1&&Y<=1&&(XAxis!=0||YAxis!=0))
			;~ {
				;~ XAxis:=-X+1
				;~ YAxis:=-Y+1
			;~ }
		;~ }
		
		MouseMove, XAxis,YAxis,0,R
	}
	return
}
;POV -> Arrows have separate label because of timing
Arrows: 
Joy_ArrowKeys()
return
Joy_ArrowKeys()
{
	GetKeyState, POV, JoyPOV
	if(POV>=0)
	{
		if(POV=0||POV=4500||POV=31500)
			Send {Up}
		if(POV=22500||POV=27000||POV=31500)
			Send {Left}
		if(POV=13500||POV=18000||POV=22500)
			Send {Down}
		if(POV=4500||POV=9000||POV=13500)
			Send {Right}
	}
	return
}
;Joystick buttons
#if Settings.Misc.GamepadRemoteControl && !IsFullScreen("A",true)
;Mouse buttons have separate press and release triggers, so they can be held for dragging etc.
Joy1::
SetMouseDelay, -1  ; Makes movement smoother.
Click Left Down  ; Hold down the left mouse button.
SetTimer, WaitForLeftButtonUp, 10
return

Joy2::
SetMouseDelay, -1  ; Makes movement smoother.
Click Right Down  ; Hold down the right mouse button.
SetTimer, WaitForRightButtonUp, 10
return

Joy3::
SetMouseDelay, -1  ; Makes movement smoother.
Click Middle Down  ; Hold down the right mouse button.
SetTimer, WaitForMiddleButtonUp, 10
return

;Buttons which trigger key presses are press only, because they should only trigger once when held
Joy4::Send {Return}
Joy5::Send #{NumpadSub}
Joy6::Send #{NumpadAdd}
Joy7::Send !{Up}
Joy8::Send {Space}
#if

WaitForLeftButtonUp:
if GetKeyState("Joy1")
    return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForLeftButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
Click Left Up  ; Release the mouse button.
return

WaitForRightButtonUp:
if GetKeyState("Joy2")
    return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForRightButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
Click Right Up  ; Release the mouse button.
return

WaitForMiddleButtonUp:
if GetKeyState("Joy3")
    return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForMiddleButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
Click Middle Up  ; Release the mouse button.
return
