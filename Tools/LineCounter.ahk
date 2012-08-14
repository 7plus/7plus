Gui, Add, ListBox, w300 h500 vList
Gui, Add, Button, gStart, Start
Gui, Add, Button, gClear x+10, Clear
Gui, Show
Clear:
GuiControl,, list,|
Files := Array()
return
GuiDropFiles:
Loop, Parse, A_GuiEvent, `n
{
	GuiControl,, List, %A_LoopField%
	Files.Insert(A_LoopField)
}
return
Start:
lines := 0
for index, file in Files
	Loop, Read, %file%
		lines++
msgbox % "lines: " lines
return
GuiClose:
ExitApp
return