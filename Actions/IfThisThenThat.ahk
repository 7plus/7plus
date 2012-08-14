Class CIfThisThenThatAction Extends CAction
{
	static Type := RegisterType(CIfThisThenThatAction, "Trigger an ""If this then that"" recipe")
	static Category := RegisterCategory(CIfThisThenThatAction, "Internet")
	static __WikiLink := "IfThisThenThat"
	static Tag  := "Message Subject"
	static Body     := "Message Body"
	static Attach   := "Path_Of_Attachment" ; can add multiple attachments, the delimiter is |
	
	Execute(Event)
	{
		WorkerThread := new CWorkerThread("SendMail_WorkerThread", 0, 1, 1)
		WorkerThread.OnFinish.Handler := "IFTT_OnFinish"
		Parameters := {}
		Parameters.From     := Settings.IFTTT.From
		Parameters.To       := "trigger@ifttt.com"
		Parameters.Subject  := Event.ExpandPlaceholders(this.Tag)
		Parameters.Body     := Event.ExpandPlaceholders(this.Body)
		Parameters.Attach   := Event.ExpandPlaceholders(this.Attach) ; can add multiple attachments, the delimiter is |

		Parameters.Server   := Settings.IFTTT.Server
		Parameters.Port     := Settings.IFTTT.Port
		Parameters.TLS      := Settings.IFTTT.TLS
		Parameters.Send     := 2   ; cdoSendUsingPort
		Parameters.Auth     := 1   ; cdoBasic
		Parameters.Username := Settings.IFTTT.Username
		Parameters.Password := Settings.IFTTT.Password
		Parameters.Timeout 	:= Settings.IFTTT.Timeout
		WorkerThread.Start(Parameters)
		return 1
	} 

	DisplayString()
	{
		return "Trigger email IFTTT recipe with tag " this.Tag
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Tag", "", "", "Tag:", "Placeholders", "Action_IFTTT_Placeholders_Tag")
			this.AddControl(GUI, "Edit", "Body", "", "", "Body:", "Placeholders", "Action_IFTTT_Placeholders_Body")
			this.AddControl(GUI, "Edit", "Attach", "", "", "Attach:", "Browse", "Action_IFTTT_Browse", "Placeholders", "Action_IFTTT_Placeholders_Attach")
		}
		else if(GoToLabel = "Browse")
			this.SelectFile(sGUI, "Attach")
		else if(InStr(GoToLabel, "Action_IFTTT_Placeholders_") = 1)
			ShowPlaceholderMenu(sGUI, SubStr(GoToLabel, 30))
	}
}
Action_IFTTT_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return

Action_IFTTT_Placeholders_Tag:
Action_IFTTT_Placeholders_Body:
Action_IFTTT_Placeholders_Attach:
GetCurrentSubEvent().GuiShow("", A_ThisLabel)
return

IFTTT_OnFinish(WorkerThread, Result)
{
	if(Result)
		Notify(this.Type " Error!", FormatMessageFromSystem(Result), 5, NotifyIcons.Error) 
}