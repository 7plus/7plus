; IconEx v1.0 by SKAN ( arian.suresh@gmail.com )  ||    CD: 13-May-2008 |  LM: 14-May-2008

#SingleInstance, Force
SetWorkingDir %A_ScriptDir%  
SetBatchLines, -1
Process, Priority,, High

SaveButton := 0x79 -1   ; ( VK code for F9 ) Note: modify -1 to -2 for F8 and so on...
KeyName := "F9"         ; depends on the VK code you use above
Deff    := A_ScriptDir  ; Default ICON save folder
CallB   := RegisterCallback( "EnumResNameProc" )
tFolder := A_WinDir "\SYSTEM32\SHELL32.DLL" ; default folder in address bar
IfExist, %A_Temp%\IconEx.tmp
 {
   FileRead, tFolder, %A_Temp%\IconEx.tmp
   FileDelete, %A_Temp%\IconEx.tmp   
 }
 
EnumResNameProc( hModule, lpszType, lpszName, lParam ) { 
 Global IconGroups, IGCount 
 IconGroups .= ( ( IconGroups!="" ) ? "|" : "" ) . lpszName , IGCount:=IGCount+1  
 Return True 
} 

Gui,Font, s10 Normal, Tahoma
; SHAutoComplete():  Sean - http://www.autohotkey.com/forum/viewtopic.php?p=121621#121621
; For constants : http://www.codeproject.com/KB/edit/autocomp.aspx
Gui, Add, Combobox, x7 y7 w550 h21 Choose1 -Theme hwndhSHAC vtFolder, %tFolder% 
ControlGet, hMyEdit, hWnd,, Edit1, ahk_id %hSHAC% 

DllCall( "ole32\CoInitialize", UInt,0 ) 
DllCall( "shlwapi\SHAutoComplete", UInt,hMyEdit, UInt,0x1|0x10000000 ) 
; DllCall( "ole32\CoUninitialize" ) ; In Vista: Crashes AHK On Exit 
 
Gui,Font, s8 Normal, Tahoma
Gui, Add, Button, x+2 w33 h24 +Default gUpdateResourceList, &Go
Gui, Add, Button, x+2 w52 h24 gSelectFolder, &Browse
Gui, Add, ListView, x7 y+5 h280 w235 -Theme -E0x200 +0x4 +0x8 +Border vLVR gLVR  
                   +BackGroundFFFFFA c444466 AltSubmit, Resource File|Icons|IconGroup
LV_ModifyCol( 1 ,"170" ), LV_ModifyCol( 2, "42 Integer" ), LV_ModifyCol( 3, "0" )
Gui, Add, ListView, x+0 yp h280 w405 -Theme +Icon -E0x200 +0x100 
                   +BackGroundFFFFFC cBB2222 Border AltSubmit vLVI gLVI hwndLVC2 
Gui, Add, Hotkey, x2 y+79 w1 h1 +Disabled vHotkey gCreateSimpleIcon
Loop 8 {
   Ix += 1  
   Gui, Add, Text,x+10 yp-70 0x1203 w70 h70 vI%Ix% hWndIcon%Ix% gSelectSimpleIcon
   Gui, Add, Text, xp  yp+70 0x201  w70 h16 vIconT%Ix%, -
}  
Gui, Add, Text, x2 y+79 w1 h1 
Loop 8 {
   Ix += 1  
   Gui, Add, Text,x+10 yp-70 0x1203 w70 h70 vI%Ix% hWndIcon%Ix% gSelectSimpleIcon
   Gui, Add, Text, xp  yp+70 0x201  w70 h16 vIconT%Ix%, -
}  

Gui, Add, Button, X7 y+30 gAccelerator, &File
Gui, Add, Button, x+5     gAccelerator, &Icon
Gui, Add, Button, x+5     gAccelerator, A&ddress Bar
Gui, Add, Button, x+5     gAccelerator, &Reload
Gui,Font
Gui, Add, StatusBar, vSB gFindTarget
SB_SetParts( 40,425 )
GoSub, UpdateResourceList
SB_SetText( "Type the path to a folder/file. Auto complete enabled", 2 ) 
Gui, Show, w655 h535 , IconEx - v1.0
Return                                                 ; // end of auto-execute section //

