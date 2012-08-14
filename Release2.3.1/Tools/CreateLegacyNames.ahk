ConditionMapping := {}
Loop D:\Projekte\Autohotkey\7plus\SubEventBackup\Conditions\*.ahk
{
	Loop, Read, %A_LoopFileLongPath%
	{
		if(InStr(A_LoopReadLine, "Condition_") = 1)
		{
			OldName := SubStr(A_LoopReadLine, 11, InStr(A_LoopReadLine, "_", 0, 12) - 11)
			if(!FileExist("D:\Projekte\Autohotkey\7plus\Conditions\" A_LoopFileName))
			{
				MsgBox File %A_LoopFileName% doesn't Exist!
				continue
			}
			Loop, Read, D:\Projekte\Autohotkey\7plus\Conditions\%A_LoopFileName%
			{
				if(InStr(A_LoopReadLine, "static Type :="))
				{
					Start := InStr(A_LoopReadLine, """") + 1
					End := InStr(A_LoopReadLine, """", 0, Start)
					NewName := SubStr(A_LoopReadLine, Start, End - Start)
					if(NewName != OldName)
						ConditionMapping.Insert({OldName : OldName, NewName : NewName})
					break 2
				}
			}
		}
	}
}

ActionMapping := {}
Loop D:\Projekte\Autohotkey\7plus\SubEventBackup\Actions\*.ahk
{
	Loop, Read, %A_LoopFileLongPath%
	{
		if(InStr(A_LoopReadLine, "Action_") = 1)
		{
			OldName := SubStr(A_LoopReadLine, 8, InStr(A_LoopReadLine, "_", 0, 9) - 8)
			if(!FileExist("D:\Projekte\Autohotkey\7plus\Actions\" A_LoopFileName))
			{
				MsgBox File %A_LoopFileName% doesn't Exist!
				continue
			}
			Loop, Read, D:\Projekte\Autohotkey\7plus\Actions\%A_LoopFileName%
			{
				if(InStr(A_LoopReadLine, "static Type :="))
				{
					Start := InStr(A_LoopReadLine, """") + 1
					End := InStr(A_LoopReadLine, """", 0, Start)
					NewName := SubStr(A_LoopReadLine, Start, End - Start)
					if(NewName != OldName)
						ActionMapping.Insert({OldName : OldName, NewName : NewName})
					break 2
				}
			}
		}
	}
}

TriggerMapping := {}
Loop D:\Projekte\Autohotkey\7plus\SubEventBackup\Triggers\*.ahk
{
	Loop, Read, %A_LoopFileLongPath%
	{
		if(InStr(A_LoopReadLine, "Trigger_") = 1)
		{
			OldName := SubStr(A_LoopReadLine, 9, InStr(A_LoopReadLine, "_", 0, 10) - 9)
			if(!FileExist("D:\Projekte\Autohotkey\7plus\Triggers\" A_LoopFileName))
			{
				MsgBox File %A_LoopFileName% doesn't Exist!
				continue
			}
			Loop, Read, D:\Projekte\Autohotkey\7plus\Triggers\%A_LoopFileName%
			{
				if(InStr(A_LoopReadLine, "static Type :="))
				{
					Start := InStr(A_LoopReadLine, """") + 1
					End := InStr(A_LoopReadLine, """", 0, Start)
					NewName := SubStr(A_LoopReadLine, Start, End - Start)
					if(NewName != OldName)
						TriggerMapping.Insert({OldName : OldName, NewName : NewName})
					break 2
				}
			}
		}
	}
}
clip := ""
for index, obj in TriggerMapping
{
	clip .= "  * [docsTriggers" obj.OldName " " obj.NewName "]`n"
}
;~ for index, obj in ConditionMapping
;~ {
	;~ clip .= "  * [docsConditions" obj.OldName " " obj.NewName "]`n"
;~ }
;~ for index, obj in ActionMapping
;~ {
	;~ clip .= "  * [docsActions" obj.OldName " " obj.NewName "]`n"
;~ }
clipboard := clip
