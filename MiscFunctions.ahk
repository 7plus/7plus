;usage example:
;outputdebug % "blup" TranslateMUI("shell32.dll",31236)
TranslateMUI(resDll, resID)
{
VarSetCapacity(buf, 256) 
hDll := DllCall("LoadLibrary", "str", resDll) 
Result := DllCall("LoadString", "uint", hDll, "uint", resID, "str", buf, "int", 128)
return buf
}
;Splits a command into command and arguments
SplitCommand(fullcmd, ByRef cmd, ByRef args)
{
	if(strStartsWith(fullcmd,""""))
	{
		pos:=InStr(fullcmd, """" ,0, 2)
		cmd:=SubStr(fullcmd,2,pos-2)
		args:=SubStr(fullcmd,pos+1)
		args:=strTrim(args," ")
	}
	else
	{
		pos:=InStr(fullcmd, " " ,0, 1)
		cmd:=SubStr(fullcmd,1,pos-1)
		args:=SubStr(fullcmd,pos+1)
		args:=strTrim(args," ")
	}
}
IsWindowUnderCursor(what)
{
	MouseGetPos, , , win
	if(InStr(WinGetClass("ahk_id " win),what))
		return true
	return false
}
IsControlUnderCursor(what)
{
	MouseGetPos, , , , control
	outputdebug control %control%
	IfInString control, %what%
		return control
	return false
}

/* 
Performs a hittest on the window under the mouse and returns the WM_NCHITTEST Result
#define HTERROR             (-2) 
#define HTTRANSPARENT       (-1) 
#define HTNOWHERE           0 
#define HTCLIENT            1 
#define HTCAPTION           2 
#define HTSYSMENU           3 
#define HTGROWBOX           4 
#define HTSIZE              HTGROWBOX 
#define HTMENU              5 
#define HTHSCROLL           6 
#define HTVSCROLL           7 
#define HTMINBUTTON         8 
#define HTMAXBUTTON         9 
#define HTLEFT              10 
#define HTRIGHT             11 
#define HTTOP               12 
#define HTTOPLEFT           13 
#define HTTOPRIGHT          14 
#define HTBOTTOM            15 
#define HTBOTTOMLEFT        16 
#define HTBOTTOMRIGHT       17 
#define HTBORDER            18 
#define HTREDUCE            HTMINBUTTON 
#define HTZOOM              HTMAXBUTTON 
#define HTSIZEFIRST         HTLEFT 
#define HTSIZELAST          HTBOTTOMRIGHT 
#if(WINVER >= 0x0400) 
#define HTOBJECT            19 
#define HTCLOSE             20 
#define HTHELP              21 
*/ 
MouseHitTest()
{
  MouseGetPos, MouseX, MouseY, WindowUnderMouseID 
  WinGetClass, winclass , ahk_id %WindowUnderMouseID%
  ;outputdebug windclass: %winclass%
  if winclass in BaseBar,D2VControlHost,Shell_TrayWnd,WorkerW,ProgMan  ; make sure we're not doing this on the taskbar
  	return -2
  if IsContextMenuActive()
  	return -2
  IfWinNotActive, ahk_id %WindowUnderMouseID%
  	WinActivate, ahk_id %WindowUnderMouseID% 
  ; WM_NCHITTEST 
  SendMessage, 0x84,, ( MouseY << 16 )|MouseX,, ahk_id %WindowUnderMouseID%
  return ErrorLevel
}

/*! TheGood 
    Checks if a window is in fullscreen mode. 
    ______________________________________________________________________________________________________________ 
    sWinTitle       - WinTitle of the window to check. Same syntax as the WinTitle parameter of, e.g., WinExist(). 
    bRefreshRes     - Forces a refresh of monitor data (necessary if resolution has changed) 
    Return value    o If window is fullscreen, returns the index of the monitor on which the window is fullscreen. 
                    o If window is not fullscreen, returns False. 
    ErrorLevel      - Sets ErrorLevel to True if no window could match sWinTitle 
    
        Based on the information found at http://support.microsoft.com/kb/179363/ which discusses under what 
    circumstances does a program cover the taskbar. Even if the window passed to IsFullscreen is not the 
    foreground application, IsFullscreen will check if, were it the foreground, it would cover the taskbar. 
*/ 
IsFullscreen(sWinTitle = "A", UseExcludeList = true, UseIncludeList=true) { 
    Static 
    Local iWinX, iWinY, iWinW, iWinH, iCltX, iCltY, iCltW, iCltH, iMidX, iMidY, iMonitor, c, D, iBestD 
    global FullScreenExclude, FullScreenInclude
    ErrorLevel := False 
    
    ;Resolution change would only need to be detected every few seconds or so, but since it doesn't add anything notably to cpu usage, just do it always
    SysGet, Mon0, MonitorCount 
    SysGet, iPrimaryMon, MonitorPrimary 
    Loop %Mon0% { ;Loop through each monitor 
        SysGet, Mon%A_Index%, Monitor, %A_Index% 
        Mon%A_Index%MidX := Mon%A_Index%Left + Ceil((Mon%A_Index%Right - Mon%A_Index%Left) / 2) 
        Mon%A_Index%MidY := Mon%A_Index%Top + Ceil((Mon%A_Index%Top - Mon%A_Index%Bottom) / 2) 
    } 
    
    ;Get the active window's dimension 
    hWin := WinExist(sWinTitle) 
    If Not hWin { 
        ErrorLevel := True 
        Return False 
    } 
    
    ;Make sure it's not desktop 
    WinGetClass, c, ahk_id %hWin% 
    If (hWin = DllCall("GetDesktopWindow") Or (c = "Progman") Or (c = "WorkerW")) 
        Return False 
        
    ;Fullscreen include list
    if(UseIncludeList)
    	if c in %FullscreenInclude%
				return true
    ;Fullscreen exclude list
    if(UseExcludeList)
    	if c in %FullscreenExclude%
				return false
			
    ;Get the window and client area, and style 
    VarSetCapacity(iWinRect, 16), VarSetCapacity(iCltRect, 16) 
    DllCall("GetWindowRect", UInt, hWin, UInt, &iWinRect) 
    DllCall("GetClientRect", UInt, hWin, UInt, &iCltRect) 
    WinGet, iStyle, Style, ahk_id %hWin% 
    
    ;Extract coords and sizes 
    iWinX := NumGet(iWinRect, 0), iWinY := NumGet(iWinRect, 4) 
    iWinW := NumGet(iWinRect, 8) - NumGet(iWinRect, 0) ;Bottom-right coordinates are exclusive 
    iWinH := NumGet(iWinRect, 12) - NumGet(iWinRect, 4) ;Bottom-right coordinates are exclusive 
    iCltX := 0, iCltY := 0 ;Client upper-left always (0,0) 
    iCltW := NumGet(iCltRect, 8), iCltH := NumGet(iCltRect, 12) 
    
    ;Check in which monitor it lies 
    iMidX := iWinX + Ceil(iWinW / 2) 
    iMidY := iWinY + Ceil(iWinH / 2) 
    
   ;Loop through every monitor and calculate the distance to each monitor 
   iBestD := 0xFFFFFFFF 
    Loop % Mon0 { 
      D := Sqrt((iMidX - Mon%A_Index%MidX)**2 + (iMidY - Mon%A_Index%MidY)**2) 
      If (D < iBestD) { 
         iBestD := D 
         iMonitor := A_Index 
      } 
   } 
    
    ;Check if the client area covers the whole screen 
    bCovers := (iCltX <= Mon%iMonitor%Left) And (iCltY <= Mon%iMonitor%Top) And (iCltW >= Mon%iMonitor%Right - Mon%iMonitor%Left) And (iCltH >= Mon%iMonitor%Bottom - Mon%iMonitor%Top) 
    If bCovers 
        Return True 
    
    ;Check if the window area covers the whole screen and styles 
    bCovers := (iWinX <= Mon%iMonitor%Left) And (iWinY <= Mon%iMonitor%Top) And (iWinW >= Mon%iMonitor%Right - Mon%iMonitor%Left) And (iWinH >= Mon%iMonitor%Bottom - Mon%iMonitor%Top) 
    If bCovers { ;WS_THICKFRAME or WS_CAPTION 
        bCovers &= Not (iStyle & 0x00040000) Or Not (iStyle & 0x00C00000) 
        Return bCovers ? iMonitor : False 
    } Else Return False 
}

;Returns the (signed) minimum of the absolute values of x and y 
absmin(x,y)
{
	return abs(x)>abs(y) ? y : x
}
;Returns the (signed) maximum of the absolute values of x and y
absmax(x,y)
{
	return abs(x)<abs(y) ? y : x
}
;Returns 1 if x is positive and -1 if x is negative
sign(x)
{
	return x<0 ? -1 : 1
}
;returns the maximum of xdir and y, but with the sign of xdir
dirmax(xdir,y)
{
	if(xdir=0)
		return 0
	if(abs(xdir)>y)
		return xdir
	return xdir/abs(xdir)*abs(y)
}
;returns the maximum of xdir and y, but with the sign of xdir
dirmin(xdir,y)
{
	if(xdir=0)
		return 0
	if(abs(xdir)<y)
		return xdir
	return xdir/abs(xdir)*abs(y)
}
min(x,y)
{
	return x>y ? y : x
}
max(x,y)
{
	return x<y ? y : x
}
strStartsWith(string,start)
{	
	x:=(strlen(start)<=strlen(string)&&Substr(string,1,strlen(start))=start)
	return x
}

strEndsWith(string,end)
{
	return strlen(end)<=strlen(string) && Substr(string,-strlen(end)+1)=end
}

strTrim(string, trim)
{
	return strTrimLeft(strTrimRight(string,trim),trim)
}

strTrimLeft(string,trim)
{
	len:=strLen(trim)
	while(strStartsWith(string,trim))
	{					
		StringTrimLeft, string, string, %len% 
	}
	return string
}

strTrimRight(string,trim)
{
	len:=strLen(trim)
	while(strEndsWith(string,trim))
	{					
		StringTrimRight, string, string, %len% 
	}
	return string
}
strStripLeft(string,strip)
{
	return substr(string,InStr(string, strip ,0, 0)+strLen(strip))
}
strStripRight(string,strip)
{
	StringGetPos, pos, string, %strip% ,R
	x:=substr(string,1,pos)
	return substr(string,1,pos)
}
strStrip(string, strip)
{
	return strStripLeft(strStripRight(string,strip),strip)
}
Quote(string, once=1)
{
	if(once)
	{
		if(!strStartsWith(string,""""))
			string:="""" string
		if(!strEndsWith(string,""""))
			string:=string """"
		return string
	}
	return """" string """"
}
UnQuote(string)
{
	if(strStartswith(string,"""") && strEndsWith(string,""""))
		return strTrim(string,"""")
	return string
}

SplitByExtension(ByRef files, ByRef SplitFiles,extensions)
{
	;Init string incase it wasn't resetted before or so
	Splitfiles:=""
	Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds ('r`n). 
	{ 
		SplitPath, A_LoopField , , , OutExtension
	  if (InStr(extensions, OutExtension)&&OutExtension!="")
	  {
	  	Splitfiles .= A_LoopField "`n"
	  }
	  else
	  {
	  	newFiles .= A_LoopField "`n"
	  }
	} 
	files:=strTrimRight(newFiles,"`n")
	SplitFiles:=strTrimRight(SplitFiles,"`n")
	return
}

GetVisibleWindowAtPoint(x,y,IgnoredWindow)
{
	DetectHiddenWindows,off
	WinGet, id, list,,,
	Loop, %id%
	{
	    this_id := id%A_Index%
	    ;WinActivate, ahk_id %this_id%
	    WinGetClass, this_class, ahk_id %this_id%
	    WinGetPos , WinX, WinY, Width, Height, ahk_id %this_id%
	    if(IsInArea(x,y,WinX,WinY,Width,Height)&&this_class!=IgnoredWindow)
	    {
	    	DetectHiddenWindows,on
	    	return this_class
	    }
	}
	DetectHiddenWindows,on
}
IsInArea(px,py,x,y,w,h)
{
	return (px>x&&py>y&&px<x+w&&py<y+h)
}
ExpandEnvVars(ppath)
{
	VarSetCapacity(dest, 2000) 
	DllCall("ExpandEnvironmentStrings", "str", ppath, "str", dest, int, 1999, "Cdecl int") 
	return dest
}

IsControlActive(controlclass)
{
	ControlGetFocus, active ,A
	if(InStr(active, controlclass))
		return true
	return false
}

; This script retrieves the ahk_id (HWND) of the active window's focused control. 
; This script requires Windows 98+ or NT 4.0 SP3+. 
GetFocusedControl() 
{ 
   guiThreadInfoSize = 48 
   VarSetCapacity(guiThreadInfo, guiThreadInfoSize, 0) 
   addr := &guiThreadInfo 
   DllCall("RtlFillMemory" 
         , "UInt", addr 
         , "UInt", 1 
         , "UChar", guiThreadInfoSize)   ; Below 0xFF, one call only is needed 
   If not DllCall("GetGUIThreadInfo" 
         , "UInt", 0   ; Foreground thread 
         , "UInt", &guiThreadInfo) 
   { 
      ErrorLevel := A_LastError   ; Failure 
      Return 0 
   } 
   focusedHwnd := *(addr + 12) + (*(addr + 13) << 8) +  (*(addr + 14) << 16) + (*(addr + 15) << 24) 
   Return focusedHwnd 
} 
InsertInteger(pInteger, ByRef pDest, pOffset = 0, pSize = 4) 
{ 
    Loop %pSize%  ; Copy each byte in the integer into the structure as raw binary data. 
        DllCall("RtlFillMemory", "UInt", &pDest + pOffset + A_Index-1, "UInt", 1, "UChar", pInteger >> 8*(A_Index-1) & 0xFF) 
} 
PointerToString(string)
{
	return DllCall("MulDiv", int, &sTest, int, 1, int, 1, str)
}

ExtractInteger(ByRef pSource, pOffset = 0, pIsSigned = false, pSize = 4) 
{ 
    Loop %pSize%  ; Build the integer by adding up its bytes. 
        result += *(&pSource + pOffset + A_Index-1) << 8*(A_Index-1) 
    if (!pIsSigned OR pSize > 4 OR result < 0x80000000) 
        return result  ; Signed vs. unsigned doesn't matter in these cases. 
    return -(0xFFFFFFFF - result + 1) 
}

RemoveLineFeedsAndSurroundWithDoubleQuotes(files)
{
	result:=""
	Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds ('r`n). 
   { 
      if !InStr(FileExist(A_LoopField), "D")
   			result=%result% "%A_LoopField%"
   } 
   return result
}

;get data starting from pointer up to 0 char
ExtractData(pointer) { 
Loop { 
       errorLevel := ( pointer+(A_Index-1) ) 
       Asc := *( errorLevel ) 
       IfEqual, Asc, 0, Break ; Break if NULL Character 
       String := String . Chr(Asc) 
     } 
Return String 
}
ReadUnicodeFile(path)
{
	FileGetSize fileSize, %path%
	FileRead fileBuffer, %path%
	bufferAddress := &fileBuffer
	If (*bufferAddress != 0xFF || *(bufferAddress + 1) != 0xFE)
	{
		MsgBox 16, Test, Not a valid Windows Unicode file! (no little-endian Bom)
		Exit
	}
	
	textSize := fileSize / 2 - 1
	VarSetCapacity(ansiText, textSize, 0)
	
	DllCall("SetLastError", "UInt", 0)
	r := DllCall("WideCharToMultiByte"
			, "UInt", 0           ; CodePage: CP_ACP=0 (current Ansi), CP_UTF7=65000, CP_UTF8=65001
			, "UInt", 0           ; dwFlags
			, "UInt", bufferAddress + 2  ; LPCWSTR lpWideCharStr
			, "Int", textSize     ; cchWideChar: size in WCHAR values, -1=null terminated
			, "Str", ansiText     ; LPSTR lpMultiByteStr
			, "Int", textSize     ; cbMultiByte: 0 to get required size
			, "UInt", 0           ; LPCSTR lpDefaultChar
			, "UInt", 0)          ; LPBOOL lpUsedDefaultChar
			
			
			
	return ansiText
}
WriteUnicodeFile(path,text)
{
	;===== Use a Bom
	
	; Convert the Ansi text to Unicode
	
	textLength := StrLen(text)
	uniLength := textLength * 2 + 2
	VarSetCapacity(uniText, uniLength + 1, 0)
	; Write Bom
	DllCall("RtlFillMemory", "UInt", &uniText, "UInt", 1, "UChar", 0xFF)
	DllCall("RtlFillMemory", "UInt", &uniText+1, "UInt", 1, "UChar", 0xFE)
	
	DllCall("SetLastError", "UInt", 0)
	r := DllCall("MultiByteToWideChar"
			, "UInt", 0             ; CodePage: CP_ACP=0 (current Ansi), CP_UTF7=65000, CP_UTF8=65001
			, "UInt", 0             ; dwFlags
			, "Str", text  ; LPSTR lpMultiByteStr
			, "Int", textLength     ; cbMultiByte: -1=null terminated
			, "UInt", &uniText + 2  ; LPCWSTR lpWideCharStr
			, "Int", textLength)    ; cchWideChar: 0 to get required size
	
	;~ MsgBox % DumpDWORDs(uniText, textLength * 2, true)
	; Write it as binary blob to a file
	
	fh := OpenFileForWrite(path)
	If (ErrorLevel != 0)
	{
		MsgBox 16, Test, Can't open file '%path%': %ErrorLevel%
		Exit
	}
	WriteInFile(fh, uniText, uniLength)
	If (ErrorLevel != 0)
	{
		MsgBox 16, Test, Can't write in file '%path%': %ErrorLevel%
		Exit
	}
	CloseFile(fh)
}
IsNumeric(x)
{
   If x is number 
      Return 1 
   Return 0 
}
