#NoEnv 
#SingleInstance, force 
SetWorkingDir %A_ScriptDir% 
SetBatchLines,-1 
CoordMode, Mouse, Screen 



WinGetID := "" 
WinGetEx := 1 
WinGetOnTop := "+" 
WinGetHidden := "Off" 
WinGetUpdate := 100 


Menu, Tray, Click, 1 
Menu, Tray, NoStandard 
Menu, Tray, Add, WinGet, WinGetShow 
Menu, Tray, Add 
Menu, Tray, Add, Always on top, WinGetOnTop 
Menu, Tray, Add, Show hidden text, WinGetHidden 
Menu, Tray, Add, Frozen, WinGetFrozen 
Menu, Tray, Add 
Menu, Tray, Add, Quit, WinGetQuit 
Menu, Tray, Default, WinGet 
Menu, Tray, Icon, shell32.dll, 172 
if ( WinGetOnTop = "+" ) 
   Menu, Tray, Check, Always on top 
if ( WinGetHidden = "On" ) { 
   DetectHiddenText, On 
   Menu, Tray, Check, Show hidden text 
} 
else 
   DetectHiddenText, Off 

WinGetShow: 

   if WinGetID 
      WinActivate, ahk_id %WinGetID% 
   else { 
      WinGetCreate() 
      SetTimer, WinGetUpdate, %WinGetUpdate% 
   } 
   WinGetFrozen := 0 
   Menu, Tray, Uncheck, Frozen 
   WinSetTitle, ahk_id %WinGetID%,, %A_Space%WinGet ( Press CTRL to freeze ) 

Return 

WinGetFrozen: 

   if WinGetFrozen { 
      WinGetFrozen := 0 
      Menu, Tray, Uncheck, Frozen 
      WinSetTitle, ahk_id %WinGetID%,, %A_Space%WinGet ( Press CTRL to freeze ) 
      SetTimer, WinGetUpdate, %WinGetUpdate% 
   } 
   else { 
      WinGetFrozen := 1 
      Menu, Tray, Check, Frozen 
      WinSetTitle, ahk_id %WinGetID%,, %A_Space%WinGet ( frozen ) 
      SetTimer, WinGetUpdate, Off 
   } 

Return 


WinGetOnTop: 

   WinSet, AlwaysOnTop, Toggle, ahk_id %WinGetID% 
   Menu, Tray, ToggleCheck, Always on top 
   if ( WinGetOnTop = "+" ) 
      WinGetOnTop = "-" 
   else 
      WinGetOnTop = "+" 
    
Return 



WinGetHidden: 

   if ( WinGetHidden = "On" ) { 
      WinGetHidden = "Off" 
      DetectHiddenText, Off 
   } 
   else { 
      WinGetHidden = "On" 
      DetectHiddenText, On 
   } 
   Menu, Tray, ToggleCheck, Show hidden text 
   WinGetUpdate( "last" ) 

Return 



WinGetClose: 
WinGetEscape: 

   SetTimer, WinGetUpdate, Off 
   WinGetID := "" 
   Gui, %A_Gui%:Submit 
   Gui, %A_Gui%:Destroy 

Return 



WinGetQuit: 

   ExitApp 

Return 



WinGetUpdate: 

   WinGetUpdate() 

Return 



WinGetEx: 

   WinGetEx := WinGetEx + 1 
   if ( WinGetEx > 2 ) 
      WinGetEx := 1 
   WinGetUpdate( "last" ) 

Return 



