#include %A_ScriptDir%\FastFolders.ahk
;Some stuff here to use those functions separately to add custom buttons, might have to be expanded a bit later on
if(A_OSVersion!="WIN_VISTA" && A_OSVersion!="WIN_7")
{
	MsgBox This program is only used for Windows Vista and Windows 7. 
	return
}
MsgBox, 4,, This program allows you to add buttons to the explorer bar.`nWould you like to add a button(yes) or remove one(no)?
IfMsgBox Yes
{
	path:=COMObjCreate("Shell.Application").BrowseForFolder(0, "Enter Path to add as button", 0).Self.Path
	SplitPath, path , foldername
	if(foldername="")
		foldername:=path
	InputBox, foldername , Enter the title for the button, Enter the title for the button, , , , , , , , %foldername%
	if Errorlevel
		return
	AddButton("",path,,foldername)
}
IfMsgBox No
{
	MsgBox, 4,, Would you like to remove one button (yes) or remove all buttons(no) made by this script ?
	IfMsgBox Yes
	{
		path:=COMObjCreate("Shell.Application").BrowseForFolder(0, "Enter Path which should be removed", 0).Self.Path
		RemoveButton(path)
	}
	IfMsgBox No
	{
		RemoveAllExplorerButtons()
	}
}
return