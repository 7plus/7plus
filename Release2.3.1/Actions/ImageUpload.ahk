Class CImageUploadAction Extends CAction
{
	static Type := RegisterType(CImageUploadAction, "Upload image to image hoster")
	static Category := RegisterCategory(CImageUploadAction, "Internet")
	static Hoster := "ImgUr"
	static SourceFiles := "${SelNM}" ;All upload actions need to have SourceFiles property (used in ImageConverter)
	static CopyToClipboard := 1

	__New()
	{
		;Setup the message handler for receiving image upload progress notifications
		OnMessage(55556, "Action_ImageUpload_ProgressHandler")
	}
	DisplayString()
	{
		return "Upload images: " this.SourceFiles
	}
	Execute(Event)
	{
		if(!this.HasKey("tmpFiles"))
		{
			Files := Event.ExpandPlaceholders(this.SourceFiles)
			this.tmpFiles := ToArray(Files)
			this.tmpFailed := Array()
			if(this.tmpFiles.MaxIndex() < 1)
				return 0
			else
				this.tmpFile := 1
		}
		if(this.HasKey("tmpFiles"))
		{
			if(this.tmpFile > this.tmpFiles.MaxIndex()) ;All uploads finished
			{
				if(this.CopyToClipboard)
					Clipboard := this.tmpClipboard
				this.tmpNotificationWindow.Close()
				if(this.tmpFailed.MaxIndex() = 0)
					Notify("Transfer finished", "File(s) uploaded" (this.CopyToClipboard ? " and copied to clipboard" : ""), 2, NotifyIcons.Success)
				else if(this.tmpFailed.MaxIndex() = this.tmpFiles.MaxIndex() && this.tmpFiles.MaxIndex() > 0)
					Notify("Transfer failed", "Maybe the file extension is not supported by this hoster?", 5, NotifyIcons.Error, "FTP_Notify_Error")
				else
					Notify("Transfer partially failed", "The following files could not be transferred:`n" this.tmpFailed.ToString(), 5, NotifyIcons.Error, "FTP_Notify_Error")
				this.Remove("tmpNotificationWindow")
				this.Remove("tmpFiles")
				this.Remove("tmpFile")
				this.Remove("tmpClipboard")
				this.Remove("tmpFailed")
				return 1
			}
			if(!IsObject(this.tmpWorkerThread))
			{
				File := this.tmpFiles[this.tmpFile]
				if(!FileExist(File) || !File)
				{
					this.tmpFile++
					return -1
				}
				this.tmpWorkerThread := new CWorkerThread("ImageUploadThread", 0, 1, 1)
				this.tmpWorkerThread.OnProgress.Handler := "Action_ImageUpload_ProgressHandler"
				this.tmpWorkerThread.OnStop.Handler := "Action_ImageUpload_OnStop"
				this.tmpWorkerThread.OnFinish.Handler := "Action_ImageUpload_OnFinish"
				this.tmpWorkerThread.Start(File, Event.EventScheduleID, this.Hoster, Event.Actions.IndexOf(this))
				return -1
			}
			else ;Upload still running, keep Action in EventSchedule
				return -1
		}
		return 0 ;No files
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action uploads images to image hosters. Currently only ImgUr is supported, others may follow.")		
			this.AddControl(GUI, "DropDownList", "Hoster", GetImageHosterList().ToString("|"), "", "Hoster:")
			this.AddControl(GUI, "Edit", "SourceFiles", "", "", "Files:", "Placeholders", "Action_ImageUpload_Placeholders_Files")
			this.AddControl(GUI, "Edit", "LinksPlaceholder", "", "", "Links Placeholder:", "", "","","","Name only, without ${}")
			this.AddControl(GUI, "Checkbox", "CopyToClipboard", "Copy links to clipboard")
		}
		else if(GoToLabel = "Placeholders_Files")
			ShowPlaceholderMenu(sGUI, "SourceFiles")
	}
}
Action_ImageUpload_Placeholders_Files:
GetCurrentSubEvent().GuiShow("", "Placeholders_Files")
return

