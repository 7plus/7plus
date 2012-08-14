;Called when clipboard changes, used for "Paste text/image as file" functionality and for clipboard manager
;To use the clipboard without triggering these features, set MuteClipboardList := true before writing to clipboard
OnClipboardChange:
if(!ApplicationState.ClipboardListenerRegistered)
	OnClipboardChange()
return

OnClipboardChange()
{
	global MuteClipboardList, ClipboardList
	RaiseEvent("ClipboardChange")
	if(MuteClipboardList)
	{
		FileAppend, %A_Now%: Clipboard changed to %Clipboard% but it's muted`n, %A_Temp%\7plus\Log.log
		return
	}

	; Some programs can be ignored to protect privacy of passwords, ...
	; Note: This fails in certain cases where AHK needs to temporarily use the clipboard while sensitive content is on it.
	; An example is the GetSelectedText() function. It might be useful to try waiting in this function to skip the event
	; which apparently doesn't work right now.
	owner := GetProcessName(DllCall("GetClipboardOwner"))
	outputdebug % "owner: " owner " index: " ToArray(Settings.Misc.IgnoredPrograms, "|").indexOf(owner)
	if(ToArray(Settings.Misc.IgnoredPrograms, "|").indexOf(owner))
		return

	if(WinActive("ahk_group ExplorerGroup") || WinActive("ahk_group DesktopGroup")|| IsDialog())
		CreateFileFromClipboard()
	else
		ShowTip({Min : 1, Max : 2})
	text := ReadClipboardText()
	FileAppend, %A_Now%: Clipboard changed to %text%`n, %A_Temp%\7plus\Log.log
	if(text && IsObject(ClipboardList))
		ClipboardList.Push(text)
	return
}

;Creates a file for pasting text/image in explorer
CreateFileFromClipboard()
{
	global MuteClipboardList
	static CF_HDROP := 0xF
	MuteClipboardList := true
	if(!DllCall("IsClipboardFormatAvailable", "Uint", CF_HDROP))
	{
		If(DllCall("IsClipboardFormatAvailable", "Uint", 2) && Settings.Explorer.PasteImageAsFileName !="" )
		{
			ShowTip(3)
			PasteImageAsFilePath := A_Temp "\" Settings.Explorer.PasteImageAsFileName
			success := WriteClipboardImageToFile(PasteImageAsFilePath, Settings.Misc.ImageQuality)
			if(success)
				CopyToClipboard(PasteImageAsFilePath, false)
		}
		else if (DllCall("IsClipboardFormatAvailable", "Uint", 1) && Settings.Explorer.PasteTextAsFileName !="" )
		{
			ShowTip(3)
			PasteTextAsFilePath := A_Temp "\" Settings.Explorer.PasteTextAsFileName
			success := WriteClipboardTextToFile(PasteTextAsFilePath)
			if(success)
				CopyToClipboard(PasteTextAsFilePath, false)
		}
	}
	else
	{
		ShowTip({Min : 14, Max : 15})
		outputdebug a file is already in the clipboard
	}
	WaitForEvent("ClipboardChange", 100)
	MuteClipboardList := false
}
;Read real text (=not filenames, when CF_HDROP is in clipboard) from clipboard
ReadClipboardText()
{
	if((!A_IsUnicode && DllCall("IsClipboardFormatAvailable", "Uint", 1)) || (A_IsUnicode && DllCall("IsClipboardFormatAvailable", "Uint", 13))) ;CF_TEXT = 1 ;CF_UNICODETEXT = 13
	{
		DllCall("OpenClipboard", "Ptr", 0)	
		htext:=DllCall("GetClipboardData", "Uint", A_IsUnicode ? 13 : 1, "Ptr")
		ptext := DllCall("GlobalLock", "Ptr", htext)
		text := StrGet(pText, A_IsUnicode ? "UTF-16" : "cp0")
		DllCall("GlobalUnlock", "Ptr", htext)
		DllCall("CloseClipboard")
	}
	return text
}

;Reads an image from clipboard, saves it to a file, and puts CF_HDROP structure in clipboard for file pasting
WriteClipboardImageToFile(path,Quality="")
{
	if(!Quality)
		Quality := Settings.Misc.ImageQuality
	pBitmap := Gdip_CreateBitmapFromClipboard()
	if(pBitmap > 0)
	{
		Gdip_SaveBitmapToFile(pBitmap, path, Settings.Misc.ImageQuality)
		return 1
	}
	return -1
}

WriteClipboardTextToFile(path)
{
	text:=ReadClipboardText()
	if(!text)
		return -1
	if(FileExist(path))
		FileDelete, %path%
	FileAppend , %text%, %path%, % A_IsUnicode ? "UTF-8" : ""
	return 1 
}

;Copies a list of files (separated by new line) to the clipboard so they can be pasted in explorer
/* Example clipboard data:
00000000   14 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
00000010   01 00 00 00 43 00 3A 00 5C 00 62 00 6F 00 6F 00    ....C.:.\.b.o.o.				<-- I believe the 01 byte at the start of this line could indicate unicode?
00000020   74 00 6D 00 67 00 72 00 00 00 43 00 3A 00 5C 00    t.m.g.r...C.:.\.
00000030   62 00 6C 00 61 00 2E 00 6C 00 6F 00 67 00 00 00    b.l.a...l.o.g...
00000040   00 00                                             										..     

typedef struct _DROPFILES {
  DWORD pFiles;
  POINT pt;
  BOOL  fNC;
  BOOL  fWide;
} DROPFILES, *LPDROPFILES;

_DROPFILES struct: 20 characters at the start
null-terminated filename list, and double-null termination at the end
*/
CopyToClipboard(files, clear, cut=0){
	static CF_HDROP := 0xF
	FileCount:=0
	PathLength:=0
	;Count files and total string length
	Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds (`r`n).
	{
		FileCount++
		PathLength+=StrLen(A_LoopField)
	}
	pid:=DllCall("GetCurrentProcessId","Uint")
	hwnd:=WinExist("ahk_pid " . pid)
	DllCall("OpenClipboard", "Ptr", hwnd)
	hPath := DllCall("GlobalAlloc", "uint", 0x42, "uint", 20 + (PathLength + FileCount + 1) * 2, "Ptr")      ; 0x42 = GMEM_MOVEABLE(0x2) | GMEM_ZEROINIT(0x40)
	pPath := DllCall("GlobalLock", "Ptr", hPath)                   ; Lock the moveable memory, retrieving a pointer to it.
	NumPut(20, pPath+0), pPath += 16 ; DROPFILES.pFiles = offset of file list
	NumPut(1, pPath+0), pPath += 4 ;fWide = 0 -->ANSI, fWide = 1 -->Unicode
	Offset:=0
	Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds (`r`n).
		offset += StrPut(A_LoopField, pPath+offset,StrLen(A_LoopField)+1,"UTF-16") * 2
	DllCall("GlobalUnlock", "Ptr", hPath)  
	;hPath must not be freed! ->http://msdn.microsoft.com/en-us/library/ms649051(VS.85).aspx
	if clear
	{
		DllCall("EmptyClipboard")                                                              ; Empty the clipboard, otherwise SetClipboardData may fail.
		Clipwait, 1, 1
	}
	result:=DllCall("SetClipboardData", "uint", CF_HDROP, "Ptr", hPath) ; Place the data on the clipboard. CF_HDROP=0xF
	Clipwait, 1, 1
	
	;Write Preferred DropEffect structure to clipboard to switch between copy/cut operations
 	mem := DllCall("GlobalAlloc","UInt",0x42,"UInt",4, "Ptr")  ; 0x42 = GMEM_MOVEABLE(0x2) | GMEM_ZEROINIT(0x40)
	str := DllCall("GlobalLock","Ptr",mem) 
	if(!cut)
		DllCall("RtlFillMemory","UInt",str,"UInt",1,"UChar",0x05) 
	else 
		DllCall("RtlFillMemory","UInt",str,"UInt",1,"UChar",0x02) 
	DllCall("GlobalUnlock","Ptr",mem)
	cfFormat := DllCall("RegisterClipboardFormat","Str","Preferred DropEffect") 
	result:=DllCall("SetClipboardData","UInt",cfFormat,"Ptr",mem)
	Clipwait, 1, 1
	DllCall("CloseClipboard")
	;mem must not be freed! ->http://msdn.microsoft.com/en-us/library/ms649051(VS.85).aspx
	return
}

;Appends files to CF_HDROP structure in clipboard
AppendToClipboard( files, cut=0) { 
	DllCall("OpenClipboard", "Ptr", 0)
	if(DllCall("IsClipboardFormatAvailable", "Uint", 1)) ;If text is stored in clipboard, clear it and consider it empty (even though the clipboard may contain CF_HDROP due to text being copied to a temp file for pasting)
		DllCall("EmptyClipboard")
	DllCall("CloseClipboard")
	txt:=clipboard (clipboard = "" ? "" : "`n") files
	Sort, txt , U ;Remove duplicates
	CopyToClipboard(txt, true, cut)
	return
}

