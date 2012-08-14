/*
	Title:	Win
			Set of window functions.
 */

/*
 Function:	Animate
 			Enables you to produce special effects when showing or hiding windows.
 
 Parameters:
 			Type		- White space separated list of animation flags. By default, these flags take effect when showing a window.
			Time		- Specifies how long it takes to play the animation, in millisecond .
 
 Animation types:
			activate	- Activates the window. Do not use this value with HIDE flag.
			blend		- Uses a fade effect. This flag can be used only if hwnd is a top-level window.
			center		- Makes the window appear to collapse inward if HIDE is used or expand outward if the HIDE is not used. The various direction flags have no effect.
			hide		- Hides the window. By default, the window is shown.
			slide		- Uses slide animation. Ignored when used with CENTER.
			:
			hneg		- Animates the window from right to left. This flag can be used with roll or slide animation. It is ignored when used with CENTER or BLEND.
			hpos		- Animates the window from left to right. This flag can be used with roll or slide animation. It is ignored when used with CENTER or BLEND.
			vneg		- Animates the window from top to bottom. This flag can be used with roll or slide animation. It is ignored when used with CENTER or BLEND.
			vpos		- Animates the window from bottom to top. This flag can be used with roll or slide animation. It is ignored when used with CENTER or BLEND.

 Remarks:
			When using slide or roll animation, you must specify the direction.
			You can combine HPOS or HNEG with VPOS or VNEG to animate a window diagonally.
			If a child window is displayed partially clipped, when it is animated it will have holes where it is clipped.
			Avoid animating a window that has a drop shadow because it produces visually distracting, jerky animations.

 Returns:
 			If the function succeeds, the return value is nonzero.
 
 Example:
		>  Win_Animate(hWnd, "hide blend", 500)
 
 */
Win_Animate(Hwnd, Type="", Time=100){
	static AW_ACTIVATE = 0x20000, AW_BLEND=0x80000, AW_CENTER=0x10, AW_HIDE=0x10000
			,AW_HNEG=0x2, AW_HPOS=0x1, AW_SLIDE=0x40000, AW_VNEG=0x8, AW_VPOS=0x4

	hFlags := 0
	loop, parse, Type, %A_Tab%%A_Space%, %A_Tab%%A_Space%
		ifEqual, A_LoopField,,continue
		else hFlags |= AW_%A_LoopField%

	ifEqual, hFlags, ,return "Err: Some of the types are invalid"
	DllCall("AnimateWindow", "Ptr", Hwnd, "uint", Time, "uint", hFlags)
}

/*
 Function:	GetClassNN
			Get a control ClassNN.
 
 Parameters:
			HCtrl	- Handle of the parent window.
			HRoot	- Handle of the top level window containing control.

 Returns:
			ClassNN
 
 About:
			o Developed by Lexikos. See <http://www.autohotkey.com/forum/viewtopic.php?p=308628#308628>
 */