UpdateResourceList:
  SendInput, {Escape}
  ControlGetText,tFolder,, ahk_id %hSHAC%
  If ! InStr( FileExist( tFolder ), "D" )  
    Folder := tFolder
  Else Folder := tFolder . "\*.*"
  GoSub, SetFolder
  Gui, ListView, LVI
  LV_Delete()
  Gui, ListView, LVR
  LV_Delete(), , SB_SetText( "  Loading files.. Please wait" , 2 ), FileCount := 0
  Loop, %Folder%  {
    If A_LoopFileExt Not in EXE,DLL,CPL,SCR
      Continue
    hModule := DllCall( "LoadLibraryEx", Str,A_LoopFileLongPath, UInt,0, UInt,0x2 )
    IfEqual,hModule,0,Continue
    IGCount:=0, IconGroups := ""
    DllCall("EnumResourceNamesA", UInt,hModule, UInt,14, UInt,CallB, UInt,0 )
    DllCall( "FreeLibrary", UInt,hModule )
    IfEqual,IGCount,0, Continue
    FileCount:=FileCount+1
    FileName := DllCall( "CharUpperA", Str,A_LoopFileName, Str )
    Gui, ListView, LVR
    LV_ADD( "", FileName, IGCount, IconGroups )
    SB_SetText( "`t" FileCount, 1 ) 
  } 
  SB_SetText( "`t" FileCount, 1 ), SB_SetText( "  Done!" , 2 )
  GuiControl, Focus, LVR
  RowNo := 1
  GoSub, LVRSUB
  Gui, ListView, LVI
  LV_Modify( 1, "Select" )
  Gui, ListView, LVR
  GuiControl, Focus, LVR
  LV_Modify( 1, "Select" )
  GuiControl, Focus, tFolder
Return

LVR:
  If ( A_GuiEvent="k" and ( A_EventInfo=40 or A_EventInfo=38 ) ) {
       RowNo := LV_GetNext( 0, "Focused" )
       GoTo, LVRSUB
       Return
  } 
  
  If ( A_GuiEvent="k" and A_EventInfo=SaveButton ) {
       RowNo := LV_GetNext( 0, "Focused" )
       IfNotEqual,RowNo,0, GoSub, ExtractIconRes
       Return
  } 
  IfNotEqual, A_GuiEvent,Normal, Return
  RowNo := A_EventInfo
