;CTRL+U:Upload selected files
#if FTP_Enabled && (WinActive("ahk_group ExplorerGroup")||WinActive("ahk_group DesktopGroup")||IsDialog())
^u::
	files:=GetSelectedFiles()
	if(files)
		Upload(files)
	return
#If
;Alt+Insert:Upload full screenshot, Win+Insert: Upload screenshot of active window, Win+Delete: Upload text/image from clipboard
#if FTP_Enabled
!Insert::
#Insert::
	MuteClipboardSurveillance:=true
	outputdebug mute 11
	MuteClipboardList:=true
	clipboard:=""
	ClipWait , 0.05, 1
	outputdebug mute 12
	MuteClipboardList:=true
	if(!GetKeyState("Alt"))
		Send !{PrintScreen}
	else
		Send {PrintScreen}
	ClipWait , 1, 1	
	MuteClipboardList:=false
	MuteClipboardSurveillance:=false
	outputdebug pre upload mute: %muteclipboardlist%
	if(!Errorlevel)
	{
		UploadfromClipboard()
		outputdebug post upload mute: %muteclipboardlist%
	}
	else
	{
		ToolTip(1, "Couldn't take a screenshot", "Couldn't take a screenshot","O1 L1 P99 C1 XTrayIcon YTrayIcon I4")
		SetTimer, ToolTipClose, -5000
	}
	return
#Delete::
	UploadfromClipboard()
	return
#if

;Uploads files (separated by newline) to FTP server and copies the links to clipboard
Upload(Files)
{
	global FTP_Host, FTP_Port, FTP_Username, FTP_Password,FTP_Path,FTP_URL
	outputdebug upload %files%
	result:=FtpOpen(FTP_Host, FTP_Port, FTP_Username, FTP_Password)
	cliptext=
	if(result=1)
	{
		Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds ('r`n). 
	  {
	  	SplitPath A_LoopField, file
	   	result:=FtpPutFile(A_LoopField,FTP_Path file) 
	   	if(result=0)
			{
				ToolTip(1, "Couldn't upload " FTP_Path file " properly. Make sure you have write rights and the path exists", "Couldn't upload file","O1 L1 P99 C1 XTrayIcon YTrayIcon I4")
				SetTimer, ToolTipClose, -5000
		 	}
			else
			{
				if(A_Index=1)
				{
					cliptext:=FTP_URL file
				}else
				{
					cliptext:=cliptext . "`r`n" . FTP_URL file
				}
			}
	  }
	  FtpClose()
	  outputdebug clipboard: %cliptext%
	  clipboard:=cliptext
	  ToolTip(1, "File uploaded and links copied to clipboard", "Transfer finished","O1 L1 P99 C1 XTrayIcon YTrayIcon I4")
		SetTimer, ToolTipClose, -2000
		SoundBeep
  }
	else
	{
		ToolTip(1, "Couldn't connect to " FTP_Host ". Correct host/username/password?", "Connection Error","O1 L1 P99 C1 XTrayIcon YTrayIcon I4")
		SetTimer, ToolTipClose, -5000
	}
}
;Uploads text/image from clipboard and puts links in clipboard
UploadFromClipboard()
{
	text:=DllCall("IsClipboardFormatAvailable", "Uint", 1)
	image:=DllCall("IsClipboardFormatAvailable", "Uint", 2)
	outputdebug text: %text% image: %image%
	if(text||image)
	{
		InputBox, Destination, "File Upload", "Enter a filename"
		if !Errorlevel
		{			
			SplitPath, Destination, OutFileName, , OutExtension, OutNameNoExt
			if text
			{
				Destination:=OutFileName
				if(OutNameNoExt=OutFileName)
					Destination:=OutNameNoExt ".txt"			
				WriteClipboardTextToFile(A_Temp "\" Destination)
			}
			else if image
			{
				if(!(OutExtension="jpg"||OutExtension="png"||OutExtension="bmp"))
				{
					Destination:=OutNameNoExt ".png"
				}	
				WriteClipboardImageToFile(A_Temp "\" Destination)			
			}
			outputdebug destination: %A_Temp%\%Destination%
			Upload(A_Temp "\" Destination)
		}
	}	
	return
}

;Called on startup and on config change and ensures that FTP variables have correct format
ValidateFTPVars()
{
	global
	outputdebug validateftpvars
	FTP_Host:=strTrimRight(FTP_Host,"/")
	FTP_Path:=FTP_Path="" ? "/" : strTrim(FTP_Path,"/") "/"
	FTP_URL:=strTrimRight(FTP_URL,"/") "/"
	return
}
