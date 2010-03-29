;Call this to show settings dialog
SettingsHandler:
ShowSettings()
return

ShowSettings()
{
	global
	local x,y,ybase,checkboxstep,textboxstep,TextBoxCheckBoxOffset,TextBoxTextOffset,TextBoxButtonOffset,xCheckBoxTextOffset,yCheckBoxTextOffset,hText,yIt,xBase,wTBShort,wTBMedium,wTBLarge,wButton,hCheckbox,xHelp
	if(!SettingsActive)
	{
		;---------------------------------------------------------------------------------------------------------------
		; Create GUI
		;---------------------------------------------------------------------------------------------------------------
		Gui, 2:Default
		ybase:=40
		checkboxstep:=20
		textboxstep:=30
		TextBoxCheckBoxOffset:=4
		TextBoxTextOffset:=4
		TextBoxButtonOffset:=-1
		xCheckBoxTextOffset:=17
		yCheckBoxTextOffset:=-6
		hText:=16
		yIt:=yBase
		y:=yIt
		xBase:=22
		xHelp:=xBase
		x1:=xHelp+10
		x2:=302
		wTBShort:=50
		wTBMedium:=170
		wTBLarge:=210
		wButton:=30
		hCheckbox:=16
		
		Gui, Add, Button, x444 y370 w80 h23 gCancel, Cancel
		Gui, Add, Button, x364 y370 w70 h23 gOK, OK
		Gui, Add, Text, x%xBase% y374, Click on ? to see video tutorial help!
		Gui, Add, Tab, x12 y10 w512 h350 , Explorer 1|Explorer 2|Windows|FTP|Misc|About ;Explorer 1|Explorer 2|Windows|FTP|Calendar|Misc|About
		;---------------------------------------------------------------------------------------------------------------
		Gui, Add, Text, x%x1% y%y%, Text and images from clipboard can be pasted as file in explorer with these settings
		yIt+=checkboxstep
		
		y:=yIt+TextBoxCheckBoxOffset
		Gui, Add, CheckBox, x%x1% y%y% gtxt, Paste text as file
		Gui, Add, Text, y%y% x%xhelp% cBlue ghPasteAsFile vURL_PasteAsFile, ?
		
		Gui, Add, Text, x252 y%y%, Filename:
		y:=yIt
		Gui, Add, Edit, x%x2% y%y% w%wTBMedium% vTxtName R1,%TxtName%
		yIt+=textboxstep
		
		y:=yIt+TextBoxCheckBoxOffset
		Gui, Add, CheckBox, x%x1% y%y% gimg, Paste image as file
		Gui, Add, Text, y%y% x%xhelp% cBlue ghPasteAsFile vURL_PasteAsFile1, ?
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x252 y%y%, Filename:
		y:=yIt
		Gui, Add, Edit, x302 y%y% w%wTBMedium% vImgName R1, %ImgName%	
		yIt+=textboxstep	
		
		y:=yIt+TextBoxCheckBoxOffset
		Gui, Add, CheckBox, x%x1% y%y% gEditor, F3: Open selected files in text/image editor
		Gui, Add, Text, y%y% x%xhelp% cBlue ghOpenEditor vURL_OpenEditor, ?
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x267 y%y%, Editor:
		y:=yIt
		Gui, Add, Edit, x%x2% y%y% w%wTBMedium% vTextEditor R1,%TextEditor% 
		x:=x2+wTBMedium+10
		y:=yIt+TextBoxButtonOffset
		Gui, Add, Button, x%x% y%y% w%wButton% gTextBrowse, ...
		yIt+=textboxstep
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x235 y%y%, Image editor:
		y:=yIt
		Gui, Add, Edit, x%x2% y%y% w%wTBMedium% vImageEditor R1,%ImageEditor% 
		x:=x2+wTBMedium+10
		y:=yIt+TextBoxButtonOffset
		Gui, Add, Button, x%x% y%y% w%wButton% gImageBrowse, ...
		yIt+=textboxstep
		
		x2:=x2-60
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghCreateNew vURL_CreateNew, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKCreateNewFile, F7: Create new file
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghCreateNew vURL_CreateNew1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKCreateNewFolder, F8: Create new folder
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghCopyFilenames vURL_CopyFilenames, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKCopyFilenames, ALT + C: Copy Filenames	
		;Gui, Add, Checkbox, x%x2% y%yIt% vHKImprovedWinE, WIN+E:
		;x:=x2+60
		;Gui, Add, Text, x%x% y%yIt% R2, Starts a second explorer window`, and aligns `nthem to the left and right of the screen
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghCopyFilenames vURL_CopyFilenames1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKCopyPaths, CTRL + ALT + C: Copy paths + filenames
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghNavigation vURL_Navigation, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKProperBackspace, Backspace (Vista/7): Go upwards
		if(!Vista7)
			GuiControl, disable, HKProperBackspace
		x:=x2+80
		yIt+=checkboxstep	
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghNavigation vURL_Navigation1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKMouseGestureBack, Hold down right mouse button and click left: Go back
		yIt+=checkboxstep	
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghNavigation vURL_Navigation2, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKDoubleClickUpwards, Double click on empty space in filelist: Go upwards
		yIt+=checkboxstep	
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghAppendClipboard vURL_AppendClipboard, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKAppendClipboard, Shift + X / Shift + C: Append files to clipboard instead of replacing (cut/copy)
		yIt+=checkboxstep	
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghScrollUnderMouse vURL_ScrollUnderMouse, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vScrollUnderMouse, Scroll explorer scrollbars with mouse over them
		;---------------------------------------------------------------------------------------------------------------
		Gui, Tab, Explorer 2
		yIt:=yBase
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghSelectFirstFile vURL_SelectFirstFile, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKSelectFirstFile, Explorer automatically selects the first file when you enter a directory
		yIt+=checkboxstep	
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghSelectFirstFile vURL_SelectFirstFile1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKImproveEnter, Files which are only focussed but not selected can be executed by pressing enter
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghShowSpaceAndSize vURL_ShowSpaceAndSize, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKShowSpaceAndSize, Show free space and size of selected files in status bar like in XP (Vista/7 only)		
		if(!Vista7)
			GuiControl, disable, HKShowSpaceAndSize
		yIt+=checkboxstep	
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghApplyOperation vURL_ApplyOperation, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKAutoCheck, Automatically check "Apply to all further operations" checkboxes in file operations (Vista/7 only)
		if(!Vista7)
			GuiControl, disable, HKAutoCheck
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghFastFolders1 vURL_FastFolders1, ?		
		Gui, Add, Checkbox, x%x1% y%yIt% gFastFolders,Use Fast Folders
		yIt+=checkboxstep	
		x:=x1+xCheckboxTextOffset
		xhelp+=xCheckboxTextOffset
		y:=yIt+yCheckboxTextOffset
		Gui, Add, Text, x%x% y%y% R2, In all kinds of file views you can store a path in one of ten slots by pressing CTRL`nand a numpad number key, and restore it by pressing the numpad number key again
		yIt+=checkboxstep*1.5
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghFastFolders1 vURL_FastFolders11, ?
		Gui, Add, Checkbox, x%x% y%yIt% vHKFolderBand, Integrate Fast Folders into explorer folder band bar (Vista/7 only)		
		if(!Vista7)
			GuiControl, disable, HKFolderBand
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghFastFolders2 vURL_FastFolders2, ?
		Gui, Add, Checkbox, x%x% y%yIt% vHKCleanFolderBand, Remove windows folder band buttons (Vista/7 only)
		yIt+=checkboxstep
		x+=xCheckboxTextOffset
		y:=yIt+yCheckboxTextOffset
		text:="If you use the folder band as a favorites bar like in browsers, it is recommended that you get rid`nof the buttons predefined by windows whereever possible (such as Slideshow, Add to Library,...)"
		Gui, Add, Text, x%x% y%y% R2, %text%
		if(!Vista7)
		{
			GuiControl, disable, HKCleanFolderBand
			GuiControl, disable, %text%
		}
		x-=xCheckboxTextOffset
		yIt+=checkboxstep*1.5
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghFastFolders2 vURL_FastFolders21, ?
		Gui, Add, Checkbox, x%x% y%yIt% vHKPlacesBar, Integrate Fast Folders into open/save dialog places bar (First 5 Entries)
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghFastFolders2 vURL_FastFolders22, ?
		Gui, Add, Checkbox, x%x% y%yIt% vHKFFMenu, Middle mouse button: Show Fast Folders move/copy menu
		yIt+=checkboxstep
		y:=yIt+yCheckboxTextOffset
		x+=xCheckboxTextOffset
		Gui, Add, Text, x%x% y%y% R3, When clicking with middle mouse button in a supported file view, a menu`nwith the stored Fast Folders will show up. Clicking an entry will move all`nselected files into that directory, holding CTRL while clicking will copy the files.
		
		;---------------------------------------------------------------------------------------------------------------
		Gui, Tab, Windows	
		yIt:=yBase
		y:=yIt+TextBoxCheckBoxOffset
		xhelp:=xBase
		Gui, Add, Text, y%y% x%xhelp% cBlue ghTaskbar vURL_Taskbar, ?
		Gui, Add, Checkbox, x%x1% y%y% gTaskbarLaunch, Double click on empty taskbar: Run
		x:=232
		Gui, Add, Edit, 		x%x% y%yIt% w%wTBLarge% R1 vTaskbarLaunchPath, %TaskbarLaunchPath%
		y:=yIt+TextBoxButtonOffset
		x:=x+wTBLarge+10
		Gui, Add, Button, x%x% y%y% w%wButton% gTaskbarLaunchBrowse, ...
		yIt+=textboxstep
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghTaskbar vURL_Taskbar1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKMiddleClose, Middle click on taskbuttons: close task
		yIt+=checkboxstep	
		
		x:=x1+xCheckboxTextOffset
		y:=yIt+yCheckBoxTextOffset
		Gui, Add, Text, x%x% y%y%, Middle click on empty taskbar: Taskbar properties
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghTaskbar vURL_Taskbar2, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKActivateBehavior, Left click on task group button (7 only): cycle through windows		
		if(A_OsVersion!="WIN_7")
			GuiControl, disable, HKActivateBehavior
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghTaskbar vURL_Taskbar3, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKTitleClose, Middle click on title bar: Close program
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghWindow vURL_Window, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKToggleAlwaysOnTop, Right click on title bar: Toggle "Always on top"
		yIt+=checkboxstep			
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghWindow vURL_Window1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKKillWindows, Alt+F5/Right click on close button: Force-close active window (kill process)
		yIt+=checkboxstep	
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghWindow vURL_Window2, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKToggleWallpaper, Middle mouse click on desktop: Toggle wallpaper (7 only)
		if(A_OsVersion!="WIN_7")
			GuiControl, disable, HKToggleWallpaper
		yIt+=checkboxstep	
		
		y:=yIt+TextBoxCheckBoxOffset
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghWindow vURL_Window3, ?
		Gui, Add, Checkbox, x%x1% y%y% gFlip3D, Mouse in upper left corner: Toggle Aero Flip 3D (Vista/7 only)
		x:=362
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x% y%y%, Seconds in corner:
		x:=248+wTBLarge
		Gui, Add, Edit, 		x%x% y%yIt% w%wTBShort% R1 vAeroFlipTime, %AeroFlipTime%		
		if(!Vista7)
		{
			GuiControl, disable, AeroFlipTime
			GuiControl, disable, Mouse in upper left corner: Toggle Aero Flip 3D (Vista/7 only)
			GuiControl, disable, Seconds in corner:
		}
		y:=yIt+TextBoxButtonOffset
		yIt+=textboxstep
		
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghSlideWindow vURL_SlideWindow, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKSlideWindows, WIN + SHIFT + Arrow keys: Slide Window function
		yIt+=checkboxstep	
		y:=yIt+yCheckboxTextOffset
		x:=x1+xCheckboxTextOffset
		Gui, Add, Text, x%x% y%y% R4, A Slide Window is moved off screen, it will not be shown until you activate it through task bar /`nALT + TAB or move the mouse to the border where it was hidden. It will then slide into the screen,`nand slide out again when the mouse leaves the window or when another window gets activated.`nDeactivate this mode by moving the window or pressing WIN+SHIFT+Arrow key in another direction.
		yIt+=checkboxstep*2.5
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghCapslock vURL_Capslock, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKFlashWindow, Capslock: Activate flashing window (blinking on taskbar, e.g. instant messengers, ...)
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghCapslock vURL_Capslock1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKToggleWindows, Capslock: Switch between current and previous window
		yIt+=checkboxstep	
		;---------------------------------------------------------------------------------------------------------------
		Gui, Tab, FTP
		yIt:=yBase
		xhelp:=xBase
		Gui, Add, Text, x%x1% y%yIt% R4, You can upload selected files from explorer to an FTP server by`npressing CTRL + U. You can also take screenshots (ALT + Insert = fullscreen`,`nWIN + Insert = active window) and directly upload them. WIN + Delete will upload`nimage or text data from clipboard. URL(s) will be copied to the clipboard.
		yIt:=100
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghFTP vURL_FTP, ?
		Gui, Add, CheckBox, x%x1% y%yIt% gFTP, Use FTP
		yIt+=checkboxstep	
		x1:=xBase+xCheckBoxTextOffset
		x2:=122
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Hostname
		Gui, Add, Edit, x%x2% y%yIt% w%wTBMedium% R1 vFTP_Host, %FTP_Host%
		yIt+=TextBoxStep	
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Port
		Gui, Add, Edit, x%x2% y%yIt% w%wTBShort% R1 vFTP_PORT Number, %FTP_PORT%
		yIt+=TextBoxStep
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Username
		Gui, Add, Edit, x%x2% y%yIt% w%wTBMedium% R1 vFTP_Username ,%FTP_Username% 
		yIt+=TextBoxStep	
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Password
		Gui, Add, Edit, x%x2% y%yIt% w%wTBMedium% R1 vFTP_Password Password, %FTP_Password%
		yIt+=TextBoxStep	
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Remote Folder
		Gui, Add, Edit, x%x2% y%yIt% w%wTBMedium% R1 vFTP_Path, %FTP_Path%
		yIt+=TextBoxStep
		
		Gui, Add, Text, x%x1% y%yIt%, URL under which the files can be accessed through HTTP
		yIt+=checkboxstep
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, URL
		Gui, Add, Edit, x%x2% y%yIt% w%wTBMedium% R1 vFTP_URL, %FTP_URL%
		
		/*
		;---------------------------------------------------------------------------------------------------------------
		Gui, Tab, Calendar
		yIt:=yBase
		Gui, Add, Text, x%xBase% y%yIt% R5, It is possible to replace the lame windows calender that pops up when`nyou click on the clock with a custom one`, such as Google Calendar or`nSunbird. The program will run hidden in the background while it isn't used`,`nso it can remind you of upcoming events by showing a popup dialog.
		yIt:=100
		Gui, Add, CheckBox, x%xBase% y%yIt% gReplaceCalendar, Use Calendar
		yIt+=checkboxstep
		
		x1:=xBase+xCheckBoxTextOffset
		x2:=202
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Calendar program path
		outputdebug calendar command:  %CalendarCommand%
		Gui, Add, Edit, x%x2% y%yIt% w%wTBMedium% R1 vCalendarCommand, %CalendarCommand%
		y:=yIt+TextBoxButtonOffset
		x:=x2+wTBMedium+10
		Gui, Add, Button, x%x% y%y% w%wButton% gCalenderBrowse, ...
		yIt+=TextBoxStep
			
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Calendar window class
		Gui, Add, Edit, x%x2% y%yIt% w%wTBLarge% R1 vCalendarClass, %CalendarClass%
		yIt+=TextBoxStep
		
		y:=yIt+TextBoxTextOffset
		Gui, Add, Text, x%x1% y%y%, Presets for
		x:=x1+64
		Gui, Add, Button, x%x% y%yIt% w140 gChromeGoogle, Google Chrome + Calendar
		x+=140+10
		Gui, Add, Button, x%x% y%yIt% w75 gSunbird, Sunbird
		x+=75+10
		Gui, Add, Button, x%x% y%yIt% w75 gOutlook, Outlook	
		yIt+=TextBoxStep
		
		Gui, Add, Text, x%xbase% y%yIt% R2, For other calendar programs, please use window spy utility which comes with `nAutohotkey to figure out window classes.
		*/
		;---------------------------------------------------------------------------------------------------------------
		Gui, Tab, Misc
		x1:=xBase+10
		xhelp:=xBase
		yIt:=yBase
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghImproveConsole vURL_ImproveConsole, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKImproveConsole, Open current folder in CMD by pressing WIN + C and enable CTRL + V and Alt + F4 in CMD
		yIt+=checkboxstep
		;Gui, Add, Text, y%yIt% x%xhelp% cBlue ghImproveConsole vURL_ImproveConsole1, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vHKPhotoViewer, Windows picture viewer: Rotate image with R and L
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghJoyControl vURL_JoyControl, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vJoyControl, Use joystick/gamepad as remote control when not in fullscreen (optimized for XBOX360 gamepad)
		yIt+=checkboxstep
		Gui, Add, Text, y%yIt% x%xhelp% cBlue ghClipboardManager vURL_ClipboardManager, ?
		Gui, Add, Checkbox, x%x1% y%yIt% vClipboardManager, WIN + V: Clipboard manager (stores last 10 entries)
		
		yIt+=2*checkboxstep
		Gui, Add, Checkbox, x%x1% y%yIt% vAutorun, Autorun 7plus on windows startup
		;---------------------------------------------------------------------------------------------------------------
		Gui, Tab, About
		yIt:=YBase
		if(A_IsCompiled)			
			Gui, Add, Picture, w128 h128 y%yIt% x350 Icon3 vLogo, %A_ScriptFullPath%
		else
			Gui, Add, Picture, w128 h128 y%yIt% x350 vLogo, %A_ScriptDir%\128.png
		
		gui, font, s20
		Gui, Add, Text, y%yIt% x%x1%, 7plus Version 1.0
		gui, font
		yIt+=hText*3
		x2:=x1+100
		Gui, Add, Text, y%yIt% x%x1% , Project page:
		Gui, Add, Text, y%yIt% x%x2% cBlue gProjectpage vURL_Projectpage, http://code.google.com/p/7plus/
		yIt+=hText
		Gui, Add, Text, y%yIt% x%x1% , Report bugs:
		Gui, Add, Text, y%yIt% x%x2% cBlue gBugtracker vURL_Bugtracker, http://code.google.com/p/7plus/issues/list
		yIt+=hText
		Gui, Add, Text, y%yIt% x%x1% , Author:
		Gui, Add, Text, y%yIt% x%x2% , Christian Sander
		yIt+=hText
		Gui, Add, Text, y%yIt% x%x1% , E-Mail:
		Gui, Add, Text, y%yIt% x%x2% cBlue gMail vURL_Mail, fragman@gmail.com
		yIt+=hText*2
		Gui, Add, Text, y%yIt% x%x1%, Proudly written in Autohotkey
		yIt+=hText
		Gui, Add, Text, y%yIt% x%x1% cBlue gAhk vURL_AHK, www.autohotkey.com		
		yIt+=hText*2
		Gui, Add, Text, y%yIt% x%x1% , Licensed under  
		Gui, Add, Text, y%yIt% x%x2% cBlue gGPL vURL_GPL, GNU General Public License v3
		yIt+=hText*2
		Gui, Add, Text, y%yIt% x%x1% , Credits for lots of code samples and help go out to:`nSean, HotKeyIt, majkinetor, Titan, Lexikos, TheGood, PhiLho, Temp01`nand the other guys and gals on #ahk and the forums.
		
		Gui, Show, x338 y159 h404 w540, 7plus Settings
		Winwaitactive 7plus Settings
		SettingsActive:=True
		
		;---------------------------------------------------------------------------------------------------------------
		; Setup Control Status
		;---------------------------------------------------------------------------------------------------------------
		
		;Setup paste text as file
		if(txtName!="")
			GuiControl,,Paste text as file,1
		else
			GuiControl, disable ,TxtName
		;Setup paste image as file	
		if(imgName!="")
			GuiControl,,Paste image as file,1
		else
			GuiControl, disable,ImgName
		;Setup text editor
		if(TextEditor!=""||ImageEditor!="")
			GuiControl,,F3: Open selected files in text/image editor,1
		else
		{
			GuiControl, disable,TextEditor
			GuiControl, disable,Button6
			GuiControl, disable,ImageEditor
			GuiControl, disable,Button7
		}
		;Setup taskbar launch
		if(TaskbarLaunchPath!="")
			GuiControl,,Double click on empty taskbar: Run,1
		else
		{
			GuiControl, disable,TaskbarLaunchPath
			GuiControl, disable,Button25
		}
		
		
		if HKCreateNewFile
			GuiControl,,HKCreateNewFile,1
		if HKCreateNewFolder
			GuiControl,,HKCreateNewFolder,1
		if HKCopyFilenames
			GuiControl,,HKCopyFilenames,1
		if HKCopyPaths
			GuiControl,,HKCopyPaths,1
		if HKDoubleClickUpwards
			GuiControl,,HKDoubleClickUpwards,1
		if HKAppendClipboard
			GuiControl,,HKAppendClipboard,1
		if HKFastFolders
			GuiControl,,HKFastFolders,1
		if HKProperBackspace
			GuiControl,,HKProperBackspace,1
		;if HKImprovedWinE
		;	GuiControl,,HKImprovedWinE,1
		if HKSelectFirstFile
			GuiControl,,HKSelectFirstFile,1
		if HKImproveEnter
			GuiControl,,HKImproveEnter,1
		if HKImproveConsole
			GuiControl,,HKImproveConsole,1
		if HKTaskbarLaunch
			GuiControl,,HKTaskbarLaunch,1
		if HKMiddleClose
			GuiControl,,HKMiddleClose,1
		if HKTitleClose
			GuiControl,,HKTitleClose,1
		if HKToggleAlwaysOnTop
			GuiControl,,HKToggleAlwaysOnTop,1
		if HKActivateBehavior
			GuiControl,,HKActivateBehavior,1
		if HKShowSpaceAndSize
			GuiControl,,HKShowSpaceAndSize,1
		if HKMouseGestureBack
			GuiControl,,HKMouseGestureBack,1
		if HKKillWindows
			GuiControl,,HKKillWindows,1
		if HKToggleWallpaper
			GuiControl,,HKToggleWallpaper,1
		if HKPhotoViewer
			GuiControl,,HKPhotoViewer,1
		if HKAutoCheck
			GuiControl,,HKAutoCheck,1
		if HKSlideWindows
			GuiControl,,HKSlideWindows,1	
		if HKFlashWindow
			GuiControl,,HKFlashWindow,1
		if HKToggleWindows
			GuiControl,,HKToggleWindows,1
		if HKFolderBand
			GuiControl,,HKFolderBand,1
		if HKCleanFolderBand
		  GuiControl,,HKCleanFolderBand,1		
		if HKPlacesBar
			GuiControl,,HKPlacesBar,1
		if HKFFMenu
		  GuiControl,,HKFFMenu,1
		if HKFastFolders
		  GuiControl,,Use Fast Folders,1
		else
		{
			GuiControl, disable, HKFolderBand
			GuiControl, disable, HKCleanFolderBand
			GuiControl, disable, HKPlacesBar
			GuiControl, disable, HKFFMenu
		}
		if JoyControl
		  GuiControl,,JoyControl,1
		if ScrollUnderMouse
			GuiControl,,ScrollUnderMouse,1
		if ClipboardManager
			GuiControl,,ClipboardManager,1
		;Setup Aero Flip 3D
		if(AeroFlipTime>=0)
		{
			GuiControl,,Mouse in upper left corner: Toggle Aero Flip 3D,1
		}
		else
		{
			GuiControl,,AeroFlipTime,%A_SPACE%
			GuiControl, disable, AeroFlipTime
		}
		
		;Setup FTP
		if(FTP_Enabled)
			GuiControl,,Use FTP,1
		else
		{
			GuiControl, disable, FTP_Host
			GuiControl, disable, FTP_Username
			GuiControl, disable, FTP_Password
			GuiControl, disable, FTP_Port
			GuiControl, disable, FTP_Path
			GuiControl, disable, FTP_URL
		}
		/*
		;Setup Calendar
		if(ReplaceCalendar)
			GuiControl,,Use Calendar,1
		else
		{
			GuiControl, disable, CalendarCommand
			GuiControl, disable, CalendarClass
			GuiControl, disable, Button39
		}
		*/
		
		;Figure out if Autorun is enabled
		RegRead, Autorun, HKCU, Software\Microsoft\Windows\CurrentVersion\Run , 7plus
		if(Autorun="""" A_ScriptFullPath """")
			GuiControl,, Autorun,1
			
		;Hand cursor over controls where the assigned variable starts with URL_
		; Retrieve scripts PID 
	  Process, Exist 
	  pid_this := ErrorLevel 
	  
	  ; Retrieve unique ID number (HWND/handle) 
	  WinGet, hw_gui, ID, ahk_class AutoHotkeyGUI ahk_pid %pid_this% 
	  
	  ; Call "HandleMessage" when script receives WM_SETCURSOR message 
	  WM_SETCURSOR = 0x20 
	  OnMessage(WM_SETCURSOR, "HandleMessage") 
	  
	  ; Call "HandleMessage" when script receives WM_MOUSEMOVE message 
	  WM_MOUSEMOVE = 0x200 
	  OnMessage(WM_MOUSEMOVE, "HandleMessage")
	}
	Return
}
GuiClose: 
ExitApp 
;---------------------------------------------------------------------------------------------------------------
; Control Handlers
;---------------------------------------------------------------------------------------------------------------

txt:
GuiControlGet, txtenabled , , Paste text as file
if txtenabled
	GuiControl, enable,TxtName
else
	GuiControl, disable,TxtName
Return

img:
GuiControlGet, imgenabled , , Paste image as file
if imgenabled
	GuiControl, enable,ImgName
else
	GuiControl, disable,ImgName
Return

Editor:
GuiControlGet, editorenabled , , F3: Open selected files in text/image editor
if editorenabled
{
	GuiControl, enable,TextEditor
	GuiControl, enable,ImageEditor
	GuiControl, enable,Button6
	GuiControl, enable,Button7
}
else
{
	GuiControl, disable,TextEditor
	GuiControl, disable,ImageEditor
	GuiControl, disable,Button6
	GuiControl, disable,Button7
}
Return

TaskbarLaunch:
GuiControlGet, taskbarlaunchenabled , , Double click on empty taskbar: Run
if taskbarlaunchenabled
{
	GuiControl, enable,TaskbarLaunchPath
	GuiControl, enable,Button25
}
else
{
	GuiControl, disable,TaskbarLaunchPath
	GuiControl, disable,Button25
}
Return

TextBrowse:
FileSelectFile, editorpath , 3, , Select text editor executable, *.exe
if !ErrorLevel
	GuiControl, ,TextEditor,%editorpath%
Return
ImageBrowse:
FileSelectFile, imagepath , 3, , Select image editor executable, *.exe
if !ErrorLevel
	GuiControl, ,ImageEditor,%imagepath%
Return

FastFolders:
GuiControlGet, ffenabled , , Use Fast Folders
if(ffenabled)
{
		GuiControl, enable, HKFolderBand
		GuiControl, enable, HKCleanFolderBand
		GuiControl, enable, HKPlacesBar
		GuiControl, enable, HKFFMenu
}
else
{
		GuiControl, disable, HKFolderBand
		GuiControl, disable, HKCleanFolderBand
		GuiControl, disable, HKPlacesBar
		GuiControl, disable, HKFFMenu
}
return

TaskbarLaunchBrowse:
FileSelectFile, TaskbarPath , 3, , Select taskbar executable, *.exe
if !ErrorLevel
	GuiControl, ,TaskbarLaunchPath,%TaskbarPath%
Return

Flip3D:
GuiControlGet, flip , ,Mouse in upper left corner: Toggle Aero Flip 3D
if(flip)
{
	GuiControl, enable, AeroFlipTime
	GuiControlGet, flip , ,AeroFlipTime
	if(flip<0||flip="")
		flip=0
	GuiControl,,AeroFlipTime,%flip%
}
else
{
	GuiControl, disable, AeroFlipTime
}
return
FTP:
GuiControlGet, ftp , ,Use FTP
if(ftp)
{
	GuiControl, enable, FTP_Host
	GuiControl, enable, FTP_Username
	GuiControl, enable, FTP_Password
	GuiControl, enable, FTP_Port
	GuiControl, enable, FTP_Path
	GuiControl, enable, FTP_URL
}
else
{
	GuiControl, disable, FTP_Host
	GuiControl, disable, FTP_Username
	GuiControl, disable, FTP_Password
	GuiControl, disable, FTP_Port
	GuiControl, disable, FTP_Path
	GuiControl, disable, FTP_URL
}
Return
/*
ReplaceCalendar:
GuiControlGet, Calendar , ,Use Calendar
if(Calendar)
{
	GuiControl, enable, CalendarClass
	GuiControl, enable, CalendarCommand
	GuiControl, enable, Button39
}
else
{
	GuiControl, disable, CalendarClass
	GuiControl, disable, CalendarCommand
	GuiControl, disable, Button39
}
Return

CalenderBrowse:
FileSelectFile, calendarpath , 3, , Select Calendar executable, *.exe
if !ErrorLevel
	GuiControl, ,CalendarCommand,%calendarpath%
Return

ChromeGoogle:
RegRead, path, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe
if(!path)
	FileSelectFile, path , 3, , Select Google Chrome executable, *.exe
if(path)
{
	GuiControl,,Use Calendar,1
	GuiControl, enable, CalendarClass
	GuiControl, enable, CalendarCommand
	GuiControl, enable, Button39
	path:=Quote(path)
	GuiControl,, CalendarCommand, %path% --app="http://www.google.com/calendar"
	GuiControl,, CalendarClass, Chrome_WindowImpl_0
	msgbox If you use another language in Google Calendar, you will have to adjust the calendar window title to match your language.
} 
Return

Sunbird:
Return

Outlook:
RegRead, path, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE, path
if(!path)
	FileSelectFile, path , 3, , Select Outlook executable, *.exe
if(path)
{
	GuiControl,,Use Calendar,1
	GuiControl, enable, CalendarClass
	GuiControl, enable, CalendarCommand
	GuiControl, enable, Button39
	GuiControl,, CalendarCommand, "%path%Outlook.exe"
	GuiControl,, CalendarClass, rctrl_renwnd32
}

Return
*/

;---------------------------------------------------------------------------------------------------------------
; Help Links
;---------------------------------------------------------------------------------------------------------------
hPasteAsFile:
run http://www.youtube.com/watch?v=yOJ8evyuVhY
return
hOpenEditor:
run http://www.youtube.com/watch?v=6bxiyNRh0dk
return
hCreateNew:
run http://www.youtube.com/watch?v=e3op-boVfOk
return
hCopyFilenames:
run http://www.youtube.com/watch?v=CA-W1i1bMmQ
return
hNavigation:
run http://www.youtube.com/watch?v=RZOdgDl2ujU
return
hScrollUnderMouse:
run http://www.youtube.com/watch?v=qJ_u4C3EuhU
return
hAppendClipboard:
run http://www.youtube.com/watch?v=je9zk1zy5Xk
return
hSelectFirstFile:
run http://www.youtube.com/watch?v=Bih7HEtpk0A
return
hShowSpaceAndSize:
run http://www.youtube.com/watch?v=-fnOBf3Ggoc
return
hApplyOperation:
run http://www.youtube.com/watch?v=flBnx2NETlc
return
hFastFolders1:
run http://www.youtube.com/watch?v=dTIGxue6WCY
return
hFastFolders2:
run http://www.youtube.com/watch?v=cC6cnG87j2M
return
hTaskbar:
run http://www.youtube.com/watch?v=v__ZiHFt7NE
return
hWindow:
run http://www.youtube.com/watch?v=JJ-kqjRY910
return
hCapslock:
run http://www.youtube.com/watch?v=im088NYiSvw
return
hSlideWindow:
run http://www.youtube.com/watch?v=e0yLqr8mjsg
return
hFTP:
run http://www.youtube.com/watch?v=d01Mjiny_E8
return
hImproveConsole:
run http://www.youtube.com/watch?v=irMu69t3kEg
return
hJoyControl:
run http://www.youtube.com/watch?v=MZiK7E98hOU
return
hClipboardManager:
run http://www.youtube.com/watch?v=Yq8HXOuSEiU
return
GPL:
run http://www.gnu.org/licenses/gpl.html
return
Mail:
run mailto://fragman@gmail.com
return
Ahk:
run http://www.autohotkey.com
return
Projectpage:
run http://code.google.com/p/7plus/
return
Bugtracker:
run http://code.google.com/p/7plus/issues/list
return
;---------------------------------------------------------------------------------------------------------------
; OK/Cancel/Close
;---------------------------------------------------------------------------------------------------------------
OK:
;First process variables which require comparison with previous values
;Store explorer info settings
x:=HKShowSpaceAndSize

;Store Fast Folders settings and make everything consistent by backing up and restoring reg keys
wasActive:=HKFastFolders
GuiControlGet, active , , Use Fast Folders
HKFastFolders:=active

changed:=false
GuiControlGet, active , , HKFolderBand
if(active && HKFastFolders && (!HKFolderBand || !wasactive))
{
	PrepareFolderBand()
	changed:=true
}
else if(HKFolderBand && ((wasActive && !HKFastFolders) || !active))
{
	RestoreFolderBand()
	changed:=true
}

GuiControlGet, active , , HKCleanFolderBand
if(active && HKFastFolders && (!HKCleanFolderBand || !wasactive))
{
	BackupAndRemoveFolderBandButtons()
	changed:=true
}
else if(HKCleanFolderBand && ((wasActive && !HKFastFolders) || !active))
{
	RestoreFolderBandButtons()
	changed:=true
}
		
GuiControlGet, active , , HKPlacesBar
if(active && HKFastFolders && (!HKPlacesBar || !wasactive))
{
	BackupPlacesBar()
	changed:=true
}
else if(HKPlacesBar && ((wasActive && !HKFastFolders) || !active))
{
	RestorePlacesBar()
	changed:=true
}
if(changed)
	RefreshFastFolders()

Autorun:=0

;Store variables which can be stored directly
Gui Submit

if(JoyControl)
	JoystickStart()
else
	JoystickStop()
	
;Store paste text as file filename
GuiControlGet, txtenabled , , Paste text as file
GuiControlGet, pastename , , TxtName
if txtenabled
{
	TxtName:=pastename
	temp_txt:=A_Temp . "\" . TxtName
}
else
{
	TxtName:=""
	temp_txt:=""
}
outputdebug txtenabled:=%txtenabled% pastename=%pastename%
;Store paste image as file filename
GuiControlGet, imgenabled , , Paste image as file
GuiControlGet, pastename , , ImgName
if imgenabled
{
	ImgName:=pastename
	temp_img:=A_Temp . "\" . ImgName
}
else
{
	ImgName:=""
	temp_img:=""
}

;Store editor filename
GuiControlGet, editorenabled , , F3: Open selected files in text/image editor
GuiControlGet, editorpath , , TextEditor
if editorenabled
{
	TextEditor:=editorpath
}
else
{
	TextEditor:=""
}

;Store image editor filename
GuiControlGet, imageeditorpath , , ImageEditor
if editorenabled
{
	ImageEditor:=imageeditorpath
}
else
{
	ImageEditor:=""
}

		

;Store taskbar launch filename
GuiControlGet, taskbarlaunchenabled , , Double click on empty taskbar: Run
GuiControlGet, taskbarPath , , TaskbarLaunchPath
if taskbarlaunchenabled
{
	TaskbarLaunchPath:=taskbarPath
}
else
{
	TaskbarLaunchPath:=""
}

;Store Aero Flip time
GuiControlGet, flip,,Mouse in upper left corner: Toggle Aero Flip 3D
if(flip&&Vista7)
	SetTimer, hovercheck, 10
else
{
	AeroFlipTime:=-1
	SetTimer, hovercheck, Off
}
;UnSlide hidden windows
if(!HKSlideWindows)
	SlideWindows_Exit()
;Store FTP Settings
GuiControlGet, FTP_Enabled, ,Use FTP
ValidateFTPVars()
/*
;Store Calendar Settings
x:=ReplaceCalendar
GuiControlGet, ReplaceCalendar, ,Use Calendar
if(ReplaceCalendar && !x)
	RunCalendar()
else if(!ReplaceCalendar && x)
	KillCalendar()
*/

;Store Autorun setting
if(Autorun)
	RegWrite, REG_SZ, HKCU, Software\Microsoft\Windows\CurrentVersion\Run , 7plus, "%A_ScriptFullPath%"
else
	RegDelete, HKCU, Software\Microsoft\Windows\CurrentVersion\Run, 7plus

WriteIni()
SettingsActive:=False
Gui Destroy
Gui 1:Default
Return

2GuiEscape:
Cancel:
2GuiClose:
SettingsActive:=False
Gui Destroy
Gui 1:Default
Return


;Link hand cursor handling
;######## Function ############################################################# 
HandleMessage(p_w, p_l, p_m, p_hw) 
  { 
    global   WM_SETCURSOR, WM_MOUSEMOVE, 
    static   URL_hover, h_cursor_hand, h_old_cursor, CtrlIsURL, LastCtrl 
    
    If (p_m = WM_SETCURSOR) 
      { 
        If URL_hover 
          Return, true 
      } 
    Else If (p_m = WM_MOUSEMOVE) 
      { 
        ; Mouse cursor hovers URL text control 
        StringLeft, CtrlIsURL, A_GuiControl, 3 
        If (CtrlIsURL = "URL") 
          { 
            If URL_hover= 
              { 
                Gui, Font, cBlue underline 
                GuiControl, Font, %A_GuiControl% 
                LastCtrl = %A_GuiControl% 
                
                h_cursor_hand := DllCall("LoadCursor", "uint", 0, "uint", 32649) 
                
                URL_hover := true 
              }                  
              h_old_cursor := DllCall("SetCursor", "uint", h_cursor_hand) 
          } 
        ; Mouse cursor doesn't hover URL text control 
        Else 
          { 
            If URL_hover 
              { 
                Gui, Font, norm cBlue 
                GuiControl, Font, %LastCtrl% 
                
                DllCall("SetCursor", "uint", h_old_cursor) 
                
                URL_hover= 
              } 
          } 
      } 
  } 
;######## End Of Functions #####################################################
