Class CImageConverterAction Extends CAction
{
	static Type := RegisterType(CImageConverterAction, "Show Image Converter")
	static Category := RegisterCategory(CImageConverterAction, "7plus")
	static Files := "${SelNM}"
	static Hoster := "ImgUr"
	static FTPTargetDir := ""
	static TemporaryFiles := false
	static ReuseWindow := false
	static TargetPath := "%Desktop%"
	Execute(Event)
	{
		Files := Event.ExpandPlaceholders(this.Files)
		if(this.ReuseWindow)
			for index, window in CImageConverter.Instances ;Find existing instance of window
				if(window.ReuseWindow)
				{
					ImageConverter := window
					break
				}
		if(!ImageConverter)
			ImageConverter := new CImageConverter(this)
		ImageConverter.AddFiles(Files)
		return 1
	}

	DisplayString()
	{
		return "Open Image Converter: " this.Files
	}
	
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Files", "", "", "Files:", "Placeholders", "Action_ImageConverter_Placeholders")
			Loop % CFTPUploadAction.FTPProfiles.MaxIndex()
				Hosters .= "|" A_Index ": " CFTPUploadAction.FTPProfiles[A_Index].Hostname
			Hosters .= "|" GetImageHosterList().ToString("|")
			this.AddControl(GUI, "DropDownList", "Hoster", Hosters, "", "IMG Hoster:","","","","","FTP profiles which are created on their specific sub page in the settings window can be used here.")
			this.AddControl(GUI, "Edit", "TargetDir", "", "", "Target dir:", "Placeholders", "Action_ImageConverter_Placeholders_TargetFolder")
			this.AddControl(GUI, "Edit", "FTPTargetDir", "", "", "FTP Target dir:", "Placeholders", "Action_ImageConverter_Placeholders_FTPTargetFolder")
			this.AddControl(GUI, "Checkbox", "TemporaryFiles", "Temporary files", "", "", "", "","","","If set, source files will be deleted after operation.")
			this.AddControl(GUI, "Checkbox", "ReuseWindow", "Reuse window", "", "", "", "","","","If set, all files from an action with this property will be added to the same window.`nIt's best if they are also located in the same directory.")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Files")
		else if(GoToLabel = "TargetFolder")
			ShowPlaceholderMenu(sGUI, "TargetDir")
		else if(GoToLabel = "FTPTargetFolder")
			ShowPlaceholderMenu(sGUI, "FTPTargetDir")
	}
}
Action_ImageConverter_Placeholders:
GetCurrentSubEvent().GuiShow("", "", "Placeholders")
return
Action_ImageConverter_Placeholders_TargetFolder:
GetCurrentSubEvent().GuiShow("", "", "TargetFolder")
return
Action_ImageConverter_Placeholders_FTPTargetFolder:
GetCurrentSubEvent().GuiShow("", "", "FTPTargetFolder")
return