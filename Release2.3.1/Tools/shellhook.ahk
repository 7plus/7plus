#SingleInstance Force 
#NoTrayIcon 
SetBatchLines, -1 
; Process, Priority,, High 
Title := "ShellHook Messages", Filters := "", Pause := 0 
FilterMenu(), Gui() 
Hwnd := WinExist(), WM_VSCROLL := 0x115, SB_BOTTOM := 7 
DllCall( "RegisterShellHookWindow", UInt,Hwnd ) 
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" ) 
OnMessage( MsgNum, "ShellMessage" ) 
Return 

DecToHex( ByRef lParam )
{
	f := A_FormatInteger
   SetFormat, Integer, Hex 
   lParam += 0
   SetFormat, Integer, %f%
   Return lParam
} 

FilterMenu() 
{ 
   Global FilterList 
   Menu, Filter, Add, Filter &All, FilterAll 
   Menu, Filter, Add, Filter &None, FilterNone 
   Menu, Filter, Add 
   FilterList = WINDOWCREATED,WINDOWDESTROYED,ACTIVATESHELLWINDOW,WINDOWACTIVATED 
   ,GETMINRECT,REDRAW,TASKMAN,LANGUAGE,SYSMENU,ENDTASK,ACCESSIBILITYSTATE,APPCOMMAND 
   ,WINDOWREPLACED,WINDOWREPLACING,HIGHBIT,FLASH,RUDEAPPACTIVATED 
   Loop, Parse, FilterList, `, 
   { 
      If A_Loopfield    
         Menu, Filter, Add, %A_Loopfield%, SetFilter 
   } 
   Menu, FilterMenu, Add, Message &Filter, :Filter 
   Gui, Menu, FilterMenu 
} 

Gui() 
{ 
   Global 
   Gui, +LastFound +AlwaysOnTop +Resize ; +ToolWindow 
   Gui, Margin, 0, 0 
   Gui, Font, s8, Microsoft Sans Serif 
   Gui, Color,, DEDEDE 
   Gui, Add, ListView, w400 r10 vData +Grid +NoSort, lParam (hWnd)|Process|wParam|Message 
   LV_ModifyCol( 1, 60 ), LV_ModifyCol( 2, 100 ), LV_ModifyCol( 3, 40 ), LV_ModifyCol( 4, 180 ) 
   Gui, Show,, %Title% 
} 

ShellMessage( wParam,lParam ) 
{ 
   Global Data,Hwnd,WM_VSCROLL,SB_BOTTOM,Filters,Pause 
   WinGetTitle, title, ahk_id %lParam% 
   WinGet, pname, ProcessName, ahk_id %lParam% 
   WinGet, pid, PID, ahk_id %lParam% 

   if wParam = 1 
      msg = HSHELL_WINDOWCREATED 
   if wParam = 2 
      msg = HSHELL_WINDOWDESTROYED 
   if wParam = 3 
      msg = HSHELL_ACTIVATESHELLWINDOW 
   if wParam = 4 
      msg = HSHELL_WINDOWACTIVATED 
   if wParam = 5 
      msg = HSHELL_GETMINRECT 
   if wParam = 6 
      msg = HSHELL_REDRAW 
   if wParam = 7 
      msg = HSHELL_TASKMAN 
   if wParam = 8 
      msg = HSHELL_LANGUAGE 
   if wParam = 9 
      msg = HSHELL_SYSMENU 
   if wParam = 10 
      msg = HSHELL_ENDTASK 
   if wParam = 11 
      msg = HSHELL_ACCESSIBILITYSTATE 
   if wParam = 12    
      msg = HSHELL_APPCOMMAND 
   if wParam = 13 
      msg = HSHELL_WINDOWREPLACED 
   if wParam = 14 
      msg = HSHELL_WINDOWREPLACING 
   if wParam = 15 
      msg = HSHELL_HIGHBIT 
   if wParam = 16 
      msg = HSHELL_FLASH 
   if wParam = 17 
      msg = HSHELL_RUDEAPPACTIVATED 
    
   If wParam not in %Filters% 
   { 
      If ( Pause = 0 ) 
      {    
         DecToHex( lParam ) 
         LV_Add( "", lParam, pname, wParam, msg ) 
         SendMessage, WM_VSCROLL, SB_BOTTOM, 0, SysListView321, ahk_id %Hwnd%       
      }    
   }    
} 

SetFilter: 
Menu, Filter, ToggleCheck, %A_ThisMenuItem% 
Loop, Parse, FilterList, `, 
{ 
   If ( A_ThisMenuItem = A_Loopfield ) 
   { 
      If A_Index in %Filters% ; remove from filter 
      {       
         Filter := A_Index 
         Loop, Parse, Filters, `, 
         { 
            If ( A_Loopfield != Filter ) 
               NewFilters .= A_Loopfield . ( A_Loopfield != "" ? "`," : "" ) 
         } 
         Filters := NewFilters, NewFilters := "" 
      }    
      Else ; add to filter 
      { 
         Filters .= A_Index . "," 
      }    
   }    
} 
Return 

FilterAll: 
Filters = 
Loop, Parse, FilterList, `, 
{    
   Menu, Filter, Check, %A_Loopfield% 
   Filters .= A_Index . ( A_Index != 17 ? "," : "" ) 
} 
Return 

FilterNone: 
Loop, Parse, FilterList, `, 
{ 
   Menu, Filter, UnCheck, %A_Loopfield% 
   Filters = 
} 
Return 

GuiContextMenu: 
Menu, Filter, Show 
Return 

GuiSize: 
GuiControl, Move, Data, w%A_GuiWidth% h%A_GuiHeight% 
SendMessage, WM_VSCROLL, SB_BOTTOM, 0, SysListView321, ahk_id %Hwnd% 
Return 

GuiClose: 
GuiEscape: 
ExitApp 
Return 

#IfWinActive ShellHook Messages 
   C::LV_Delete() 
       
   P:: 
   Pause :=! Pause, WinTitle := ( Pause = 0 ? Title : Title . " (Paused)" ) 
   WinSetTitle %WinTitle% 
   Return 
    
   R::Reload 
   X::ExitApp    
#IfWinActive