Win_GetClassNN(HCtrl, HRoot="") {
	ifEqual, HRoot,, SetEnv, HRoot, % DllCall("GetAncestor", "Ptr", HCtrl, "Uint", 2, "Uint")
	WinGet, hlist, ControlListHwnd, ahk_id %HRoot% 
    WinGetClass, tclass, ahk_id %HCtrl% 
    Loop, Parse, hlist, `n 
    { 
        WinGetClass, lclass, ahk_id %A_LoopField% 
        if (lclass == tclass) 
        { 
            nn += 1 
            if A_LoopField = %hctl% 
                return tclass nn 
        } 
    }
}

/*
 Function:	SetParent
 			Changes the parent window of the specified window.
 
 Parameters:
			Hwnd	- Handle of the window for which to send parent.
			HParent	- Handle to the parent window. If this parameter is 0, the desktop window becomes the new parent window.
			bFixStyle - Set to TRUE to fix WS_CHILD & WS_POPUP styles. SetParent does not modify the WS_CHILD or WS_POPUP window styles of the window whose parent is being changed.
						If HParent is 0, you should also clear the WS_CHILD bit and set the WS_POPUP style after calling SetParent (and vice-versa).
						
 Returns:
			If the function succeeds, the return value is a handle to the previous parent window. Otherwise, its 0.

 Remarks:
			If the window identified by the Hwnd parameter is visible, the system performs the appropriate redrawing and repainting.
			The function sends WM_CHANGEUISTATE to the parent after succesifull operation uncoditionally.
			See <http://msdn.microsoft.com/en-us/library/ms633541(VS.85).aspx> for more information.
 */
Win_SetParent(Hwnd, HParent=0, bFixStyle=false){
	static WS_POPUP=0x80000000, WS_CHILD=0x40000000, WM_CHANGEUISTATE=0x127, UIS_INITIALIZE=3
	
	if (bFixStyle) {
		s1 := HParent ? "+" : "-", s2 := HParent ? "-" : "+"
		WinSet, Style, %s1%%WS_CHILD%, ahk_id %Hwnd%
		WinSet, Style, %s2%%WS_POPUP%, ahk_id %Hwnd%
	}
	r := DllCall("SetParent", "Ptr", Hwnd, "uint", HParent, "Uint")
	ifEqual, r, 0, return 0
	SendMessage, WM_CHANGEUISTATE, UIS_INITIALIZE,,,ahk_id %HParent%
	return r
}

/*
 Function:	SetOwner
 			Changes the owner window of the specified window.
 
 Parameters:
			hOwner	- Handle to the owner window.

 Returns:
			Handle of the previous owner.

 Remarks:
			An owned window is always above its owner in the z-order. The system automatically destroys an owned window when its owner is destroyed. An owned window is hidden when its owner is minimized. 
			Only an overlapped or pop-up window can be an owner window; a child window cannot be an owner window.
 */
Win_SetOwner(Hwnd, hOwner){
	;Famous misleading statement. Almost as misleading as the choice of GWL_HWNDPARENT as the name. It has nothing to do with a window's parent. 
	;It really changes the Owner exactly the same thing as including the Owner argument in the Show statement. 
	;A more accurate version might be: "SetWindowLong with the GWL_HWNDPARENT will not change the parent of a child window. Instead, use the SetParent function."
	;GWL_HWNDPARENT should have been called GWL_HWNDOWNER, but nobody noticed it until after a bazillion copies of the SDK had gone out. This is what happens 
	;when the the dev team lives on M&Ms and CocaCola for to long. Too bad. Live with it.

	static GWL_HWNDPARENT = -8
	return DllCall("SetWindowLongPtr", "Ptr", Hwnd, "int", GWL_HWNDPARENT, "Ptr", hOwner)		
}

/*
 Function:	Subclass 
			Subclass window.
 
 Parameters: 
			Hwnd    - Handle to the window to be subclassed.
			Fun		- New window procedure. You can also pass function address here in order to subclass child window
					  with previously created window procedure.
			Opt		- Optional callback options for Fun, by default "" 
		   $WndProc - Optional reference to the output variable that will receive address of the new window procedure.

 Returns:
			The address of the previous window procedure or 0 on error.

 Remarks:
			Works only for controls created in the autohotkey process.

 Example:
	(start code)
  	if !Win_SubClass(hwndList, "MyWindowProc") 
  	     MsgBox, Subclassing failed. 
  	... 
  	MyWindowProc(hwnd, uMsg, wParam, lParam){ 
  
  	   if (uMsg = .....)  
            ; my message handling here 
  
  	   return DllCall("CallWindowProc", "UInt", A_EventInfo, "UInt", hwnd, "UInt", uMsg, "UInt", wParam, "UInt", lParam) 
  	}
	(end code)
 */
Win_Subclass(Hwnd, Fun, Opt="", ByRef $WndProc="") { 
	if Fun is not integer
	{
		 oldProc := DllCall("GetWindowLong", "Ptr", Hwnd, "uint", -4) 
		 ifEqual, oldProc, 0, return 0 
		 $WndProc := RegisterCallback(Fun, Opt, 4, oldProc) 
		 ifEqual, $WndProc, , return 0
	}
	else $WndProc := Fun
	   
    return DllCall("SetWindowLongPtr", "Ptr", Hwnd, "Int", -4, "Int", $WndProc, "UInt") 
}

/*
Group: About
	o v1.25 by majkinetor.
	o Reference: <http://msdn.microsoft.com/en-us/library/ms632595(VS.85).aspx>
	o Licensed under GNU GPL <http://creativecommons.org/licenses/GPL/2.0/>
/*