WinGetCreate() 
{ 
Global WinGetID 
   , WinGetOnTop 



   Gui, Destroy 
   Gui, Font, s9, Lucida Sans Unicode 
   Gui, +LabelWinGet %WinGetOnTop%AlwaysOnTop +LastFound 
   WinGetID := WinExist() 
   Gui, Add, Tab2, W310 H256, General|Style|ExStyle|Control|Mouse 
   Gui, Tab, 1 
   Gui, Add, Text, H16 Section, Title: 
   Gui, Add, Edit, W244 H16 xp+48 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+16, Class: 
   Gui, Add, Edit, W244 H16 xp+48 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+16, Hwnd: 
   Gui, Add, Edit, W244 H16 xp+48 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+16, Process: 
   Gui, Add, Edit, W244 H16 xp+48 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+20, x: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, y: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, W64 H16 xp+68 yp, Transcolor: 
   Gui, Add, Edit, W64 H16 xp+64 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+16, w: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, h: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, W64 H16 xp+68 yp, Alpha: 
   Gui, Add, Edit, W64 H16 xp+64 yp -E0x200 ReadOnly 
   Gui, Add, Text, W200 H16 xs yp+20 gWinGetEx 
   Gui, Add, Edit, W288 H96 xs yp+16 -E0x200 ReadOnly 
   Gui, Tab, 2 
   Gui, Add, Edit, H16 xs ys -E0x200 ReadOnly 
   Gui, Add, Edit, W288 H192 xs ys+24 -E0x200 ReadOnly 
   Gui, Tab, 3 
   Gui, Add, Edit, H16 xs ys -E0x200 ReadOnly 
   Gui, Add, Edit, W288 H192 xs ys+24 -E0x200 ReadOnly 
   Gui, Tab, 4 
   Gui, Add, Text, H16 Section, Name: 
   Gui, Add, Edit, W252 H16 xp+40 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+16, Hwnd: 
   Gui, Add, Edit, H16 xp+40 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+20, x: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, y: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+16, w: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, h: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Edit, W288 H144 xs yp+20 -E0x200 ReadOnly 
   Gui, Tab, 5 
   Gui, Add, Text, H16 Section, Relative to screen: 
   Gui, Add, Text, H16 xs yp+20, x: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, y: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, W200 H16 xs yp+30, Relative to window: 
   Gui, Add, Text, H16 xs yp+20, x: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, y: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xs yp+30, Relative to control: 
   Gui, Add, Text, H16 xs yp+20, x: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Add, Text, H16 xp+68 yp, y: 
   Gui, Add, Edit, W64 H16 xp+12 yp -E0x200 ReadOnly 
   Gui, Show,, %A_Space%WinGet ( Press CTRL to freeze ) 

} 



WinGetUpdate(win_id = 0, ctrl_id = 0 ) 
{ 
Global WinGetID 
   , WinGetEx 
Static WinGetLast 



   if not win_id 
      MouseGetPos,x2 ,y2 , win_id, ctrl_id 
   if ( win_id = WinGetID ) 
      Return 
   else if ( win_id = "last" ) { 
      MouseGetPos,x2 ,y2 
      RegExMatch( WinGetLast, "^0x.* ", win_id ) 
      RegExMatch( WinGetLast, " 0x.*$", ctrl_id ) 
   } 
   GuiControl,, Edit23, %x2% 
   GuiControl,, Edit24, %y2% 
   WinGetLast := win_id . " " . ctrl_id 
   WinGetTitle, x, ahk_id %win_id% 
   WinGetClass, y, ahk_id %win_id% 
   WinGet, w, ProcessName, ahk_id %win_id% 
   GuiControl,, Edit1, %x% 
   GuiControl,, Edit2, %y% 
   GuiControl,, Edit3, %win_id% 
   GuiControl,, Edit4, %w% 
   WinGetPos, x, y, w, h, ahk_id %win_id% 
   x2 -= x 
   y2 -= y 
   GuiControl,, Edit25, %x2% 
   GuiControl,, Edit26, %y2% 
   GuiControl,, Edit5, %x% 
   GuiControl,, Edit6, %y% 
   GuiControl,, Edit8, %w% 
   GuiControl,, Edit9, %h% 
   WinGet, x, Transcolor, ahk_id %win_id% 
   WinGet, y, Transparent, ahk_id %win_id% 
   if not x 
      x := "none" 
   if not y 
      y := "Off" 
   GuiControl,, Edit7, %x% 
   GuiControl,, Edit10, %y% 
   if  ( WinGetEx = 1 ) { 
      GuiControl,, Static11, Status bar: 
      x := "" 
      Loop, 9 
      { 
         StatusBarGetText, y, %A_Index%, ahk_id %win_id% 
         if y 
            x := x . "`n" . y 
      } 
      GuiControl,, Edit11, % SubStr( x, 2 ) 
   } 
   else if ( WinGetEx = 2 ) { 
      GuiControl,, Static11, Window text: 
      WinGetText, x, ahk_id %win_id% 
      GuiControl,, Edit11, %x% 
   } 
   WinGet, x, Style, ahk_id %win_id% 
   WinGet, y, ExStyle, ahk_id %win_id% 
   GuiControl,, Edit12, %x% 
   GuiControl,, Edit13, % WinGetStyle( x, "WS_" ) 
   GuiControl,, Edit14, %y% 
   GuiControl,, Edit15, % WinGetStyle( y, "WS_EX_" ) 
   if ctrl_id { 
      GuiControl,, Edit16, %ctrl_id% 
      ControlGet, ctrl_id, HWND,, %ctrl_id%, ahk_id %win_id% 
      GuiControl,, Edit17, %ctrl_id% 
      ControlGetPos, x, y, w, h,, ahk_id %ctrl_id% 
      GuiControl,, Edit18, %x% 
      GuiControl,, Edit19, %y% 
      GuiControl,, Edit20, %w% 
      GuiControl,, Edit21, %h% 
      GuiControl,, Edit27, % ( x2 - x ) 
      GuiControl,, Edit28, % ( y2 - y ) 
      ControlGet, x, Style,,, ahk_id %ctrl_id% 
      ControlGet, y, ExStyle,,, ahk_id %ctrl_id% 
      x := x . "`n" . WinGetStyle( x, "WS_" ) 
      if y 
         x := x . "`n`nExStyle: " . y . "`n" . WinGetStyle( y, "WS_EX_" ) 
      ControlGetText, y,, ahk_id %ctrl_id% 
      if y 
         x := x . "`n`nText:`n" . y 
      GuiControl,, Edit22, Style: %x% 
   } 
   else { 
      GuiControl,, Edit16 
      GuiControl,, Edit17 
      GuiControl,, Edit18 
      GuiControl,, Edit19 
      GuiControl,, Edit20 
      GuiControl,, Edit21 
      GuiControl,, Edit22 
      GuiControl,, Edit27 
      GuiControl,, Edit28 
   } 
    

} 



