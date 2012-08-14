/*
This class holds some status variables needed by 7plus
*/
Class CApplicationState
{
	IsPortable := false
	ShellHookMessage := ""
	HookProcAdr := ""
	ClipboardListenerRegistered := false
	ProgramStartupFinished := false
	
	;Notify ID for volume OSD
	VolumeNotifyID := ""
	__New()
	{
	
	}
}