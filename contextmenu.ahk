#Persistent

;This stuff doesn't use COM.ahk yet :(

/*
Executes context menu entries of shell items without showing their menus
Usage:
ShellContextMenu("Desktop",1)			;Calls "Next Desktop background" in Win7
1st parameter can be "Desktop" for empty selection desktop menu, a path, or an idl
Leave 2nd parameter empty to show context menu and extract idn by clicking on an entry (shows up in debugview)
*/ 
ShellContextMenu(sPath,idn) 
{ 
   DllCall("ole32\OleInitialize", "Uint", 0) 
   if (spath="Desktop")
   {
		 DllCall("shell32\SHGetDesktopFolder", "UintP", psf) 
		 DllCall(NumGet(NumGet(1*psf)+32), "Uint", psf, "Uint", 0, "Uint", GUID4String(IID_IContextMenu,"{000214E4-0000-0000-C000-000000000046}"), "UintP", pcm) 
	 }
   else
   {
		 If   sPath Is Not Integer 
	      DllCall("shell32\SHParseDisplayName", "Uint", Unicode4Ansi(wPath,sPath), "Uint", 0, "UintP", pidl, "Uint", 0, "Uint", 0) 
	   Else   DllCall("shell32\SHGetFolderLocation", "Uint", 0, "int", sPath, "Uint", 0, "Uint", 0, "UintP", pidl) 
	   DllCall("shell32\SHBindToParent", "Uint", pidl, "Uint", GUID4String(IID_IShellFolder,"{000214E6-0000-0000-C000-000000000046}"), "UintP", psf, "UintP", pidlChild) 
	   DllCall(NumGet(NumGet(1*psf)+40), "Uint", psf, "Uint", 0, "Uint", 1, "UintP", pidlChild, "Uint", GUID4String(IID_IContextMenu,"{000214E4-0000-0000-C000-000000000046}"), "Uint", 0, "UintP", pcm)
	 }
	 Release(psf) 
   CoTaskMemFree(pidl) 

   hMenu := DllCall("CreatePopupMenu") 
   idnMIN=1
   DllCall(NumGet(NumGet(1*pcm)+12), "Uint", pcm, "Uint", hMenu, "Uint", 0, "Uint", idnMIN, "Uint", 0x7FFF, "Uint", 0)   ; QueryContextMenu
	  

   DetectHiddenWindows, On 
   Process, Exist 
   WinGet, hAHK, ID, ahk_pid %ErrorLevel% 
   if !idn
   {
	   WinActivate, ahk_id %hAHK% 	   
	   Global   pcm2 := QueryInterface(pcm,IID_IContextMenu2:="{000214F4-0000-0000-C000-000000000046}") 
	   Global   pcm3 := QueryInterface(pcm,IID_IContextMenu3:="{BCFCE0A0-EC17-11D0-8D10-00A0C90F2719}") 
	   Global   WPOld:= DllCall("SetWindowLong", "Uint", hAHK, "int",-4, "int",RegisterCallback("WindowProc")) 
	   DllCall("GetCursorPos", "int64P", pt) 
	   DllCall("InsertMenu", "Uint", hMenu, "Uint", 0, "Uint", 0x0400|0x800, "Uint", 2, "Uint", 0) 
	   DllCall("InsertMenu", "Uint", hMenu, "Uint", 0, "Uint", 0x0400|0x002, "Uint", 1, "Uint", &sPath) 
	   idn2 := DllCall("TrackPopupMenu", "Uint", hMenu, "Uint", 0x0100, "int", pt << 32 >> 32, "int", pt >> 32, "Uint", 0, "Uint", hAHK, "Uint", 0)
	 }
	 else
	 	 idn2:=idn
   NumPut(VarSetCapacity(ici,64,0),ici)
	 NumPut(0x4000|0x20000000,ici,4) 
	 NumPut(1,NumPut(hAHK,ici,8),12)
	 NumPut(idn2-idnMIN,NumPut(idn2-idnMIN,ici,12),24)
	 if !idn
	 	NumPut(pt,ici,56,"int64") 
   DllCall(NumGet(NumGet(1*pcm)+16), "Uint", pcm, "Uint", &ici)   ; InvokeCommand 
   if !idn
   {
	 VarSetCapacity(sName,259), DllCall(NumGet(NumGet(1*pcm)+20), "Uint", pcm, "Uint", idn2-idnMIN, "Uint", 1, "Uint", 0, "str", sName, "Uint", 260)   ; GetCommandString
	 outputdebug command string: %sname% idn: %idn2%
   DllCall("GlobalFree", "Uint", DllCall("SetWindowLong", "Uint", hAHK, "int", -4, "int", WPOld)) 
   
   Release(pcm3) 
   Release(pcm2) 
   }
   DllCall("DestroyMenu", "Uint", hMenu) 
   Release(pcm) 
   DllCall("ole32\OleUnInitialize", "Uint", 0) 
   if !idn
	 	pcm2:=pcm3:=WPOld:=0 
} 
WindowProc(hWnd, nMsg, wParam, lParam) 
{ 
   Critical 
   Global   pcm2, pcm3, WPOld 
   If   pcm3 
   { 
      If   !DllCall(NumGet(NumGet(1*pcm3)+28), "Uint", pcm3, "Uint", nMsg, "Uint", wParam, "Uint", lParam, "UintP", lResult) 
         Return   lResult 
   } 
   Else If   pcm2 
   { 
      If   !DllCall(NumGet(NumGet(1*pcm2)+24), "Uint", pcm2, "Uint", nMsg, "Uint", wParam, "Uint", lParam) 
         Return   0 
   } 
   Return   DllCall("user32.dll\CallWindowProcA", "Uint", WPOld, "Uint", hWnd, "Uint", nMsg, "Uint", wParam, "Uint", lParam) 
} 
VTable(ppv, idx) 
{ 
   Return   NumGet(NumGet(1*ppv)+4*idx) 
} 
QueryInterface(ppv, ByRef IID) 
{ 
   If   StrLen(IID)=38 
      GUID4String(IID,IID) 
   DllCall(NumGet(NumGet(1*ppv)), "Uint", ppv, "str", IID, "UintP", ppv) 
   Return   ppv 
} 
AddRef(ppv) 
{ 
   Return   DllCall(NumGet(NumGet(1*ppv)+4), "Uint", ppv) 
} 
Release(ppv) 
{ 
   Return   DllCall(NumGet(NumGet(1*ppv)+8), "Uint", ppv) 
} 
GUID4String(ByRef CLSID, String) 
{ 
   VarSetCapacity(CLSID, 16) 
   DllCall("ole32\CLSIDFromString", "Uint", Unicode4Ansi(String,String,38), "Uint", &CLSID) 
   Return   &CLSID 
} 
CoTaskMemAlloc(cb) 
{ 
   Return   DllCall("ole32\CoTaskMemAlloc", "Uint", cb) 
} 
CoTaskMemFree(pv) 
{ 
   Return   DllCall("ole32\CoTaskMemFree", "Uint", pv) 
} 
Unicode4Ansi(ByRef wString, sString, nSize = "") 
{ 
   If (nSize = "") 
       nSize:=DllCall("kernel32\MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &sString, "int", -1, "Uint", 0, "int", 0) 
   VarSetCapacity(wString, nSize * 2 + 1) 
   DllCall("kernel32\MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &sString, "int", -1, "Uint", &wString, "int", nSize + 1) 
   Return   &wString 
}

API_GetMenuItemID( hMenu, nPos ) { 
   return DllCall("GetMenuItemID", "uint", hMenu, "int", nPos) 
} 
API_GetSubmenu( hMenu, nPos ) { 
   return DllCall("GetSubMenu", "uint", hMenu, "int", nPos) 
} 
API_GetMenuItemsCount(hMenu) 
{ 
   return DllCall("GetMenuItemCount", "Uint", hMenu, "Uint") 
} 

;Executes context menu entries by comparing the name of the selected entry with a desired one and using key navigation
;NOT USED
ContextMenuCommand(name, name2="") 
{ 
   ;SendInput,{APPSKEY}    
   winwait ahk_class #32768
   if WinExist("ahk_class #32768") 
   {        
   	outputdebug dialog found
      ;WinGet, activeWindow, ID 
      ;hWnd := activeWindow 
      ;activeWindow := DllCall("GetWindow", "Uint", activeWindow, "Uint", 4, "Uint") 
      SendMessage,0x01E1 
      hmenu := ErrorLevel 
      nPos := -1 
      nPos2 := -1 
      
      if hmenu!=1 
      { 
      	outputdebug hmenu found
            ;hmenu := API_GetSubMenu(hmenu, itemCount-1) 
            nPos := findMenuItem(hmenu, name, keyPos) 
            outputdebug menu item: %npos%
            ;MsgBox % "m2 " . nPos 
            if(nPos != -1 and name2 != "") 
            { 
              hMenu2 := API_GetSubMenu(hmenu, nPos)   
							 outputdebug 2nd hwnd: %hmenu2%             
               nPos2 := findMenuItem(hmenu2, name2, keyPos2) 
               outputdebug 2nd menu item: %npos2%
               ;MsgBox % "m2 " . nPos2 
            } 

            if((nPos2 != -1) or (nPos != -1 and name2 = "")) 
            { 
            	outputdebug go to entry %nPos%
               
							 Loop %keyPos% 
               { 
                  SendInput,{DOWN} 
               } 
               SendInput,{ENTER},{Up}    

               if(name2 <> "") 
               { 
                  Loop %keyPos2% { 
                     SendInput,{DOWN} 
                  	sleep,500
                  } 
                  SendInput,{ENTER}    
               } 
            } 

      } 
   } 
}

GetMenuString(hMenu, nPos) 
{ 
   length := DllCall("GetMenuString" 
         , "UInt", hMenu 
         , "UInt", nPos 
         , "UInt", 0   ; NULL 
         , "Int", 0   ; Get length 
         , "UInt", 0x0400)   ; MF_BYPOSITION 
      VarSetCapacity(lpString, length + 1)   ; I don't check the result... 
      length := DllCall("GetMenuString" 
         , "UInt", hMenu 
         , "UInt", nPos 
         , "Str", lpString 
         , "Int", length + 1 
         , "UInt", 0x0400) 
   return lpString 
} 

findMenuItem(hMenu, name, ByRef keyPos) { 
		outputdebug findmenuitem called with hmenu: %hmenu% name: %name% keypos: %keypos%
   RepeatCount := API_GetMenuItemsCount(hMenu)
	 outputdebug repeatcount %repeatcount% 
	 nPos:=0
   Loop %RepeatCount% { 
   		nPos:=A_Index-1
       keyPos++
       outputdebug keyPos: %keyPos%
       string:=GetMenuString(hMenu, nPos)
       ;Separators don't count
       if(!string)
			 {
			 	outputdebug decrease
			  keyPos--
			 }
       outputdebug string %string%
       if (string=name) { 
       		outputdebug return %nPos%, keypos=%keypos%
       		
          return nPos
       } 
   } 
   return -1 
} 

;Checks if a context menu is active and has focus
IsContextMenuActive() 
{ 
	GuiThreadInfoSize = 48 
	VarSetCapacity(GuiThreadInfo, 48) 
	NumPut(GuiThreadInfoSize, GuiThreadInfo, 0) 
	if not DllCall("GetGUIThreadInfo", uint, 0, str, GuiThreadInfo) 
	{ 
	  MsgBox GetGUIThreadInfo() indicated a failure. 
	  return 
	} 
	; GuiThreadInfo contains a DWORD flags at byte 4 
	; Bit 4 of this flag is set if the thread is in menu mode. GUI_INMENUMODE = 0x4 
	if (NumGet(GuiThreadInfo, 4) & 0x4) 
	  return true
	return false
}