Class CClipboardList extends CQueue
{
	Persistent := Array()
	MaxSize := 10
	__new()
	{
		this.Load()
	}
	Load()
	{
		if(FileExist(Settings.ConfigPath "\Clipboard.xml"))
		{
			FileRead, xml, % Settings.ConfigPath "\Clipboard.xml"
			XMLObject := XML_Read(xml)
			;Convert empty and single arrays to real array
			if(!XMLObject.List.MaxIndex())
				XMLObject.List := IsObject(XMLObject.List) ? Array(XMLObject.List) : Array()	
			if(!XMLObject.Persistent.MaxIndex())
				XMLObject.Persistent := IsObject(XMLObject.Persistent) ? Array(XMLObject.Persistent) : Array()		

			Loop % min(XMLObject.List.MaxIndex(), 10)
				this.Insert(Decrypt(XMLObject.List[A_Index])) ;Read encrypted clipboard history
			Loop % XMLObject.Persistent.MaxIndex()
			{
				Clip := RichObject()
				Clip.Name := XMLObject.Persistent[A_Index].Name
				Clip.Text := XMLObject.Persistent[A_Index].Text
				this.Persistent.Insert(Clip)
			}
		}
	}
	Save()
	{
		FileDelete, % Settings.ConfigPath "\Clipboard.xml"
		for index, Event in EventSystem.Events ;Check if clipboard history is actually used and don't store the history when it isn't
		{
			Action := Event.Actions.GetItemWithValue("Type", "Show menu")
			if((Action.Menu = "ClipboardMenu" || Event.Actions.GetItemWithValue("Type", "ClipPaste")) && Event.Enabled)
			{
				XMLObject := Object("List", Array(), "Persistent", Array())
				Loop % min(this.MaxIndex(), 10)
					XMLObject.List.Insert(Encrypt(this[A_Index])) ;Store encrypted
				Loop % this.Persistent.MaxIndex()
					XMLObject.Persistent.Insert({Name : this.Persistent[A_Index].Name, Text : this.Persistent[A_Index].Text})
				XML_Save(XMLObject, Settings.ConfigPath "\Clipboard.xml")
				return
			}
		}
	}
}

