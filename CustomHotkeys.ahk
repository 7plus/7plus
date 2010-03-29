;Some general hotkeys:
#if HKImproveConsole
#c::
dir:=GetCurrentFolder()
outputdebug dir %dir%
if(dir)
	Run "cmd.exe", %dir%
else
	Run "cmd.exe", C:\
return
#if
/*
#o::
	Run "%A_programfiles%\Opera\Opera.exe"
	return
#a::
	Run "%A_programfiles%\AdiIrc\AdiIrc.exe"
	return
#s::
	Run "%A_programfiles%\Speq\Speq Mathematics.exe"
	return
#t::
	DetectHiddenWindows, On
	x:=WinExist("ahk_class icoTrilly")
	if(x)
	{	
		Send #+!^ü
	}
	else
	{
		Run "%A_programfiles%\Trillian\Trillian.exe"
	}
	return

;Escape to hide trillian list
#if WinActive("ahk_class icoTrilly") && !ControlGet("Visible","","Trillian Window2","A") 
Esc::#^!+ö
#if

;Add a second PsPad close hotkey
#IfWinActive, ahk_class TfPSPad.UnicodeClass
^w::
	Send {CTRL Down}{F4}{CTRL Up}
	return
#IfWinActive

;VLC: Alt+Enter=fullscreen
#IfWinActive, ahk_class QWidget
!Enter::
	ControlClick , QWidget11, ahk_class QWidget,,,, NA 
	
	return
#IfWinActive
#IfWinActive, ahk_class VLC DirectX
!Enter::
	ControlClick , QWidget2, ahk_class QTool
	return
#IfWinActive
*/
;windows picture viewer image rotation r and l hotkeys
PictureViewerActive()
{
	if !WinActive("ahk_class Photo_Lightweight_Viewer")
		return false
	ControlGetFocus, x,A
	outputdebug %x%
	return x="Photos_PhotoCanvas1"||x="Photos_NavigationPane1"||x="Photos_CommandBar1"
}	
#if HKPhotoViewer && WinActive("ahk_class Photo_Lightweight_Viewer")
r::^.
l::^,
#if
