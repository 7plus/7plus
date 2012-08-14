Class CChecksumDialogAction Extends CAction
{
	static Type := RegisterType(CChecksumDialogAction, "Show Explorer checksum dialog")
	static Category := RegisterCategory(CChecksumDialogAction, "Explorer")	
	static Files := "${SelNM}"
	
	Execute(Event)
	{
		if(!this.tmpGuiNum)
		{
			result := MD5Dialog(Event.ExpandPlaceHolders(this.Files))
			if(result) ;
			{
				this.tmpGuiNum := result
				return -1
			}
			else
				return 0 ;Msgbox wasn't created
		}
		else
		{
			GuiNum := this.tmpGuiNum
			Gui,%GuiNum%:+LastFound 
			WinGet, MD5_hwnd,ID
			DetectHiddenWindows, Off
			If(WinExist("ahk_id " MD5_hwnd)) ;Box not closed yet, need more processing time
				return -1
			else
				return 1 ;Box closed, all fine
		}
	}
	
	DisplayString()
	{
		return "Calculate MD5 Checksum on " this.Files
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Files", "", "", "Files:", "Placeholders", "Action_MD5_Files_Placeholders")
		}
		else if(GoToLabel = "Files_Placeholders")
			ShowPlaceholderMenu(sGUI, "Files")
	}
}
Action_MD5_Files_Placeholders:
GetCurrentSubEvent().GuiShow("", "Files_Placeholders")
return


;Non blocking MD5 box (can wait for closing in event system though)
MD5Dialog(Files) 
{
	static MD5ListView, l_GUI, sFiles
	outputdebug files %files%
	if(!IsObject(Files))
		Files := ToArray(Files)
	if(!(Files.MaxIndex() > 0))
	{
		Notify("MD5 Checksums Error!", "Invalid Files specified!", 5, NotifyIcons.Error)
		return 0
	}
	WasCritical := A_IsCritical
	Critical, Off
	;Check if MD5Checksum window is already open
	if(l_GUI)
	{		
		Gui, ListView, MD5ListView
		Loop % Files.MaxIndex()
		{
			if(sFiles.IndexOf(Files[A_Index]) = 0)
			{
				LV_Add("",Files[A_Index], FileMD5(Files[A_Index]))
				sFiles.Insert(Files[A_Index])
			}
		}
		Gui, %l_GUI%:Show
		return
	}
	l_GUI:=GetFreeGUINum(10)
	sFiles := Files.DeepCopy()
	if(!l_GUI)
		return
	
	Gui, %l_GUI%:Default
	Gui, Destroy 
	Gui, Add,ListView,vMD5ListView w600 R20,File|MD5 Checksum
         
	Gui, Add,Button,% "Default y+10 x420 w100 gMD5Copy",Copy checksums
	Gui, Add,Button,% "Default x+10 w80 gMD5Close",Close
         
	Gui, -MinimizeBox -MaximizeBox +LabelMD5 +AlwaysOnTop
	Gui, Show,,MD5 Checksums
	Loop % sFiles.MaxIndex()
	{
		if(!InStr(FileExist(sFiles[A_Index]), "D"))
		{
			Gui, ListView, MD5ListView
			LV_Add("", sFiles[A_Index], FileMD5(sFiles[A_Index]))
		}
	}
	LV_ModifyCol(1, 370)
	LV_ModifyCol(2, "AutoHdr")
	if(WasCritical)
		Critical
	;return Gui number to indicate that the MD5 box is still open
	return l_GUI
	
	MD5Close:
	MD5Escape:
	Gui, Destroy
	sFiles := ""
	l_GUI := ""
	return
	MD5Copy:
	Gui, ListView, MD5ListView
	Clip := ""
	Loop % LV_GetCount()
	{
		LV_GetText(File, A_Index, 1)
		LV_GetText(MD5, A_Index, 2)
		Clip .= (A_Index = 1 ? "" : "`n") File " : " MD5
	}
	if(Clip != "")
		Clipboard := Clip
	return
}