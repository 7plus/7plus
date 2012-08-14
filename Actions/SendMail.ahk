Class CSendMailAction Extends CAction
{
	static Type := RegisterType(CSendMailAction, "Send an email")
	static Category := RegisterCategory(CSendMailAction, "Internet")
	static __WikiLink := "SendMail"
	
	static From     := "...@gmail.com"
	static To       := "anybody@somewhere.com"
	static Subject  := "Message Subject"
	static Body     := "Message Body"
	static Attach   := "Path_Of_Attachment" ; can add multiple attachments, the delimiter is |
	static Server   := "smtp.gmail.com" ; specify your SMTP server
	static Port     := 465 ; 25
	static TLS      := True ; False
	static Username := "...@gmail.com"
	static Password := ""
	static Timeout := 10
	
	Execute(Event)
	{
		WorkerThread := new CWorkerThread("SendMail_WorkerThread", 0, 1, 1)
		WorkerThread.OnFinish.Handler := "SendMail_OnFinish"
		Parameters := {}
		Parameters.From     := Event.ExpandPlaceholders(this.From)
		Parameters.To       := Event.ExpandPlaceholders(this.To)
		Parameters.Subject  := Event.ExpandPlaceholders(this.Subject)
		Parameters.Body     := Event.ExpandPlaceholders(this.Body)
		Parameters.Attach   := Event.ExpandPlaceholders(this.Attach) ; can add multiple attachments, the delimiter is |

		Parameters.Server   := Event.ExpandPlaceholders(this.Server) ; specify your SMTP server
		Parameters.Port     := Event.ExpandPlaceholders(this.Port) ; 25
		Parameters.TLS      := Event.ExpandPlaceholders(this.TLS) ; False
		Parameters.Send     := 2   ; cdoSendUsingPort
		Parameters.Auth     := 1   ; cdoBasic
		Parameters.Username := Event.ExpandPlaceholders(this.Username)
		Parameters.Password := Encrypt(Event.ExpandPlaceholders(Decrypt(this.Password)))
		Parameters.Timeout 	:= this.Timeout
		WorkerThread.Start(Parameters)
		return 1
	} 

	DisplayString()
	{
		return "Send mail to " this.To
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.Password := Decrypt(this.Password)
			this.AddControl(GUI, "Edit", "From", "", "", "From:", "Placeholders", "Action_SendMail_Placeholders_From")
			this.AddControl(GUI, "Edit", "To", "", "", "To:", "Placeholders", "Action_SendMail_Placeholders_To")
			this.AddControl(GUI, "Edit", "Subject", "", "", "Subject:", "Placeholders", "Action_SendMail_Placeholders_Subject")
			this.AddControl(GUI, "Edit", "Body", "", "", "Body:", "Placeholders", "Action_SendMail_Placeholders_Body")
			this.AddControl(GUI, "Edit", "Attach", "", "", "Attach:", "Browse", "Action_SendMail_Browse", "Placeholders", "Action_SendMail_Placeholders_Attach")
			this.AddControl(GUI, "Edit", "Server", "", "", "Server:", "Placeholders", "Action_SendMail_Placeholders_Server")
			this.AddControl(GUI, "Edit", "Port", "", "", "Port:", "Placeholders", "Action_SendMail_Placeholders_Port")
			this.AddControl(GUI, "Checkbox", "TLS", "TLS")
			this.AddControl(GUI, "Edit", "Username", "", "", "Username:", "Placeholders", "Action_SendMail_Placeholders_Username")
			this.AddControl(GUI, "Edit", "Password", "", "", "Password:", "Placeholders", "Action_SendMail_Placeholders_Password")
			this.AddControl(GUI, "Edit", "Timeout", "", "", "Timeout:")
		}
		else if(GoToLabel = "Browse")
			this.SelectFile(sGUI, "Attach")
		else if(InStr(GoToLabel, "Action_SendMail_Placeholders_") = 1)
			ShowPlaceholderMenu(sGUI, SubStr(GoToLabel, 30))
	}
	GuiSubmit(GUI)
	{
		Base.GuiSubmit(GUI)
		this.Password := Encrypt(this.Password)
	}
}
Action_SendMail_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return

Action_SendMail_Placeholders_From:
Action_SendMail_Placeholders_To:
Action_SendMail_Placeholders_Subject:
Action_SendMail_Placeholders_Body:
Action_SendMail_Placeholders_Attach:
Action_SendMail_Placeholders_Server:
Action_SendMail_Placeholders_Port:
Action_SendMail_Placeholders_Username:
Action_SendMail_Placeholders_Password:
GetCurrentSubEvent().GuiShow("", A_ThisLabel)
return

;Called in a separate instance to improve reliability
SendMail_WorkerThread(WorkerThread, Parameters)
{
	Critical ;Needed for reliability apparently, even in separate thread
	pmsg :=   ComObjCreate("CDO.Message")
	pcfg :=   pmsg.Configuration
	pfld :=   pcfg.Fields
	
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") := Parameters.Send
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") := Parameters.Timeout
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") := Parameters.Server
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") := Parameters.Port
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/smtpusessl") := Parameters.TLS
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") := Parameters.Auth
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/sendusername") := Parameters.Username
	pfld.Item("http://schemas.microsoft.com/cdo/configuration/sendpassword") := Decrypt(Parameters.Password)
	pfld.Update()
	
	pmsg.From := Parameters.From
	pmsg.To := Parameters.To
	pmsg.Subject := Parameters.Subject
	pmsg.TextBody := Parameters.Body
	Attach := Parameters.Attach
	Loop, Parse, Attach, |, %A_Space%%A_Tab%
		pmsg.AddAttachment(A_LoopField)
	pmsg.Send()
	Critical, Off
	return A_LastError
}
SendMail_OnFinish(WorkerThread, Result)
{
	if(Result)
		Notify(this.Type " Error!", FormatMessageFromSystem(Result), 5, NotifyIcons.Error) 
}