LVRSUB:  
  Gui, ListView, LVR
  LV_GetText( File, RowNo,1 ), LV_GetText( IGC, RowNo,2 ), LV_GetText( IG, RowNo,3 )
  SB_SetText( "Press <" KeyName "> to save all icons in " File , 2 )  
  Gui, ListView, LVI
  LV_Delete()
  ImageListID ? IL_Destroy( ImageListID ) :
  ImageListID := IL_Create( 10,10,1 ), LV_SetImageList(ImageListID)
  Loop, %IGC%
        IL_Add(ImageListID, tFolder "\" File, A_Index )
  Loop, Parse, IG, |
       {
          Gui, ListView, LVI
          LV_Add("Icon" . A_Index, A_LoopField )
       }     
  RowNo := 1
  GoSub, LVISUB
  Gui, ListView, LVR
Return

LVI:
  Gui, ListView, LVI
  If ( A_GuiEvent="k" and ( A_EventInfo>=37 and A_EventInfo<=40 ) ) {
       RowNo := LV_GetNext( 0, "Focused" )
       LV_GetText( IconGroup, RowNo,1 )  
       SB_SetText( "Press <" KeyName "> to save the Icon Group " IconGroup, 2 )
       GoTo, LVISUB
       Return
  } 
  If ( A_GuiEvent="k" and A_EventInfo=SaveButton ) {
       RowNo := LV_GetNext( 0, "Focused" )
       IfNotEqual,RowNo,0,GoSub, ExtractIcon
       Return
  } 
  IfNotEqual, A_GuiEvent,Normal, Return
  RowNo := A_EventInfo
  LV_GetText( IconGroup, RowNo,1 )  
  SB_SetText( "Press <" KeyName "> to save the Icon Group " IconGroup, 2 )
LVISUB:
  Gui, ListView, LVI
  LV_GetText( IconGroup, RowNo,1 )
  hMod := DllCall( "LoadLibraryEx", Str,tFolder "\" File, UInt,0, UInt,0x2 )
  Buff := GetResource( hMod, IconGroup, (RT_GROUP_ICON:=14), nSize, hResData ) 
  Icos := NumGet( Buff+4, 0, "UShort" ), Buff:=Buff+6
  SB_SetText( "`t" Icos " Icons in < Group " IconGroup " >", 3 ) 
  Loop, %Icos% { 
      W   := NumGet( Buff+0,0,"UChar" ),   H   := NumGet( Buff+0,1,"UChar" )
      BPP := NumGet( Buff+0,6,"UShort"),   nID := NumGet( Buff+0,12,"UShort")
      If ( W+H = 0 ) {
        SendMessage, ( STM_SETIMAGE:=0x172 ), 0x1, 0,, % "ahk_id " Icon%A_Index%        
        DllCall( "FreeResource", UInt,hResData ) 
        GuiControl,,IconT%A_Index%, -  
        Continue 
      }
      Buff+=14
      IconD  := GetResource( hMod, nID, (RT_ICON:=3), nSize, hResData )
      Wi := ( W > 64 ) ? 64 : W , Hi := ( H > 64 ) ? 64 : H
      hIcon  := DllCall( "CreateIconFromResourceEx", UInt,IconD, UInt,BPP, Int,1 
                        , UInt, 0x00030000, Int,Wi, Int,Hi, UInt,(LR_SHARED := 0x8000) )
      SendMessage, ( STM_SETIMAGE:=0x172 ), 0x1, 0,, % "ahk_id " Icon%A_Index% 
      SendMessage, ( STM_SETIMAGE:=0x172 ), 0x1, hIcon,, % "ahk_id " Icon%A_Index% 
      DllCall( "FreeResource", UInt,hResData ) 
      GuiControl,,IconT%A_Index%, % W "x" H "-" BPP "b"  
  } 
  Loop % 16-Icos {
      Ix := Icos+A_Index
      GuiControl,,IconT%Ix%, -      
      SendMessage, ( STM_SETIMAGE:=0x172 ), 0x1, 0,, % "ahk_id " Icon%Ix%
  } 
  DllCall( "FreeResource", UInt,hResData ), DllCall( "FreeLibrary", UInt,hModule )
Return

GetResource( hModule, rName, rType, ByRef nSize, ByRef hResData ) { 
  hResource := DllCall( "FindResource", UInt,hModule, UInt,rName, UInt,rType ) 
  nSize     := DllCall( "SizeofResource", UInt,hModule, UInt,hResource ) 
  hResData  := DllCall( "LoadResource", UInt,hModule, UInt,hResource ) 
Return DllCall( "LockResource", UInt, hResData ) 
}

ExtractIconRes:
  FileSelectFolder, TargetFolder, *%DEFF%, 3, Extract Icons! Where to?
  IfEqual,TargetFolder,, Return
  GoSub, SetFolder
  hModule := DllCall( "LoadLibraryEx", Str,tFolder "\" File, UInt,0, UInt,0x2 )
  Loop, Parse, IG, | 
    { 
      FileN := SubStr( "000" A_Index, -3 ) "-" SubStr( "00000" A_LoopField, -4 ) ".ico"
      SB_SetText( (FileN := TargetFolder "\" FileN), 2 ), IconGroup := A_LoopField
      GoSub, WriteIcon
    } 
  DllCall( "FreeLibrary", UInt,hModule ), SB_SetText( IGC " Icons extracted!", 2 )
  DllCall( "Sleep", UInt,1000 ), SB_SetText( TargetFolder, 2 )
Return

ExtractIcon:
  LV_GetText( IconGroup, RowNo,1 )
  FileN := SaveIcon( DEFF "\" File "-IG" SubStr( "-00000" IconGroup, -4 ) ".ico" )
  IfEqual,FileN,,Return   
  hModule := DllCall( "LoadLibraryEx", Str,tFolder "\" File, UInt,0, UInt,0x2 )
  GoSub, WriteIcon
  DllCall( "FreeLibrary", UInt,hModule ), SB_SetText( FileN, 2 )
Return

WriteIcon:
 hFile := DllCall( "_lcreat", Str,FileN, UInt,0 )
 sBuff := GetResource( hModule, IconGroup, (RT_GROUP_ICON:=14), nSize, hResData ) 
 Icons := NumGet( sBuff+0, 4, "UShort" ) 
 tSize := nSize+( Icons*2 ), VarSetCapacity( tmpBuff,tSize, 0 ), tBuff := &tmpBuff 
 CopyData( sBuff, tBuff, 6  ),   sBuff:=sBuff+06,  tBuff:=tBuff+06 
 Loop %Icons% 
      CopyData( sBuff, tBuff, 14  ),  sBuff:=sBuff+14,  tBuff:=tBuff+16 
 DllCall( "FreeResource", UInt,hResData ) 
 DllCall( "_lwrite", UInt,hFile, Str,tmpBuff, UInt,tSize ) 
 EOF := DllCall( "_llseek", UInt,hFile, UInt,-0, UInt,2 ) 
 VarSetCapacity( tmpBuff, 0 ) 
 DataOffset := DllCall( "_llseek", UInt,hFile, UInt,18, UInt,0 ) 

 Loop %Icons% {
      VarSetCapacity( Data,4,0 ) 
      DllCall( "_lread", UInt,hFile, Str,Data, UInt,2 ), 
      nID := NumGet( Data, 0, "UShort" ) 
      DllCall( "_llseek", UInt,hFile, UInt,-2, UInt,1 ) 
      NumPut( EOF, Data ),  DllCall( "_lwrite", UInt,hFile, Str,Data, UInt,4 ) 
      DataOffset := DllCall( "_llseek", UInt,hFile, UInt,0, UInt,1 ) 
      sBuff := GetResource( hModule, nID, (RT_ICON:=3), nSize, hResData )    
      DllCall( "_llseek", UInt,hFile, UInt,0, UInt,2 )          
      DllCall( "_lwrite", UInt,hFile, UInt,sBuff, UInt,nSize ) 
      DllCall( "FreeResource", UInt,hResData ) 
      EOF := DllCall( "_llseek", UInt,hFile, UInt,-0, UInt,2 ) 
      DataOffset := DllCall( "_llseek", UInt,hFile, UInt,DataOffset+12, UInt,0 ) 
 }  
 DllCall( "_lclose", UInt,hFile ) 
Return

SelectSimpleIcon:
  StringTrimLeft,FNo,A_GuiControl,1
  GuiControlGet, IconT%fNo%
  If ( (IconT := IconT%fNo%) = "-" )
       Return
  SB_SetText("Press <" KeyName "> to save Icon " IconT  " from Icon Group " IconGroup ,2)
  GuiControl, Enable, Hotkey
  GuiControl, Focus,  Hotkey
  GuiControl,,Hotkey
  SetTimer, DisableHotkey, -5000
Return

DisableHotkey:
  GuiControlGet, Hotkey, Enabled
  If ( Hotkey ) {
  GuiControl,,Hotkey
  GuiControl, Disable, Hotkey
  GuiControl, Focus, LVI
  StatusBarGetText, SbTxt, 2, IconEx
  InStr( SbTxt, "to save Icon") ? SB_SetText( "", 2 ) : 
  }   
Return  

CreateSimpleIcon:
  SB_SetText( "", 2 )
  GuiControlGet, Hotkey
  GuiControl, Disable, Hotkey
  IfNotEqual, Hotkey, %KeyName%, Return

  FileN := SaveIcon( Deff "\" File " [" SubStr("0000" IconGroup, -4 ) "-" 
                    . SubStr( "0" FNo,-1) "][ " IconT "].ico" )            
  IfEqual,FileN,, Return     
  hModule := DllCall( "LoadLibraryEx", Str,tFolder "\" File, UInt,0, UInt,0x2 )
  Buffer := GetResource( hModule, IconGroup, (RT_GROUP_ICON:=14), nSize, hResData )
  tBuff := Buffer+6+((Fno-1)*14), nID := Numget( tBuff+0, 12, "Ushort" )
  VarSetCapacity(Z,10,0), NumPut(1,Z,2,"UChar"), NumPut(1,Z,4,"UChar" ),NumPut(22,Z,6)
  SBuff := GetResource( hModule, nID, (RT_ICON:=3), nSize, hResData )
  hFile := DllCall( "_lcreat", Str,FileN, UInt,0 )
  DllCall( "_lwrite", UInt,hFile, Str,Z, UInt,6 )
  DllCall( "_lwrite", UInt,hFile, UInt,tbuff, UInt,12 ) 
  DllCall( "_lwrite", UInt,hFile, UInt,&Z+6, UInt,4 )
  DllCall( "FreeResource", UInt,hResData )
  Buff := GetResource( hModule, nID, (RT_ICON:=3), nSize, hResData )
  DllCall( "_lwrite", UInt,hFile, UInt,Buff, UInt,nSize )
  DllCall( "_lclose", UInt,hFile ) 
  DllCall( "FreeResource", UInt,hResData ),  DllCall( "FreeLibrary", UInt,hModule )
  SB_SetText( FileN, 2 )
Return

FindTarget:
  StatusBarGetText, SB, 2, A
  IfExist, %SB%, Run, %COMSPEC% /c "Explorer /select`, %SB%",,Hide
Return

SetFolder:
  ControlGetText,tFolder,, ahk_id %hSHAC%
  If ! InStr( FileExist( tFolder ), "D" ) { 
    SplitPath, tFolder,, tFolder
    ControlSetText,,% (tFolder:=DllCall("CharUpperA",Str,tFolder,Str )), ahk_id %hSHAC%
 }      
Return

SelectFolder:
  GoSub, SetFolder
  FileSelectFolder, nFolder, *%tFolder%, , Select a Resource Folder
  IfEqual,nFolder,,Return
  ControlSetText,,%nFolder%, ahk_id %hSHAC%
  GoSub, SetFolder
  GoSub, UpdateResourceList
Return

CopyData( SPtr, TPtr, nSize ) { 
  Return DllCall( "RtlMoveMemory", UInt,TPtr, UInt,SPtr, UInt,nSize ) 
}

SaveIcon( Filename, Prompt="Save Icon As"  ) {
  FileSelectFile, File, 16, %Filename%, %Prompt%, Icon (*.ico)
Return ( File <> "" and SubStr( File, -3 ) <> ".ico" ) ? File ".ico" : File
}

Accelerator:
 IfEqual,A_GuiControl,&File, GuiControl,Focus,LVR
 IfEqual,A_GuiControl,&Icon, GuiControl,Focus,LVI
 IfEqual,A_GuiControl,A&ddress Bar, GuiControl,Focus,tFolder
 IfEqual,A_GuiControl,&Reload,IfExist,%tFolder%\%File%
    {
      FileAppend,%tFolder%\%File%,%A_Temp%\IconEx.tmp
      Reload      
    }
  
Return
 
GuiContextMenu:
  StatusBarGetText, SbTxt, 2, IconEx
  StringTrimLeft, SbTxt,SbTxt, 14
  If ( SubStr( SbTxt, 1,4) = "save" )
     SendInput {%KeyName%}
Return   

GuiClose:
  ExitApp