;This is called in the main 7plus process when a status message from an upload process is received
Action_ImageUpload_ProgressHandler(WorkerThread, Progress)
{
	EventScheduleID := WorkerThread.Task.Parameters[2]
	Event := EventSystem.EventSchedule.GetItemWithValue("EventScheduleID", EventScheduleID)
	Action := Event.Actions[WorkerThread.Task.Parameters[4]]
	if(!Action.HasKey("tmpNotificationWindow"))
	{
		Action.tmpNotificationWindow := Notify("Uploading " Action.tmpFiles.MaxIndex() " file" (Action.tmpFiles.MaxIndex() > 1 ? "s" : "" ) " to " Action.Hoster,"File " Action.tmpFile ": " Action.tmpFiles[Action.tmpFile], "", NotifyIcons.Internet, "", {min : 0, max : 100, value : 0})
		return
	}
	Action.tmpNotificationWindow.Progress := Progress
	Action.tmpNotificationWindow.Text := "File " Action.tmpFile ": " Action.tmpFiles[Action.tmpFile]
}
Action_ImageUpload_OnStop(WorkerThread, Reason)
{
	EventScheduleID := WorkerThread.Task.Parameters[2]
	Event := EventSystem.EventSchedule.GetItemWithValue("EventScheduleID", EventScheduleID)
	Action := Event.Actions[WorkerThread.Task.Parameters[4]]
	Action.tmpFailed.Insert(Action.tmpFiles[Action.tmpFile])
	Action.tmpFile++
	Action.Remove("tmpWorkerThread")
}
Action_ImageUpload_OnFinish(WorkerThread, Result)
{
	EventScheduleID := WorkerThread.Task.Parameters[2]
	Event := EventSystem.EventSchedule.GetItemWithValue("EventScheduleID", EventScheduleID)
	Action := Event.Actions[WorkerThread.Task.Parameters[4]]
	
	;Code to read link and copy to clipboard
	FileRead, Link, %A_Temp%\7plus\Upload%EventScheduleID%.txt
	FileDelete, %A_Temp%\7plus\Upload%EventScheduleID%.txt
	Action.tmpClipboard .= (Action.tmpClipboard ? "`n" : "") Link
	Action.tmpFile++
	Action.Remove("tmpWorkerThread")
}
	
GetImageHosterList()
{
	return Array("ImgUr")
}

;This function is run in another 7plus process to prevent blocking the only available real thread
ImageUploadThread(WorkerThread, File, EventScheduleID, Hoster, ActionIndex)
{
	if(!FileExist(File))
	{
		WorkerThread.Stop()
		return
	}
	URL := %Hoster%_Upload(File,xml)
	If(URL)
		FileAppend, %URL%, %A_Temp%\7plus\Upload%EventScheduleID%.txt
	else
		WorkerThread.Stop()
}

Imgur_Upload( image_file, byref output_XML="" ) { ; ----------------------------- 
; Uploads one image file to Imgur via the anonymous API and returns the URL to the image. 
; To acquire an anonymous API key, please register at http://imgur.com/register/api_anon. 
; This function was written by [VxE] and relies on the HTTPRequest function, also by [VxE]. 
; HTTPRequest can be found at http://www.autohotkey.com/forum/viewtopic.php?t=73040 
   Static Imgur_Upload_Endpoint := "http://api.imgur.com/2/upload.xml" 
   Static Anonymous_API_Key := Decrypt("F5QTo=^aqmf^h|C}@ERLI;GG;T>sjV""t")
   FileGetSize, size, % image_file 
   FileRead, output_XML, % "*c " image_file 
   If HTTPRequest( Imgur_Upload_Endpoint "?key=" Anonymous_API_Key, output_XML 
      , Response_Headers := "Content-Type: application/octet-stream`nContent-Length: " size 
      , "Callback: Imgur_Callback" ) 
   && ( pos := InStr( output_XML, "<original>" ) ) 
      Return SubStr( output_XML, pos + 10, Instr( output_XML, "</original>", 0, pos ) - pos - 10 ) 
   Else Return "" ; error: see response 
} ; Imgur_Upload( image_path, Anonymous_API_Key, byref output_XML="" ) ----------------------------- 

;Callback from ImgUr_Upload()
Imgur_Callback(Percent, FileSize)
{
	global WorkerThread
	If(Percent <= 0 && Percent >= -1)
		WorkerThread.Progress := Round((Percent + 1) * 100)
}