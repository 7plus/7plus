+#c::
outputdebug clipboard %clipboard%
text:=ReadClipboardtext()
outputdebug text: %text%
return

;Called when clipboard changes, used for "Paste text/image as file" functionality and for clipboard manager
;To use the clipboard without triggering these features, set MuteClipboardList:=true before writing to clipboard
OnClipboardChange:
outputdebug clipboardchange mute %MuteClipboardList% to %clipboard% 
if(MuteClipboardList)
	return
if(WinActive("ahk_group ExplorerGroup") || WinActive("ahk_group DesktopGroup")|| IsDialog())
	CreateFile()
text:=ReadClipboardText()
if(text)
	ClipboardList.Push(text)
outputdebug clipboardchange end
return

;Stack Push function for clipboard manager stack
Stack_Push(stack,item)
{
	x:=stack.IndexOf(item)
	if(x=0)
	{
		stack.Insert(1,item)
		if(stack.len()=11)
			stack.Delete(stack.len())
	}
	else
	{
		stack.Move(x,1)
	}
}
;Win+v:Clipboard manager menu
#if ClipboardManager && !IsFullscreen()
#v::
	ClipboardManagerMenu()
return
#if
ClipboardManagerMenu()
{
	global ClipboardList
	Menu, ClipboardMenu, add, 1,ClipboardHandler1
	Menu, ClipboardMenu, DeleteAll
	loop % ClipboardList.len()
	{		
		i:=A_Index ;ClipboardList.len()-A_Index+1
		
		x:=ClipboardList[i]
		outputdebug a %i% %x%
		StringReplace,x,x,`r,,All
		StringReplace,x,x,`n,[NEWLINE],All
		y:="`t"
		StringReplace,x,x,%y%,[TAB],All ;Weird syntax bug requires `t to be stored in a variable here
		x:=Substr(x,1,100)
		if(x)
			Menu, ClipboardMenu, add, %x%, ClipboardHandler%i%
	}
	Menu, ClipboardMenu, Show
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
	global ClipboardList,MuteClipboardList,clipboardchanged
	if(ClipboardList[index])
	{	
		ClipboardBackup:=ClipboardAll
		MuteClipboardList:=true
		Clipboard:=y		
		Clipwait,1,1
		if(!Errorlevel)
		{
			Send ^v
			Sleep 20
		}
		else
		{
			ToolTip(1, "Error pasting text", "Error pasting text","O1 L1 P99 C1 XTrayIcon YTrayIcon I4")
			SetTimer, ToolTipClose, -10000
		}
		Clipboard:=ClipboardBackup
	}
	Menu, ClipboardMenu, DeleteAll
}
;Creates a file for pasting text/image in explorer
CreateFile()
{
	global temp_img, temp_txt, CF_HDROP,MuteClipboardList
	outputdebug CreateFile
	if(!MuteClipboardList)
	{	 
    MuteClipboardList:=true
		DllCall("OpenClipboard", "Uint", 0)
		if(!DllCall("IsClipboardFormatAvailable", "Uint", CF_HDROP))
		{			
		  If (DllCall("IsClipboardFormatAvailable", "Uint", 2) && temp_img!="" )
			{
				outputdebug image in clipboard
				x:=WriteClipboardImageToFile(temp_img)
				if (x)
					CopyToClipboard(temp_img, false)
			}
			else if (DllCall("IsClipboardFormatAvailable", "Uint", 1) && temp_txt!="" )
			{
				outputdebug text in clipboard
				x:=WriteClipboardTextToFile(temp_txt)
				if (x)
					CopyToClipboard(temp_txt, false)
			}
		}
		else
			outputdebug a file is already in the clipboard
		DllCall("CloseClipboard")		
    MuteClipboardList:=false
	}
}

;Read real text (=not filenames, when CF_HDROP is in clipboard) from clipboard
ReadClipboardText()
{
	if(DllCall("IsClipboardFormatAvailable", "Uint", 1))
	{
		DllCall("OpenClipboard", "Uint", 0)	
		htext:=DllCall("GetClipboardData", "Uint", 1)
		ptext := DllCall("GlobalLock", "uint", htext)
		text:=PointerToString(pText)
		text:=ExtractData(ptext)				
		DllCall("GlobalUnlock", "uint", htext)
		DllCall("CloseClipboard")
	}
	return text
}
;Read image from clipboard and return a pointer to a bitmap
ReadClipboardImage()
{
	if(DllCall("IsClipboardFormatAvailable", "Uint", 2))
	{
		DllCall("OpenClipboard", "Uint", 0)	
		hBM:=DllCall("GetClipboardData", "Uint", 2)
		pBitmap := Gdip_CreateBitmapFromHBITMAP(hBM)
		Gdip_DisposeImage(hBM)
		return pBitmap
	}
}

;Reads an image from clipboard, saves it to a file, and puts CF_HDROP structure in clipboard for file pasting
WriteClipboardImageToFile(path)
{
	pBitmap:=ReadClipboardImage()
	if(!pBitmap)
		return -1
	Gdip_SaveBitmapToFile(pBitmap, path, 100)
	DllCall("EmptyClipboard") 
	;Write the file into clipboard again
	Gdip_ImageToClipboard(temp_img)
	DllCall("CloseClipboard")
	return 1 
}

WriteClipboardTextToFile(path)
{
	text:=ReadClipboardText()
	if(!text)
		return -1
	if(FileExist(path))
		FileDelete, %path%
	FileAppend , %text%, %path%
	return 1 
}
;Copies a list of files (separated by new line) to the clipboard so they can be pasted in explorer
CopyToClipboard(files, clear, cut=0){
	global MuteClipboardList
	FileCount:=0
	PathLength:=0
	Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds (`r`n).
	{
		FileCount++
		PathLength+=StrLen(A_LoopField)
	}	
	MuteClipboardList:=true
	; Copy image file - CF_HDROP	
	pid:=DllCall("GetCurrentProcessId","Uint")
	hwnd:=WinExist("ahk_pid " . pid)
	DllCall("OpenClipboard", "Uint", hwnd)
  hPath := DllCall("GlobalAlloc", "uint", 0x42, "uint", PathLength+FileCount+22)      ; 0x42 = GMEM_MOVEABLE(0x2) | GMEM_ZEROINIT(0x40)
  pPath := DllCall("GlobalLock", "uint", hPath)                   ; Lock the moveable memory, retrieving a pointer to it.
  NumPut(20, pPath+0), pPath += 20                                                ; DROPFILES.pFiles = offset of file list
  Offset:=0	  
  Offset:=0       
  Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds (`r`n).
		DllCall("lstrcpy", "uint", pPath+offset, "str", A_LoopField)    ; Copy the file into moveable memory.
			, offset+=StrLen(A_LoopField)+1
  DllCall("GlobalUnlock", "uint", hPath)  
  MuteClipboardList:=true
	if clear
	{
  	DllCall("EmptyClipboard")                                                              ; Empty the clipboard, otherwise SetClipboardData may fail.
  	Clipwait, 1, 1		
		MuteClipboardList:=true	
  }
  result:=DllCall("SetClipboardData", "uint", 0xF, "uint", hPath) ; Place the data on the clipboard. CF_HDROP=0xF
	Clipwait, 1, 1
	MuteClipboardList:=true	
  outputdebug hdrop setclipboarddata result: %result% errorlevel %errorlevel%
  x:=GetLastError()
 	mem := DllCall("GlobalAlloc","UInt",2,"UInt",4) 
  str := DllCall("GlobalLock","UInt",mem) 
  if(!cut)
     DllCall("RtlFillMemory","UInt",str,"UInt",1,"UChar",0x05) 
  else 
     DllCall("RtlFillMemory","UInt",str,"UInt",1,"UChar",0x02) 
  DllCall("RtlZeroMemory","UInt",str + 1,"UInt",1) 
  DllCall("RtlZeroMemory","UInt",str + 2,"UInt",1) 
  DllCall("RtlZeroMemory","UInt",str + 3,"UInt",1) 
  DllCall("GlobalUnlock","UInt",mem)

  cfFormat := DllCall("RegisterClipboardFormat","Str","Preferred DropEffect") 
  result:=DllCall("SetClipboardData","UInt",cfFormat,"UInt",mem)
  Clipwait, 1, 1
  outputdebug mute 9
  MuteClipboardList:=true
  outputdebug drop effect setclipboarddata result: %result% errorlevel %errorlevel%
	;DllCall("SetClipboardData", "uint", 49320, "uint", 0x02000000)
	DllCall("CloseClipboard")
  Clipwait, 1, 1
  MuteClipboardSurveillance:=false
	return
}

;Appends files to CF_HDROP structure in clipboard
AppendToClipboard( files, cut=0) { 
	DllCall("OpenClipboard", "Uint", 0)
	if(DllCall("IsClipboardFormatAvailable", "Uint", 1))
		DllCall("EmptyClipboard")	
	DllCall("CloseClipboard")
	txt:=clipboard (clipboard = "" ? "" : "`r`n") files
	Sort, txt , U
	DllCall("OpenClipboard", "Uint", 0)
	CopyToClipboard(txt, true, cut)
	DllCall("CloseClipboard")
	return
}

;Writes image data from file to clipboard
Gdip_ImageToClipboard(Filename) 
{
	global MuteClipboardList
	outputdebug mute 10
	MuteClipboardList:=true
  pBitmap := Gdip_CreateBitmapFromFile(Filename) 
  if !pBitmap 
      return 
  hbm := Gdip_CreateHBITMAPFromBitmap(pBitmap) 
  Gdip_DisposeImage(pBitmap) 
  if !hbm 
      return 
  if hdc := DllCall("CreateCompatibleDC","uint",0) 
  { 
      ; Get BITMAPINFO. 
      VarSetCapacity(bmi,40,0), NumPut(40,bmi) 
      DllCall("GetDIBits","uint",hdc,"uint",hbm,"uint",0 
           ,"uint",0,"uint",0,"uint",&bmi,"uint",0) 
      ; GetDIBits seems to screw up and give the image the BI_BITFIELDS 
      ; (i.e. colour-indexed) compression type when it is in fact BI_RGB. 
      NumPut(0,bmi,16) 
      ; Get bitmap bits. 
      if size := NumGet(bmi,20) 
      { 
          VarSetCapacity(bits,size) 
          DllCall("GetDIBits","uint",hdc,"uint",hbm,"uint",0 
              ,"uint",NumGet(bmi,8),"uint",&bits,"uint",&bmi,"uint",0) 
          ; 0x42 = GMEM_MOVEABLE(0x2) | GMEM_ZEROINIT(0x40) 
          hMem := DllCall("GlobalAlloc","uint",0x42,"uint",40+size) 
          pMem := DllCall("GlobalLock","uint",hMem) 
          DllCall("RtlMoveMemory","uint",pMem,"uint",&bmi,"uint",40) 
          DllCall("RtlMoveMemory","uint",pMem+40,"uint",&bits,"uint",size) 
          DllCall("GlobalUnlock","uint",hMem) 
      } 
      DllCall("DeleteDC","uint",hdc) 
  } 
  if hMem 
  { 
  		DllCall("OpenClipboard", "Uint", 0)
      ; Place the data on the clipboard. CF_DIB=0x8 
      if ! DllCall("SetClipboardData","uint",0x8,"uint",hMem) 
          DllCall("GlobalFree","uint",hMem) 
      DllCall("CloseClipboard")
  } 
  MuteClipboardList:=false
} 
