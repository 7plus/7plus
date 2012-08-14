Class CHotkeyTrigger Extends CTrigger
{
	static Type := RegisterType(CHotkeyTrigger, "Hotkey")
	static Category := RegisterCategory(CHotkeyTrigger, "Hotkeys")
	static Key := ""

	Enable()
	{
		key := this.Key
		key := "$" key ;Add $ so key can not be triggered through script to prevent loops
		if(InStr(key, "~"))
		{
			Hotkey, If, IsObject(HotkeyShouldFire( A_ThisHotkey))
			Hotkey, %key%, HotkeyTrigger2, On
		}
		else
		{
			Hotkey, If, IsObject(HotkeyShouldFire(A_ThisHotkey))
			Hotkey, %key%, HotkeyTrigger, On
		}
		Hotkey, If
	}
	
	Disable()
	{
		key := this.Key
		key := "$" key ;Add $ so key can not be triggered through script to prevent loops
		if(InStr(key, "~"))
		{
			Hotkey, If, IsObject(HotkeyShouldFire( A_ThisHotkey))
			Hotkey, %key%, HotkeyTrigger2, On ;Do this to make sure it exists
		}
		else
		{
			Hotkey, If, IsObject(HotkeyShouldFire(A_ThisHotkey))
			Hotkey, %key%, HotkeyTrigger, On ;Do this to make sure it exists
		}
		Hotkey, %key%, Off
		Hotkey, If
	}
	
	;When hotkey is deleted, it needs to be removed from hotkeyarrays
	Delete()
	{
	}

	Matches(Filter)
	{
		return (StringReplace(this.Key, "~") = StringReplace(Filter.Key, "~"))
	}

	DisplayString()
	{
		return FormatHotkey(this.Key)
	}
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.CreateHotkeyGUI(sGUI)
		}
		else if(GoToLabel = "UpdateHotkey")
		{
			;Get values from GUI
			ControlGet, Key, Choice,,, % "ahk_id " sGUI.tmphKeyList
			ControlGet, CtrlModifier, Checked,,, % "ahk_id " sGUI.tmphCtrlModifier
			ControlGet, ShiftModifier, Checked,,, % "ahk_id " sGUI.tmphShiftModifier
			ControlGet, WinModifier, Checked,,, % "ahk_id " sGUI.tmphWinModifier
			ControlGet, AltModifier, Checked,,, % "ahk_id " sGUI.tmphAltModifier
			
			ControlGet, NativeOption, Checked,,, % "ahk_id " sGUI.tmphNativeOption
			ControlGet, WildcardOption, Checked,,, % "ahk_id " sGUI.tmphWildcardOption
			ControlGet, LeftPairOption, Checked,,, % "ahk_id " sGUI.tmphLeftPairOption
			ControlGet, RightPairOption, Checked,,, % "ahk_id " sGUI.tmphRightPairOption
			ControlGet, UpOption, Checked,,, % "ahk_id " sGUI.tmphUpOption
			;Substitute Pause|Break for CtrlBreak?
			if Key in Pause,Break
				if(CtrlModifier)
					Key := "CtrlBreak"
			
			
			;Substitute CtrlBreak for Pause (Break would work OK too)
			if(Key = "CtrlBreak")
				if(!CtrlModifier)
					Key := "Pause"
			
			;Initialize
			Hotkey := ""
			Desc := ""
			
			;Options
			if(NativeOption)
				Hotkey .= "~"
			
			if(WildcardOption)
				Hotkey .= "*"
			
			if(LeftPairOption)
				Hotkey .= "<"
			
			if(RightPairOption)
				Hotkey .= ">"
			
			;Modifiers
			if(CtrlModifier)
			{
				Hotkey .= "^"
				Desc .= "Ctrl + "
			}
			
			if(ShiftModifier)
			{
				Hotkey .= "+"
				Desc .= "Shift + "
			}
			
			if(WinModifier)
			{
				Hotkey .= "#"
				Desc .= "Win + "
			}
			
			if(AltModifier)
			{
				Hotkey .= "!"
				Desc .= "Alt + "
			}
			
			Hotkey .= Key
			Desc .= Key
			if(UpOption)
			{
				Hotkey .= " UP"
				Desc .= " UP"
			}
			ControlSetText,,%Desc%,% "ahk_id " sGUI.tmphHotkey
			sGUI.tmpHotkey := Hotkey
			return
		}
		else if(GoToLabel = "LeftPair")
		{
			GuiControl,,% sGUI.tmphRightPairOption,0
			this.GuiShow("", "UpdateHotkey")
		}
		else if(GoToLabel = "RightPair")
		{
			GuiControl,,% sGUI.tmphLeftPairOption,0
			this.GuiShow("", "UpdateHotkey")
		}
		else if(GoToLabel = "UpdateKeyList")
		{
			;Get values from GUI
			ControlGet, StandardKeysView, Checked,,, % "ahk_id " sGUI.tmphStandardKeysView
			ControlGet, FunctionKeysView, Checked,,, % "ahk_id " sGUI.tmphFunctionKeysView
			ControlGet, NumpadKeysView, Checked,,, % "ahk_id " sGUI.tmphNumpadKeysView
			ControlGet, MouseKeysView, Checked,,, % "ahk_id " sGUI.tmphMouseKeysView
			ControlGet, MultimediaKeysView, Checked,,, % "ahk_id " sGUI.tmphMultimediaKeysView
			ControlGet, SpecialKeysView, Checked,,, % "ahk_id " sGUI.tmphSpecialKeysView
			Gui, +Delimiterƒ
			;Standard
			if(StandardKeysView)
				KeyList := "AƒBƒCƒDƒEƒFƒGƒHƒIƒJƒKƒLƒMƒNƒOƒPƒQƒRƒSƒTƒUƒVƒWƒXƒYƒZƒ0ƒ1ƒ2ƒ3ƒ4ƒ5ƒ6ƒ7ƒ8ƒ9ƒ0ƒ``ƒ-ƒ=ƒ[ƒ]ƒ\ƒ;ƒ'ƒ,ƒ.ƒ/ƒSpaceƒTabƒEnterƒEscapeƒBackspaceƒDeleteƒScrollLockƒCapsLockƒPrintScreenƒCtrlBreakƒPauseƒBreakƒInsertƒHomeƒEndƒPgUpƒPgDnƒUpƒDownƒLeftƒRightƒ"
					
			;Function keys
			if(FunctionKeysView)
				KeyList := "F1ƒF2ƒF3ƒF4ƒF5ƒF6ƒF7ƒF8ƒF9ƒF10ƒF11ƒF12ƒF13ƒF14ƒF15ƒF16ƒF17ƒF18ƒF19ƒF20ƒF21ƒF22ƒF23ƒF24ƒ"
			
			;Numpad
			if(NumpadKeysView)
				KeyList := "NumLockƒNumpadDivƒNumpadMultƒNumpadAddƒNumpadSubƒNumpadEnterƒNumpadDelƒNumpadInsƒNumpadClearƒNumpadUpƒNumpadDownƒNumpadLeftƒNumpadRightƒNumpadHomeƒNumpadEndƒNumpadPgUpƒNumpadPgDnƒNumpad0ƒNumpad1ƒNumpad2ƒNumpad3ƒNumpad4ƒNumpad5ƒNumpad6ƒNumpad7ƒNumpad8ƒNumpad9ƒNumpadDotƒ"
			
			;Mouse
			if(MouseKeysView)
				KeyList := "LButtonƒRButtonƒMButtonƒWheelDownƒWheelUpƒXButton1ƒXButton2ƒ"
			
			;Multimedia
			if(MultimediaKeysView)
				KeyList := "Browser_BackƒBrowser_ForwardƒBrowser_RefreshƒBrowser_StopƒBrowser_SearchƒBrowser_FavoritesƒBrowser_HomeƒVolume_MuteƒVolume_DownƒVolume_UpƒMedia_NextƒMedia_PrevƒMedia_StopƒMedia_Play_PauseƒLaunch_MailƒLaunch_MediaƒLaunch_App1ƒLaunch_App2ƒ"
			
			;Special
			if(SpecialKeysView)
				KeyList := "HelpƒSleepƒ"
			Key := ExtractKey(sGUI.tmpHotkey)
			if(Key)
				KeyList := StringReplace(KeyList, "ƒ" Key "ƒ", "ƒ" Key "ƒƒ")
			if(!InStr(KeyList, "ƒƒ"))
				KeyList := StringReplace(KeyList, "ƒ", "ƒƒ")
			GUIControl ,, % sGUI.tmphKeyList,ƒ%KeyList%
			Gui, % "+Delimiter" sGUI.Delimiter
			;Reset Hotkey and HKDesc
			this.GuiShow("", "UpdateHotkey")
		}
	}
	CreateHotkeyGUI(GUI)
	{
		Critical, Off    
		;Modifier
		x := GUI.x
		y := GUI.y
		CtrlModifier := InStr(this.Key, "^") > 0
		ShiftModifier := InStr(this.Key, "+") > 0
		WinModifier := InStr(this.Key, "#") > 0
		AltModifier := InStr(this.Key, "!") > 0
		LeftPairOption := InStr(this.Key, "<") > 0
		RightPairOption := InStr(this.Key, ">") > 0
		WildcardOption := InStr(this.Key, "*") > 0
		NativeOption := InStr(this.Key, "~") > 0
		UpOption := InStr(this.Key, " UP") > 0 
		Key := ExtractKey(this.Key)
		FunctionKeys := InStr("ƒF1ƒF2ƒF3ƒF4ƒF5ƒF6ƒF7ƒF8ƒF9ƒF10ƒF11ƒF12ƒF13ƒF14ƒF15ƒF16ƒF17ƒF18ƒF19ƒF20ƒF21ƒF22ƒF23ƒF24ƒ", "ƒ" Key "ƒ") > 0
		NumpadKeys := InStr("ƒNumLockƒNumpadDivƒNumpadMultƒNumpadAddƒNumpadSubƒNumpadEnterƒNumpadDelƒNumpadInsƒNumpadClearƒNumpadUpƒNumpadDownƒNumpadLeftƒNumpadRightƒNumpadHomeƒNumpadEndƒNumpadPgUpƒNumpadPgDnƒNumpad0ƒNumpad1ƒNumpad2ƒNumpad3ƒNumpad4ƒNumpad5ƒNumpad6ƒNumpad7ƒNumpad8ƒNumpad9ƒNumpadDotƒ", "ƒ" Key "ƒ") > 0
		MouseKeys := InStr("ƒLButtonƒRButtonƒMButtonƒWheelDownƒWheelUpƒXButton1ƒXButton2ƒ", "ƒ" Key "ƒ") > 0
		MultimediaKeys := InStr("ƒBrowser_BackƒBrowser_ForwardƒBrowser_RefreshƒBrowser_StopƒBrowser_SearchƒBrowser_FavoritesƒBrowser_HomeƒVolume_MuteƒVolume_DownƒVolume_UpƒMedia_NextƒMedia_PrevƒMedia_StopƒMedia_Play_PauseƒLaunch_MailƒLaunch_MediaƒLaunch_App1ƒLaunch_App2ƒ", "ƒ" Key "ƒ") > 0
		SpecialKeys := InStr("ƒHelpƒSleepƒ", "ƒ" Key "ƒ") > 0
		StandardKeys := !FunctionKeys && !NumpadKeys && !MouseKeys && !MultimediaKeys && !SpecialKeys
		Gui, Add, GroupBox, x%x% y%y% w120 h140 hwndhModifier Section, Modifier
		GUI.tmphModifier := hModifier
		
		Gui, Add, CheckBox, xs+10 ys+20 h20 hwndhCtrlModifier gHotkeyGUI_UpdateHotkey Checked%CtrlModifier%, Ctrl
		GUI.tmphCtrlModifier := hCtrlModifier
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_UpdateHotkey hwndhShiftModifier Checked%ShiftModifier%, Shift
		GUI.tmphShiftModifier := hShiftModifier
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_UpdateHotkey hwndhWinModifier Checked%WinModifier%, Win
		GUI.tmphWinModifier := hWinModifier
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_UpdateHotkey hwndhAltModifier Checked%AltModifier%, Alt
		GUI.tmphAltModifier := hAltModifier    
		
		;Optional Attributes
		Gui, Add, GroupBox, xs+120 ys w140 h140 hwndhOptionalAttributes, Optional Attributes
		GUI.tmphOptionalAttributes := hOptionalAttributes
		
		Gui, Add, CheckBox, xs+130 ys+20 h20 gHotkeyGUI_UpdateHotkey hwndhNativeOption Checked%NativeOption%, ~ (Native)
		GUI.tmphNativeOption := hNativeOption
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_UpdateHotkey hwndhWildcardOption Checked%WildcardOption%, * (Wildcard)
		GUI.tmphWildcardOption := hWildcardOption
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_LeftPair hwndhLeftPairOption Checked%LeftPairOption%, < (Left pair only)
		GUI.tmphLeftPairOption := hLeftPairOption
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_RightPair hwndhRightPairOption Checked%RightPairOption%, > (Right pair only)
		GUI.tmphRightPairOption := hRightPairOption
		
		Gui, Add, CheckBox, y+0 h20 gHotkeyGUI_UpdateHotkey hwndhUpOption Checked%UpOption%, UP (Key release)
		GUI.tmphUpOption := hUpOption
		
		;Keys
		Gui, Add, GroupBox, xs ys+140 w260 h180 hwndhKeys, Keys
		GUI.tmphKeys := hKeys
		
		Gui, Add, Radio, xs+10 ys+160 w100 h20 gHotkeyGUI_UpdateKeyList Checked%StandardKeys% hwndhStandardKeysView, Standard
		GUI.tmphStandardKeysView := hStandardKeysView
		
		Gui, Add, Radio, y+0 w100 h20 gHotkeyGUI_UpdateKeyList Checked%FunctionKeys% hwndhFunctionKeysView, Function keys
		GUI.tmphFunctionKeysView := hFunctionKeysView
		
		Gui, Add, Radio, y+0 w100 h20 gHotkeyGUI_UpdateKeyList Checked%NumpadKeys% hwndhNumpadKeysView, Numpad
		GUI.tmphNumpadKeysView := hNumpadKeysView
		
		Gui, Add, Radio, y+0 w100 h20 gHotkeyGUI_UpdateKeyList Checked%MouseKeys% hwndhMouseKeysView, Mouse
		GUI.tmphMouseKeysView := hMouseKeysView
		
		Gui, Add, Radio, y+0 w100 h20 gHotkeyGUI_UpdateKeyList Checked%MultimediaKeys% hwndhMultimediaKeysView, Multimedia
		GUI.tmphMultimediaKeysView := hMultimediaKeysView
		
		Gui, Add, Radio, y+0 w100 h20 gHotkeyGUI_UpdateKeyList Checked%SpecialKeys% hwndhSpecialKeysView, Special
		GUI.tmphSpecialKeysView := hSpecialKeysView
		
		Gui, Add, ListBox, xs+130 ys+160 w120 h150 gHotkeyGUI_UpdateHotkey hwndhKeyList
		GUI.tmphKeyList := hKeyList
		
		;Hotkey Display
		Gui, Add, Text, xs ys+332 w40 h20 hwndhHotkeyLabel, Hotkey:
		GUI.tmphHotkeyLabel := hHotkeyLabel
		
		Gui, Add, Edit, x+5 ys+330 w215 h20 +ReadOnly hwndhHotkey
		GUI.tmphHotkey := hHotkey
		GUI.tmpHotkey := this.Key
		this.GuiShow("", "UpdateKeyList")
		
		return
	}

	GuiSubmit(GUI)
	{
		;Any key?
		if(!GUI.tmpHotkey)
		{
			MsgBox 262160, Select Hotkey Error, A key must be selected.
			Abort := true
		}
		
		;[===================]
		;[  Collision Check  ]
		;[===================]
		if(this.CollisionCheck(GUI.tmpHotkey, 0, ""))
		{
			MsgBox 262160, Select Hotkey Error, This hotkey is already in use.
			Abort := true
		}
		this.Key := GUI.tmpHotkey
		
		WinKill, % "ahk_id " GUI.tmphModifier
		WinKill, % "ahk_id " GUI.tmphCtrlModifier
		WinKill, % "ahk_id " GUI.tmphShiftModifier
		WinKill, % "ahk_id " GUI.tmphWinModifier
		WinKill, % "ahk_id " GUI.tmphAltModifier
		WinKill, % "ahk_id " GUI.tmphOptionalAttributes
		WinKill, % "ahk_id " GUI.tmphNativeOption
		WinKill, % "ahk_id " GUI.tmphWildcardOption
		WinKill, % "ahk_id " GUI.tmphLeftPairOption
		WinKill, % "ahk_id " GUI.tmphRightPairOption
		WinKill, % "ahk_id " GUI.tmphUpOption
		WinKill, % "ahk_id " GUI.tmphKeys
		WinKill, % "ahk_id " GUI.tmphStandardKeysView
		WinKill, % "ahk_id " GUI.tmphFunctionKeysView
		WinKill, % "ahk_id " GUI.tmphNumpadKeysView
		WinKill, % "ahk_id " GUI.tmphMouseKeysView
		WinKill, % "ahk_id " GUI.tmphMultimediaKeysView
		WinKill, % "ahk_id " GUI.tmphSpecialKeysView
		WinKill, % "ahk_id " GUI.tmphKeyList
		WinKill, % "ahk_id " GUI.tmphHotkeyLabel
		WinKill, % "ahk_id " GUI.tmphHotkey
		;Return to sender
		return Abort = true
	}
	;Checks if a hotkey is not used internally by 7plus and may be used for a custom hotkey trigger
	CollisionCheck(key1,filter1,exclude)
	{
		7PlusHotkeys := "#e,^i,^t,^Tab,^+Tab,^w"
		if(key1 = exclude) 
			return false
		key1_Win := InStr(key1, "#") > 0
		key1_Alt := InStr(key1, "!") > 0
		key1_Control := InStr(key1, "^") > 0
		key1_Shift := InStr(key1, "+") > 0
		key1_Left := InStr(key1, "<") > 0 || !InStr(key1, ">")
		key1_Right := InStr(key1, ">") > 0 || !InStr(key1, "<")
		key1_WildCard := InStr(key1, "*") > 0
		key1_stripped := RegExReplace(key1, "[\*\+\^#><!~]*")
		Loop, parse, 7PlusHotkeys, `,,%A_Space%
		{
			key2 := A_LoopField
			key2_Win := InStr(key2, "#") > 0
			key2_Alt := InStr(key2, "!") > 0
			key2_Control := InStr(key2, "^") > 0
			key2_Shift := InStr(key2, "+") > 0
			key2_Left := InStr(key2, "<") > 0 || !InStr(key2, ">")
			key2_Right := InStr(key2, ">") > 0 || !InStr(key2, "<")
			key2_WildCard := InStr(key2, "*") > 0
			key2_stripped := RegExReplace(key2, "[\*\+\^#><!~]*")
			DirCollision:=((key1_Left = true && key1_Left = key2_Left)||(key1_Right = true && key1_Right = key2_Right))
			KeyCollision:=(key1_stripped = key2_stripped)
			StateCollision:=((key1_Win = key2_Win && key1_Alt = key2_Alt && key1_Control = key2_Control && key1_Shift = key2_Shift) || key1_WildCard || key2_WildCard)
			if(KeyCollision && StateCollision && DirCollision)
				return true
		}
		return false
	}
}
HotkeyGUI_UpdateHotkey:
GetCurrentSubEvent().GuiShow("", "UpdateHotkey")
return
HotkeyGUI_LeftPair:
GetCurrentSubEvent().GuiShow("","LeftPair")
return
HotkeyGUI_RightPair:
GetCurrentSubEvent().GuiShow("","RightPair")
return
HotkeyGUI_UpdateKeyList:
GetCurrentSubEvent().GuiShow("","UpdateKeyList")
return

#if IsObject(HotkeyShouldFire(A_ThisHotkey))
HotkeyTrigger:
HotkeyTrigger(A_ThisHotkey)
return
#if

;Handler for hotkeys that contain a tilde
#if IsObject(HotkeyShouldFire( A_ThisHotkey))
HotkeyTrigger2:
HotkeyTrigger(A_ThisHotkey)
return
#if
HotkeyTrigger(key)
{
	outputdebug, % "Hotkey triggered, key: " A_ThisHotkey
	if(!key)
		return 0
	if(!IsObject(HotkeyShouldFire(A_ThisHotkey)))
		return 0
	Trigger := new CHotkeyTrigger()
	Trigger.Key := StringReplace(key,"$") ;Remove $ because it is not stored
	EventSystem.OnTrigger(Trigger)
}

HotkeyShouldFire(key)
{
	key := StringReplace(key,"$")
	key := StringReplace(key,"~")
	for index, Event in EventSystem.Events
	{
		if(!Event.Trigger.Is(CHotkeyTrigger) || StringReplace(Event.Trigger.Key, "~") != key)
			continue
		
		if(!(enable := Event.CheckConditions(false)))
			continue
		
		;Don't swallow hotkey if event only allows one instance and it is already running
		if(Event.OneInstance)
			for index2, ScheduledEvent in EventSystem.EventSchedule
				if(ScheduledEvent.ID = Event.ID)
				{
					enable := false
					break
				}
		if(enable)
			return Event.Trigger
	}
	return 0
}

FormatHotkey(key)
{
	formatted .= InStr(key, "*") > 0 ? "Any Modifier key + " : ""
	formatted .= InStr(key, "#") > 0 ? "WIN + " : ""
	formatted .= InStr(key, "^") > 0 ? "CONTROL + " : ""
	formatted .= InStr(key, "!") > 0 ? "ALT + " : ""
	formatted .= InStr(key, "+") > 0 ? "SHIFT + " : ""
	formatted .= RegExReplace(key, "[\*\+\^#><!~]*")
	formatted .= InStr(key, "<") > 0 ? ", left modifier keys only" :""
	formatted .= InStr(key, ">") > 0 ? ", right modifier keys only" :""
	formatted := StringReplace(formatted, "LButton", "Left Mouse")
	formatted := StringReplace(formatted, "MButton", "Middle Mouse")
	formatted := StringReplace(formatted, "RButton", "Right Mouse")
	return formatted
}

ExtractKey(Hotkey)
{
	Key := StringReplace(Hotkey, "*", "")
	Key := StringReplace(Key, "~", "")
	Key := StringReplace(Key, "<", "")
	Key := StringReplace(Key, ">", "")
	Key := StringReplace(Key, " UP", "")
	Key := StringReplace(Key, "^", "")
	Key := StringReplace(Key, "+", "")
	Key := StringReplace(Key, "#", "")
	Key := StringReplace(Key, "!", "")
	return Key
}