;Need separate handlers because menu index doesn't have to match array index
ClipboardHandler1:
ClipboardMenuClicked(1)
return
ClipboardHandler2:
ClipboardMenuClicked(2)
return
ClipboardHandler3:
ClipboardMenuClicked(3)
return
ClipboardHandler4:
ClipboardMenuClicked(4)
return
ClipboardHandler5:
ClipboardMenuClicked(5)
return
ClipboardHandler6:
ClipboardMenuClicked(6)
return
ClipboardHandler7:
ClipboardMenuClicked(7)
return
ClipboardHandler8:
ClipboardMenuClicked(8)
return
ClipboardHandler9:
ClipboardMenuClicked(9)
return
ClipboardHandler10:
ClipboardMenuClicked(10)
return

ClipboardMenuClicked(index)
{
	global ClipboardList
	if(ClipboardList[index])
		PasteText(ClipboardList[index])
}

PersistentClipboardHandler:
PersistentClipboard(A_ThisMenuItemPos)
return

EditClips:
ShowSettings("Clipboard")
return

AddClip:
AddClip()
return
AddClip(Text = "")
{
	iw := new CInputWindow("Enter name for clip:")
	iw.Text := Text ? Text : GetSelectedText()
	iw.WaitForInputAsync(new Delegate("AddClip_Callback"))
	return
}
AddClip_Callback(Sender)
{
	global ClipboardList
	if(Sender.Result)
		ClipboardList.Persistent.Insert({Name : Sender.Result, Text : Sender.Text})
}
PersistentClipboard(index)
{
	global ClipboardList
	text := ClipboardList.Persistent[index].Text
	if(InStr(text, "%") && InStr(text, "%", false, 1, 2) && SubStr(text, InStr(text, "%") + 1, InStr(text, "%", false, 1, 2) - InStr(text, "%") - 1))
		ClipVariableWindow := new CClipVariableWindow(ClipboardList.Persistent[index].DeepCopy())
	else
		PasteText(text)
}
Class CClipVariableWindow extends CGUI
{
	editText := this.AddControl("Edit", "editText", "x10 y10 w300", "")
	btnOK := this.AddControl("Button", "btnOK", "x180 y+10 Default w50", "&OK")
	btnCancel := this.AddControl("Button", "btnCancel", "x+10 w70", "&Cancel")
	__new(Clip)
	{
		static EM_SETSEL := 0x00B1
		this.Clip := Clip
		this.Variable := SubStr(Clip.Text, InStr(Clip.Text, "%") + 1, InStr(Clip.Text, "%", false, 1, 2) - InStr(Clip.Text, "%") - 1)
		this.ActiveControl := this.editText
		this.Show()
		this.editText.Text := "Text for """ this.Variable """"
		SendMessage, EM_SETSEL, 0, -1, , % "ahk_id " this.editText.hwnd
		this.DestroyOnClose := true
		this.CloseOnEscape := true
	}
	btnCancel_Click()
	{
		this.Close()
	}
	btnOK_Click()
	{
		text := this.Clip.Text
		StringReplace, text, text, % "%" this.Variable "%", % this.editText.Text
		this.Clip.Text := text
		this.Hide()
		this.Close()
		if(InStr(this.Clip.Text, "%") && InStr(this.Clip.Text, "%", false, 1, 2) && SubStr(this.Clip.Text, InStr(this.Clip.Text, "%") + 1, InStr(this.Clip.Text, "%", false, 1, 2) - InStr(this.Clip.Text, "%") - 1))
			ClipVariableWindow := new CClipVariableWindow(this.Clip)
		else
			PasteText(text)
	}
}

; Write text at cursor position, overwriting selected text
PasteText(Text)
{
	global MuteClipboardList
	ClipboardBackup := ClipboardAll
	MuteClipboardList := true
	Clipboard := Text
	if(WaitForEvent("ClipboardChange", 100))
	{
		Sleep 100 ;Some extra sleep to increase reliability
		if(WinActive("ahk_class ConsoleWindowClass"))
		{
			CoordMode, Mouse, Screen
			MouseGetPos, mx, my
			CoordMode, Mouse, Relative
			Click Right 40, 40
			CoordMode, Mouse, Screen
			MouseMove, %mx%, %my%
			Send {Down 3}{Enter}
		}
		else	
			Send ^v
		Sleep 20
	}
	else
		SendInput, {Raw}%Text%
	Clipboard := ClipboardBackup
	WaitForEvent("ClipboardChange", 100)
	MuteClipboardList := false
}