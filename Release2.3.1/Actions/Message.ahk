Class CMessageAction Extends CAction
{
	static Type := RegisterType(CMessageAction, "Message")
	static Category := RegisterCategory(CMessageAction, "Input/Output")
	static Text := "Example Message"
	static Title := "7plus"
	static Timeout := 0
	Execute(Event)
	{
		if(!this.tmpGuiNum)
		{
			result := CustomMsgBox(Event.ExpandPlaceHolders(this.Title), Event.ExpandPlaceHolders(this.Text))
			if(result) ;
			{
				this.tmpGuiNum := result
				this.Time := A_TickCount
				return -1
			}
			else
				return 0 ;Msgbox wasn't created
		}
		else
		{
			GuiNum := this.tmpGuiNum
			;outputdebug waiting for messagebox close %guinum%
			Gui,%GuiNum%:+LastFound 
			WinGet, Msgbox_hwnd,ID
			DetectHiddenWindows, Off
			;outputdebug %A_IsCritical%
			If(WinExist("ahk_id " Msgbox_hwnd)) ;Box not closed yet, need more processing time
			{
				if(this.Timeout * 1000 > 0 && A_TickCount - this.Time > this.Timeout * 1000)
				{
					Gui, %GuiNum%:Destroy 
					return 0
				}
				return -1
			}
			else
				return 1 ;Box closed, all fine
		}
	}
	DisplayString()
	{
		return "Message " this.Text
	}

	GuiShow(ActionGUI, GoToLabel = "")
	{
		static sActionGUI
		if(GoToLabel = "")
		{
			sActionGUI := ActionGUI
			this.AddControl(ActionGUI, "Text", "Desc", "This action shows a message box.")
			this.AddControl(ActionGUI, "Edit", "Text", "", "", "Text:", "Placeholders", "Action_Message_Text_Placeholders")
			this.AddControl(ActionGUI, "Edit", "Title", "", "", "Window Title:", "Placeholders", "Action_Message_Title_Placeholders")
			this.AddControl(ActionGUI, "Edit", "Timeout", "", "", "Timeout:","","","","","The message box is closed after this time.`nUse 0 or empty string to disable timeout.")
		}
		else if(GoToLabel = "Text_Placeholders")
			ShowPlaceholderMenu(sActionGUI, "Text")
		else if(GoToLabel = "Title_Placeholders")
			ShowPlaceholderMenu(sActionGUI, "Title")
	}
}
Action_Message_Text_Placeholders:
GetCurrentSubEvent().GuiShow("", "Text_Placeholders")
return

Action_Message_Title_Placeholders:
GetCurrentSubEvent().GuiShow("", "Title_Placeholders")
return

;Non blocking message box (can wait for closing in event system though)
CustomMsgBox(Title,Message) 
{
	WasCritical := A_IsCritical
	Critical, Off
	l_GUI := GetFreeGUINum(1, "MsgBox")
	if(!l_GUI)
		return 0
	Gui,%l_GUI%:Destroy 
	Gui,%l_GUI%:Add,Text,,%Message%

	Gui,%l_GUI%:Add,Button,% "Default y+10 w75 gCustomMsgboxOK xp+" (TextW / 2) - 38 ,OK 

	Gui,%l_GUI%:-MinimizeBox -MaximizeBox +LabelCustomMsgbox +AlwaysOnTop
	SoundPlay,*-1
	Gui,%l_GUI%:Show,,%Title% 
	
	if(WasCritical)
		Critical
	;return Gui number to indicate that the message box is still open
	return l_GUI
}

CustomMsgboxClose:
CustomMsgboxEscape:
CustomMsgboxOK: 
Gui, Destroy 
return