WinGetStyle( style, prefix ) 
{ 
WS_ = 
( 
WS_OVERLAPPED=0x00000000 
WS_POPUP=0x80000000 
WS_CHILD=0x40000000 
WS_MINIMIZE=0x20000000 
WS_VISIBLE=0x10000000 
WS_DISABLED=0x08000000 
WS_CLIPSIBLINGS=0x04000000 
WS_CLIPCHILDREN=0x02000000 
WS_MAXIMIZE=0x01000000 
WS_CAPTION=0x00C00000 
WS_BORDER=0x00800000 
WS_DLGFRAME=0x00400000 
WS_VSCROLL=0x00200000 
WS_HSCROLL=0x00100000 
WS_SYSMENU=0x00080000 
WS_THICKFRAME=0x00040000 
WS_GROUP=0x00020000 
WS_TABSTOP=0x00010000 
WS_MINIMIZEBOX=0x00020000 
WS_MAXIMIZEBOX=0x00010000 
WS_TILED=0x00000000 
WS_ICONIC=0x20000000 
WS_SIZEBOX=0x00040000 
WS_CHILDWINDOW=0x40000000 
) 
WS_EX_ = 
( 
WS_EX_DLGMODALFRAME=0x00000001 
WS_EX_NOPARENTNOTIFY=0x00000004 
WS_EX_TOPMOST=0x00000008 
WS_EX_ACCEPTFILES=0x00000010 
WS_EX_TRANSPARENT=0x00000020 
WS_EX_MDICHILD=0x00000040 
WS_EX_TOOLWINDOW=0x00000080 
WS_EX_WINDOWEDGE=0x00000100 
WS_EX_CLIENTEDGE=0x00000200 
WS_EX_CONTEXTHELP=0x00000400 
WS_EX_RIGHT=0x00001000 
WS_EX_LEFT=0x00000000 
WS_EX_RTLREADING=0x00002000 
WS_EX_LTRREADING=0x00000000 
WS_EX_LEFTSCROLLBAR=0x00004000 
WS_EX_RIGHTSCROLLBAR=0x00000000 
WS_EX_CONTROLPARENT=0x00010000 
WS_EX_STATICEDGE=0x00020000 
WS_EX_APPWINDOW=0x00040000 
WS_EX_LAYERED=0x00080000 
WS_EX_NOINHERITLAYOUT=0x00100000 
WS_EX_LAYOUTRTL=0x00400000 
WS_EX_NOACTIVATE=0x08000000 
) 


   st := "" 
   Loop, Parse, %prefix%, `n 
   { 
      RegExMatch( A_LoopField, prefix . "[a-zA-Z0-9]+", s ) 
      n := 23 - StrLen(s) 
      Loop, %n% 
         s := s . A_Space 
      RegExMatch( A_LoopField, "0x.*$", n ) 
      if ( style & n ) { 
         st := st . "`n" . s . A_Tab . "( " . n . " )" 
      } 
   } 
   st := SubStr( st, 2 ) 
   return st 

} 



~Control:: 

   if WinGetID and not WinGetFrozen { 
      SetTimer, WinGetUpdate, Off 
      WinSetTitle, ahk_id %WinGetID%,, %A_Space%WinGet ( frozen ) 
   } 

Return 



~Control Up:: 

   if WinGetID and not WinGetFrozen { 
      SetTimer, WinGetUpdate, %WinGetUpdate% 
      WinSetTitle, ahk_id %WinGetID%,, %A_Space%WinGet ( Press CTRL to freeze ) 
   } 

Return
